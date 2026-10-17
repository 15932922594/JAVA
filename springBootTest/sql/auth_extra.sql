-- ============================================================
-- AGENT ACCESS 找回密码 + RIOT 第三方登录 建表脚本
-- 执行方式: mysql -uroot -p123456 --default-character-set=utf8mb4 < sql/auth_extra.sql
-- 说明: 可重复执行（CREATE TABLE IF NOT EXISTS）
-- ============================================================
CREATE DATABASE IF NOT EXISTS agent_access DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE agent_access;

-- ---------- 1. 找回密码验证码 ----------
CREATE TABLE IF NOT EXISTS agent_reset_code (
  id          BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  email       VARCHAR(100) NOT NULL COMMENT '接收验证码的邮箱',
  code        VARCHAR(12) NOT NULL COMMENT '6 位验证码',
  expires_at  DATETIME    NOT NULL COMMENT '过期时间（10 分钟）',
  used        TINYINT     NOT NULL DEFAULT 0 COMMENT '是否已使用',
  create_time DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_email_code (email, code)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='找回密码验证码';

-- ---------- 2. 第三方账号绑定 / 授权票据 ----------
-- 一条记录同时承担两个角色：
--   ticket 阶段：user_id 为空，ticket 有值，代表「Riot 已授权、尚未绑定本站账号」
--   绑定完成后：user_id 有值，ticket 置空，代表「该 Riot 账号已绑定某特工」
CREATE TABLE IF NOT EXISTS agent_oauth (
  id               BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  provider         VARCHAR(24) NOT NULL DEFAULT 'RIOT' COMMENT '第三方来源',
  provider_uid     VARCHAR(64) NOT NULL COMMENT '第三方的唯一用户 id',
  riot_id          VARCHAR(64) NOT NULL COMMENT '展示用的 Riot ID，如 JETT#CN1',
  user_id          BIGINT      DEFAULT NULL COMMENT '绑定的 agent_user.id，NULL 表示未绑定',
  ticket           VARCHAR(48) DEFAULT NULL COMMENT '一次性授权票据',
  ticket_expires_at DATETIME   DEFAULT NULL COMMENT '票据过期时间（10 分钟）',
  create_time      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_provider_uid (provider, provider_uid),
  UNIQUE KEY uk_ticket (ticket),
  KEY idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='第三方账号绑定与授权票据';
