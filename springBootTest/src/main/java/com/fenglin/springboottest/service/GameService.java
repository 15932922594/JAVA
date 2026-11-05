package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fenglin.springboottest.common.HeroLevel;
import com.fenglin.springboottest.common.WeaponCatalog;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.entity.GameRecord;
import com.fenglin.springboottest.entity.MissionBrief;
import com.fenglin.springboottest.entity.MissionProgress;
import com.fenglin.springboottest.mapper.AgentUserMapper;
import com.fenglin.springboottest.mapper.GameRecordMapper;
import com.fenglin.springboottest.mapper.MissionBriefMapper;
import com.fenglin.springboottest.mapper.MissionProgressMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;
import java.util.TreeSet;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * RANGE 训练场业务：成绩上报 / 个人统计 / 历史记录
 *
 * 核心玩法闭环：
 *   前端小游戏打完一局 → /api/game/report 上报成绩 → 落库 game_record
 *   → 按模式累计 units（命中数 / 完成组数 / 达标次数）
 *   → 自动勾选进行中任务里匹配的目标（如「靶机命中 30 次」），全部完成转 READY
 */
@Service
public class GameService extends ServiceImpl<GameRecordMapper, GameRecord> {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("yyyy-MM-dd HH:mm");
    private static final ObjectMapper JSON = new ObjectMapper();

    /** 目标文案里的数量：如「靶机命中 30 次」「完成压枪练习 3 组」 */
    private static final Pattern COUNT_IN_TEXT = Pattern.compile("(\\d+)\\s*[次组]");

    /** 模式 → 目标文案关键词（决定哪个模式能自动完成哪些目标） */
    private static final Map<String, String> MODE_KEYWORD = Map.of(
            GameRecord.TARGET, "命中",
            GameRecord.RECOIL, "压枪",
            GameRecord.REACTION, "急停");

    private final MissionBriefMapper briefMapper;
    private final MissionProgressMapper progressMapper;
    private final AgentUserMapper userMapper;
    private final HeroLevelService levelService;

    public GameService(MissionBriefMapper briefMapper, MissionProgressMapper progressMapper,
                       AgentUserMapper userMapper, HeroLevelService levelService) {
        this.briefMapper = briefMapper;
        this.progressMapper = progressMapper;
        this.userMapper = userMapper;
        this.levelService = levelService;
    }

    /* ==========================================================
       1. 成绩上报
       ========================================================== */

    /**
     * @param userId 当前特工 id
     * @param mode   训练模式 TARGET / RECOIL / REACTION
     * @param score  本局得分
     * @param units  本局有效单位数（前端按规则计算）
     * @param shots  本局射击次数
     * @param hits   本局命中次数
     * @param avgMs  本局平均反应毫秒
     */
    public Map<String, Object> report(Long userId, String mode, int score, int units,
                                      int shots, int hits, int avgMs) {
        String m = normalizeMode(mode);

        GameRecord r = new GameRecord();
        r.setUserId(userId);
        r.setMode(m);
        r.setScore(Math.max(0, score));
        r.setUnits(Math.max(0, units));
        r.setShots(Math.max(0, shots));
        r.setHits(Math.max(0, hits));
        r.setAvgMs(Math.max(0, avgMs));
        r.setCreateTime(LocalDateTime.now());
        save(r);

        // 训练奖励一：信用点（得分 ÷ 10，区间 [1, 200]）
        int reward = Math.max(WeaponCatalog.CREDIT_REWARD_MIN,
                Math.min(WeaponCatalog.CREDIT_REWARD_MAX, r.getScore() / 10));
        AgentUser u = userMapper.selectById(userId);
        int credits = (u == null || u.getCredits() == null ? 0 : u.getCredits()) + reward;
        userMapper.update(null, new UpdateWrapper<AgentUser>()
                .eq("id", userId)
                .set("credits", credits));

        // 训练奖励二：经验值（得分 ÷ 20，单局上限 100），升级时额外发信用点
        Map<String, Object> levelInfo = levelService.gain(userId,
                HeroLevel.expFromScore(r.getScore()), null);

        // 自动完成匹配的作战任务目标
        List<String> completed = autoCompleteMissions(userId, m, totalUnits(userId, m));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("record", toItem(r, true));
        data.put("stats", stats(userId));
        data.put("missionCompleted", completed);
        data.put("creditsEarned", reward);
        // 升级奖励会再追加信用点：有升级就以 gain() 返回的最终余额为准
        Object afterLevel = levelInfo.get("credits");
        data.put("credits", afterLevel instanceof Number n ? n.intValue() : credits);
        data.put("level", levelInfo);
        return data;
    }

    /* ==========================================================
       2. 个人统计 + 历史记录
       ========================================================== */

    /** 各模式：总局数 / 累计 units / 最高分 / 最好成绩（最小 avgMs） */
    public Map<String, Object> stats(Long userId) {
        List<GameRecord> all = list(new QueryWrapper<GameRecord>().eq("user_id", userId));

        Map<String, Object> modes = new LinkedHashMap<>();
        for (String mode : new String[]{GameRecord.TARGET, GameRecord.RECOIL, GameRecord.REACTION}) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("games", 0);
            m.put("units", 0);
            m.put("bestScore", 0);
            m.put("bestAvgMs", 0);
            modes.put(mode, m);
        }
        for (GameRecord r : all) {
            @SuppressWarnings("unchecked")
            Map<String, Object> m = (Map<String, Object>) modes.get(r.getMode());
            if (m == null) {
                continue;
            }
            m.put("games", (int) m.get("games") + 1);
            m.put("units", (int) m.get("units") + nz(r.getUnits()));
            if (nz(r.getScore()) > (int) m.get("bestScore")) {
                m.put("bestScore", nz(r.getScore()));
            }
            int ms = nz(r.getAvgMs());
            if (ms > 0 && ((int) m.get("bestAvgMs") == 0 || ms < (int) m.get("bestAvgMs"))) {
                m.put("bestAvgMs", ms);
            }
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("modes", modes);
        data.put("total", all.size());
        return data;
    }

    /** 最近成绩（默认 10 条） */
    public List<Map<String, Object>> records(Long userId, int limit) {
        int n = Math.max(1, Math.min(limit, 50));
        List<GameRecord> list = list(new QueryWrapper<GameRecord>()
                .eq("user_id", userId)
                .orderByDesc("id")
                .last("LIMIT " + n));
        List<Map<String, Object>> out = new ArrayList<>();
        for (GameRecord r : list) {
            out.add(toItem(r, false));
        }
        return out;
    }

    /* ==========================================================
       3. 任务目标自动完成
       ========================================================== */

    /**
     * 累计 units 达到目标文案要求的数量时自动勾选该目标；
     * 全部目标完成则状态转 READY（与手动勾选同一套逻辑）。
     *
     * @return 本次自动完成的目标文案列表（供前端提示）
     */
    private List<String> autoCompleteMissions(Long userId, String mode, long totalUnits) {
        String keyword = MODE_KEYWORD.get(mode);
        List<String> completed = new ArrayList<>();
        if (keyword == null) {
            return completed;
        }

        // 该特工进行中 / 待结算的任务进度
        List<MissionProgress> progresses = progressMapper.selectList(new QueryWrapper<MissionProgress>()
                .eq("user_id", userId)
                .in("status", MissionProgress.ACTIVE, MissionProgress.READY));

        for (MissionProgress p : progresses) {
            MissionBrief b = briefMapper.selectOne(
                    new QueryWrapper<MissionBrief>().eq("mission_code", p.getMissionCode()));
            if (b == null) {
                continue;
            }
            List<String> objectives = parseTexts(b.getObjectives());
            if (objectives.isEmpty()) {
                continue;
            }

            Set<Integer> done = new TreeSet<>(parseInts(p.getDoneObjectives()));
            boolean changed = false;
            for (int i = 0; i < objectives.size(); i++) {
                if (done.contains(i)) {
                    continue;
                }
                String text = objectives.get(i);
                if (!text.contains(keyword)) {
                    continue;
                }
                Matcher mt = COUNT_IN_TEXT.matcher(text);
                if (mt.find() && totalUnits >= Integer.parseInt(mt.group(1))) {
                    done.add(i);
                    changed = true;
                    completed.add(text);
                }
            }
            if (changed) {
                p.setDoneObjectives(toJson(done));
                p.setStatus(done.size() >= objectives.size() ? MissionProgress.READY : MissionProgress.ACTIVE);
                progressMapper.updateById(p);
            }
        }
        return completed;
    }

    /** 某模式累计 units（用于「命中 30 次」这类终身累计型目标） */
    private long totalUnits(Long userId, String mode) {
        return list(new QueryWrapper<GameRecord>()
                .eq("user_id", userId).eq("mode", mode))
                .stream().mapToLong(r -> nz(r.getUnits())).sum();
    }

    /* ==========================================================
       4. 内部工具
       ========================================================== */

    private static String normalizeMode(String mode) {
        String s = mode == null ? "" : mode.trim().toUpperCase();
        return s.equals(GameRecord.RECOIL) || s.equals(GameRecord.REACTION) ? s : GameRecord.TARGET;
    }

    private Map<String, Object> toItem(GameRecord r, boolean withModeName) {
        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", r.getId());
        m.put("mode", r.getMode());
        if (withModeName) {
            m.put("modeName", modeName(r.getMode()));
        }
        m.put("score", nz(r.getScore()));
        m.put("units", nz(r.getUnits()));
        m.put("shots", nz(r.getShots()));
        m.put("hits", nz(r.getHits()));
        m.put("avgMs", nz(r.getAvgMs()));
        m.put("time", r.getCreateTime() == null ? "" : r.getCreateTime().format(FMT));
        return m;
    }

    public static String modeName(String mode) {
        return switch (mode == null ? "" : mode) {
            case GameRecord.RECOIL -> "压枪练习";
            case GameRecord.REACTION -> "反应测试";
            default -> "靶场点击";
        };
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

    private static String toJson(Set<Integer> set) {
        try {
            return JSON.writeValueAsString(new ArrayList<>(set));
        } catch (Exception e) {
            return "[]";
        }
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
