-- ============================================================
-- 后台管理模块建表脚本（管理员账号 / 操作日志）
-- 执行方式:
--   mysql -uroot -p123456 --default-character-set=utf8mb4 -D agent_access < sql/admin.sql
--
-- 默认管理员（脚本可重复执行，已存在则跳过）:
--   账号: admin
--   密码: admin123   （sha256(salt::pass)，与 PasswordUtil 算法一致）
--   首次登录后请立即在后台修改密码！
-- ============================================================
USE agent_access;

-- ---------- 1. 管理员账号（与前台 agent_user 完全隔离） ----------
CREATE TABLE IF NOT EXISTS admin_user (
  id               BIGINT      NOT NULL AUTO_INCREMENT COMMENT '主键',
  username         VARCHAR(40) NOT NULL COMMENT '登录账号（唯一）',
  display_name     VARCHAR(40) NOT NULL DEFAULT '' COMMENT '显示名',
  password_hash    VARCHAR(128) NOT NULL COMMENT 'sha256(salt::password) hex',
  salt             VARCHAR(64) NOT NULL COMMENT '16 字节随机盐（32 位 hex）',
  token            VARCHAR(64) NULL COMMENT '当前会话 token（单会话，重登覆盖）',
  token_expires_at DATETIME    NULL COMMENT 'token 过期时间',
  status           TINYINT     NOT NULL DEFAULT 1 COMMENT '1 启用，0 停用',
  create_time      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP,
  update_time      DATETIME    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  UNIQUE KEY uk_username (username)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台管理员';

INSERT IGNORE INTO admin_user (id, username, display_name, password_hash, salt) VALUES
  (1, 'admin', '超级管理员',
   'b0b168d92e122cca122586f50d2e1d05af219d8eed3d79945d51cabef6de5bd3',
   '5f8a9b3c1d2e4f60718293a4b5c6d7e8');

-- ---------- 2. 操作日志 ----------
CREATE TABLE IF NOT EXISTS admin_log (
  id          BIGINT       NOT NULL AUTO_INCREMENT COMMENT '主键',
  admin_id    BIGINT       NOT NULL DEFAULT 0 COMMENT '操作人 id',
  admin_name  VARCHAR(40)  NOT NULL DEFAULT '' COMMENT '操作人账号',
  target      VARCHAR(24)  NOT NULL DEFAULT '' COMMENT '对象：archive/category/feed/mission/admin',
  action      VARCHAR(24)  NOT NULL DEFAULT '' COMMENT '动作：CREATE/UPDATE/DELETE/LOGIN/PASSWORD',
  detail      VARCHAR(255) NOT NULL DEFAULT '' COMMENT '摘要说明',
  create_time DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY idx_admin (admin_id),
  KEY idx_time (create_time)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COMMENT='后台操作日志';
