package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.service.AgentUserService;
import com.fenglin.springboottest.service.MissionService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 作战任务接口：供 vue-login「作战任务」页调用
 *   POST /api/mission/list       任务列表 + 个人统计（进行中 / 待结算 / 已完成 / 积分）
 *   POST /api/mission/accept     接取任务
 *   POST /api/mission/objective  勾选 / 取消勾选目标
 *   POST /api/mission/abandon    放弃任务
 *   POST /api/mission/claim      结算任务（目标全部完成后发放积分）
 *
 * 所有接口都需要登录态 token，未登录统一返回 401。
 */
@RestController
@RequestMapping("/api/mission")
public class MissionController {

    private final MissionService missionService;
    private final AgentUserService userService;

    public MissionController(MissionService missionService, AgentUserService userService) {
        this.missionService = missionService;
        this.userService = userService;
    }

    /** 任务列表：{ token, status, q, sub, tier } */
    @PostMapping("/list")
    public Result<Object> list(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(missionService.list(
                user.getId(),
                str(body.get("status")),
                str(body.get("q")),
                str(body.get("sub")),
                str(body.get("tier"))));
    }

    /** 接取任务：{ token, code } */
    @PostMapping("/accept")
    public Result<Object> accept(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return wrap(missionService.accept(user.getId(), str(body.get("code"))));
    }

    /** 勾选目标：{ token, code, index } */
    @PostMapping("/objective")
    public Result<Object> objective(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return wrap(missionService.toggleObjective(
                user.getId(), str(body.get("code")), (int) toLong(body.get("index"), -1)));
    }

    /** 放弃任务：{ token, code } */
    @PostMapping("/abandon")
    public Result<Object> abandon(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return wrap(missionService.abandon(user.getId(), str(body.get("code"))));
    }

    /** 结算任务：{ token, code } */
    @PostMapping("/claim")
    public Result<Object> claim(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return wrap(missionService.claim(user.getId(), str(body.get("code"))));
    }

    /* ---------------- 工具 ---------------- */

    private Result<Object> wrap(MissionService.ActionResult r) {
        if (r.isOk()) {
            return new Result<>(0, r.getMsg(), r.getData());
        }
        return Result.fail(r.getCode(), r.getMsg());
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
