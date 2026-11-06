package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.service.AgentUserService;
import com.fenglin.springboottest.service.SocialService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.LinkedHashMap;
import java.util.Map;

/**
 * 社交 / 竞技接口（vue-login「竞技场」页）
 *   POST /api/social/friends   好友面板（好友 / 收到的申请 / 发出的申请 / 我的资料）
 *   POST /api/social/search    按代号搜索玩家（带关系状态）
 *   POST /api/social/request   发送好友申请
 *   POST /api/social/accept    同意申请
 *   POST /api/social/reject    拒绝申请
 *   POST /api/social/remove    删除好友
 *   POST /api/social/rank      战力排行榜（前 50 + 我的名次）
 *   POST /api/social/pk        与任意特工自动 PK（每天同一对手 3 场）
 *   POST /api/social/frame     佩戴头像框（tier=0 跟随最新解锁）
 *   POST /api/social/logs      我的 PK 记录
 */
@RestController
@RequestMapping("/api/social")
public class SocialController {

    private final SocialService socialService;
    private final AgentUserService userService;

    public SocialController(SocialService socialService, AgentUserService userService) {
        this.socialService = socialService;
        this.userService = userService;
    }

    @PostMapping("/friends")
    public Result<Object> friends(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        return me == null ? Result.fail(401, "登录态已失效，请重新登录")
                : Result.ok(socialService.friends(me));
    }

    @PostMapping("/search")
    public Result<Object> search(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(socialService.search(me, str(body.get("q"))));
    }

    @PostMapping("/request")
    public Result<Object> request(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        String r = socialService.request(me, toLong(body.get("targetId")));
        return "ok".equals(r) ? Result.ok(msg("好友申请已发送")) : Result.fail(400, r);
    }

    @PostMapping("/accept")
    public Result<Object> accept(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        String r = socialService.accept(me, toLong(body.get("rowId")));
        return "ok".equals(r) ? Result.ok(msg("已同意好友申请")) : Result.fail(400, r);
    }

    @PostMapping("/reject")
    public Result<Object> reject(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        String r = socialService.reject(me, toLong(body.get("rowId")));
        return "ok".equals(r) ? Result.ok(msg("已拒绝")) : Result.fail(400, r);
    }

    @PostMapping("/remove")
    public Result<Object> remove(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        socialService.removeFriend(me, toLong(body.get("friendId")));
        return Result.ok(msg("已删除好友"));
    }

    @PostMapping("/rank")
    public Result<Object> rank(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        return me == null ? Result.fail(401, "登录态已失效，请重新登录")
                : Result.ok(socialService.rank(me));
    }

    @PostMapping("/pk")
    public Result<Object> pk(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        Object r = socialService.pk(me, toLong(body.get("targetId")));
        return r instanceof String reason ? Result.fail(400, reason) : Result.ok(r);
    }

    /** 佩戴头像框（tier = 0 跟随最新解锁；未解锁的档位返回 frame-locked） */
    @PostMapping("/frame")
    public Result<Object> frame(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        Integer tier = null;
        try {
            tier = (int) Double.parseDouble(String.valueOf(body.get("tier")));
        } catch (Exception ignored) {
        }
        Map<String, Object> r = socialService.equipFrame(me, tier);
        return r == null ? Result.fail(400, "frame-locked") : Result.ok(r);
    }

    @PostMapping("/logs")
    public Result<Object> logs(@RequestBody Map<String, Object> body) {
        AgentUser me = requireLogin(body);
        if (me == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        int limit = 20;
        try {
            limit = (int) Double.parseDouble(String.valueOf(body.get("limit")));
        } catch (Exception ignored) {
        }
        return Result.ok(socialService.logs(me, limit));
    }

    private AgentUser requireLogin(Map<String, Object> body) {
        return body == null ? null : userService.resolveToken(str(body.get("token")));
    }

    private static Map<String, Object> msg(String text) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("msg", text);
        return m;
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }

    private static Long toLong(Object o) {
        try {
            return (long) Double.parseDouble(String.valueOf(o));
        } catch (Exception e) {
            return null;
        }
    }
}
