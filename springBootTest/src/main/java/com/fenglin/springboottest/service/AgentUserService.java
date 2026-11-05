package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.common.HeroLevel;
import com.fenglin.springboottest.common.WeaponCatalog;
import com.fenglin.springboottest.entity.AgentSession;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.entity.AgentWeapon;
import com.fenglin.springboottest.mapper.AgentSessionMapper;
import com.fenglin.springboottest.mapper.AgentUserMapper;
import com.fenglin.springboottest.mapper.AgentWeaponMapper;
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
    private final AgentWeaponMapper weaponMapper;
    private final HeroLevelService levelService;

    /** 会话有效期：7 天 */
    private static final int SESSION_DAYS = 7;

    public AgentUserService(AgentSessionMapper sessionMapper, AgentWeaponMapper weaponMapper,
                            HeroLevelService levelService) {
        this.sessionMapper = sessionMapper;
        this.weaponMapper = weaponMapper;
        this.levelService = levelService;
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
        // 新特工：英雄从 1 级开始 + 起始信用点；标配免费人手一把，注册即拥有
        user.setHeroLevel(1);
        user.setCredits(WeaponCatalog.START_CREDITS);
        save(user);
        weaponMapper.insert(new AgentWeapon(user.getId(), user.getName(), "classic", "标配"));
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

        // 每日首次登录 +20 EXP（同一天重复登录不重复发）
        java.time.LocalDate today = java.time.LocalDate.now();
        if (user.getLastLoginDate() == null || !today.equals(user.getLastLoginDate())) {
            userMapper0().update(null, new UpdateWrapper<AgentUser>()
                    .eq("id", user.getId())
                    .set("last_login_date", today));
            user.setLastLoginDate(today);
            levelService.gain(user.getId(), HeroLevel.DAILY_LOGIN_EXP, user);
        }

        return toSafeMap(user);
    }

    /** 本服务的 BaseMapper（MyBatis-Plus 自带 getBaseMapper 的别名，便于阅读） */
    private com.fenglin.springboottest.mapper.AgentUserMapper userMapper0() {
        return getBaseMapper();
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
        info.put("credits", user.getCredits() == null ? WeaponCatalog.START_CREDITS : user.getCredits());

        // 经验与等级：**以 exp 为唯一真相**，等级由公式实时推导（避免手动改库造成等级/经验冲突）
        int exp = user.getExp() == null ? 0 : user.getExp();
        int level = HeroLevel.levelOf(exp);
        info.put("heroLevel", level);
        info.put("exp", exp);
        info.put("expInLevel", HeroLevel.expInLevel(exp));
        info.put("expForNext", HeroLevel.expForNext(level));
        // 头像框：已解锁的可在图鉴里自选佩戴；0 = 跟随最新解锁
        int frameMaxTier = HeroLevel.frameMaxTier(level);
        int frameShown = HeroLevel.shownFrameTier(level, user.getEquippedFrame());
        Integer eqFrame = user.getEquippedFrame();
        info.put("frameTier", frameShown);
        info.put("frameMaxTier", frameMaxTier);
        info.put("frameAuto", eqFrame == null || eqFrame == 0 || eqFrame >= frameMaxTier);
        info.put("frameName", HeroLevel.frameNameOfTier(frameShown));
        info.put("frameEn", HeroLevel.frameEnOfTier(frameShown));
        info.put("nextFrameLevel", HeroLevel.nextFrameLevel(level));
        info.put("nextFrameName", HeroLevel.nextFrameName(level));
        // 等级无上限，不再有 maxLevel 字段（前端按 exp / expForNext 画进度条即可）

        // 战力与装备：竞技场 / 排行榜展示用
        String weapon = user.getEquippedWeapon() == null || user.getEquippedWeapon().isBlank()
                ? "classic" : user.getEquippedWeapon();
        info.put("equippedWeapon", weapon);
        info.put("power", com.fenglin.springboottest.common.HeroStats.power(user.getAgentIndex(), level, weapon));
        info.put("pkWin", user.getPkWin() == null ? 0 : user.getPkWin());
        info.put("pkLose", user.getPkLose() == null ? 0 : user.getPkLose());
        return info;
    }
}
