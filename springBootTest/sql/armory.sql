-- ============================================================
-- 军械商店迁移脚本（在 agent_access 库上执行）
--   1. agent_user 增加 hero_level / credits 字段
--   2. 新建 agent_weapon 已购武器表
-- ============================================================

ALTER TABLE `agent_user`
    ADD COLUMN `hero_level` int NOT NULL DEFAULT 1 COMMENT '英雄等级（注册后从 1 级开始）' AFTER `agent_index`,
    ADD COLUMN `credits` int NOT NULL DEFAULT 800 COMMENT '信用点余额（购买武器消耗）' AFTER `hero_level`,
    ADD COLUMN `exp` int NOT NULL DEFAULT 0 COMMENT '累计经验值（决定英雄等级）' AFTER `credits`,
    ADD COLUMN `last_login_date` date NULL DEFAULT NULL COMMENT '最近一次登录日期（每日登录经验去重）' AFTER `exp`;

DROP TABLE IF EXISTS `agent_weapon`;
CREATE TABLE `agent_weapon` (
    `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id` bigint NOT NULL COMMENT '关联 agent_user.id',
    `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '特工代号（冗余，便于直查）',
    `weapon_code` varchar(32) NOT NULL COMMENT '武器代号：classic/sheriff/marshal/odin/guardian/phantom/vandal/operator',
    `weapon_name` varchar(32) NOT NULL DEFAULT '' COMMENT '武器中文名（冗余，便于直查）',
    `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '购买时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE INDEX `uk_user_weapon` (`user_id`, `weapon_code`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '特工已购武器表';
