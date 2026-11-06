-- ============================================================
-- 社交 / 竞技迁移脚本（agent_access 库）
--   1. agent_user 增加主武器、PK 胜负字段
--   2. 新建 agent_friend 好友关系表
--   3. 新建 agent_pk PK 战绩表
-- ============================================================

ALTER TABLE `agent_user`
    ADD COLUMN `equipped_weapon` varchar(32) NOT NULL DEFAULT 'classic' COMMENT '当前主武器 code（影响战力）' AFTER `exp`,
    ADD COLUMN `pk_win` int NOT NULL DEFAULT 0 COMMENT 'PK 胜场' AFTER `equipped_weapon`,
    ADD COLUMN `pk_lose` int NOT NULL DEFAULT 0 COMMENT 'PK 负场' AFTER `pk_win`;

DROP TABLE IF EXISTS `agent_friend`;
CREATE TABLE `agent_friend` (
    `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
    `user_id` bigint NOT NULL COMMENT '发起方 agent_user.id',
    `user_name` varchar(50) NOT NULL DEFAULT '' COMMENT '发起方代号（冗余展示）',
    `friend_id` bigint NOT NULL COMMENT '对方 agent_user.id',
    `friend_name` varchar(50) NOT NULL DEFAULT '' COMMENT '对方案号（冗余展示）',
    `status` varchar(16) NOT NULL DEFAULT 'PENDING' COMMENT 'PENDING 待同意 / ACCEPTED 已是好友',
    `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发起时间',
    `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '处理时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE INDEX `uk_pair` (`user_id`, `friend_id`) USING BTREE,
    INDEX `idx_friend` (`friend_id`, `status`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '好友关系表';

DROP TABLE IF EXISTS `agent_pk`;
CREATE TABLE `agent_pk` (
    `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
    `challenger_id` bigint NOT NULL COMMENT '挑战方',
    `challenger_name` varchar(50) NOT NULL DEFAULT '',
    `defender_id` bigint NOT NULL COMMENT '应战方',
    `defender_name` varchar(50) NOT NULL DEFAULT '',
    `challenger_power` int NOT NULL DEFAULT 0 COMMENT '挑战方战力',
    `defender_power` int NOT NULL DEFAULT 0 COMMENT '应战方战力',
    `winner_id` bigint NULL DEFAULT NULL COMMENT '胜者 id',
    `detail` varchar(200) NOT NULL DEFAULT '' COMMENT '结算描述',
    `create_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP,
    PRIMARY KEY (`id`) USING BTREE,
    INDEX `idx_challenger` (`challenger_id`) USING BTREE,
    INDEX `idx_defender` (`defender_id`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = 'PK 战绩表';
