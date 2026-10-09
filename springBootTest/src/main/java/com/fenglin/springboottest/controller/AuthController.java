package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
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

    public AuthController(AgentUserService userService) {
        this.userService = userService;
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
