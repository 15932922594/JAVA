package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.service.AgentUserService;
import com.fenglin.springboottest.service.GameService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * RANGE 训练场接口：供 vue-login「训练场」页调用
 *   POST /api/game/report   上报一局成绩（自动推进匹配的作战任务目标）
 *   POST /api/game/stats    个人各模式统计（局数 / 累计 / 最佳）
 *   POST /api/game/records  最近成绩记录
 */
@RestController
@RequestMapping("/api/game")
public class GameController {

    private final GameService gameService;
    private final AgentUserService userService;

    public GameController(GameService gameService, AgentUserService userService) {
        this.gameService = gameService;
        this.userService = userService;
    }

    @PostMapping("/report")
    public Result<Object> report(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(gameService.report(
                user.getId(),
                str(body.get("mode")),
                toInt(body.get("score")),
                toInt(body.get("units")),
                toInt(body.get("shots")),
                toInt(body.get("hits")),
                toInt(body.get("avgMs"))));
    }

    @PostMapping("/stats")
    public Result<Object> stats(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(gameService.stats(user.getId()));
    }

    @PostMapping("/records")
    public Result<Object> records(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(gameService.records(user.getId(), toInt(body.get("limit"), 10)));
    }

    private AgentUser requireLogin(Map<String, Object> body) {
        return body == null ? null : userService.resolveToken(str(body.get("token")));
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }

    private static int toInt(Object o) {
        return toInt(o, 0);
    }

    private static int toInt(Object o, int def) {
        try {
            return (int) Double.parseDouble(String.valueOf(o));
        } catch (Exception e) {
            return def;
        }
    }
}
