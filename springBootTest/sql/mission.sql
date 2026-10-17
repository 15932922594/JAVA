-- ============================================================
-- AGENT ACCESS 作战任务模块建表脚本
-- 执行方式: mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/mission.sql
-- 说明: 脚本可重复执行（ON DUPLICATE KEY UPDATE），不会产生重复数据
--   mission_brief     任务简报（简报 / 目标清单 / 奖励 / 时限）
--   mission_progress  特工任务进度（接取 / 目标勾选 / 结算）
-- 任务本体（名称、分类、分级、故事）仍然存在 agent_archive 里，
-- 通过 mission_code = agent_archive.code 关联。
-- ============================================================
CREATE DATABASE IF NOT EXISTS agent_access DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE agent_access;

-- ---------- 1. 任务简报 ----------
CREATE TABLE IF NOT EXISTS mission_brief (
  id             BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  mission_code   VARCHAR(64)  NOT NULL COMMENT '任务代号，关联 agent_archive.code',
  briefing       VARCHAR(500) NOT NULL DEFAULT '' COMMENT '任务简报',
  objectives     TEXT         NOT NULL COMMENT '目标清单（JSON 字符串数组）',
  reward         INT          NOT NULL DEFAULT 0 COMMENT '结算积分',
  duration_min   INT          NOT NULL DEFAULT 30 COMMENT '任务时限（分钟）',
  region         VARCHAR(64)  NOT NULL DEFAULT '' COMMENT '作战区域',
  squad          VARCHAR(16)  NOT NULL DEFAULT '5V5' COMMENT '编队规模',
  status         TINYINT      NOT NULL DEFAULT 1 COMMENT '1 上线 / 0 下线',
  create_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time    DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_mission_code (mission_code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='作战任务简报';

-- ---------- 2. 特工任务进度 ----------
CREATE TABLE IF NOT EXISTS mission_progress (
  id              BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  user_id         BIGINT      NOT NULL COMMENT '关联 agent_user.id',
  mission_code    VARCHAR(64) NOT NULL COMMENT '任务代号',
  status          TINYINT     NOT NULL DEFAULT 1 COMMENT '1 进行中 / 2 待结算 / 3 已结算',
  done_objectives VARCHAR(255) NOT NULL DEFAULT '[]' COMMENT '已完成目标下标（JSON 数组）',
  started_at      DATETIME    NOT NULL COMMENT '接取时间',
  deadline        DATETIME    NOT NULL COMMENT '限时截止',
  finished_at     DATETIME    DEFAULT NULL COMMENT '结算时间',
  update_time     DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_user_mission (user_id, mission_code),
  KEY idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='特工任务进度';

-- ---------- 3. 任务简报数据（与 agent_archive 中的 MISSION 档案一一对应） ----------
INSERT INTO mission_brief (mission_code, briefing, objectives, reward, duration_min, region, squad)
VALUES
('ascent',
 '双点位地图，中路可开闭的闸门决定了整局的攻防节奏。情报显示敌方在 B 点布置了交叉火力，建议先控中路再分兵施压。',
 '["占领 A 点区域","控制中路可开闭闸门","完成 3 次有效击杀","安放尖刺并成功引爆"]',
 120, 40, '威尼斯 · VENICE', '5V5'),
('bind',
 '无中路的双点图，两处单向传送门让绕后变得随心所欲。切断传送门视野是拿下本局的关键。',
 '["封锁 A 点传送门视野","占领并守住 B 点","完成 2 次绕后击杀","安放尖刺并成功引爆"]',
 180, 45, '摩洛哥 · MOROCCO', '5V5'),
('haven',
 '罕见的三点位地图，战线被拉长，信息收集比枪法更重要。任何一处失守都会让轮转陷入被动。',
 '["完成开局信息侦察","守住被指定的点位","完成 4 次有效击杀","拿下本局胜利"]',
 150, 50, '不丹 · BHUTAN', '5V5'),
('range',
 '训练场，靶机与 bots 全开放，压枪与急停的日常修行地。所有训练项目均不计入战绩。',
 '["靶机命中 30 次","完成压枪练习 3 组","急停射击达标 2 次"]',
 40, 20, '训练设施 · RANGE', '单人'),
('nightfall',
 '限时行动：夜幕下的据点争夺，视野受限，投掷物价值翻倍。行动窗口仅在三十分钟内有效。',
 '["在夜视受限状态下进入据点","用投掷物完成 2 次击杀","坚持到行动结束"]',
 220, 30, '夜幕据点 · NIGHTFALL', '5V5'),
('breakout',
 '限时行动：护送与突围交替，节奏快到没有喘息窗口。护送目标一旦停滞，敌方增援会在 20 秒内抵达。',
 '["完成一轮护送","完成一次突围","队伍存活至撤离点"]',
 90, 25, '突围通道 · BREAKOUT', '5V5')
ON DUPLICATE KEY UPDATE
  briefing = VALUES(briefing),
  objectives = VALUES(objectives),
  reward = VALUES(reward),
  duration_min = VALUES(duration_min),
  region = VALUES(region),
  squad = VALUES(squad);
