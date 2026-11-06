package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.service.AgentUserService;
import com.fenglin.springboottest.service.ArmoryService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 军械商店接口：供 vue-login「军械商店」页调用
 *   POST /api/game/armory      商店页数据（余额 / 等级 / 武器目录 / 已拥有）
 *   POST /api/game/armory/buy  购买武器（扣信用点）
 *
 * 购买失败错误码（前端按 code 映射提示）：
 *   unknown-weapon       武器代号不存在
 *   already-owned        已拥有该武器
 *   not-enough-credits   信用点不足
 */
@RestController
@RequestMapping("/api/game/armory")
public class ArmoryController {

    private final ArmoryService armoryService;
    private final AgentUserService userService;

    public ArmoryController(ArmoryService armoryService, AgentUserService userService) {
        this.armoryService = armoryService;
        this.userService = userService;
    }

    @PostMapping
    public Result<Object> armory(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        return Result.ok(armoryService.armory(user));
    }

    @PostMapping("/buy")
    public Result<Object> buy(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        Object r = armoryService.buy(user, str(body.get("code")));
        if (r instanceof String reason) {
            return Result.fail(400, reason);
        }
        return Result.ok(r);
    }

    /** 装备主武器（影响战力） */
    @PostMapping("/equip")
    public Result<Object> equip(@RequestBody Map<String, Object> body) {
        AgentUser user = requireLogin(body);
        if (user == null) {
            return Result.fail(401, "登录态已失效，请重新登录");
        }
        Object r = armoryService.equip(user, str(body.get("code")));
        if (r instanceof String reason) {
            return Result.fail(400, reason);
        }
        return Result.ok(r);
    }

    private AgentUser requireLogin(Map<String, Object> body) {
        return body == null ? null : userService.resolveToken(str(body.get("token")));
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }
}
