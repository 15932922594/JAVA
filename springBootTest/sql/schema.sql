-- AGENT ACCESS 登录系统建库建表脚本
-- 执行方式: mysql -uroot -p123456 < sql/schema.sql
CREATE DATABASE IF NOT EXISTS agent_access DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_general_ci;
USE agent_access;

CREATE TABLE IF NOT EXISTS agent_user (
  id BIGINT NOT NULL AUTO_INCREMENT COMMENT '主键',
  name VARCHAR(50) NOT NULL COMMENT '特工代号',
  email VARCHAR(100) NOT NULL COMMENT '邮箱',
  password_hash VARCHAR(128) NOT NULL COMMENT '密码摘要 SHA-256(salt::password)',
  salt VARCHAR(64) NOT NULL COMMENT '随机盐',
  agent_index INT NOT NULL DEFAULT 0 COMMENT '注册时选择的特工下标',
  create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_email (email),
  UNIQUE KEY uk_name (name)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='特工账号表';

CREATE TABLE IF NOT EXISTS agent_session (
  id BIGINT NOT NULL AUTO_INCREMENT,
  token VARCHAR(64) NOT NULL COMMENT '会话令牌',
  user_id BIGINT NOT NULL COMMENT '关联 agent_user.id',
  expires_at DATETIME NOT NULL COMMENT '过期时间',
  create_time DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_token (token),
  KEY idx_user (user_id)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='登录会话表';
