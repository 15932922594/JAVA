-- ============================================================
-- 军械商店 · 武器目录（在 agent_access 库上执行）
--
-- 说明：
--   1. 表已存在时本脚本不做任何改动（IF NOT EXISTS / INSERT IGNORE）；
--   2. 后端 WeaponCatalogService 首次访问时会执行等价 DDL 并自动灌入内置目录，
--      新环境 / 新库不用手动跑本脚本；
--   3. 后台「军械」页改的就是这张表：售价 / 需求等级 / 战力 / 排序 / 上下架；
--   4. code 必须与前端 vue-login/src/data/weapons.js 的 key 一致，
--      否则商店卡片拿不到主题色 / 简介（会走兜底外观）。
--   5. 下架标记列名是 on_sale（接口对外仍输出 status）。
-- ============================================================

CREATE TABLE IF NOT EXISTS `weapon_catalog` (
    `id` bigint NOT NULL AUTO_INCREMENT COMMENT '主键',
    `code` varchar(32) NOT NULL COMMENT '武器代号：classic/sheriff/marshal/guardian/phantom/vandal/odin/operator',
    `name` varchar(32) NOT NULL DEFAULT '' COMMENT '武器中文名',
    `category` varchar(32) NOT NULL DEFAULT '步枪' COMMENT '类别：手枪/步枪/狙击枪/机枪',
    `price` int NOT NULL DEFAULT 0 COMMENT '售价（信用点，0 = 免费）',
    `req_level` int NOT NULL DEFAULT 1 COMMENT '购买所需英雄等级',
    `power` int NOT NULL DEFAULT 0 COMMENT '装备后战力加成',
    `sort` int NOT NULL DEFAULT 0 COMMENT '商店展示顺序（小的在前）',
    `on_sale` tinyint NOT NULL DEFAULT 1 COMMENT '1 上架 / 0 下架（下架后不可购买）',
    `update_time` datetime NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP COMMENT '最后修改时间',
    PRIMARY KEY (`id`) USING BTREE,
    UNIQUE KEY `uk_code` (`code`) USING BTREE
) ENGINE = InnoDB CHARACTER SET = utf8mb4 COLLATE = utf8mb4_0900_ai_ci COMMENT = '军械商店武器目录（后台可编辑价格与等级门槛）';

-- 初始目录（与 WeaponCatalog.ALL 一致，价格体系对齐无畏契约）
INSERT IGNORE INTO `weapon_catalog`
    (`code`, `name`, `category`, `price`, `req_level`, `power`, `sort`, `on_sale`)
VALUES
    ('classic',  '标配', '手枪',   0,    1,  5,  1, 1),
    ('sheriff',  '正义', '手枪',   800,  1, 15,  2, 1),
    ('marshal',  '鸟狙', '狙击枪',  950,  2, 25,  3, 1),
    ('guardian', '戍卫', '步枪',   2250, 3, 35,  4, 1),
    ('phantom',  '幻影', '步枪',   2900, 4, 45,  5, 1),
    ('vandal',   '狂徒', '步枪',   2900, 4, 45,  6, 1),
    ('odin',     '战神', '机枪',   3200, 6, 50,  7, 1),
    ('operator', '冥狙', '狙击枪',  4700, 8, 60,  8, 1);
