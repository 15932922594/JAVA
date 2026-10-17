package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.fenglin.springboottest.entity.AgentOauth;
import com.fenglin.springboottest.entity.AgentResetCode;
import com.fenglin.springboottest.entity.AgentSession;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.mapper.AgentOauthMapper;
import com.fenglin.springboottest.mapper.AgentResetCodeMapper;
import com.fenglin.springboottest.mapper.AgentSessionMapper;
import com.fenglin.springboottest.util.PasswordUtil;
import org.springframework.stereotype.Service;

import java.security.SecureRandom;
import java.time.LocalDateTime;
import java.util.LinkedHashMap;
import java.util.Map;
import java.util.UUID;

/**
 * 账号辅助认证：找回密码 + RIOT 第三方登录
 *
 * 找回密码：邮箱 → 6 位验证码（10 分钟有效）→ 用验证码重置密码并踢掉旧会话。
 *   演示环境没有邮件服务，验证码由接口直接返回给前端展示。
 *
 * RIOT 登录：授权票据（ticket）→ 回调 → 已绑定直接签发 token；
 *   未绑定则进入「建档」步骤，绑定一个新特工账号后再签发 token。
 */
@Service
public class AccountAuthService {

    private static final String PROVIDER = "RIOT";
    private static final int CODE_MINUTES = 10;
    private static final SecureRandom RND = new SecureRandom();

    /** 模拟 Riot 账号池（真实环境应走 accounts.riotgames.com 的 OAuth） */
    private static final String[] RIOT_NAMES = {"JETT", "RAZE", "VIPER", "OMEN", "CHAMBER", "KILLJOY"};
    private static final String[] RIOT_TAGS = {"CN1", "CN2", "KR9", "JP7", "NA5", "EU3"};

    private final AgentResetCodeMapper resetMapper;
    private final AgentOauthMapper oauthMapper;
    private final AgentSessionMapper sessionMapper;
    private final AgentUserService userService;

    public AccountAuthService(AgentResetCodeMapper resetMapper,
                              AgentOauthMapper oauthMapper,
                              AgentSessionMapper sessionMapper,
                              AgentUserService userService) {
        this.resetMapper = resetMapper;
        this.oauthMapper = oauthMapper;
        this.sessionMapper = sessionMapper;
        this.userService = userService;
    }

    /* ==========================================================
       1. 找回密码
       ========================================================== */

    /** 请求验证码：{ email } → { email, code, expiresIn } */
    public Outcome requestReset(String email) {
        String mail = norm(email);
        AgentUser user = byEmail(mail);
        if (user == null) {
            return Outcome.fail(404, "该邮箱未注册，请检查后重试");
        }

        // 同一邮箱的旧验证码一律作废
        resetMapper.delete(new QueryWrapper<AgentResetCode>()
                .eq("email", mail).eq("used", 0));

        String code = String.valueOf(100000 + RND.nextInt(900000));
        AgentResetCode rc = new AgentResetCode();
        rc.setEmail(mail);
        rc.setCode(code);
        rc.setExpiresAt(LocalDateTime.now().plusMinutes(CODE_MINUTES));
        rc.setUsed(0);
        resetMapper.insert(rc);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("email", mail);
        data.put("code", code);
        data.put("expiresIn", CODE_MINUTES * 60);
        data.put("name", user.getName());
        return Outcome.ok("验证码已生成", data);
    }

    /** 用验证码重置密码：{ email, code, newPass } */
    public Outcome confirmReset(String email, String code, String newPass) {
        String mail = norm(email);
        AgentUser user = byEmail(mail);
        if (user == null) {
            return Outcome.fail(404, "该邮箱未注册，请检查后重试");
        }

        AgentResetCode rc = resetMapper.selectOne(new QueryWrapper<AgentResetCode>()
                .eq("email", mail)
                .eq("code", code == null ? "" : code.trim())
                .eq("used", 0)
                .gt("expires_at", LocalDateTime.now())
                .orderByDesc("id")
                .last("LIMIT 1"));
        if (rc == null) {
            return Outcome.fail(400, "验证码错误或已过期");
        }

        // 换盐 + 重算摘要
        String salt = PasswordUtil.randomSalt();
        user.setSalt(salt);
        user.setPasswordHash(PasswordUtil.sha256(salt, newPass));
        userService.updateById(user);

        rc.setUsed(1);
        resetMapper.updateById(rc);

        // 重置密码后踢掉所有会话，要求重新登录
        sessionMapper.delete(new QueryWrapper<AgentSession>().eq("user_id", user.getId()));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("name", user.getName());
        data.put("email", user.getEmail());
        return Outcome.ok("密码重置成功，请使用新密码登录", data);
    }

    /* ==========================================================
       2. RIOT 第三方登录
       ========================================================== */

    /**
     * 第一步：向 Riot 授权网关发起授权 → 返回一次性票据与账号信息
     *
     * @param uidHint 前端记住的 Riot 身份（相当于网关侧的登录态）。
     *                传入且库中存在则复用同一个 Riot 账号，
     *                这样「已绑定 → 直接登录」的路径才走得通；
     *                为空或已失效时视为新账号，重新分配。
     */
    public Outcome riotAuthorize(String uidHint) {
        AgentOauth oauth = null;
        if (uidHint != null && !uidHint.isBlank()) {
            oauth = oauthMapper.selectOne(new QueryWrapper<AgentOauth>()
                    .eq("provider", PROVIDER).eq("provider_uid", uidHint.trim()));
        }
        if (oauth != null) {
            oauth.setTicket(UUID.randomUUID().toString().replace("-", ""));
            oauth.setTicketExpiresAt(LocalDateTime.now().plusMinutes(CODE_MINUTES));
            oauthMapper.updateById(oauth);

            Map<String, Object> data = new LinkedHashMap<>();
            data.put("ticket", oauth.getTicket());
            data.put("riotId", oauth.getRiotId());
            data.put("uid", oauth.getProviderUid());
            data.put("region", "CN");
            data.put("bound", oauth.getUserId() != null);
            data.put("expiresIn", CODE_MINUTES * 60);
            return Outcome.ok("授权网关已就绪", data);
        }

        String uid = UUID.randomUUID().toString().replace("-", "").substring(0, 16);
        String riotId = RIOT_NAMES[RND.nextInt(RIOT_NAMES.length)] + "#" + RIOT_TAGS[RND.nextInt(RIOT_TAGS.length)];
        String ticket = UUID.randomUUID().toString().replace("-", "");

        oauth = new AgentOauth();
        oauth.setProvider(PROVIDER);
        oauth.setProviderUid(uid);
        oauth.setRiotId(riotId);
        oauth.setTicket(ticket);
        oauth.setTicketExpiresAt(LocalDateTime.now().plusMinutes(CODE_MINUTES));
        oauthMapper.insert(oauth);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("ticket", ticket);
        data.put("riotId", riotId);
        data.put("uid", uid);
        data.put("region", "CN");
        data.put("bound", false);
        data.put("expiresIn", CODE_MINUTES * 60);
        return Outcome.ok("授权网关已就绪", data);
    }

    /** 第二步：回调。已绑定 → 直接登录；未绑定 → 返回 bound:false 让前端建档 */
    public Outcome riotCallback(String ticket) {
        AgentOauth oauth = byTicket(ticket);
        if (oauth == null) {
            return Outcome.fail(400, "授权票据无效或已过期，请重新授权");
        }
        if (oauth.getUserId() != null) {
            AgentUser user = userService.getById(oauth.getUserId());
            if (user == null) {
                return Outcome.fail(404, "该 Riot 账号绑定的特工档案已不存在");
            }
            Map<String, Object> account = new LinkedHashMap<>(userService.toSafeMap(user));
            account.put("token", userService.issueToken(user.getId()));
            account.put("riotId", oauth.getRiotId());
            account.put("uid", oauth.getProviderUid());
            // 票据用掉即作废（必须走 UpdateWrapper：updateById 会跳过 null 字段，清空不了）
            clearTicket(oauth.getId());
            return Outcome.ok("已通过 Riot 授权接入", account);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("bound", false);
        data.put("riotId", oauth.getRiotId());
        data.put("ticket", oauth.getTicket());
        data.put("suggestName", oauth.getRiotId().split("#")[0]);
        return Outcome.ok("首次授权，需要创建特工档案", data);
    }

    /** 第三步：把 Riot 账号绑到一个新建的特工档案上并登录 */
    public Outcome riotBind(String ticket, String name, String email, Integer agentIndex, String password) {
        AgentOauth oauth = byTicket(ticket);
        if (oauth == null) {
            return Outcome.fail(400, "授权票据无效或已过期，请重新授权");
        }
        if (oauth.getUserId() != null) {
            return Outcome.fail(409, "该 Riot 账号已绑定其他特工");
        }
        if (name == null || name.trim().length() < 2) {
            return Outcome.fail(400, "代号至少 2 个字符");
        }
        String mail = norm(email);
        if (!mail.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$")) {
            return Outcome.fail(400, "邮箱格式不正确");
        }

        // 未绑定 Riot 的账号没有本站密码，这里随机生成，之后只能走 Riot 或找回密码
        String pass = password == null || password.trim().length() < 6
                ? UUID.randomUUID().toString().replace("-", "")
                : password.trim();

        String reason = userService.register(name, mail, pass, agentIndex == null ? 0 : agentIndex);
        if (!AgentUserService.OK.equals(reason)) {
            return Outcome.fail(409, "duplicate-email".equals(reason) ? "该邮箱已被占用" : "该代号已被占用");
        }

        AgentUser user = byEmail(mail);
        oauthMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<AgentOauth>()
                .eq("id", oauth.getId())
                .set("user_id", user.getId())
                .set("ticket", null)
                .set("ticket_expires_at", null));

        Map<String, Object> account = new LinkedHashMap<>(userService.toSafeMap(user));
        account.put("token", userService.issueToken(user.getId()));
        account.put("riotId", oauth.getRiotId());
        account.put("uid", oauth.getProviderUid());
        return Outcome.ok("Riot 账号绑定成功", account);
    }

    /* ==========================================================
       工具
       ========================================================== */

    /** 作废票据：必须用 UpdateWrapper 显式 set null，updateById 会跳过 null 字段 */
    private void clearTicket(Long id) {
        oauthMapper.update(null, new com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper<AgentOauth>()
                .eq("id", id)
                .set("ticket", null)
                .set("ticket_expires_at", null));
    }

    private AgentOauth byTicket(String ticket) {
        if (ticket == null || ticket.isBlank()) {
            return null;
        }
        return oauthMapper.selectOne(new QueryWrapper<AgentOauth>()
                .eq("provider", PROVIDER)
                .eq("ticket", ticket.trim())
                .gt("ticket_expires_at", LocalDateTime.now()));
    }

    private AgentUser byEmail(String mail) {
        if (mail.isEmpty()) {
            return null;
        }
        return userService.getOne(new QueryWrapper<AgentUser>().eq("email", mail));
    }

    private static String norm(String email) {
        return email == null ? "" : email.trim().toLowerCase();
    }

    /** 业务结果（Service 层不依赖 Controller 的 Result） */
    public static class Outcome {
        private final int code;
        private final String msg;
        private final Map<String, Object> data;

        public Outcome(int code, String msg, Map<String, Object> data) {
            this.code = code;
            this.msg = msg;
            this.data = data;
        }

        public static Outcome ok(String msg, Map<String, Object> data) {
            return new Outcome(0, msg, data);
        }

        public static Outcome fail(int code, String msg) {
            return new Outcome(code, msg, null);
        }

        public boolean isOk() {
            return code == 0;
        }

        public int getCode() {
            return code;
        }

        public String getMsg() {
            return msg;
        }

        public Map<String, Object> getData() {
            return data;
        }
    }
}
