-- ============================================================
-- 用户权限字段 + 密码改明文（增量迁移脚本，已建库的执行这一份即可）
-- 执行方式:
--   mysql -uroot -p123456 --default-character-set=utf8mb4 -D agent_access < sql/permission.sql
--
-- 权限约定:
--   permission = 1  默认权限（注册用户默认）→ 首页看不到「后台管理」按钮，也登录不了后台
--   permission = 0  管理员权限          → 首页显示「后台管理」按钮，可用本人账号登录后台
-- ============================================================
USE agent_access;

-- ---------- 1. 新增权限字段 ----------
ALTER TABLE agent_user
  ADD COLUMN permission TINYINT NOT NULL DEFAULT 1
  COMMENT '权限：1 默认权限，0 管理员权限' AFTER agent_index;

-- ---------- 2. 新增明文密码列 ----------
ALTER TABLE agent_user
  ADD COLUMN password VARCHAR(64) NULL
  COMMENT '登录密码（明文，不做加密）' AFTER email;

-- ---------- 3. 旧摘要列改为可空 ----------
-- 新账号不再写入 password_hash / salt，放宽为 NULL 否则插入会报错。
-- 历史账号的明文列为空，登录时自动回退到旧摘要校验，老账号不会立刻登不上；
-- 一旦改密码 / 找回密码，就自动转成明文存储。
ALTER TABLE agent_user
  MODIFY password_hash VARCHAR(128) NULL COMMENT '（已废弃）旧版密码摘要',
  MODIFY salt VARCHAR(64) NULL COMMENT '（已废弃）旧版随机盐';

-- ---------- 4. 可选：直接建一个管理员账号（密码明文） ----------
-- INSERT INTO agent_user (name, email, password, permission, agent_index)
-- VALUES ('ADMIN', 'admin@agent.io', 'admin123', 0, 0);

-- ---------- 5. 授予管理员权限（按需放开注释，把邮箱换成你自己的账号） ----------
-- UPDATE agent_user SET permission = 0 WHERE email = 'you@example.com';
-- 也可以只按代号授权:
-- UPDATE agent_user SET permission = 0 WHERE name = '你的代号';

-- ---------- 6. 撤销管理员权限 ----------
-- UPDATE agent_user SET permission = 1 WHERE email = 'you@example.com';

-- ---------- 7. 查看现有账号权限 ----------
-- SELECT id, name, email, permission FROM agent_user;
