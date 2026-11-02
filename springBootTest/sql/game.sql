-- ============================================================
-- AGENT ACCESS RANGE 训练场模块建表脚本
-- 执行方式: mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/game.sql
-- 说明: 可重复执行（CREATE TABLE IF NOT EXISTS）
--   game_record 记录每次训练成绩（靶场 / 压枪 / 反应），
--   累计成绩用于自动完成作战任务的目标（如「靶机命中 30 次」）。
-- ============================================================
CREATE DATABASE IF NOT EXISTS agent_access DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE agent_access;

CREATE TABLE IF NOT EXISTS game_record (
  id          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  user_id     BIGINT      NOT NULL COMMENT '关联 agent_user.id',
  mode        VARCHAR(16) NOT NULL COMMENT '训练模式：TARGET 靶场 / RECOIL 压枪 / REACTION 反应',
  score       INT         NOT NULL DEFAULT 0 COMMENT '本局得分',
  units       INT         NOT NULL DEFAULT 0 COMMENT '本局有效单位数（命中数 / 完成组数 / 达标次数）',
  shots       INT         NOT NULL DEFAULT 0 COMMENT '本局总射击次数',
  hits        INT         NOT NULL DEFAULT 0 COMMENT '本局命中次数',
  avg_ms      INT         NOT NULL DEFAULT 0 COMMENT '本局平均反应毫秒数',
  create_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_user_mode (user_id, mode),
  KEY idx_user_time (user_id, create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='RANGE 训练场成绩';
