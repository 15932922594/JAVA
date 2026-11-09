package com.fenglin.springboottest.common;

import java.util.ArrayList;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;

/**
 * 军械商店武器目录（前后端共用同一份数据，前端按 weapon_code 匹配外观）。
 *
 * 价格体系（信用点，与无畏契约一致）：
 *   标配 classic   —— 免费（人手一把）
 *   正义 sheriff   —— 800
 *   鸟狙 marshal   —— 950
 *   戍卫 guardian  —— 2250
 *   幻影 phantom   —— 2900
 *   狂徒 vandal    —— 2900（与幻影同价）
 *   战神 odin      —— 3200
 *   冥狙 operator  —— 4700（全场最贵）
 */
public final class WeaponCatalog {

    public static final class Weapon {
        public final String code;
        public final String name;
        public final String category;
        public final int price;
        /** 购买所需英雄等级 */
        public final int level;
        /** 装备后的战力加成 */
        public final int power;
        /** 1 上架 / 0 下架（下架后不可购买，但仍保留外观/战力数据） */
        public final int status;

        public Weapon(String code, String name, String category, int price, int level, int power) {
            this(code, name, category, price, level, power, 1);
        }

        public Weapon(String code, String name, String category, int price, int level, int power, int status) {
            this.code = code;
            this.name = name;
            this.category = category;
            this.price = price;
            this.level = level;
            this.power = power;
            this.status = status;
        }

        public boolean free() {
            return price == 0;
        }

        public boolean onSale() {
            return status != 0;
        }
    }

    /**
     * 代码内的「初始目录」：仅在数据库 weapon_catalog 无数据时作为兜底，运行时以库为准。
     *
     * 目录顺序即商店展示顺序（从免费到最贵）。
     * 等级门槛：越强的枪需要越高的英雄等级才允许购买。
     * 战力加成：装备为主武器后加在英雄战力上。
     */
    private static final List<Weapon> ALL = List.of(
            new Weapon("classic", "标配", "手枪", 0, 1, 5),
            new Weapon("sheriff", "正义", "手枪", 800, 1, 15),
            new Weapon("marshal", "鸟狙", "狙击枪", 950, 2, 25),
            new Weapon("guardian", "戍卫", "步枪", 2250, 3, 35),
            new Weapon("phantom", "幻影", "步枪", 2900, 4, 45),
            new Weapon("vandal", "狂徒", "步枪", 2900, 4, 45),
            new Weapon("odin", "战神", "机枪", 3200, 6, 50),
            new Weapon("operator", "冥狙", "狙击枪", 4700, 8, 60)
    );

    /** 注册赠送的起始信用点（正好够立刻买一把正义） */
    public static final int START_CREDITS = 800;

    /** 训练场每局信用点奖励上限 / 下限 */
    public static final int CREDIT_REWARD_MAX = 200;
    public static final int CREDIT_REWARD_MIN = 1;

    private WeaponCatalog() {
    }

    public static List<Weapon> all() {
        return ALL;
    }

    /** code 是否在初始目录内（用于校验后台修改的是不是已知武器） */
    public static boolean exists(String code) {
        return find(code) != null;
    }

    /** 按 code 查武器；不存在返回 null */
    public static Weapon find(String code) {
        if (code == null || code.isBlank()) {
            return null;
        }
        String c = code.trim().toLowerCase();
        for (Weapon w : ALL) {
            if (w.code.equals(c)) {
                return w;
            }
        }
        return null;
    }

    /** 目录的 JSON 形态（给前端接口用） */
    public static List<Map<String, Object>> toList() {
        List<Map<String, Object>> out = new ArrayList<>();
        for (Weapon w : ALL) {
            Map<String, Object> m = new LinkedHashMap<>();
            m.put("code", w.code);
            m.put("name", w.name);
            m.put("category", w.category);
            m.put("price", w.price);
            m.put("reqLevel", w.level);
            m.put("power", w.power);
            out.add(m);
        }
        return out;
    }
}
