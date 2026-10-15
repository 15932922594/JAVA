package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.service.AgentUserService;
import com.fenglin.springboottest.service.HomeService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 首页接口：供 vue-login 首页调用
 *   POST /api/home/categories  分级分类目录（两级树 + 各类档案数）
 *   POST /api/home/search      分级分类检索（关键词 + 一级/二级分类 + 分级 + 分页）
 *   POST /api/home/overview    首页概览（统计 + 精选 + 最新动态）
 *   POST /api/home/feed        首页动态流（分页）
 */
@RestController
@RequestMapping("/api/home")
public class HomeController {

    private final HomeService homeService;
    private final AgentUserService userService;

    public HomeController(HomeService homeService, AgentUserService userService) {
        this.homeService = homeService;
        this.userService = userService;
    }

    /** 分级分类目录：{ token } → [{code,name,nameEn,count,children:[…]}] */
    @PostMapping("/categories")
    public Result<Object> categories(@RequestBody Map<String, Object> body) {
        if (requireLogin(body) == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(homeService.categories());
    }

    /**
     * 分级分类检索：
     * { token, q, category, subCategory, tier, page, size }
     *   q            关键词，匹配名称 / 代号 / 简介 / 分类名
     *   category     一级分类编码 AGENT / GEAR / MISSION
     *   subCategory  二级分类编码 ASSAULT / RIFLE / RANKED …
     *   tier         分级 S / A / B
     */
    @PostMapping("/search")
    public Result<Object> search(@RequestBody Map<String, Object> body) {
        if (requireLogin(body) == null) {
            return Result.fail(401, "notfound");
        }
        String q = str(body.get("q"));
        String category = str(body.get("category"));
        String sub = str(body.get("subCategory"));
        String tier = str(body.get("tier"));
        long page = toLong(body.get("page"), 1);
        long size = toLong(body.get("size"), 12);
        return Result.ok(homeService.search(q, category, sub, tier, page, size));
    }

    /** 首页概览：{ token } → 统计 / 精选档案 / 最新动态 */
    @PostMapping("/overview")
    public Result<Object> overview(@RequestBody Map<String, Object> body) {
        if (requireLogin(body) == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(homeService.overview());
    }

    /** 首页动态流：{ token, kind, page, size } */
    @PostMapping("/feed")
    public Result<Object> feed(@RequestBody Map<String, Object> body) {
        if (requireLogin(body) == null) {
            return Result.fail(401, "notfound");
        }
        String kind = str(body.get("kind"));
        long page = toLong(body.get("page"), 1);
        long size = toLong(body.get("size"), 5);
        return Result.ok(homeService.feed(kind, page, size));
    }

    /** 校验 token，通过返回用户，否则 null */
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
