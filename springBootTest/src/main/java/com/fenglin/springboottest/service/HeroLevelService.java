package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.fenglin.springboottest.common.HeroLevel;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.mapper.AgentUserMapper;
import org.springframework.stereotype.Service;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 英雄成长业务：加经验 → 重算等级 → 升级发奖励（信用点 + 头像框解锁）。
 *
 * 奖励规则（等级无上限，每级都有）：
 *   · 普通升级：100 + 50 × 新等级 信用点
 *   · 边框里程碑：再额外 +300 信用点，并解锁对应档位头像框
 *
 * 经验来源：训练场（GameService）、任务结算（MissionService）、每日登录（AgentUserService）、
 *          好友 PK（SocialService）。
 */
@Service
public class HeroLevelService {

    private final AgentUserMapper userMapper;

    public HeroLevelService(AgentUserMapper userMapper) {
        this.userMapper = userMapper;
    }

    /**
     * 给账号加经验并处理升级。
     *
     * @param userId 账号 id
     * @param exp    本次获得的经验（<=0 时直接返回当前状态）
     * @param user   可选的已加载账号（避免重复查库）
     * @return 变化详情：expGained / exp / level、原地升级时 levelUp=true 与升级奖励 creditsGained
     */
    public Map<String, Object> gain(Long userId, int exp, AgentUser user) {
        AgentUser u = user != null ? user : userMapper.selectById(userId);
        Map<String, Object> out = new LinkedHashMap<>();
        if (u == null) {
            out.put("expGained", 0);
            out.put("levelUp", false);
            return out;
        }

        int add = Math.max(0, exp);
        int oldExp = u.getExp() == null ? 0 : u.getExp();
        // 等级一律由经验推导，库里 hero_level 只当缓存写回
        int oldLevel = HeroLevel.levelOf(oldExp);

        // 等级无上限：只要经验够就一直升。这里只用 INT 上限兜底（exp 列是 INT），
        // 属于数据列容量限制，不是游戏规则里的满级。
        int newExp = (int) Math.min(Integer.MAX_VALUE, (long) oldExp + add);
        int newLevel = HeroLevel.levelOf(newExp);

        boolean levelUp = newLevel > oldLevel;
        int creditBonus = 0;
        int frameBonus = 0;
        List<String> unlockedFrames = new ArrayList<>();
        if (levelUp) {
            for (int lv = oldLevel + 1; lv <= newLevel; lv++) {
                // 每一级都有奖励：100 + 50 × 新等级
                creditBonus += HeroLevel.levelUpReward(lv);
                // 到达边框阶梯的等级，额外奖励并解锁新边框
                if (HeroLevel.isFrameMilestone(lv)) {
                    creditBonus += HeroLevel.FRAME_BONUS;
                    frameBonus += HeroLevel.FRAME_BONUS;
                    unlockedFrames.add("LV." + lv + " " + HeroLevel.frameNameOfTier(HeroLevel.frameTier(lv)));
                }
            }
        }

        int credits = (u.getCredits() == null ? 0 : u.getCredits()) + creditBonus;
        userMapper.update(null, new UpdateWrapper<AgentUser>()
                .eq("id", u.getId())
                .set("exp", newExp)
                .set("hero_level", newLevel)
                .set("credits", credits));

        u.setExp(newExp);
        u.setHeroLevel(newLevel);
        u.setCredits(credits);

        out.put("expGained", newExp - oldExp);
        out.put("exp", newExp);
        out.put("expInLevel", HeroLevel.expInLevel(newExp));
        out.put("expForNext", HeroLevel.expForNext(newLevel));
        out.put("level", newLevel);
        out.put("levelUp", levelUp);
        // 头像框：玩家可自选佩戴（equipped_frame，0 = 跟随最新解锁），
        // 返回「实际显示的档位」与「当前等级可解锁的最高档」
        int maxTier = HeroLevel.frameMaxTier(newLevel);
        Integer equipped = u.getEquippedFrame();
        int shownTier = HeroLevel.shownFrameTier(newLevel, equipped);
        out.put("frameTier", shownTier);
        out.put("frameMaxTier", maxTier);
        out.put("frameAuto", equipped == null || equipped == 0 || equipped >= maxTier);
        out.put("frameName", HeroLevel.frameNameOfTier(shownTier));
        out.put("frameEn", HeroLevel.frameEnOfTier(shownTier));
        out.put("nextFrameLevel", HeroLevel.nextFrameLevel(newLevel));
        out.put("nextFrameName", HeroLevel.nextFrameName(newLevel));
        if (levelUp) {
            out.put("fromLevel", oldLevel);
            out.put("creditsGained", creditBonus);
            out.put("credits", credits);
            out.put("frameBonus", frameBonus);
            out.put("frameUnlocked", !unlockedFrames.isEmpty());
            out.put("unlockedFrames", unlockedFrames);
        }
        return out;
    }
}
