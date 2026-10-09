# springBootTest — AGENT ACCESS 登录系统后端

Spring Boot 3.4.5 + MyBatis-Plus 3.5.12 + MySQL 8，为
`C:\Users\Administrator\Desktop\vue-login` 前端提供注册/登录接口（前端开发服务器
`localhost:5173` 经 Vite 代理转发 `/api` 到本服务）。

## 接口

| 方法 | 路径 | 入参 (JSON) | 返回 |
| --- | --- | --- | --- |
| POST | /api/auth/register | `{ name, email, pass, agentIndex }` | `{code:0, data:{name,email,agentIndex}}`；重复→`code:409, msg:duplicate-email / duplicate-name` |
| POST | /api/auth/login | `{ id, pass }`（id 可为邮箱或代号） | `{code:0, data:{id,name,email,agentIndex,token}}`；失败→`code:401, msg:notfound / wrongpass` |
| POST | /api/auth/me | `{ token }` | `{code:0, data:{id,name,email,agentIndex}}`；无效/过期→`code:401`（前端自动登录用） |
| POST | /api/auth/logout | `{ token }` | `{code:0}`；注销该会话 |
| POST | /api/auth/sessions | `{ token }` | `{code:0, data:[{id,createTime,expiresAt,current}]}`；当前账号全部有效会话（current 标记本机），登录设备管理用 |
| POST | /api/auth/revoke | `{ token, sessionId }` | `{code:0}`；踢出指定会话（只能踢自己的） |
| POST | /api/auth/change-pass | `{ token, oldPass, newPass }` | `{code:0}`；旧密码错→`code:400, msg:wrongpass`，成功后重置盐+摘要 |

统一返回体 `{ code, msg, data }`，`code===0` 为成功。

## 登录态（会话）

- 登录成功签发 32 位 token，存入 `agent_session` 表，有效期 **7 天**
- 前端保存 token（localStorage），刷新页面调 `/api/auth/me` 自动登录
- 登录时未勾选「保持登录」则不保存 token；`/api/auth/logout` 注销会话
- 每次登录顺手清理已过期会话

## 启动

```bash
# 1. 建库建表（首次）
mysql -uroot -p123456 < sql/schema.sql
# 2. 启动（端口 8081，配置在 application-dev.properties）
mvnw.cmd spring-boot:run
```

数据源：`localhost:3306/agent_access`，root / 123456（见 `application-dev.properties`）。

## 代码结构

```
src/main/java/com/fenglin/springboottest/
├─ SpringBootTestApplication.java    # 入口
├─ common/Result.java               # 统一 JSON 返回体
├─ config/WebCorsConfig.java        # 跨域（放行 localhost:* 前端）
├─ controller/AuthController.java   # /api/auth 注册+登录+会话
├─ entity/AgentUser.java            # agent_user 表实体
├─ entity/AgentSession.java         # agent_session 会话表实体
├─ mapper/AgentUserMapper.java      # MyBatis-Plus BaseMapper
├─ mapper/AgentSessionMapper.java
├─ service/AgentUserService.java    # 业务（查重、盐+SHA-256 校验、token 签发/校验）
└─ util/PasswordUtil.java           # 随机盐 + SHA-256 摘要
```

密码存储：`SHA-256(salt::password)` 十六进制摘要 + 每账号独立随机盐，与前端算法一致。

## 注意

- 原 Thymeleaf 演示页（/user/to_login 等）保留未动。
- 会话用数据库表实现（教学直观、重启不丢）；生产环境建议改 JWT 或 Redis 存会话，密码改 BCrypt。
