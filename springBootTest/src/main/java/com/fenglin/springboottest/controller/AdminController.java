package com.fenglin.springboottest.controller;

import com.fenglin.springboottest.common.Result;
import com.fenglin.springboottest.entity.AdminUser;
import com.fenglin.springboottest.entity.ArchiveCategory;
import com.fenglin.springboottest.mapper.ArchiveCategoryMapper;
import com.fenglin.springboottest.service.AdminService;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

/**
 * 后台管理接口（供 vue-login 前端 AdminLogin / AdminDashboard 调用）
 *
 * 管理员与前台特工账号隔离（admin_user），后台只登录不注册。
 * 除 login 外所有接口都要求携带有效 token（AdminLogin 成功后前端保存于 admin_token）。
 *
 *   POST /api/admin/login          登录 → { id, username, displayName, token }
 *   POST /api/admin/verify         校验 token（刷新保持登录）
 *   POST /api/admin/logout         退出
 *   POST /api/admin/change-pass    修改管理员密码
 *   POST /api/admin/stats          各表记录数
 *   POST /api/admin/archive/*      档案 list / save / delete
 *   POST /api/admin/category/*     分类 list / save / delete（一级分类不可删）
 *   POST /api/admin/feed/*         动态(情报) list / save / delete
 *   POST /api/admin/mission/*      任务简报 list / save / delete
 *   POST /api/admin/user/list      前台用户（只读）
 *   POST /api/admin/log/list       操作日志
 */
@RestController
@RequestMapping("/api/admin")
public class AdminController {

    private final AdminService adminService;
    private final ArchiveCategoryMapper categoryMapper;

    public AdminController(AdminService adminService, ArchiveCategoryMapper categoryMapper) {
        this.adminService = adminService;
        this.categoryMapper = categoryMapper;
    }

    /* ================= 登录态 ================= */

    @PostMapping("/login")
    public Result<Object> login(@RequestBody Map<String, Object> body) {
        String username = str(body.get("username"));
        String pass = str(body.get("pass"));
        if (username.isEmpty() || pass.isEmpty()) {
            return Result.fail(400, "请输入账号与密码");
        }
        Object outcome = adminService.login(username, pass);
        if (outcome instanceof String reason) {
            return Result.fail(401, switch (reason) {
                case "notfound" -> "账号不存在";
                case "disabled" -> "账号已被停用";
                case "wrongpass" -> "密码错误";
                default -> "登录失败";
            });
        }
        return Result.ok(outcome);
    }

    /** 校验 token：前端刷新页面时恢复后台登录态 */
    @PostMapping("/verify")
    public Result<Object> verify(@RequestBody Map<String, Object> body) {
        AdminUser admin = adminService.resolveToken(str(body.get("token")));
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.toSafeMap(admin, admin.getToken()));
    }

    @PostMapping("/logout")
    public Result<Object> logout(@RequestBody Map<String, Object> body) {
        boolean removed = adminService.logout(str(body.get("token")));
        return removed ? Result.ok() : Result.fail(401, "notfound");
    }

    @PostMapping("/change-pass")
    public Result<Object> changePass(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        String reason = adminService.changePassword(admin.getId(), str(body.get("oldPass")), str(body.get("newPass")));
        return switch (reason) {
            case "ok" -> Result.ok();
            case "wrongpass" -> Result.fail(400, "旧密码错误");
            case "weakpass" -> Result.fail(400, "新密码至少 6 位");
            default -> Result.fail(400, reason);
        };
    }

    /* ================= 概览统计 ================= */

    @PostMapping("/stats")
    public Result<Object> stats(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.stats());
    }

    /* ================= 档案 ================= */

    @PostMapping("/archive/list")
    public Result<Object> archiveList(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.listArchive(str(body.get("q")),
                intOf(body.get("page"), 1), intOf(body.get("size"), 8)));
    }

    @PostMapping("/archive/save")
    public Result<Object> archiveSave(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        String reason = adminService.saveArchive(data);
        if ("ok".equals(reason)) {
            adminService.record(admin, "archive",
                    data != null && data.get("id") != null ? "UPDATE" : "CREATE",
                    "档案：" + data.get("name"));
            return Result.ok();
        }
        return Result.fail(400, switch (reason) {
            case "empty" -> "代号与名称必填";
            case "duplicate-code" -> "档案代号已存在";
            case "notfound" -> "档案不存在";
            default -> reason;
        });
    }

    @PostMapping("/archive/delete")
    public Result<Object> archiveDelete(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        Long id = longOf(body.get("id"));
        if (id == null || !adminService.deleteArchive(id)) {
            return Result.fail(400, "notfound");
        }
        adminService.record(admin, "archive", "DELETE", "删除档案 id=" + id);
        return Result.ok();
    }

    /* ================= 分类 ================= */

    @PostMapping("/category/list")
    public Result<Object> categoryList(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.listCategory());
    }

    @PostMapping("/category/save")
    public Result<Object> categorySave(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        String reason = adminService.saveCategory(data);
        if ("ok".equals(reason)) {
            adminService.record(admin, "category",
                    data != null && data.get("id") != null ? "UPDATE" : "CREATE",
                    "分类：" + data.get("name"));
            return Result.ok();
        }
        return Result.fail(400, switch (reason) {
            case "empty" -> "编码与名称必填";
            case "duplicate-code" -> "分类编码已存在";
            case "notfound" -> "分类不存在";
            default -> reason;
        });
    }

    @PostMapping("/category/delete")
    public Result<Object> categoryDelete(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        Long id = longOf(body.get("id"));
        if (id == null) {
            return Result.fail(400, "notfound");
        }
        String reason = adminService.deleteCategory(id);
        if ("ok".equals(reason)) {
            adminService.record(admin, "category", "DELETE", "删除分类 id=" + id);
            return Result.ok();
        }
        return Result.fail(400, "root".equals(reason) ? "一级分类不可删除" : "分类不存在");
    }

    /* ================= 动态 / 情报 ================= */

    @PostMapping("/feed/list")
    public Result<Object> feedList(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.listFeed(str(body.get("q")),
                intOf(body.get("page"), 1), intOf(body.get("size"), 8)));
    }

    @PostMapping("/feed/save")
    public Result<Object> feedSave(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        String reason = adminService.saveFeed(data);
        if ("ok".equals(reason)) {
            adminService.record(admin, "feed",
                    data != null && data.get("id") != null ? "UPDATE" : "CREATE",
                    "动态：" + data.get("title"));
            return Result.ok();
        }
        return Result.fail(400, switch (reason) {
            case "empty" -> "标题必填";
            case "notfound" -> "动态不存在";
            default -> reason;
        });
    }

    @PostMapping("/feed/delete")
    public Result<Object> feedDelete(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        Long id = longOf(body.get("id"));
        if (id == null || !adminService.deleteFeed(id)) {
            return Result.fail(400, "notfound");
        }
        adminService.record(admin, "feed", "DELETE", "删除动态 id=" + id);
        return Result.ok();
    }

    /* ================= 任务简报 ================= */

    @PostMapping("/mission/list")
    public Result<Object> missionList(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.listMission(str(body.get("q")),
                intOf(body.get("page"), 1), intOf(body.get("size"), 8)));
    }

    @PostMapping("/mission/save")
    public Result<Object> missionSave(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        @SuppressWarnings("unchecked")
        Map<String, Object> data = (Map<String, Object>) body.get("data");
        String reason = adminService.saveMission(data);
        if ("ok".equals(reason)) {
            adminService.record(admin, "mission",
                    data != null && data.get("id") != null ? "UPDATE" : "CREATE",
                    "任务：" + data.get("mission_code"));
            return Result.ok();
        }
        return Result.fail(400, switch (reason) {
            case "empty" -> "任务代号必填";
            case "duplicate-code" -> "该任务代号已有简报";
            case "notfound" -> "简报不存在";
            default -> reason;
        });
    }

    @PostMapping("/mission/delete")
    public Result<Object> missionDelete(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        Long id = longOf(body.get("id"));
        if (id == null || !adminService.deleteMission(id)) {
            return Result.fail(400, "notfound");
        }
        adminService.record(admin, "mission", "DELETE", "删除任务简报 id=" + id);
        return Result.ok();
    }

    /* ================= 前台用户（只读） ================= */

    @PostMapping("/user/list")
    public Result<Object> userList(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.listUser(str(body.get("q")),
                intOf(body.get("page"), 1), intOf(body.get("size"), 8)));
    }

    /* ================= 操作日志 ================= */

    @PostMapping("/log/list")
    public Result<Object> logList(@RequestBody Map<String, Object> body) {
        AdminUser admin = requireAdmin(body);
        if (admin == null) {
            return Result.fail(401, "notfound");
        }
        return Result.ok(adminService.listLog(intOf(body.get("page"), 1), intOf(body.get("size"), 8)));
    }

    /* ================= 工具 ================= */

    /** 统一鉴权：token 无效 / 过期返回 null */
    private AdminUser requireAdmin(Map<String, Object> body) {
        return adminService.resolveToken(str(body.get("token")));
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }

    private static int intOf(Object o, int def) {
        if (o == null) {
            return def;
        }
        try {
            return Integer.parseInt(String.valueOf(o));
        } catch (NumberFormatException e) {
            return def;
        }
    }

    private static Long longOf(Object o) {
        if (o == null) {
            return null;
        }
        try {
            return Long.parseLong(String.valueOf(o));
        } catch (NumberFormatException e) {
            return null;
        }
    }
}
