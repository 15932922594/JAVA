package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fenglin.springboottest.entity.AgentArchive;
import com.fenglin.springboottest.entity.ArchiveCategory;
import com.fenglin.springboottest.entity.MissionBrief;
import com.fenglin.springboottest.entity.MissionProgress;
import com.fenglin.springboottest.mapper.AgentArchiveMapper;
import com.fenglin.springboottest.mapper.ArchiveCategoryMapper;
import com.fenglin.springboottest.mapper.MissionBriefMapper;
import com.fenglin.springboottest.mapper.MissionProgressMapper;
import org.springframework.stereotype.Service;

import java.time.Duration;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.function.Function;
import java.util.stream.Collectors;

/**
 * 作战任务业务：任务列表 / 接取 / 目标勾选 / 放弃 / 结算
 *
 * 数据组成：
 *   agent_archive（任务本体：名称、分级、背景故事）
 * + mission_brief（简报、目标清单、奖励、时限）
 * + mission_progress（该特工的任务状态，一人一任务一条记录）
 *
 * 状态流转：IDLE（未接取）→ ACTIVE（进行中）→ READY（目标完成待结算）→ DONE（已结算）
 */
@Service
public class MissionService extends ServiceImpl<MissionProgressMapper, MissionProgress> {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm:ss");

    /** 任务归属于这个一级分类 */
    private static final String CATEGORY = "MISSION";

    /** 目标清单 JSON 解析器（数据量小，复用同一个实例） */
    private static final ObjectMapper JSON = new ObjectMapper();

    private final MissionBriefMapper briefMapper;
    private final AgentArchiveMapper archiveMapper;
    private final ArchiveCategoryMapper categoryMapper;

    public MissionService(MissionBriefMapper briefMapper,
                          AgentArchiveMapper archiveMapper,
                          ArchiveCategoryMapper categoryMapper) {
        this.briefMapper = briefMapper;
        this.archiveMapper = archiveMapper;
        this.categoryMapper = categoryMapper;
    }

    /* ==========================================================
       1. 任务列表 + 个人统计
       ========================================================== */

    /**
     * @param userId 当前特工 id
     * @param status 状态筛选：IDLE / ACTIVE / READY / DONE，空为全部
     * @param q      关键词（名称 / 代号 / 简报 / 区域）
     * @param sub    二级分类（TRAINING / RANKED / EVENT）
     * @param tier   分级 S / A / B
     */
    public Map<String, Object> list(Long userId, String status, String q, String sub, String tier) {
        List<AgentArchive> archives = missionArchives();
        Map<String, MissionBrief> briefs = briefMap();
        Map<String, MissionProgress> progress = progressMap(userId);
        Map<String, String> subNames = subNameMap();

        List<Map<String, Object>> all = new ArrayList<>();
        for (AgentArchive a : archives) {
            all.add(toItem(a, briefs.get(a.getCode()), progress.get(a.getCode()),
                    subNames.getOrDefault(a.getSubCode(), a.getSubCode())));
        }

        // 统计永远基于全量任务，不受筛选影响
        Map<String, Object> stats = stats(all);
        stats.put("points", points(userId));

        String keyword = q == null ? "" : q.trim().toLowerCase();
        String st = status == null ? "" : status.trim().toUpperCase();
        String subCode = sub == null ? "" : sub.trim().toUpperCase();
        String tierCode = tier == null ? "" : tier.trim().toUpperCase();

        List<Map<String, Object>> filtered = new ArrayList<>();
        for (Map<String, Object> m : all) {
            if (!st.isEmpty() && !st.equals(m.get("status"))) {
                continue;
            }
            if (!subCode.isEmpty() && !subCode.equals(m.get("subCode"))) {
                continue;
            }
            if (!tierCode.isEmpty() && !tierCode.equals(m.get("tier"))) {
                continue;
            }
            if (!keyword.isEmpty()) {
                String hay = (str(m.get("name")) + " " + str(m.get("code")) + " "
                        + str(m.get("briefing")) + " " + str(m.get("region"))).toLowerCase();
                if (!hay.contains(keyword)) {
                    continue;
                }
            }
            filtered.add(m);
        }

        Map<String, Object> res = new LinkedHashMap<>();
        res.put("stats", stats);
        res.put("subs", subTree(all));
        res.put("total", filtered.size());
        res.put("list", filtered);
        return res;
    }

    /** 单个任务（接取 / 勾选 / 结算后回传给前端刷新） */
    public Map<String, Object> one(Long userId, String code) {
        AgentArchive a = archiveByCode(code);
        if (a == null) {
            return null;
        }
        MissionBrief b = briefMapper.selectOne(
                new QueryWrapper<MissionBrief>().eq("mission_code", code).eq("status", 1));
        MissionProgress p = progressByCode(userId, code);
        Map<String, String> subNames = subNameMap();
        return toItem(a, b, p, subNames.getOrDefault(a.getSubCode(), a.getSubCode()));
    }

    /* ==========================================================
       2. 接取 / 勾选目标 / 放弃 / 结算
       ========================================================== */

    /** 接取任务：生成一条进行中的进度记录 */
    public ActionResult accept(Long userId, String code) {
        AgentArchive a = archiveByCode(code);
        MissionBrief b = a == null ? null : briefMapper.selectOne(
                new QueryWrapper<MissionBrief>().eq("mission_code", code).eq("status", 1));
        if (a == null || b == null) {
            return ActionResult.fail(404, "任务不存在或已下线");
        }

        MissionProgress old = progressByCode(userId, code);
        if (old != null) {
            if (Integer.valueOf(MissionProgress.CLAIMED).equals(old.getStatus())) {
                return ActionResult.fail(409, "该任务已结算，无法重复接取");
            }
            return ActionResult.fail(409, "该任务已在执行中");
        }

        LocalDateTime now = LocalDateTime.now();
        int minutes = b.getDurationMin() == null || b.getDurationMin() <= 0 ? 30 : b.getDurationMin();

        MissionProgress p = new MissionProgress();
        p.setUserId(userId);
        p.setMissionCode(code);
        p.setStatus(MissionProgress.ACTIVE);
        p.setDoneObjectives("[]");
        p.setStartedAt(now);
        p.setDeadline(now.plusMinutes(minutes));
        save(p);

        return ActionResult.ok("任务已接取", one(userId, code));
    }

    /** 勾选 / 取消勾选某个目标：全部勾完自动进入待结算 */
    public ActionResult toggleObjective(Long userId, String code, int index) {
        MissionProgress p = progressByCode(userId, code);
        if (p == null) {
            return ActionResult.fail(400, "请先接取任务");
        }
        if (Integer.valueOf(MissionProgress.CLAIMED).equals(p.getStatus())) {
            return ActionResult.fail(409, "任务已结算，无法再修改目标");
        }

        MissionBrief b = briefMapper.selectOne(
                new QueryWrapper<MissionBrief>().eq("mission_code", code).eq("status", 1));
        List<String> objectives = b == null ? Collections.emptyList() : parseTexts(b.getObjectives());
        if (index < 0 || index >= objectives.size()) {
            return ActionResult.fail(400, "目标编号不合法");
        }

        Set<Integer> done = new TreeSet<>(parseInts(p.getDoneObjectives()));
        if (!done.remove(index)) {
            done.add(index);
        }
        p.setDoneObjectives(JSONArray(done));

        boolean allDone = done.size() >= objectives.size() && !objectives.isEmpty();
        p.setStatus(allDone ? MissionProgress.READY : MissionProgress.ACTIVE);
        updateById(p);

        String msg = allDone ? "全部目标已完成，可以结算了" : "目标已更新";
        return ActionResult.ok(msg, one(userId, code));
    }

    /** 放弃任务：删除进度记录，任务回到未接取 */
    public ActionResult abandon(Long userId, String code) {
        MissionProgress p = progressByCode(userId, code);
        if (p == null) {
            return ActionResult.fail(400, "该任务尚未接取");
        }
        if (Integer.valueOf(MissionProgress.CLAIMED).equals(p.getStatus())) {
            return ActionResult.fail(409, "任务已结算，无法放弃");
        }
        removeById(p.getId());
        return ActionResult.ok("任务已放弃", one(userId, code));
    }

    /** 结算任务：目标全部完成后发放积分 */
    public ActionResult claim(Long userId, String code) {
        MissionProgress p = progressByCode(userId, code);
        if (p == null) {
            return ActionResult.fail(400, "请先接取任务");
        }
        if (Integer.valueOf(MissionProgress.CLAIMED).equals(p.getStatus())) {
            return ActionResult.fail(409, "该任务已结算");
        }
        if (!Integer.valueOf(MissionProgress.READY).equals(p.getStatus())) {
            return ActionResult.fail(400, "目标尚未全部完成，无法结算");
        }

        p.setStatus(MissionProgress.CLAIMED);
        p.setFinishedAt(LocalDateTime.now());
        updateById(p);

        MissionBrief b = briefMapper.selectOne(
                new QueryWrapper<MissionBrief>().eq("mission_code", code));
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("reward", b == null ? 0 : nz(b.getReward()));
        data.put("points", points(userId));
        data.put("mission", one(userId, code));
        return new ActionResult(0, "任务结算完成", data);
    }

    /* ==========================================================
       3. 内部工具
       ========================================================== */

    /** 全部上线的任务档案，按 sort 排序 */
    private List<AgentArchive> missionArchives() {
        return archiveMapper.selectList(new QueryWrapper<AgentArchive>()
                .eq("category_code", CATEGORY)
                .eq("status", 1)
                .orderByAsc("sort")
                .orderByDesc("heat"));
    }

    private AgentArchive archiveByCode(String code) {
        if (!has(code)) {
            return null;
        }
        return archiveMapper.selectOne(new QueryWrapper<AgentArchive>()
                .eq("code", code.trim())
                .eq("category_code", CATEGORY)
                .eq("status", 1), false);
    }

    private Map<String, MissionBrief> briefMap() {
        return briefMapper.selectList(new QueryWrapper<MissionBrief>().eq("status", 1)).stream()
                .collect(Collectors.toMap(MissionBrief::getMissionCode, Function.identity(), (x, y) -> x));
    }

    private Map<String, MissionProgress> progressMap(Long userId) {
        if (userId == null) {
            return Collections.emptyMap();
        }
        return list(new QueryWrapper<MissionProgress>().eq("user_id", userId)).stream()
                .collect(Collectors.toMap(MissionProgress::getMissionCode, Function.identity(), (x, y) -> x));
    }

    private MissionProgress progressByCode(Long userId, String code) {
        if (userId == null || !has(code)) {
            return null;
        }
        return getOne(new QueryWrapper<MissionProgress>()
                .eq("user_id", userId)
                .eq("mission_code", code.trim()), false);
    }

    /** 二级分类编码 → 中文名 */
    private Map<String, String> subNameMap() {
        return categoryMapper.selectList(new QueryWrapper<ArchiveCategory>().eq("status", 1)).stream()
                .collect(Collectors.toMap(ArchiveCategory::getCode, ArchiveCategory::getName, (x, y) -> x));
    }

    /** 个人积分：所有已结算任务的奖励之和 */
    private int points(Long userId) {
        if (userId == null) {
            return 0;
        }
        Set<String> claimed = list(new QueryWrapper<MissionProgress>()
                .eq("user_id", userId).eq("status", MissionProgress.CLAIMED))
                .stream().map(MissionProgress::getMissionCode).collect(Collectors.toSet());
        int sum = 0;
        for (MissionBrief b : briefMap().values()) {
            if (claimed.contains(b.getMissionCode())) {
                sum += nz(b.getReward());
            }
        }
        return sum;
    }

    /** 统计卡：进行中 / 待结算 / 已完成 / 积分 / 完成率 */
    private Map<String, Object> stats(List<Map<String, Object>> all) {
        int active = 0;
        int ready = 0;
        int done = 0;
        int rewardSum = 0;
        for (Map<String, Object> m : all) {
            String st = str(m.get("status"));
            rewardSum += (int) m.get("reward");
            if ("ACTIVE".equals(st)) {
                active++;
            } else if ("READY".equals(st)) {
                ready++;
            } else if ("DONE".equals(st)) {
                done++;
            }
        }
        int total = all.size();
        Map<String, Object> s = new LinkedHashMap<>();
        s.put("total", total);
        s.put("active", active);
        s.put("ready", ready);
        s.put("done", done);
        s.put("rewardTotal", rewardSum);
        s.put("rate", total == 0 ? 0 : Math.round(done * 100f / total));
        return s;
    }

    /** 二级分类（含任务数与已完成数），供前端筛选器展示 */
    private List<Map<String, Object>> subTree(List<Map<String, Object>> all) {
        Map<String, Map<String, Object>> byCode = new LinkedHashMap<>();
        for (Map<String, Object> m : all) {
            String code = str(m.get("subCode"));
            Map<String, Object> node = byCode.computeIfAbsent(code, k -> {
                Map<String, Object> n = new LinkedHashMap<>();
                n.put("code", k);
                n.put("name", "");
                n.put("count", 0);
                n.put("done", 0);
                return n;
            });
            node.put("name", m.get("subName"));
            node.put("count", (int) node.get("count") + 1);
            if ("DONE".equals(m.get("status"))) {
                node.put("done", (int) node.get("done") + 1);
            }
        }
        return new ArrayList<>(byCode.values());
    }

    /** 组装前端任务对象 */
    private Map<String, Object> toItem(AgentArchive a, MissionBrief b, MissionProgress p, String subName) {
        List<String> texts = b == null ? Collections.emptyList() : parseTexts(b.getObjectives());
        Set<Integer> doneSet = p == null ? Collections.emptySet() : new TreeSet<>(parseInts(p.getDoneObjectives()));

        List<Map<String, Object>> objectives = new ArrayList<>();
        int doneCount = 0;
        for (int i = 0; i < texts.size(); i++) {
            boolean done = doneSet.contains(i);
            Map<String, Object> o = new LinkedHashMap<>();
            o.put("index", i);
            o.put("text", texts.get(i));
            o.put("done", done);
            objectives.add(o);
            if (done) {
                doneCount++;
            }
        }

        String status = "IDLE";
        if (p != null) {
            int st = p.getStatus() == null ? MissionProgress.ACTIVE : p.getStatus();
            status = st == MissionProgress.CLAIMED ? "DONE" : st == MissionProgress.READY ? "READY" : "ACTIVE";
        }

        int total = texts.size();
        int percent = total == 0 ? 0 : Math.round(doneCount * 100f / total);
        if ("DONE".equals(status)) {
            percent = 100;
        }

        int duration = b == null || b.getDurationMin() == null ? 0 : b.getDurationMin();
        long remainSec = duration * 60L;
        if (p != null && p.getDeadline() != null) {
            remainSec = Duration.between(LocalDateTime.now(), p.getDeadline()).getSeconds();
        }

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("code", a.getCode());
        m.put("name", a.getName());
        m.put("mono", a.getMono());
        m.put("color", a.getColor());
        m.put("tier", a.getTier());
        m.put("subCode", a.getSubCode());
        m.put("subName", subName);
        m.put("bio", a.getBio());
        m.put("story", a.getStory() == null ? "" : a.getStory());
        m.put("briefing", b == null ? a.getBio() : b.getBriefing());
        m.put("region", b == null ? "" : b.getRegion());
        m.put("squad", b == null ? "" : b.getSquad());
        m.put("reward", b == null ? 0 : nz(b.getReward()));
        m.put("duration", duration);
        m.put("objectives", objectives);
        m.put("doneCount", doneCount);
        m.put("objectiveCount", total);
        m.put("progress", percent);
        m.put("status", status);
        m.put("startedAt", p == null || p.getStartedAt() == null ? "" : p.getStartedAt().format(FMT));
        m.put("deadline", p == null || p.getDeadline() == null ? "" : p.getDeadline().format(FMT));
        m.put("finishedAt", p == null || p.getFinishedAt() == null ? "" : p.getFinishedAt().format(FMT));
        m.put("remainSec", remainSec);
        return m;
    }

    private static List<String> parseTexts(String json) {
        if (json == null || json.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return JSON.readValue(json, new TypeReference<List<String>>() {
            });
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private static List<Integer> parseInts(String json) {
        if (json == null || json.isBlank()) {
            return Collections.emptyList();
        }
        try {
            return JSON.readValue(json, new TypeReference<List<Integer>>() {
            });
        } catch (Exception e) {
            return Collections.emptyList();
        }
    }

    private static String JSONArray(Set<Integer> set) {
        try {
            return JSON.writeValueAsString(new ArrayList<>(set));
        } catch (Exception e) {
            return "[]";
        }
    }

    private static boolean has(String s) {
        return s != null && !s.trim().isEmpty();
    }

    private static String str(Object o) {
        return o == null ? "" : String.valueOf(o);
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }

    /* ==========================================================
       4. 结果封装：Service 层不直接依赖 Controller 的 Result
       ========================================================== */

    /** 业务结果：code 0 成功 */
    public static class ActionResult {
        private final int code;
        private final String msg;
        private final Object data;

        public ActionResult(int code, String msg, Object data) {
            this.code = code;
            this.msg = msg;
            this.data = data;
        }

        public static ActionResult ok(String msg, Object data) {
            return new ActionResult(0, msg, data);
        }

        public static ActionResult fail(int code, String msg) {
            return new ActionResult(code, msg, null);
        }

        public int getCode() {
            return code;
        }

        public String getMsg() {
            return msg;
        }

        public Object getData() {
            return data;
        }

        public boolean isOk() {
            return code == 0;
        }
    }
}
