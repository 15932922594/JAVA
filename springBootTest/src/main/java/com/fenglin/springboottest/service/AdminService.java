package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.plugins.pagination.Page;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fenglin.springboottest.entity.AdminLog;
import com.fenglin.springboottest.entity.AdminUser;
import com.fenglin.springboottest.entity.AgentArchive;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.entity.ArchiveCategory;
import com.fenglin.springboottest.entity.HomeFeed;
import com.fenglin.springboottest.entity.MissionBrief;
import com.fenglin.springboottest.mapper.AdminLogMapper;
import com.fenglin.springboottest.service.AgentUserService;
import com.fenglin.springboottest.mapper.AdminUserMapper;
import com.fenglin.springboottest.mapper.AgentArchiveMapper;
import com.fenglin.springboottest.mapper.AgentUserMapper;
import com.fenglin.springboottest.mapper.ArchiveCategoryMapper;
import com.fenglin.springboottest.mapper.HomeFeedMapper;
import com.fenglin.springboottest.mapper.MissionBriefMapper;
import com.fenglin.springboottest.util.PasswordUtil;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;

/**
 * 后台管理业务：管理员登录态 + 各内容表的增删改查 + 操作日志
 *
 * 约定（与前端 src/store/api.js 对应）：
 *   统一返回 { code, msg, data }，code === 0 成功；
 *   列表统一返回 { list, total, pages, page, size }，行字段用 snake_case
 *   （与前端 AdminDashboard 的表单 key 一致，编辑回填不需要转换）。
 */
@Service
public class AdminService extends ServiceImpl<AdminUserMapper, AdminUser> {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");
    private static final ObjectMapper JSON = new ObjectMapper();

    /** 后台会话有效期：2 天 */
    private static final int SESSION_DAYS = 2;
    private static final int DEFAULT_PAGE_SIZE = 8;

    private final AdminLogMapper logMapper;
    private final AgentArchiveMapper archiveMapper;
    private final ArchiveCategoryMapper categoryMapper;
    private final HomeFeedMapper feedMapper;
    private final MissionBriefMapper missionMapper;
    private final AgentUserMapper userMapper;
    private final AgentUserService userService;

    public AdminService(AdminLogMapper logMapper,
                        AgentArchiveMapper archiveMapper,
                        ArchiveCategoryMapper categoryMapper,
                        HomeFeedMapper feedMapper,
                        MissionBriefMapper missionMapper,
                        AgentUserMapper userMapper,
                        AgentUserService userService) {
        this.logMapper = logMapper;
        this.archiveMapper = archiveMapper;
        this.categoryMapper = categoryMapper;
        this.feedMapper = feedMapper;
        this.missionMapper = missionMapper;
        this.userMapper = userMapper;
        this.userService = userService;
    }

    /* ================= 管理员登录态 ================= */

    /**
     * 当前后台操作者。
     * 后台不再只能用 admin_user 登录：agent_user 中 permission = 0（管理员权限）的账号
     * 同样可以登录后台；permission = 1（默认权限）的账号一律拒绝。
     */
    public static class Actor {
        /** 操作者 id（agent_user.id 或 admin_user.id） */
        public final Long id;
        /** 操作者账号（日志用） */
        public final String username;
        /** 显示名 */
        public final String displayName;
        /** 来源：USER = 前台账号(permission=0)，ADMIN = 旧 admin_user */
        public final String source;
        /** source = USER 时非空 */
        public final AgentUser user;
        /** source = ADMIN 时非空 */
        public final AdminUser admin;

        public Actor(Long id, String username, String displayName, String source,
                     AgentUser user, AdminUser admin) {
            this.id = id;
            this.username = username;
            this.displayName = displayName;
            this.source = source;
            this.user = user;
            this.admin = admin;
        }
    }

    /**
     * 登录：成功返回账号 map（含 token），失败返回错误码字符串。
     * 错误码：notfound / disabled / wrongpass / noperm（账号存在但没有管理员权限）
     */
    public Object login(String username, String password) {
        String key = username == null ? "" : username.trim();
        String mail = key.toLowerCase();

        // 1) 前台账号：允许代号或邮箱登录，但必须是管理员权限（permission = 0）
        if (!key.isEmpty()) {
            AgentUser u = userService.getOne(new QueryWrapper<AgentUser>()
                    .and(w -> w.eq("email", mail).or().eq("name", key))
                    .eq("permission", AgentUserService.PERMISSION_ADMIN));
            if (u == null) {
                // 账号存在但权限是默认权限 → 明确提示，拒绝登录后台
                AgentUser any = userService.getOne(new QueryWrapper<AgentUser>()
                        .and(w -> w.eq("email", mail).or().eq("name", key)));
                if (any != null) {
                    return "noperm";
                }
            } else {
                if (!userService.matchPassword(u, password)) {
                    return "wrongpass";
                }
                String token = userService.issueToken(u.getId());
                Actor actor = new Actor(u.getId(), u.getName(), u.getName(), "USER", u, null);
                record(actor, "admin", "LOGIN", "管理员登录：" + u.getName());
                return toSafeMap(actor, token);
            }
        }

        // 2) 兼容旧的独立管理员账号（admin_user）
        AdminUser admin = getOne(new QueryWrapper<AdminUser>().eq("username", key));
        if (admin == null) {
            return "notfound";
        }
        if (admin.getStatus() == null || admin.getStatus() != 1) {
            return "disabled";
        }
        if (!PasswordUtil.matches(admin.getSalt(), password, admin.getPasswordHash())) {
            return "wrongpass";
        }
        // 单会话：签发新 token 覆盖旧的
        String token = UUID.randomUUID().toString().replace("-", "");
        admin.setToken(token);
        admin.setTokenExpiresAt(LocalDateTime.now().plusDays(SESSION_DAYS));
        updateById(admin);

        Actor actor = new Actor(admin.getId(), admin.getUsername(), admin.getDisplayName(),
                "ADMIN", null, admin);
        record(actor, "admin", "LOGIN", "管理员登录");
        return toSafeMap(actor, token);
    }

    /**
     * 用 token 换操作者身份（刷新页面保持登录）；无效 / 过期 / 权限被降级返回 null。
     * 先按前台账号会话（agent_session）解析，再按旧 admin_user 解析。
     */
    public Actor resolveToken(String token) {
        if (token == null || token.isBlank()) {
            return null;
        }
        // 1) 前台账号的后台会话：实时校验 permission，被降级立刻失效
        AgentUser u = userService.resolveToken(token);
        if (u != null) {
            if (!AgentUserService.isAdmin(u)) {
                return null;
            }
            return new Actor(u.getId(), u.getName(), u.getName(), "USER", u, null);
        }

        // 2) 旧的 admin_user 单会话
        AdminUser admin = getOne(new QueryWrapper<AdminUser>().eq("token", token));
        if (admin == null) {
            return null;
        }
        if (admin.getTokenExpiresAt() == null
                || admin.getTokenExpiresAt().isBefore(LocalDateTime.now())) {
            admin.setToken(null);
            admin.setTokenExpiresAt(null);
            updateById(admin);
            return null;
        }
        return new Actor(admin.getId(), admin.getUsername(), admin.getDisplayName(),
                "ADMIN", null, admin);
    }

    /** 退出后台：注销会话（前台账号走 agent_session，旧管理员清空 token 列） */
    public boolean logout(String token) {
        Actor actor = resolveToken(token);
        if (actor == null) {
            return false;
        }
        if (actor.user != null) {
            return userService.deleteToken(token);
        }
        AdminUser admin = actor.admin;
        admin.setToken(null);
        admin.setTokenExpiresAt(null);
        return updateById(admin);
    }

    /** 修改密码：前台账号改 agent_user（明文），旧管理员改 admin_user */
    public String changePassword(Actor actor, String oldPass, String newPass) {
        if (newPass == null || newPass.length() < 6) {
            return "weakpass";
        }
        if (actor.user != null) {
            String reason = userService.changePassword(actor.user.getId(), oldPass, newPass);
            if ("ok".equals(reason)) {
                record(actor, "admin", "PASSWORD", "修改账号密码");
            }
            return reason;
        }
        AdminUser admin = getById(actor.id);
        if (admin == null) {
            return "notfound";
        }
        if (!PasswordUtil.matches(admin.getSalt(), oldPass, admin.getPasswordHash())) {
            return "wrongpass";
        }
        String salt = PasswordUtil.randomSalt();
        admin.setSalt(salt);
        admin.setPasswordHash(PasswordUtil.sha256(salt, newPass));
        updateById(admin);
        record(actor, "admin", "PASSWORD", "修改管理员密码");
        return "ok";
    }

    /**
     * 设置前台账号权限：0 管理员权限 / 1 默认权限。
     * 返回 ok / notfound / badperm / self（不能取消自己的管理员）/ lastadmin（不能降级最后一个管理员）
     */
    public String setPermission(Actor actor, Long userId, int permission) {
        if (userId == null) {
            return "notfound";
        }
        if (permission != AgentUserService.PERMISSION_ADMIN
                && permission != AgentUserService.PERMISSION_USER) {
            return "badperm";
        }
        AgentUser target = userService.getById(userId);
        if (target == null) {
            return "notfound";
        }
        // 不允许把自己降级，否则会被自己锁在后台外面
        if (permission == AgentUserService.PERMISSION_USER
                && actor.user != null && userId.equals(actor.id)) {
            return "self";
        }
        // 至少保留一个管理员
        if (permission == AgentUserService.PERMISSION_USER
                && AgentUserService.isAdmin(target)
                && userService.count(new QueryWrapper<AgentUser>()
                        .eq("permission", AgentUserService.PERMISSION_ADMIN)) <= 1) {
            return "lastadmin";
        }
        String reason = userService.updatePermission(userId, permission);
        if ("ok".equals(reason)) {
            record(actor, "user", "PERMISSION",
                    target.getName() + " → " + (permission == AgentUserService.PERMISSION_ADMIN ? "管理员" : "默认"));
        }
        return reason;
    }

    /** 脱敏账号信息（含 token，仅登录 / verify 时返回） */
    public Map<String, Object> toSafeMap(Actor actor, String token) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", actor.id);
        m.put("username", actor.username);
        m.put("displayName", actor.displayName);
        m.put("source", actor.source);
        // 前台管理员账号带上 permission，前端据此判断后台入口
        m.put("permission", actor.user != null
                ? (actor.user.getPermission() == null
                    ? AgentUserService.PERMISSION_USER : actor.user.getPermission())
                : AgentUserService.PERMISSION_ADMIN);
        if (token != null) {
            m.put("token", token);
        }
        return m;
    }

    /** 写操作日志 */
    public void record(Actor actor, String target, String action, String detail) {
        AdminLog log = new AdminLog();
        log.setAdminId(actor.id);
        log.setAdminName(actor.username);
        log.setTarget(target);
        log.setAction(action);
        log.setDetail(detail == null ? "" : detail);
        logMapper.insert(log);
    }

    /* ================= 概览统计 ================= */

    public Map<String, Object> stats() {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("档案", archiveMapper.selectCount(null));
        m.put("分类", categoryMapper.selectCount(null));
        m.put("动态情报", feedMapper.selectCount(null));
        m.put("任务简报", missionMapper.selectCount(null));
        m.put("前台用户", userMapper.selectCount(null));
        m.put("管理员数", userMapper.selectCount(new QueryWrapper<AgentUser>()
                .eq("permission", AgentUserService.PERMISSION_ADMIN)));
        m.put("操作日志", logMapper.selectCount(null));
        return m;
    }

    /* ================= 档案（agent_archive） ================= */

    public Map<String, Object> listArchive(String q, int page, int size) {
        Page<AgentArchive> p = new Page<>(page, size);
        QueryWrapper<AgentArchive> qw = new QueryWrapper<>();
        if (has(q)) {
            qw.and(w -> w.like("code", q)
                    .or().like("name", q)
                    .or().like("name_cn", q)
                    .or().like("bio", q));
        }
        qw.orderByAsc("category_code").orderByAsc("sort").orderByAsc("id");
        Page<AgentArchive> r = archiveMapper.selectPage(p, qw);

        List<Map<String, Object>> list = new ArrayList<>();
        for (AgentArchive a : r.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", a.getId());
            m.put("category_code", a.getCategoryCode());
            m.put("sub_code", a.getSubCode());
            m.put("tier", a.getTier());
            m.put("code", a.getCode());
            m.put("name", a.getName());
            m.put("name_cn", a.getNameCn());
            m.put("mono", a.getMono());
            m.put("color", a.getColor());
            m.put("bio", a.getBio());
            m.put("img", a.getImg());
            m.put("firepower", a.getFirepower());
            m.put("mobility", a.getMobility());
            m.put("control", a.getControl());
            m.put("defense", a.getDefense());
            m.put("heat", a.getHeat());
            m.put("featured", a.getFeatured());
            m.put("sort", a.getSort());
            m.put("status", a.getStatus());
            m.put("story", a.getStory() == null ? "" : a.getStory());
            m.put("abilities", a.getAbilities() == null ? "" : a.getAbilities());
            list.add(m);
        }
        return pageMap(list, r.getTotal(), page, size);
    }

    /** 档案新增 / 修改（data.id 为空即新增） */
    public String saveArchive(Map<String, Object> data) {
        AgentArchive a = new AgentArchive();
        Long id = longOf(data.get("id"));
        if (id != null) {
            a = archiveMapper.selectById(id);
            if (a == null) {
                return "notfound";
            }
        }
        String code = str(data.get("code"));
        String name = str(data.get("name"));
        if (code.isBlank() || name.isBlank()) {
            return "empty";
        }
        // 代号唯一性（排除自身）
        Long dup = archiveMapper.selectCount(new QueryWrapper<AgentArchive>()
                .eq("code", code).ne(id != null, "id", id));
        if (dup != null && dup > 0) {
            return "duplicate-code";
        }

        a.setCategoryCode(strOr(data.get("category_code"), "AGENT"));
        a.setSubCode(str(data.get("sub_code")));
        a.setTier(strOr(data.get("tier"), "A"));
        a.setCode(code);
        a.setName(name);
        a.setNameCn(str(data.get("name_cn")));
        a.setMono(str(data.get("mono")));
        a.setColor(strOr(data.get("color"), "#FF4655"));
        a.setBio(str(data.get("bio")));
        a.setImg(str(data.get("img")));
        a.setFirepower(intOr(data.get("firepower"), 0));
        a.setMobility(intOr(data.get("mobility"), 0));
        a.setControl(intOr(data.get("control"), 0));
        a.setDefense(intOr(data.get("defense"), 0));
        a.setHeat(intOr(data.get("heat"), 0));
        a.setFeatured(intOr(data.get("featured"), 0));
        a.setSort(intOr(data.get("sort"), 0));
        a.setStatus(intOr(data.get("status"), 1));
        a.setStory(str(data.get("story")));
        a.setAbilities(str(data.get("abilities")));

        if (id == null) {
            archiveMapper.insert(a);
        } else {
            archiveMapper.updateById(a);
        }
        return "ok";
    }

    public boolean deleteArchive(Long id) {
        return archiveMapper.deleteById(id) > 0;
    }

    /* ================= 分类（archive_category） ================= */

    public List<Map<String, Object>> listCategory() {
        List<Map<String, Object>> list = new ArrayList<>();
        for (ArchiveCategory c : categoryMapper.selectList(new QueryWrapper<ArchiveCategory>()
                .orderByAsc("parent_id").orderByAsc("sort").orderByAsc("id"))) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", c.getId());
            m.put("parent_id", c.getParentId());
            m.put("code", c.getCode());
            m.put("name", c.getName());
            m.put("name_en", c.getNameEn());
            m.put("level", c.getLevel());
            m.put("sort", c.getSort());
            list.add(m);
        }
        return list;
    }

    public String saveCategory(Map<String, Object> data) {
        ArchiveCategory c = new ArchiveCategory();
        Long id = longOf(data.get("id"));
        if (id != null) {
            c = categoryMapper.selectById(id);
            if (c == null) {
                return "notfound";
            }
        }
        String code = str(data.get("code"));
        String name = str(data.get("name"));
        if (code.isBlank() || name.isBlank()) {
            return "empty";
        }
        Long dup = categoryMapper.selectCount(new QueryWrapper<ArchiveCategory>()
                .eq("code", code).ne(id != null, "id", id));
        if (dup != null && dup > 0) {
            return "duplicate-code";
        }
        long parentId = data.get("parent_id") == null ? 0 : longOf(data.get("parent_id"));
        c.setParentId(parentId);
        c.setCode(code);
        c.setName(name);
        c.setNameEn(str(data.get("name_en")));
        c.setLevel(parentId > 0 ? 2 : 1);
        c.setSort(intOr(data.get("sort"), 0));

        if (id == null) {
            categoryMapper.insert(c);
        } else {
            categoryMapper.updateById(c);
        }
        return "ok";
    }

    /** 一级分类不可删除（档案都挂在它下面） */
    public String deleteCategory(Long id) {
        ArchiveCategory c = categoryMapper.selectById(id);
        if (c == null) {
            return "notfound";
        }
        if (c.getParentId() == null || c.getParentId() == 0) {
            return "root";
        }
        return categoryMapper.deleteById(id) > 0 ? "ok" : "notfound";
    }

    /* ================= 动态 / 情报（home_feed） ================= */

    public Map<String, Object> listFeed(String q, int page, int size) {
        Page<HomeFeed> p = new Page<>(page, size);
        QueryWrapper<HomeFeed> qw = new QueryWrapper<>();
        if (has(q)) {
            qw.and(w -> w.like("title", q).or().like("summary", q).or().like("tag", q));
        }
        qw.orderByDesc("create_time");
        Page<HomeFeed> r = feedMapper.selectPage(p, qw);

        List<Map<String, Object>> list = new ArrayList<>();
        for (HomeFeed f : r.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", f.getId());
            m.put("kind", f.getKind());
            m.put("title", f.getTitle());
            m.put("summary", f.getSummary());
            m.put("body", f.getBody() == null ? "" : f.getBody());
            m.put("source", f.getSource());
            m.put("importance", f.getImportance());
            m.put("category_code", f.getCategoryCode());
            m.put("tag", f.getTag());
            m.put("heat", f.getHeat());
            m.put("status", f.getStatus());
            m.put("published_at", f.getPublishedAt() == null ? "" : f.getPublishedAt().format(FMT));
            list.add(m);
        }
        return pageMap(list, r.getTotal(), page, size);
    }

    public String saveFeed(Map<String, Object> data) {
        HomeFeed f = new HomeFeed();
        Long id = longOf(data.get("id"));
        if (id != null) {
            f = feedMapper.selectById(id);
            if (f == null) {
                return "notfound";
            }
        }
        String title = str(data.get("title"));
        if (title.isBlank()) {
            return "empty";
        }
        f.setKind(strOr(data.get("kind"), "NEWS"));
        f.setTitle(title);
        f.setSummary(str(data.get("summary")));
        f.setBody(str(data.get("body")));
        f.setSource(str(data.get("source")));
        f.setImportance(intOr(data.get("importance"), 1));
        f.setCategoryCode(str(data.get("category_code")));
        f.setTag(str(data.get("tag")));
        f.setHeat(intOr(data.get("heat"), 0));
        f.setStatus(intOr(data.get("status"), 1));
        if (f.getPublishedAt() == null) {
            f.setPublishedAt(LocalDateTime.now());
        }

        if (id == null) {
            feedMapper.insert(f);
        } else {
            feedMapper.updateById(f);
        }
        return "ok";
    }

    public boolean deleteFeed(Long id) {
        return feedMapper.deleteById(id) > 0;
    }

    /* ================= 任务简报（mission_brief + agent_archive 名称回显） ================= */

    public Map<String, Object> listMission(String q, int page, int size) {
        Page<MissionBrief> p = new Page<>(page, size);
        QueryWrapper<MissionBrief> qw = new QueryWrapper<>();
        if (has(q)) {
            qw.like("mission_code", q);
        }
        qw.orderByAsc("mission_code");
        Page<MissionBrief> r = missionMapper.selectPage(p, qw);

        List<Map<String, Object>> list = new ArrayList<>();
        for (MissionBrief b : r.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", b.getId());
            m.put("mission_code", b.getMissionCode());
            // 关联档案取任务名 / 分级，便于展示
            AgentArchive a = archiveMapper.selectOne(new QueryWrapper<AgentArchive>()
                    .eq("code", b.getMissionCode()).last("LIMIT 1"));
            m.put("name", a == null ? b.getMissionCode() : a.getName());
            m.put("tier", a == null ? "" : a.getTier());
            m.put("briefing", b.getBriefing());
            // 目标存的是 JSON 数组字符串，回显为每行一条，编辑框直接改
            m.put("objectives", toLines(b.getObjectives()));
            m.put("reward", b.getReward());
            m.put("duration_min", b.getDurationMin());
            m.put("region", b.getRegion());
            m.put("squad", b.getSquad());
            m.put("status", b.getStatus());
            list.add(m);
        }
        return pageMap(list, r.getTotal(), page, size);
    }

    /** 任务简报新增 / 修改（按 mission_code 关联档案，档案本体在「档案」页维护） */
    public String saveMission(Map<String, Object> data) {
        MissionBrief b = new MissionBrief();
        Long id = longOf(data.get("id"));
        if (id != null) {
            b = missionMapper.selectById(id);
            if (b == null) {
                return "notfound";
            }
        }
        String code = str(data.get("mission_code"));
        if (code.isBlank()) {
            return "empty";
        }
        b.setMissionCode(code);
        b.setBriefing(str(data.get("briefing")));
        // 前端每行一条目标，这里转成 JSON 数组字符串存库
        b.setObjectives(toJsonLines(str(data.get("objectives"))));
        b.setReward(intOr(data.get("reward"), 0));
        b.setDurationMin(intOr(data.get("duration_min"), 0));
        b.setRegion(str(data.get("region")));
        b.setSquad(str(data.get("squad")));
        b.setStatus(intOr(data.get("status"), 1));

        if (id == null) {
            Long dup = missionMapper.selectCount(new QueryWrapper<MissionBrief>()
                    .eq("mission_code", code));
            if (dup != null && dup > 0) {
                return "duplicate-code";
            }
            missionMapper.insert(b);
        } else {
            missionMapper.updateById(b);
        }
        return "ok";
    }

    public boolean deleteMission(Long id) {
        return missionMapper.deleteById(id) > 0;
    }

    /* ================= 前台用户（只读） ================= */

    public Map<String, Object> listUser(String q, int page, int size) {
        Page<AgentUser> p = new Page<>(page, size);
        QueryWrapper<AgentUser> qw = new QueryWrapper<>();
        if (has(q)) {
            qw.and(w -> w.like("name", q).or().like("email", q));
        }
        qw.orderByDesc("create_time");
        Page<AgentUser> r = userMapper.selectPage(p, qw);

        List<Map<String, Object>> list = new ArrayList<>();
        for (AgentUser u : r.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", u.getId());
            m.put("name", u.getName());
            m.put("email", u.getEmail());
            m.put("agent_index", u.getAgentIndex());
            // permission：1 默认权限 / 0 管理员权限
            m.put("permission", u.getPermission() == null
                    ? AgentUserService.PERMISSION_USER : u.getPermission());
            // 密码为明文存储，后台可见（旧账号若未转明文则显示为空）
            m.put("password", u.getPassword() == null ? "" : u.getPassword());
            m.put("create_time", u.getCreateTime() == null ? "" : u.getCreateTime().format(FMT));
            list.add(m);
        }
        return pageMap(list, r.getTotal(), page, size);
    }

    /* ================= 操作日志 ================= */

    public Map<String, Object> listLog(int page, int size) {
        Page<AdminLog> p = new Page<>(page, size);
        Page<AdminLog> r = logMapper.selectPage(p,
                new QueryWrapper<AdminLog>().orderByDesc("create_time").orderByDesc("id"));

        List<Map<String, Object>> list = new ArrayList<>();
        for (AdminLog l : r.getRecords()) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", l.getId());
            m.put("admin_name", l.getAdminName());
            m.put("target", l.getTarget());
            m.put("action", l.getAction());
            m.put("detail", l.getDetail());
            m.put("create_time", l.getCreateTime() == null ? "" : l.getCreateTime().format(FMT));
            list.add(m);
        }
        return pageMap(list, r.getTotal(), page, size);
    }

    /* ================= 工具 ================= */

    private static Map<String, Object> pageMap(List<Map<String, Object>> list, long total, int page, int size) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("list", list);
        m.put("total", total);
        m.put("pages", size <= 0 ? 0 : (int) Math.ceil((double) total / size));
        m.put("page", page);
        m.put("size", size);
        return m;
    }

    /** JSON 数组字符串 → 每行一条的纯文本（前端编辑框直接改） */
    private static String toLines(String json) {
        if (json == null || json.isBlank()) {
            return "";
        }
        try {
            List<String> arr = JSON.readValue(json, JSON.getTypeFactory()
                    .constructCollectionType(List.class, String.class));
            return String.join("\n", arr);
        } catch (Exception e) {
            return "";
        }
    }

    /** 每行一条的纯文本 → JSON 数组字符串（空行自动忽略） */
    private static String toJsonLines(String text) {
        if (text == null || text.isBlank()) {
            return "[]";
        }
        try {
            List<String> arr = Arrays.stream(text.split("\\r?\\n"))
                    .map(String::trim)
                    .filter(s -> !s.isEmpty())
                    .toList();
            return JSON.writeValueAsString(arr);
        } catch (Exception e) {
            return "[]";
        }
    }

    private static boolean has(String s) {
        return s != null && !s.isBlank();
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o).trim();
    }

    private static String strOr(Object o, String def) {
        String s = str(o);
        return s.isEmpty() ? def : s;
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

    private static int intOr(Object o, int def) {
        if (o == null) {
            return def;
        }
        try {
            return Integer.parseInt(String.valueOf(o));
        } catch (NumberFormatException e) {
            return def;
        }
    }
}
