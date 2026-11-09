package com.fenglin.springboottest.common;

/**
 * 英雄属性与战力计算（与前端 src/data/agents.js 的 stats 顺序一致）。
 *
 * 每个英雄四项属性（0~100）：火力 / 机动 / 控制 / 防御
 * 战力公式：round((火力×1.2 + 机动×1.0 + 控制×0.9 + 防御×1.1) × 等级系数 + 主武器战力加成)
 *   等级系数 = 1 + 0.02 × (等级 - 1)   （无上限：每级继续 +2%）
 */
public final class HeroStats {

    /** 属性权重：火力最重要，控制稍低 */
    private static final double W_FIRE = 1.2;
    private static final double W_MOB = 1.0;
    private static final double W_CTRL = 0.9;
    private static final double W_DEF = 1.1;

    /** 每级属性成长率 */
    private static final double GROWTH = 0.02;

    /** 英雄静态数据：下标与前端 AGENTS 一致 */
    private static final String[][] AGENTS = {
            // 代号,    定位,            火力  机动  控制  防御
            {"VECTOR", "突击 · ASSAULT", "92", "76", "44", "38"},
            {"ARCLIGHT", "侦察 · RECON", "58", "86", "72", "46"},
            {"PHANTOM", "控场 · CONTROL", "52", "74", "93", "50"},
            {"ONYX", "守护 · SENTINEL", "46", "52", "64", "96"},
            {"TEMPEST", "控场 · CONTROL", "54", "70", "90", "62"},
            {"EMBER", "突击 · ASSAULT", "90", "64", "52", "54"}
    };

    private HeroStats() {
    }

    /** 英雄数量 */
    public static int count() {
        return AGENTS.length;
    }

    /** 修正越界的英雄下标 */
    public static int clampIndex(Integer index) {
        int i = index == null ? 0 : index;
        return (i < 0 || i >= AGENTS.length) ? 0 : i;
    }

    public static String name(Integer index) {
        return AGENTS[clampIndex(index)][0];
    }

    public static String role(Integer index) {
        return AGENTS[clampIndex(index)][1];
    }

    /** 四项属性 [火力, 机动, 控制, 防御] */
    public static int[] stats(Integer index) {
        String[] a = AGENTS[clampIndex(index)];
        return new int[]{
                Integer.parseInt(a[2]), Integer.parseInt(a[3]),
                Integer.parseInt(a[4]), Integer.parseInt(a[5])
        };
    }

    /**
     * 计算战力。
     *
     * @param agentIndex 英雄下标
     * @param level      英雄等级（1 起，无上限）
     * @param weaponCode 当前主武器（null 视作标配）
     */
    public static int power(Integer agentIndex, int level, String weaponCode) {
        return power(agentIndex, level, weaponCode, WeaponCatalog.find(weaponCode));
    }

    /**
     * 计算战力（武器数据由调用方提供，便于使用数据库里可编辑的目录）。
     *
     * @param weapon 当前主武器（null 视作无加成）
     */
    public static int power(Integer agentIndex, int level, WeaponCatalog.Weapon weapon) {
        int[] s = stats(agentIndex);
        double base = s[0] * W_FIRE + s[1] * W_MOB + s[2] * W_CTRL + s[3] * W_DEF;
        int lv = Math.max(1, level);
        double growth = 1 + GROWTH * (lv - 1);

        int weaponBonus = weapon == null ? 0 : weapon.power;

        return (int) Math.round(base * growth + weaponBonus);
    }

    /**
     * 计算战力（兼容旧调用：ignoredWeaponCode 仅为占位，实际以 weapon 为准）。
     */
    public static int power(Integer agentIndex, int level, String ignoredWeaponCode, WeaponCatalog.Weapon weapon) {
        return power(agentIndex, level, weapon);
    }
}
