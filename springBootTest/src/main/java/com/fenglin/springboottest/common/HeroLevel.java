package com.fenglin.springboottest.common;

/**
 * 英雄等级公式（前后端共用同一套数值，前端只做展示计算）。
 *
 * <b>等级不设上限</b>：只要经验够就会一直升。
 *
 * 升级所需经验：第 N 级 → N+1 级需要 100 + 50×(N-1)
 *   Lv1→2: 100 · Lv2→3: 150 · Lv3→4: 200 · Lv4→5: 250 ...
 * 累计经验：Lv1 起 0 经验，升到 L 级需要累加前 L-1 段，闭式解为
 *   totalExpToReach(L) = 100·(L-1) + 25·(L-1)·(L-2)
 *
 * 升级奖励：每升一级到账 100 + 50×等级 信用点（同样不封顶）。
 *
 * 上限说明：经验存在 agent_user.exp（INT），因此实际可达到的最高等级约 9160 级
 * （2^31 经验 ≈ 25k²，k≈9165）。等级本身没有人为限制。
 */
public final class HeroLevel {

    /* ================= 经验来源 ================= */
    /** 训练场：得分 ÷ 20，单局上限 100 EXP */
    public static final int EXP_PER_SCORE = 20;
    public static final int TRAINING_EXP_MAX = 100;
    /** 完成作战任务结算 +50 EXP */
    public static final int MISSION_EXP = 50;
    /** 每日首次登录 +20 EXP */
    public static final int DAILY_LOGIN_EXP = 20;

    private HeroLevel() {
    }

    /** 当前等级升到下一级需要多少经验（无上限，等级越高需求越多） */
    public static int expForNext(int level) {
        int lv = Math.max(1, level);
        return 100 + 50 * (lv - 1);
    }

    /**
     * 到达 idx 级所需的累计经验（idx=1 → 0）。
     * 闭式解：100k + 25k(k-1)，k = idx - 1；用 long 防止高等级溢出。
     */
    public static long totalExpToReach(long idx) {
        long k = Math.max(0, idx - 1);
        return 100 * k + 25 * k * (k - 1);
    }

    /**
     * 由累计经验推算等级（<b>不封顶</b>）。
     *
     * 解 25k² + 75k = exp 得 k = (√(5625 + 100·exp) - 75) / 50，
     * 等级 = k + 1。浮点开方后做两次整数校正，保证与 totalExpToReach 完全一致。
     */
    public static int levelOf(int totalExp) {
        long exp = Math.max(0, totalExp);
        int k = (int) Math.floor((Math.sqrt(5625.0 + 100.0 * exp) - 75.0) / 50.0);
        if (k < 0) {
            k = 0;
        }
        // 浮点误差校正：先退到底，再逐级进
        while (k > 0 && totalExpToReach(k + 1L) > exp) {
            k--;
        }
        while (totalExpToReach(k + 2L) <= exp) {
            k++;
        }
        return k + 1;
    }

    /** 当前等级内已积累的经验（用于进度条） */
    public static int expInLevel(int totalExp) {
        long exp = Math.max(0, totalExp);
        long base = totalExpToReach(levelOf(totalExp));
        return (int) Math.max(0, exp - base);
    }

    /** 升到某级的奖励信用点（等级越高给得越多，不封顶） */
    public static int levelUpReward(int level) {
        return 100 + 50 * Math.max(1, level);
    }

    /** 解锁新头像框那一级的额外奖励信用点 */
    public static final int FRAME_BONUS = 300;

    /** 训练得分换算经验（单局上限 100） */
    public static int expFromScore(int score) {
        return Math.max(0, Math.min(TRAINING_EXP_MAX, Math.max(0, score) / EXP_PER_SCORE));
    }

    /* ================= 头像框 / 配色解锁 ================= */
    /**
     * 头像框阶梯：
     *   固定 11 档（Lv1~50）：新兵 银翼 特工 黄金 猩红 青碧 紫晶 熔岩 星辉 虚空 不朽
     *   之后每 10 级一枚「星穹」系列（星穹·壹 / 贰 / 叁 …），颜色由档位序号生成，永无止境。
     * 已解锁的边框可在图鉴里自主任意佩戴（agent_user.equipped_frame，0 = 跟随最新解锁）。
     * 前端 `src/styles/frames.css` 里 .frame-1…frame-11 为固定档样式，
     * 星穹系列用 .fp + 内联颜色变量（--fp/--fr）渲染。
     */
    private static final int[] FRAME_LEVELS = {1, 3, 5, 8, 12, 16, 20, 25, 30, 40, 50};
    private static final String[] FRAME_NAMES = {
            "新兵", "银翼", "特工", "黄金", "猩红", "青碧", "紫晶", "熔岩", "星辉", "虚空", "不朽"
    };
    private static final String[] FRAME_EN = {
            "RECRUIT", "SILVER", "AGENT", "GOLD", "CRIMSON", "TEAL",
            "AMETHYST", "MAGMA", "STELLAR", "VOID", "IMMORTAL"
    };

    /** 固定档数量 / 固定档最高等级 / 星穹系列的间隔等级 */
    public static final int FIXED_FRAME_COUNT = FRAME_LEVELS.length;
    public static final int FIXED_FRAME_MAX_LEVEL = FRAME_LEVELS[FIXED_FRAME_COUNT - 1];
    public static final int PROC_FRAME_STEP = 10;

    private static final String[] CN_NUM = {
            "壹", "贰", "叁", "肆", "伍", "陆", "柒", "捌", "玖", "拾"
    };

    /** 头像框总档数（跟随等级，无上限） */
    public static int frameCount(int level) {
        return frameTier(level);
    }

    /** 第 tier 档（1 起）需要的等级 */
    public static int frameLevel(int tier) {
        if (tier <= FIXED_FRAME_COUNT) {
            return FRAME_LEVELS[Math.max(0, tier - 1)];
        }
        return FIXED_FRAME_MAX_LEVEL + (tier - FIXED_FRAME_COUNT) * PROC_FRAME_STEP;
    }

    /** 当前等级对应的头像框档位（无上限） */
    public static int frameTier(int level) {
        if (level < 60) {
            int tier = 1;
            for (int i = 0; i < FRAME_LEVELS.length; i++) {
                if (level >= FRAME_LEVELS[i]) {
                    tier = i + 1;
                }
            }
            return tier;
        }
        // Lv.51~59 仍是不朽；Lv.60 起每 10 级一枚星穹
        return FIXED_FRAME_COUNT + (level - FIXED_FRAME_MAX_LEVEL) / PROC_FRAME_STEP;
    }

    /** 档位 → 中文名（含星穹系列） */
    public static String frameNameOfTier(int tier) {
        if (tier <= FIXED_FRAME_COUNT) {
            return FRAME_NAMES[Math.max(0, tier - 1)];
        }
        return "星穹·" + cnNum(tier - FIXED_FRAME_COUNT);
    }

    /** 档位 → 英文名 */
    public static String frameEnOfTier(int tier) {
        if (tier <= FIXED_FRAME_COUNT) {
            return FRAME_EN[Math.max(0, tier - 1)];
        }
        return "ASTRAL " + (tier - FIXED_FRAME_COUNT);
    }

    /** 等级 → 当前可佩戴的最高档 */
    public static int frameMaxTier(int level) {
        return frameTier(level);
    }

    /** 等级 → 应显示的边框档位（考虑玩家自选佩戴；0 = 跟随最新） */
    public static int shownFrameTier(int level, Integer equippedFrame) {
        int max = frameMaxTier(level);
        int eq = equippedFrame == null ? 0 : equippedFrame;
        return (eq >= 1 && eq <= max) ? eq : max;
    }

    /** 该佩戴档位是否合法（0 跟随最新，或 1~当前最高档） */
    public static boolean isValidFrameTier(int level, int tier) {
        return tier == 0 || (tier >= 1 && tier <= frameMaxTier(level));
    }

    /** 当前等级的边框中文名（按佩戴档位） */
    public static String frameName(int level, Integer equippedFrame) {
        return frameNameOfTier(shownFrameTier(level, equippedFrame));
    }

    /** 当前等级的边框英文名（按佩戴档位） */
    public static String frameEn(int level, Integer equippedFrame) {
        return frameEnOfTier(shownFrameTier(level, equippedFrame));
    }

    /** 下一档边框所需等级（星穹系列无限延伸，永远有下一档） */
    public static int nextFrameLevel(int level) {
        return frameLevel(frameMaxTier(level) + 1);
    }

    /** 下一档边框名称 */
    public static String nextFrameName(int level) {
        return frameNameOfTier(frameMaxTier(level) + 1);
    }

    /** 该等级是否是「解锁了新边框」的里程碑等级（升级时额外发奖励） */
    public static boolean isFrameMilestone(int level) {
        return level > 1 && frameTier(level) > frameTier(level - 1);
    }

    /** 中文序号（1~99）：星穹·壹 / 贰 … 拾 / 拾壹 … */
    private static String cnNum(int n) {
        if (n <= 0) {
            return CN_NUM[0];
        }
        if (n <= 10) {
            return CN_NUM[n - 1];
        }
        int tens = n / 10;
        int ones = n % 10;
        StringBuilder sb = new StringBuilder();
        if (tens > 1) {
            sb.append(CN_NUM[tens - 1]);
        }
        sb.append("拾");
        if (ones > 0) {
            sb.append(CN_NUM[ones - 1]);
        }
        return sb.toString();
    }
}
