package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.service.AccountAuthService;
import com.fenglin.springboottest.service.AgentUserService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 认证接口：供 vue-login 前端调用
 *   POST /api/auth/register  注册
 *   POST /api/auth/login     登录
 */
@RestController
@RequestMapping("/api/auth")
public class AuthController {

    private final AgentUserService userService;
    private final AccountAuthService accountAuthService;

    public AuthController(AgentUserService userService, AccountAuthService accountAuthService) {
        this.userService = userService;
        this.accountAuthService = accountAuthService;
    }

    @PostMapping("/register")
    public Result<Map<String, Object>> register(@RequestBody Map<String, Object> body) {
        String name = str(body.get("name"));
        String email = str(body.get("email"));
        String pass = str(body.get("pass"));
        Integer agentIndex = body.get("agentIndex") == null ? 0 : toInt(body.get("agentIndex"));

        // —— 参数校验（与前端规则一致）——
        if (name.length() < 2) {
            return Result.fail(400, "代号至少 2 个字符");
        }
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$")) {
            return Result.fail(400, "邮箱格式不正确");
        }
        if (pass.length() < 6) {
            return Result.fail(400, "密码至少 6 位");
        }

        String reason = userService.register(name, email, pass, agentIndex);
        if (!AgentUserService.OK.equals(reason)) {
            return Result.fail(409, reason);
        }
        // 返回脱敏账号信息
        Map<String, Object> account = new java.util.LinkedHashMap<>();
        account.put("name", name.trim());
        account.put("email", email.trim().toLowerCase());
        account.put("agentIndex", agentIndex);
        return Result.ok(account);
    }

    @PostMapping("/login")
    public Result<Object> login(@RequestBody Map<String, Object> body) {
        String id = str(body.get("id"));
        String pass = str(body.get("pass"));
        if (id.length() < 3 || pass.length() < 6) {
            return Result.fail(400, "凭证校验失败，请检查输入");
        }
        Object outcome = userService.login(id, pass);
        if (outcome instanceof String reason) {
            // notfound / wrongpass
            return Result.fail(401, reason);
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> account = (Map<String, Object>) outcome;
        // 签发会话 token（7 天有效），前端保存后实现「保持登录 / 自动登录」
        Long userId = ((Number) account.get("id")).longValue();
        account.put("token", userService.issueToken(userId));
        return Result.ok(account);
    }

    /** 用 token 换账号信息：页面刷新时自动登录 */
    @PostMapping("/me")
    public Result<Object> me(@RequestBody Map<String, Object> body) {
        AgentUser user = userService.resolveToken(str(body.get("token")));
        if (user == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(userService.toSafeMap(user));
    }

    /** 退出登录：注销 token */
    @PostMapping("/logout")
    public Result<Object> logout(@RequestBody Map<String, Object> body) {
        boolean removed = userService.deleteToken(str(body.get("token")));
        return removed ? Result.ok() : Result.fail(401, "notfound");
    }

    /* ================= 登录后的账号管理 ================= */

    /** 修改密码：{ token, oldPass, newPass } */
    @PostMapping("/change-pass")
    public Result<Object> changePass(@RequestBody Map<String, Object> body) {
        AgentUser user = userService.resolveToken(str(body.get("token")));
        if (user == null) {
            return Result.fail(401, "notfound");
        }
        String oldPass = str(body.get("oldPass"));
        String newPass = str(body.get("newPass"));
        if (oldPass.length() < 6 || newPass.length() < 6) {
            return Result.fail(400, "badpass");
        }
        String reason = userService.changePassword(user.getId(), oldPass, newPass);
        return AgentUserService.OK.equals(reason) ? Result.ok() : Result.fail(400, reason);
    }

    /** 会话列表（登录设备）：{ token } → [{id, createTime, expiresAt, current}] */
    @PostMapping("/sessions")
    public Result<Object> sessions(@RequestBody Map<String, Object> body) {
        String token = str(body.get("token"));
        AgentUser user = userService.resolveToken(token);
        if (user == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(userService.listSessions(user.getId(), token));
    }

    /** 注销其他会话（踢出设备）：{ token, sessionId } */
    @PostMapping("/revoke")
    public Result<Object> revoke(@RequestBody Map<String, Object> body) {
        AgentUser user = userService.resolveToken(str(body.get("token")));
        if (user == null) {
            return Result.fail(401, "notfound");
        }
        Long sessionId = toLong(body.get("sessionId"));
        if (sessionId == null) {
            return Result.fail(400, "badsession");
        }
        boolean removed = userService.revokeSession(user.getId(), sessionId);
        return removed ? Result.ok() : Result.fail(404, "notfound");
    }

    /* ================= 找回密码 ================= */

    /** 请求验证码：{ email } → { email, code, expiresIn, name } */
    @PostMapping("/reset/request")
    public Result<Object> resetRequest(@RequestBody Map<String, Object> body) {
        String email = str(body.get("email"));
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$")) {
            return Result.fail(400, "邮箱格式不正确");
        }
        return wrap(accountAuthService.requestReset(email));
    }

    /** 用验证码重置密码：{ email, code, newPass } */
    @PostMapping("/reset/confirm")
    public Result<Object> resetConfirm(@RequestBody Map<String, Object> body) {
        String email = str(body.get("email"));
        String code = str(body.get("code"));
        String newPass = str(body.get("newPass"));
        if (!email.matches("^[^\\s@]+@[^\\s@]+\\.[^\\s@]{2,}$")) {
            return Result.fail(400, "邮箱格式不正确");
        }
        if (code.isEmpty()) {
            return Result.fail(400, "请输入验证码");
        }
        if (newPass.length() < 6) {
            return Result.fail(400, "新密码至少 6 位");
        }
        return wrap(accountAuthService.confirmReset(email, code, newPass));
    }

    /* ================= RIOT 第三方登录 ================= */

    /** 发起授权：{ uid? } → { ticket, riotId, uid, region, bound }；uid 用于复用同一个 Riot 身份 */
    @PostMapping("/riot/authorize")
    public Result<Object> riotAuthorize(@RequestBody(required = false) Map<String, Object> body) {
        return wrap(accountAuthService.riotAuthorize(body == null ? "" : str(body.get("uid"))));
    }

    /** 授权回调：{ ticket } → 已绑定直接返回账号 + token；未绑定返回 bound:false */
    @PostMapping("/riot/callback")
    public Result<Object> riotCallback(@RequestBody Map<String, Object> body) {
        return wrap(accountAuthService.riotCallback(str(body.get("ticket"))));
    }

    /** 首次授权建档并绑定：{ ticket, name, email, agentIndex } → 账号 + token */
    @PostMapping("/riot/bind")
    public Result<Object> riotBind(@RequestBody Map<String, Object> body) {
        return wrap(accountAuthService.riotBind(
                str(body.get("ticket")),
                str(body.get("name")),
                str(body.get("email")),
                toInt(body.get("agentIndex")),
                str(body.get("pass"))));
    }

    private Result<Object> wrap(AccountAuthService.Outcome o) {
        if (o.isOk()) {
            return new Result<>(0, o.getMsg(), o.getData());
        }
        return Result.fail(o.getCode(), o.getMsg());
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }

    private static int toInt(Object o) {
        try {
            return (int) Double.parseDouble(String.valueOf(o));
        } catch (NumberFormatException e) {
            return 0;
        }
    }

    private static Long toLong(Object o) {
        try {
            return (long) Double.parseDouble(String.valueOf(o));
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
