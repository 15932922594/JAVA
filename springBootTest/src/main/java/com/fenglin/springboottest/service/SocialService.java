package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.common.HeroLevel;
import com.fenglin.springboottest.common.HeroStats;
import com.fenglin.springboottest.common.WeaponCatalog;
import com.fenglin.springboottest.entity.AgentFriend;
import com.fenglin.springboottest.entity.AgentPk;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.mapper.AgentFriendMapper;
import com.fenglin.springboottest.mapper.AgentPkMapper;
import com.fenglin.springboottest.mapper.AgentUserMapper;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.LocalDateTime;
import java.time.format.DateTimeFormatter;
import java.util.ArrayList;
import java.util.Comparator;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 社交与竞技业务：
 *   好友（搜索 / 申请 / 同意 / 拒绝 / 删除）
 *   战力（英雄属性 × 等级成长 + 主武器加成）
 *   排行榜（按战力排序）
 *   PK（好友间自动结算，胜者得信用点与经验；同一对手每天限 3 场）
 */
@Service
public class SocialService extends ServiceImpl<AgentFriendMapper, AgentFriend> {

    private static final DateTimeFormatter FMT = DateTimeFormatter.ofPattern("MM-dd HH:mm");

    /** 同一对玩家每天最多 PK 场次 */
    public static final int PK_DAILY_LIMIT = 3;

    /** PK 胜/负奖励 */
    private static final int WIN_CREDITS = 60;
    private static final int WIN_EXP = 20;
    private static final int LOSE_EXP = 15;

    /** 战力随机浮动 ±10% */
    private static final double FLOAT = 0.10;

    private final AgentUserMapper userMapper;
    private final AgentPkMapper pkMapper;
    private final HeroLevelService levelService;

    public SocialService(AgentUserMapper userMapper, AgentPkMapper pkMapper,
                         HeroLevelService levelService) {
        this.userMapper = userMapper;
        this.pkMapper = pkMapper;
        this.levelService = levelService;
    }

    /* ==========================================================
       1. 战力
       ========================================================== */

    /** 账号当前战力（等级由经验推导，武器取已装备主武器） */
    public int powerOf(AgentUser u) {
        int level = HeroLevel.levelOf(u.getExp() == null ? 0 : u.getExp());
        String weapon = u.getEquippedWeapon() == null || u.getEquippedWeapon().isBlank()
                ? "classic" : u.getEquippedWeapon();
        return HeroStats.power(u.getAgentIndex(), level, weapon);
    }

    /** 对外展示的玩家卡片 */
    private Map<String, Object> card(AgentUser u, String relation) {
        int level = HeroLevel.levelOf(u.getExp() == null ? 0 : u.getExp());
        WeaponCatalog.Weapon w = WeaponCatalog.find(u.getEquippedWeapon());
        int frameTier = HeroLevel.shownFrameTier(level, u.getEquippedFrame());

        Map<String, Object> m = new LinkedHashMap<>();
        m.put("id", u.getId());
        m.put("name", u.getName());
        m.put("agentIndex", HeroStats.clampIndex(u.getAgentIndex()));
        m.put("agentName", HeroStats.name(u.getAgentIndex()));
        m.put("agentRole", HeroStats.role(u.getAgentIndex()));
        m.put("level", level);
        m.put("power", powerOf(u));
        m.put("frameTier", frameTier);
        m.put("frameName", HeroLevel.frameNameOfTier(frameTier));
        m.put("weapon", w == null ? "标配" : w.name);
        m.put("weaponCode", w == null ? "classic" : w.code);
        m.put("win", u.getPkWin() == null ? 0 : u.getPkWin());
        m.put("lose", u.getPkLose() == null ? 0 : u.getPkLose());
        if (relation != null) {
            m.put("relation", relation);
        }
        return m;
    }

    /* ==========================================================
       2. 好友
       ========================================================== */

    /** 搜索玩家（按代号模糊，排除自己） */
    public List<Map<String, Object>> search(AgentUser me, String keyword) {
        String q = keyword == null ? "" : keyword.trim();
        if (q.isEmpty()) {
            return List.of();
        }
        List<AgentUser> users = userMapper.selectList(new QueryWrapper<AgentUser>()
                .like("name", q)
                .ne("id", me.getId())
                .last("LIMIT 20"));

        List<Map<String, Object>> out = new ArrayList<>();
        for (AgentUser u : users) {
            out.add(card(u, relationOf(me.getId(), u.getId())));
        }
        return out;
    }

    /** 我与某人的关系：self / friend / out（我发出的待同意）/ in（对方发来待同意）/ none */
    public String relationOf(Long myId, Long otherId) {
        if (myId.equals(otherId)) {
            return "self";
        }
        AgentFriend out = getOne(new QueryWrapper<AgentFriend>()
                .eq("user_id", myId).eq("friend_id", otherId), false);
        if (out != null) {
            return AgentFriend.ACCEPTED.equals(out.getStatus()) ? "friend" : "out";
        }
        AgentFriend in = getOne(new QueryWrapper<AgentFriend>()
                .eq("user_id", otherId).eq("friend_id", myId), false);
        if (in != null) {
            return AgentFriend.ACCEPTED.equals(in.getStatus()) ? "friend" : "in";
        }
        return "none";
    }

    /** 好友面板：好友列表 + 收到的申请 + 我发出的申请 */
    public Map<String, Object> friends(AgentUser me) {
        List<AgentFriend> accepted = list(new QueryWrapper<AgentFriend>()
                .eq("status", AgentFriend.ACCEPTED)
                .and(w -> w.eq("user_id", me.getId()).or().eq("friend_id", me.getId()))
                .orderByDesc("update_time"));

        List<Map<String, Object>> friendCards = new ArrayList<>();
        for (AgentFriend f : accepted) {
            Long otherId = f.getUserId().equals(me.getId()) ? f.getFriendId() : f.getUserId();
            AgentUser u = userMapper.selectById(otherId);
            if (u != null) {
                Map<String, Object> c = card(u, "friend");
                c.put("friendRowId", f.getId());
                friendCards.add(c);
            }
        }

        List<Map<String, Object>> incoming = new ArrayList<>();
        for (AgentFriend f : list(new QueryWrapper<AgentFriend>()
                .eq("friend_id", me.getId())
                .eq("status", AgentFriend.PENDING)
                .orderByDesc("create_time"))) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("rowId", f.getId());
            m.put("userId", f.getUserId());
            m.put("name", f.getUserName());
            m.put("time", f.getCreateTime() == null ? "" : f.getCreateTime().format(FMT));
            incoming.add(m);
        }

        List<Map<String, Object>> outgoing = new ArrayList<>();
        for (AgentFriend f : list(new QueryWrapper<AgentFriend>()
                .eq("user_id", me.getId())
                .eq("status", AgentFriend.PENDING)
                .orderByDesc("create_time"))) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("rowId", f.getId());
            m.put("userId", f.getFriendId());
            m.put("name", f.getFriendName());
            m.put("time", f.getCreateTime() == null ? "" : f.getCreateTime().format(FMT));
            outgoing.add(m);
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("friends", friendCards);
        data.put("incoming", incoming);
        data.put("outgoing", outgoing);
        data.put("me", card(me, "self"));
        return data;
    }

    /**
     * 发送好友申请。
     *
     * @return ok 或错误码：notfound / self / already-friend / already-sent / already-received
     */
    public String request(AgentUser me, Long targetId) {
        if (targetId == null || targetId.equals(me.getId())) {
            return "self";
        }
        AgentUser target = userMapper.selectById(targetId);
        if (target == null) {
            return "notfound";
        }
        String rel = relationOf(me.getId(), targetId);
        switch (rel) {
            case "friend":
                return "already-friend";
            case "out":
                return "already-sent";
            case "in":
                return "already-received";
            default:
                break;
        }
        AgentFriend f = new AgentFriend();
        f.setUserId(me.getId());
        f.setUserName(me.getName());
        f.setFriendId(target.getId());
        f.setFriendName(target.getName());
        f.setStatus(AgentFriend.PENDING);
        save(f);
        return "ok";
    }

    /** 同意申请（只能处理发给自己的申请） */
    public String accept(AgentUser me, Long rowId) {
        AgentFriend f = getById(rowId);
        if (f == null || !me.getId().equals(f.getFriendId())) {
            return "notfound";
        }
        if (!AgentFriend.PENDING.equals(f.getStatus())) {
            return "already-handled";
        }
        f.setStatus(AgentFriend.ACCEPTED);
        f.setUpdateTime(LocalDateTime.now());
        updateById(f);
        return "ok";
    }

    /** 拒绝申请（删除该行） */
    public String reject(AgentUser me, Long rowId) {
        AgentFriend f = getById(rowId);
        if (f == null || !me.getId().equals(f.getFriendId())) {
            return "notfound";
        }
        removeById(rowId);
        return "ok";
    }

    /** 删除好友（双方任一方都可以，双向删除） */
    public String removeFriend(AgentUser me, Long friendId) {
        remove(new QueryWrapper<AgentFriend>()
                .and(w -> w.and(x -> x.eq("user_id", me.getId()).eq("friend_id", friendId))
                        .or(x -> x.eq("user_id", friendId).eq("friend_id", me.getId()))));
        return "ok";
    }

    /* ==========================================================
       3. 排行榜
       ========================================================== */

    public Map<String, Object> rank(AgentUser me) {
        List<AgentUser> users = userMapper.selectList(null);
        users.sort(Comparator.comparingInt(this::powerOf).reversed());

        List<Map<String, Object>> rows = new ArrayList<>();
        int myRank = 0;
        for (int i = 0; i < users.size() && i < 50; i++) {
            AgentUser u = users.get(i);
            if (u.getId().equals(me.getId())) {
                myRank = i + 1;
            }
            Map<String, Object> c = card(u, null);
            c.put("rank", i + 1);
            rows.add(c);
        }
        // 自己不在前 50 也补算名次
        if (myRank == 0) {
            for (int i = 0; i < users.size(); i++) {
                if (users.get(i).getId().equals(me.getId())) {
                    myRank = i + 1;
                    break;
                }
            }
        }

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("list", rows);
        data.put("total", users.size());
        data.put("myRank", myRank);
        data.put("me", card(me, "self"));
        return data;
    }

    /* ==========================================================
       4. PK（自动结算）
       ========================================================== */

    /** 今日与某人的已 PK 场次 */
    private long todayPkCount(Long a, Long b) {
        LocalDateTime start = LocalDate.now().atStartOfDay();
        return pkMapper.selectCount(new QueryWrapper<AgentPk>()
                .ge("create_time", start)
                .and(w -> w.and(x -> x.eq("challenger_id", a).eq("defender_id", b))
                        .or(x -> x.eq("challenger_id", b).eq("defender_id", a))));
    }

    /**
     * 自动 PK 结算（排行榜上除自己外的任何特工都可以直接挑战，无需好友）。
     *
     * @return 成功返回结果 Map；失败返回错误码：
     *         self / notfound / daily-limit
     */
    public Object pk(AgentUser me, Long targetId) {
        if (targetId == null || targetId.equals(me.getId())) {
            return "self";
        }
        AgentUser foe = userMapper.selectById(targetId);
        if (foe == null) {
            return "notfound";
        }
        if (todayPkCount(me.getId(), targetId) >= PK_DAILY_LIMIT) {
            return "daily-limit";
        }

        int myPower = powerOf(me);
        int foePower = powerOf(foe);
        int myRoll = (int) Math.round(myPower * (1 + (Math.random() * 2 - 1) * FLOAT));
        int foeRoll = (int) Math.round(foePower * (1 + (Math.random() * 2 - 1) * FLOAT));
        boolean win = myRoll >= foeRoll;

        // 记录战绩
        AgentPk rec = new AgentPk();
        rec.setChallengerId(me.getId());
        rec.setChallengerName(me.getName());
        rec.setDefenderId(foe.getId());
        rec.setDefenderName(foe.getName());
        rec.setChallengerPower(myRoll);
        rec.setDefenderPower(foeRoll);
        rec.setWinnerId(win ? me.getId() : foe.getId());
        rec.setDetail(win ? "挑战方胜" : "应战方胜");
        rec.setCreateTime(LocalDateTime.now());
        pkMapper.insert(rec);

        // 胜负统计
        userMapper.update(null, new UpdateWrapper<AgentUser>()
                .eq("id", win ? me.getId() : foe.getId())
                .setSql("pk_win = pk_win + 1"));
        userMapper.update(null, new UpdateWrapper<AgentUser>()
                .eq("id", win ? foe.getId() : me.getId())
                .setSql("pk_lose = pk_lose + 1"));

        // 奖励：胜者信用点 + 经验；败者只有安慰经验（经验可能触发升级）
        Map<String, Object> levelInfo;
        int creditGain;
        if (win) {
            creditGain = WIN_CREDITS;
            userMapper.update(null, new UpdateWrapper<AgentUser>()
                    .eq("id", me.getId())
                    .setSql("credits = credits + " + WIN_CREDITS));
            levelInfo = levelService.gain(me.getId(), WIN_EXP, null);
        } else {
            creditGain = 20;
            userMapper.update(null, new UpdateWrapper<AgentUser>()
                    .eq("id", me.getId())
                    .setSql("credits = credits + 20"));
            levelInfo = levelService.gain(me.getId(), LOSE_EXP, null);
        }

        AgentUser fresh = userMapper.selectById(me.getId());
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("win", win);
        data.put("myPower", myPower);
        data.put("foePower", foePower);
        data.put("myRoll", myRoll);
        data.put("foeRoll", foeRoll);
        data.put("foe", card(foe, null));
        data.put("me", card(fresh == null ? me : fresh, "self"));
        data.put("creditsGained", creditGain);
        data.put("level", levelInfo);
        data.put("remainToday", PK_DAILY_LIMIT - todayPkCount(me.getId(), targetId));
        return data;
    }

    /* ==========================================================
       5. 头像框佩戴（边框图鉴里自选已解锁的档位）
       ========================================================== */

    /**
     * 佩戴头像框。
     *
     * @param tier 目标档位；0 = 跟随最新解锁
     * @return 成功返回佩戴结果；失败返回错误码 frame-locked（档位未解锁）
     */
    public Map<String, Object> equipFrame(AgentUser me, Integer tier) {
        int t = tier == null ? 0 : tier;
        int level = HeroLevel.levelOf(me.getExp() == null ? 0 : me.getExp());
        if (!HeroLevel.isValidFrameTier(level, t)) {
            return null;
        }
        userMapper.update(null, new UpdateWrapper<AgentUser>()
                .eq("id", me.getId())
                .set("equipped_frame", t));
        me.setEquippedFrame(t);

        int shown = HeroLevel.shownFrameTier(level, t);
        Map<String, Object> data = new LinkedHashMap<>();
        data.put("tier", shown);
        data.put("auto", t == 0 || t >= HeroLevel.frameMaxTier(level));
        data.put("name", HeroLevel.frameNameOfTier(shown));
        data.put("en", HeroLevel.frameEnOfTier(shown));
        return data;
    }

    /* ==========================================================
       6. PK 记录
       ========================================================== */

    /** 我的 PK 记录（最近 20 条） */
    public List<Map<String, Object>> logs(AgentUser me, int limit) {
        int n = Math.max(1, Math.min(limit, 50));
        List<AgentPk> rows = pkMapper.selectList(new QueryWrapper<AgentPk>()
                .and(w -> w.eq("challenger_id", me.getId()).or().eq("defender_id", me.getId()))
                .orderByDesc("id")
                .last("LIMIT " + n));

        List<Map<String, Object>> out = new ArrayList<>();
        for (AgentPk r : rows) {
            boolean asChallenger = me.getId().equals(r.getChallengerId());
            boolean win = me.getId().equals(r.getWinnerId());
            String rival = asChallenger ? r.getDefenderName() : r.getChallengerName();
            int myP = asChallenger ? nz(r.getChallengerPower()) : nz(r.getDefenderPower());
            int foeP = asChallenger ? nz(r.getDefenderPower()) : nz(r.getChallengerPower());

            Map<String, Object> m = new LinkedHashMap<>();
            m.put("id", r.getId());
            m.put("win", win);
            m.put("rival", rival);
            m.put("myPower", myP);
            m.put("foePower", foeP);
            m.put("time", r.getCreateTime() == null ? "" : r.getCreateTime().format(FMT));
            out.add(m);
        }
        return out;
    }

    private static int nz(Integer v) {
        return v == null ? 0 : v;
    }
}
