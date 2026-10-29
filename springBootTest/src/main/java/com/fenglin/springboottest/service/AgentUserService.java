package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.entity.AgentSession;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.mapper.AgentSessionMapper;
import com.fenglin.springboottest.mapper.AgentUserMapper;
import com.fenglin.springboottest.util.PasswordUtil;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 账号业务：注册 / 登录 / 会话（token）
 * 错误码约定（与前端 src/store/accounts.js 的 reason 对应）：
 *   duplicate-email  邮箱已被注册
 *   duplicate-name   代号已被占用
 *   notfound         账号不存在
 *   wrongpass        密码错误
 */
@Service
public class AgentUserService extends ServiceImpl<AgentUserMapper, AgentUser> {

    private final AgentSessionMapper sessionMapper;

    /** 会话有效期：7 天 */
    private static final int SESSION_DAYS = 7;

    public AgentUserService(AgentSessionMapper sessionMapper) {
        this.sessionMapper = sessionMapper;
    }

    /** 注册成功 / 失败原因（失败为上述错误码，成功为 "ok"） */
    public static final String OK = "ok";

    /** 权限：默认权限（普通用户），看不到后台入口、不能登录后台 */
    public static final int PERMISSION_USER = 1;

    /** 权限：管理员权限，可以看到后台入口并登录后台管理系统 */
    public static final int PERMISSION_ADMIN = 0;

    public String register(String name, String email, String password, Integer agentIndex) {
        String mail = email == null ? "" : email.trim().toLowerCase();

        if (count(new QueryWrapper<AgentUser>().eq("email", mail)) > 0) {
            return "duplicate-email";
        }
        if (count(new QueryWrapper<AgentUser>().eq("name", name)) > 0) {
            return "duplicate-name";
        }

        AgentUser user = new AgentUser();
        user.setName(name.trim());
        user.setEmail(mail);
        // 密码明文存储（需求要求不加密）
        user.setPassword(password);
        // 注册用户一律为默认权限；管理员权限只能由后台授权或直接改库
        user.setPermission(PERMISSION_USER);
        user.setAgentIndex(agentIndex == null ? 0 : agentIndex);
        save(user);
        return OK;
    }

    /** 是否为管理员权限账号 */
    public static boolean isAdmin(AgentUser user) {
        return user != null && user.getPermission() != null && user.getPermission() == PERMISSION_ADMIN;
    }

    /**
     * 密码校验：明文优先（新账号 / 改过密码的账号），
     * 明文列为空时才回退到旧的 SHA-256(salt::password) 摘要，避免历史账号直接失效。
     */
    public boolean matchPassword(AgentUser user, String rawPassword) {
        if (user == null || rawPassword == null) {
            return false;
        }
        if (user.getPassword() != null) {
            return user.getPassword().equals(rawPassword);
        }
        return user.getSalt() != null
                && user.getPasswordHash() != null
                && PasswordUtil.matches(user.getSalt(), rawPassword, user.getPasswordHash());
    }

    /** 写入明文密码，同时清掉旧摘要（改为明文后不再需要盐） */
    public void savePlainPassword(AgentUser user, String rawPassword) {
        user.setPassword(rawPassword);
        user.setSalt("");
        user.setPasswordHash("");
        updateById(user);
    }

    /** 登录校验：账号不存在 / 密码错误 / 成功（返回脱敏后的账号信息） */
    public Object login(String id, String password) {
        String key = id == null ? "" : id.trim().toLowerCase();
        AgentUser user = getOne(new QueryWrapper<AgentUser>()
                .eq("email", key)
                .or()
                .eq("name", id == null ? "" : id.trim()));

        if (user == null) {
            return "notfound";
        }
        if (!matchPassword(user, password)) {
            return "wrongpass";
        }

        // 顺手清掉已过期的会话
        sessionMapper.delete(new QueryWrapper<AgentSession>()
                .lt("expires_at", LocalDateTime.now()));

        return toSafeMap(user);
    }

    /** 登录成功后签发会话 token（有效期 7 天） */
    public String issueToken(Long userId) {
        AgentSession session = new AgentSession();
        session.setToken(UUID.randomUUID().toString().replace("-", ""));
        session.setUserId(userId);
        session.setExpiresAt(LocalDateTime.now().plusDays(SESSION_DAYS));
        sessionMapper.insert(session);
        return session.getToken();
    }

    /** 用 token 换账号信息（自动登录）；无效 / 过期返回 null */
    public AgentUser resolveToken(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        AgentSession session = sessionMapper.selectOne(
                new QueryWrapper<AgentSession>().eq("token", token));
        if (session == null) {
            return null;
        }
        if (session.getExpiresAt().isBefore(LocalDateTime.now())) {
            // 已过期：删除并视为未登录
            sessionMapper.deleteById(session.getId());
            return null;
        }
        return getById(session.getUserId());
    }

    /** 退出登录：注销 token */
    public boolean deleteToken(String token) {
        if (token == null || token.isBlank()) {
            return false;
        }
        return sessionMapper.delete(new QueryWrapper<AgentSession>().eq("token", token)) > 0;
    }

    /* ================= 登录后的账号管理 ================= */

    /** 修改密码：校验旧密码，成功后以明文写入新密码 */
    public String changePassword(Long userId, String oldPassword, String newPassword) {
        AgentUser user = getById(userId);
        if (user == null) {
            return "notfound";
        }
        if (!matchPassword(user, oldPassword)) {
            return "wrongpass";
        }
        savePlainPassword(user, newPassword);
        return OK;
    }

    /**
     * 修改权限：0 管理员权限 / 1 默认权限。
     * 权限变更后该账号所有会话仍在，但后台会实时校验 permission，
     * 被降级的账号立刻无法继续访问后台接口。
     */
    public String updatePermission(Long userId, int permission) {
        AgentUser user = getById(userId);
        if (user == null) {
            return "notfound";
        }
        if (permission != PERMISSION_ADMIN && permission != PERMISSION_USER) {
            return "badperm";
        }
        user.setPermission(permission);
        updateById(user);
        return OK;
    }

    private static final DateTimeFormatter TS = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /**
     * 当前用户的所有有效会话（登录设备管理）。
     * token 对应的会话标记 current=true，供前端区分「本机」与「其他设备」。
     */
    public List<Map<String, Object>> listSessions(Long userId, String token) {
        // 顺手清理已过期会话
        sessionMapper.delete(new QueryWrapper<AgentSession>()
                .lt("expires_at", LocalDateTime.now()));

        List<Map<String, Object>> result = new ArrayList<>();
        for (AgentSession s : sessionMapper.selectList(new QueryWrapper<AgentSession>()
                .eq("user_id", userId)
                .orderByDesc("create_time"))) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", s.getId());
            m.put("createTime", s.getCreateTime() == null ? "" : s.getCreateTime().format(TS));
            m.put("expiresAt", s.getExpiresAt() == null ? "" : s.getExpiresAt().format(TS));
            m.put("current", token != null && token.equals(s.getToken()));
            result.add(m);
        }
        return result;
    }

    /** 注销指定会话（只允许注销自己的；返回是否成功） */
    public boolean revokeSession(Long userId, Long sessionId) {
        return sessionMapper.delete(new QueryWrapper<AgentSession>()
                .eq("id", sessionId)
                .eq("user_id", userId)) > 0;
    }

    /** 脱敏：不返回密码相关字段 */
    public Map<String, Object> toSafeMap(AgentUser user) {
        Map<String, Object> info = new LinkedHashMap<>();
        info.put("id", user.getId());
        info.put("name", user.getName());
        info.put("email", user.getEmail());
        info.put("agentIndex", user.getAgentIndex());
        info.put("permission", user.getPermission() == null ? PERMISSION_USER : user.getPermission());
        return info;
    }
}
