package com.fenglin.springboottest.service;

import com.baomidou.mybatisplus.core.conditions.query.QueryWrapper;
import com.baomidou.mybatisplus.core.conditions.update.UpdateWrapper;
import com.baomidou.mybatisplus.extension.service.impl.ServiceImpl;
import com.fenglin.springboottest.common.HeroLevel;
import com.fenglin.springboottest.common.HeroStats;
import com.fenglin.springboottest.common.WeaponCatalog;
import com.fenglin.springboottest.entity.AgentUser;
import com.fenglin.springboottest.entity.AgentWeapon;
import com.fenglin.springboottest.mapper.AgentUserMapper;
import com.fenglin.springboottest.mapper.AgentWeaponMapper;
import org.springframework.stereotype.Service;

import java.util.HashSet;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.Set;

/**
 * 军械商店业务：
 *   查看武器目录 + 余额 + 已拥有；购买武器（扣信用点）。
 *
 * 规则：
 *   - 标配（classic）免费，人人拥有（注册时已入库，老账号购买接口也放行 0 元购）
 *   - 其余武器按目录价格扣 credits，一人一武器（唯一索引兜底）
 */
@Service
public class ArmoryService extends ServiceImpl<AgentWeaponMapper, AgentWeapon> {

    private final AgentUserMapper userMapper;
    /** 武器目录（价格 / 需求等级 存库，后台可改） */
    private final WeaponCatalogService catalog;

    public ArmoryService(AgentUserMapper userMapper, WeaponCatalogService catalog) {
        this.userMapper = userMapper;
        this.catalog = catalog;
    }

    /* 商店页数据 */
    public Map<String, Object> armory(AgentUser user) {
        Set<String> owned = ownedCodes(user.getId());

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("credits", credits(user));
        data.put("heroLevel", levelOf(user));
        data.put("frameTier", HeroLevel.frameTier(levelOf(user)));

        List<Map<String, Object>> weapons = catalog.shopList();
        String equipped = user.getEquippedWeapon() == null || user.getEquippedWeapon().isBlank()
                ? "classic" : user.getEquippedWeapon();
        for (Map<String, Object> w : weapons) {
            w.put("owned", owned.contains(w.get("code")));
            w.put("equipped", equipped.equals(w.get("code")));
        }
        data.put("weapons", weapons);
        data.put("ownedCount", owned.size());
        data.put("equipped", equipped);
        data.put("power", HeroStats.power(user.getAgentIndex(), levelOf(user), equipped, catalog.find(equipped)));
        return data;
    }

    /**
     * 装备主武器（只影响战力）。要求：已拥有、等级达标。
     *
     * @return 成功返回装备信息；失败返回错误码 not-owned / level-too-low / unknown-weapon
     */
    public Object equip(AgentUser user, String code) {
        WeaponCatalog.Weapon w = catalog.find(code);
        if (w == null) {
            return "unknown-weapon";
        }
        if (!ownedCodes(user.getId()).contains(w.code)) {
            return "not-owned";
        }
        if (levelOf(user) < w.level) {
            return "level-too-low";
        }
        userMapper.update(null, new UpdateWrapper<AgentUser>()
                .eq("id", user.getId())
                .set("equipped_weapon", w.code));
        user.setEquippedWeapon(w.code);

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("code", w.code);
        data.put("name", w.name);
        data.put("power", HeroStats.power(user.getAgentIndex(), levelOf(user), w.code, w));
        return data;
    }

    /**
     * 购买武器。
     *
     * @return 成功返回 Map（新余额等）；失败返回错误码字符串：
     *         unknown-weapon / off-shelf / already-owned / level-too-low / not-enough-credits
     */
    public Object buy(AgentUser user, String code) {
        WeaponCatalog.Weapon w = catalog.find(code);
        if (w == null) {
            return "unknown-weapon";
        }
        // 后台下架的武器不再允许购买
        if (!w.onSale()) {
            return "off-shelf";
        }

        Set<String> owned = ownedCodes(user.getId());
        if (owned.contains(w.code)) {
            return "already-owned";
        }

        // 等级门槛：英雄等级不足不允许购买（等级以 exp 推导，避免与库里的缓存值冲突）
        int level = levelOf(user);
        if (level < w.level) {
            return "level-too-low";
        }

        int balance = credits(user);
        if (balance < w.price) {
            return "not-enough-credits";
        }

        // 扣款 + 入库（agent_weapon 的 uk_user_weapon 唯一索引防并发重复购买）
        userMapper.update(null, new UpdateWrapper<AgentUser>()
                .eq("id", user.getId())
                .set("credits", balance - w.price));
        user.setCredits(balance - w.price);
        save(new AgentWeapon(user.getId(), user.getName(), w.code, w.name));

        Map<String, Object> data = new LinkedHashMap<>();
        data.put("code", w.code);
        data.put("name", w.name);
        data.put("price", w.price);
        data.put("credits", user.getCredits());
        return data;
    }

    private Set<String> ownedCodes(Long userId) {
        List<AgentWeapon> rows = list(new QueryWrapper<AgentWeapon>().eq("user_id", userId));
        Set<String> codes = new HashSet<>();
        for (AgentWeapon r : rows) {
            codes.add(r.getWeaponCode());
        }
        return codes;
    }

    private static int credits(AgentUser user) {
        return user.getCredits() == null ? 0 : user.getCredits();
    }

    /** 英雄等级：以累计经验推导，`hero_level` 只作为缓存字段 */
    private static int levelOf(AgentUser user) {
        return HeroLevel.levelOf(user.getExp() == null ? 0 : user.getExp());
    }
}
