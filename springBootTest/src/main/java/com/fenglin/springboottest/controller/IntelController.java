package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.service.AgentUserService;
import com.fenglin.springboottest.service.IntelService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 情报中心接口：供 vue-login「情报中心」页调用
 *   POST /api/intel/list      列表（类型 / 状态 / 关键词 / 排序 / 分页）+ 统计
 *   POST /api/intel/detail    详情（含正文，打开即标记已读）
 *   POST /api/intel/read      标记已读 / 未读
 *   POST /api/intel/star      收藏 / 取消收藏
 *   POST /api/intel/like      点赞 / 取消点赞
 *   POST /api/intel/mark-all  全部标记已读
 *   POST /api/intel/stats     未读 / 已读 / 收藏 / 点赞统计
 */
@RestController
@RequestMapping("/api/intel")
public class IntelController {

    private final IntelService intelService;
    private final AgentUserService userService;

    public IntelController(IntelService intelService, AgentUserService userService) {
        this.intelService = intelService;
        this.userService = userService;
    }

    @PostMapping("/list")
    public Result<Object> list(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(intelService.list(
                user.getId(),
                str(body.get("kind")),
                str(body.get("status")),
                str(body.get("q")),
                str(body.get("sort")),
                toLong(body.get("page"), 1),
                toLong(body.get("size"), 6)));
    }

    @PostMapping("/detail")
    public Result<Object> detail(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        Map<String, Object> data = intelService.detail(user.getId(), toLong(body.get("id"), 0));
        return data == null ? Result.fail(404, "情报不存在或已下线") : Result.ok(data);
    }

    @PostMapping("/read")
    public Result<Object> read(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        boolean read = !"false".equalsIgnoreCase(String.valueOf(body.get("read")));
        Map<String, Object> data = intelService.markRead(user.getId(), toLong(body.get("id"), 0), read);
        return data == null ? Result.fail(404, "情报不存在") : Result.ok(data);
    }

    @PostMapping("/star")
    public Result<Object> star(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        Map<String, Object> data = intelService.toggleStar(user.getId(), toLong(body.get("id"), 0));
        return data == null ? Result.fail(404, "情报不存在") : Result.ok(data);
    }

    @PostMapping("/like")
    public Result<Object> like(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        Map<String, Object> data = intelService.toggleLike(user.getId(), toLong(body.get("id"), 0));
        return data == null ? Result.fail(404, "情报不存在") : Result.ok(data);
    }

    @PostMapping("/mark-all")
    public Result<Object> markAll(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(intelService.markAllRead(user.getId()));
    }

    @PostMapping("/stats")
    public Result<Object> stats(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(intelService.stats(user.getId()));
    }

    private AgentUser requireLogin(Map<String, Object> body) {
        return body == null ? null : userService.resolveToken(str(body.get("token")));
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }

    private static long toLong(Object o, long def) {
        try {
            return (long) Double.parseDouble(String.valueOf(o));
        } catch (Exception e) {
            return def;
        }
    }
}
