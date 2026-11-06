-- ============================================================
-- 英雄等级取消 20 级上限（无上限成长）
-- ------------------------------------------------------------
-- 代码侧：
--   HeroLevel 删除 MAX_LEVEL / isMax，等级由 exp 用闭式解推导：
--     totalExpToReach(L) = 100(L-1) + 25(L-1)(L-2)
--     expForNext(L)      = 100 + 50(L-1)
--   HeroLevelService 不再截断经验与等级；HeroStats 的等级系数也不再封顶。
--
-- 数据库侧：
--   exp / hero_level 本就是 INT，无需改类型即可支持到约 9160 级
--   （2^31 经验 ≈ 25k² → k≈9165）。此处仅修正字段注释，
--   把「满级」语义去掉，并修复此前被 GBK 客户端写坏的乱码注释。
-- ============================================================

ALTER TABLE `agent_user`
  MODIFY COLUMN `hero_level` int NOT NULL DEFAULT 1
    COMMENT '英雄等级（由 exp 推导，无上限）',
  MODIFY COLUMN `credits` int NOT NULL DEFAULT 800
    COMMENT '信用点余额（购买武器消耗）',
  MODIFY COLUMN `exp` int NOT NULL DEFAULT 0
    COMMENT '累计经验值（决定英雄等级，无上限）';

-- 校验：等级由经验推导，库里 hero_level 只是缓存，可用下面的语句复核是否一致
-- SELECT id, name, hero_level, exp FROM agent_user ORDER BY exp DESC;
