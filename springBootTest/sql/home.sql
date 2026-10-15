-- ============================================================
-- AGENT ACCESS 首页模块建表脚本（分类目录 / 档案 / 动态流）
-- 执行方式: mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/home.sql
-- 说明: 脚本可重复执行（INSERT IGNORE + 显式 id），不会重复灌数据
-- ============================================================
CREATE DATABASE IF NOT EXISTS agent_access DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE agent_access;

-- ---------- 1. 分级分类目录（两级：level=1 大类 / level=2 子类） ----------
CREATE TABLE IF NOT EXISTS archive_category (
  id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  parent_id   BIGINT       NOT NULL DEFAULT 0 COMMENT '父分类 id，0 表示一级分类',
  code        VARCHAR(40)  NOT NULL COMMENT '分类编码，如 AGENT / ASSAULT',
  name        VARCHAR(40)  NOT NULL COMMENT '分类中文名，如 特工档案',
  name_en     VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '分类英文名，如 AGENT ARCHIVE',
  level       TINYINT      NOT NULL DEFAULT 1 COMMENT '层级：1 一级分类，2 二级分类',
  sort        INT          NOT NULL DEFAULT 0 COMMENT '排序，越小越靠前',
  status      TINYINT      NOT NULL DEFAULT 1 COMMENT '1 启用，0 停用',
  create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_code (code),
  KEY idx_parent (parent_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='档案分级分类目录';

INSERT IGNORE INTO archive_category (id, parent_id, code, name, name_en, level, sort) VALUES
  (1,  0, 'AGENT',   '特工档案', 'AGENT ARCHIVE',   1, 10),
  (2,  0, 'GEAR',    '装备库',   'ARSENAL',         1, 20),
  (3,  0, 'MISSION', '作战任务', 'OPERATIONS',      1, 30),
  -- 特工档案 · 二级（定位）
  (11, 1, 'ASSAULT',  '突击', 'ASSAULT',  2, 11),
  (12, 1, 'CONTROL',  '控场', 'CONTROL',  2, 12),
  (13, 1, 'RECON',    '侦察', 'RECON',    2, 13),
  (14, 1, 'SENTINEL', '守护', 'SENTINEL', 2, 14),
  -- 装备库 · 二级（枪型）
  (21, 2, 'RIFLE',    '步枪',   'RIFLE',   2, 21),
  (22, 2, 'SMG',      '冲锋枪', 'SMG',     2, 22),
  (23, 2, 'SNIPER',   '狙击枪', 'SNIPER',  2, 23),
  (24, 2, 'SIDEARM',  '手枪',   'SIDEARM', 2, 24),
  -- 作战任务 · 二级（模式）
  (31, 3, 'TRAINING', '训练场',   'TRAINING', 2, 31),
  (32, 3, 'RANKED',   '竞技模式', 'RANKED',   2, 32),
  (33, 3, 'EVENT',    '限时行动', 'EVENT',    2, 33);

-- ---------- 2. 档案主表（首页展示 + 搜索主体） ----------
CREATE TABLE IF NOT EXISTS agent_archive (
  id             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  category_code  VARCHAR(40)  NOT NULL COMMENT '一级分类编码（archive_category.code）',
  sub_code       VARCHAR(40)  NOT NULL DEFAULT '' COMMENT '二级分类编码（定位 / 枪型 / 模式）',
  tier           VARCHAR(8)   NOT NULL DEFAULT 'B' COMMENT '分级：S / A / B',
  code           VARCHAR(64)  NOT NULL COMMENT '档案代号（英文，唯一），如 vector',
  name           VARCHAR(64)  NOT NULL COMMENT '档案名称（展示用大写），如 VECTOR',
  mono           VARCHAR(8)   NOT NULL DEFAULT '' COMMENT '单字符缩写，卡片水印用',
  color          VARCHAR(16)  NOT NULL DEFAULT '#FF4655' COMMENT '主题色，卡片主色',
  bio            VARCHAR(255) NOT NULL DEFAULT '' COMMENT '简介，参与关键词匹配',
  img            VARCHAR(255) NOT NULL DEFAULT '' COMMENT '立绘地址，可为空（前端回退为 mono 徽标）',
  firepower      INT          NOT NULL DEFAULT 0 COMMENT '火力',
  mobility       INT          NOT NULL DEFAULT 0 COMMENT '机动',
  control        INT          NOT NULL DEFAULT 0 COMMENT '控制',
  defense        INT          NOT NULL DEFAULT 0 COMMENT '防御',
  heat           INT          NOT NULL DEFAULT 0 COMMENT '热度，用于首页精选与排序',
  featured       TINYINT      NOT NULL DEFAULT 0 COMMENT '1 首页精选',
  sort           INT          NOT NULL DEFAULT 0 COMMENT '排序，越小越靠前',
  status         TINYINT      NOT NULL DEFAULT 1 COMMENT '1 启用，0 下线',
  create_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_code (code),
  KEY idx_cat (category_code),
  KEY idx_sub (sub_code),
  KEY idx_tier (tier),
  KEY idx_heat (heat)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='首页档案主表（特工/装备/任务）';

-- 特工档案（与前端 public/agents/*.png 对应）
INSERT IGNORE INTO agent_archive
  (code, name, mono, category_code, sub_code, tier, color, bio, img, firepower, mobility, control, defense, heat, featured, sort) VALUES
  ('vector',   'VECTOR',   'V', 'AGENT', 'ASSAULT',  'S', '#FF4655', '以极高机动性撕裂防线的突进型特工，擅长在瞬间改写交火态势。', '/agents/vector.png',   92, 76, 44, 38, 98, 1, 10),
  ('arclight', 'ARCLIGHT', 'A', 'AGENT', 'RECON',    'A', '#00E0C6', '用电弧脉冲扫描战场，为队伍点亮迷雾中的每一个目标。',       '/agents/arclight.png', 58, 86, 72, 46, 91, 1, 11),
  ('phantom',  'PHANTOM',  'P', 'AGENT', 'CONTROL',  'S', '#A66CFF', '制造幻象与烟幕，掌控每一次交火的节奏与视野。',             '/agents/phantom.png',  52, 74, 93, 50, 95, 1, 12),
  ('onyx',     'ONYX',     'O', 'AGENT', 'SENTINEL', 'A', '#FFB443', '以坚固壁垒庇护队友，是阵地攻防中不可撼动的支点。',         '/agents/onyx.png',     46, 52, 64, 96, 88, 1, 13),
  ('tempest',  'TEMPEST',  'T', 'AGENT', 'CONTROL',  'A', '#4DA6FF', '召唤风暴封锁通路，让敌人在自己的领地寸步难行。',           '/agents/tempest.png',  54, 70, 90, 62, 84, 0, 14),
  ('ember',    'EMBER',    'E', 'AGENT', 'ASSAULT',  'B', '#FF6B4A', '以烈焰灼烧前线的爆发型特工，高风险，也高回报。',           '/agents/ember.png',    90, 64, 52, 54, 79, 0, 15),
-- 装备库
  ('vandal',   'VANDAL',   'V', 'GEAR',  'RIFLE',    'S', '#FF4655', '高伤害全自动步枪，远距离头部一枪致命，正面交火的标杆。',   '/agents/vandal.png', 88, 52, 40, 30, 96, 1, 20),
  ('phantom-w','PHANTOM-W','P', 'GEAR',  'RIFLE',    'A', '#A66CFF', '消音步枪，后坐可控，适合中距离压制与隐蔽推进。',           '/agents/phantom-w.png', 76, 66, 52, 34, 90, 0, 21),
  ('spectre',  'SPECTRE',  'S', 'GEAR',  'SMG',      'A', '#00E0C6', '高射速冲锋枪，近距离泼洒压制，经济局的性价比之选。',       '/agents/spectre.png', 70, 74, 44, 28, 82, 0, 22),
  ('operator', 'OPERATOR', 'O', 'GEAR',  'SNIPER',   'S', '#FFB443', '一击必杀的重型狙击枪，架点封锁整条通路的终极答案。',       '/agents/operator.png', 99, 30, 36, 44, 93, 1, 23),
  ('marshal',  'MARSHAL',  'M', 'GEAR',  'SNIPER',   'B', '#4DA6FF', '轻型狙击枪，机动性更好，命中躯干即可终结交火。',           '/agents/marshal.png', 82, 58, 40, 36, 71, 0, 24),
  ('classic',  'CLASSIC',  'C', 'GEAR',  'SIDEARM',  'B', '#FF6B4A', '开局标配手枪，右键三连发在贴脸距离拥有惊喜爆发。',         '/agents/classic.png', 54, 60, 32, 26, 68, 0, 25),
  ('sheriff',  'SHERIFF',  'H', 'GEAR',  'SIDEARM',  'A', '#FF4655', '高伤害左轮，一发入魂，是翻盘局最廉价的希望。',            '/agents/sheriff.png', 86, 50, 34, 30, 87, 0, 26),
  ('odin',     'ODIN',     'D', 'GEAR',  'RIFLE',    'A', '#00E0C6', '弹链供弹的重机枪，穿墙压制能力冠绝全场。',                 '/agents/odin.png', 94, 24, 58, 48, 80, 0, 27),
-- 作战任务
  ('ascent',   'ASCENT',   'A', 'MISSION','RANKED',   'A', '#4DA6FF', '双点位地图，中路可开闭的闸门决定了整局的攻防节奏。',      '', 62, 70, 66, 58, 92, 1, 30),
  ('bind',     'BIND',     'B', 'MISSION','RANKED',   'S', '#A66CFF', '无中路的双点图，两处单向传送门让绕后变得随心所欲。',      '', 66, 78, 70, 54, 90, 0, 31),
  ('haven',    'HAVEN',    'H', 'MISSION','RANKED',   'A', '#FFB443', '罕见的三点位地图，战线被拉长，信息收集比枪法更重要。',    '', 60, 64, 74, 62, 86, 0, 32),
  ('range',    'RANGE',    'R', 'MISSION','TRAINING', 'B', '#3DDC97', '训练场，靶机与 bots 全开放，压枪与急停的日常修行地。',    '', 30, 40, 20, 20, 74, 0, 33),
  ('nightfall','NIGHTFALL','N', 'MISSION','EVENT',    'S', '#FF4655', '限时行动：夜幕下的据点争夺，视野受限，投掷物价值翻倍。',  '', 78, 72, 80, 60, 89, 1, 34),
  ('breakout', 'BREAKOUT', 'K', 'MISSION','EVENT',    'B', '#FF6B4A', '限时行动：护送与突围交替，节奏快到没有喘息窗口。',        '', 74, 80, 56, 46, 70, 0, 35);

-- ---------- 3. 首页动态流 ----------
CREATE TABLE IF NOT EXISTS home_feed (
  id            BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  kind          VARCHAR(24)  NOT NULL DEFAULT 'NEWS' COMMENT '类型：NEWS 情报 / PATCH 版本 / MISSION 任务',
  title         VARCHAR(120) NOT NULL COMMENT '标题',
  summary       VARCHAR(255) NOT NULL DEFAULT '' COMMENT '摘要',
  category_code VARCHAR(40)  NOT NULL DEFAULT '' COMMENT '关联一级分类，可为空',
  tag           VARCHAR(24)  NOT NULL DEFAULT '' COMMENT '角标文案',
  published_at  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP COMMENT '发布时间',
  heat          INT          NOT NULL DEFAULT 0 COMMENT '热度，越大越靠前',
  status        TINYINT      NOT NULL DEFAULT 1 COMMENT '1 启用，0 下线',
  create_time   DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_kind (kind),
  KEY idx_pub (published_at)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='首页动态流';

INSERT IGNORE INTO home_feed
  (id, kind, title, summary, category_code, tag, published_at, heat) VALUES
  (1, 'PATCH',   'v8.11 平衡性调整',     '步枪后坐曲线回调，控场类技能冷却小幅上调，竞技环境重新洗牌。',         'GEAR',    'HOT',     '2026-10-14 09:00:00', 100),
  (2, 'MISSION', '限时行动 · NIGHTFALL', '夜幕据点争夺开放至本月末，完成 5 场可解锁专属喷漆。',                   'MISSION', 'NEW',     '2026-10-13 18:30:00', 96),
  (3, 'NEWS',    '竞技赛季结算提醒',     '本赛季将于 10 月 31 日 23:59 结算，请确认你的段位奖励领取状态。',       'MISSION', 'NOTICE',  '2026-10-12 12:00:00', 88),
  (4, 'NEWS',    '档案库完成数字化',     '全部特工、装备与任务档案已入库，现支持分级分类检索。',                   'AGENT',   'SYSTEM',  '2026-10-11 10:15:00', 84),
  (5, 'PATCH',   '反作弊模块升级',       '新增行为特征检测，异常对局的判定速度与准确率均有提升。',                 '',        'SYSTEM',  '2026-10-10 15:40:00', 76),
  (6, 'MISSION', '训练场靶机刷新',       'RANGE 新增移动靶与跳靶，压枪与急停练习更贴近实战。',                     'MISSION', 'UPDATE',  '2026-10-09 11:20:00', 70),
  (7, 'NEWS',    '周末双倍经验',         '本周五 18:00 至周日 24:00，全部模式经验加成 100%。',                     'MISSION', 'EVENT',   '2026-10-08 09:00:00', 66),
  (8, 'PATCH',   '装备库数据校准',       '依据近 30 天实战数据重新校准了各枪械的火力与机动评分。',                 'GEAR',    'UPDATE',  '2026-10-07 16:00:00', 60);
