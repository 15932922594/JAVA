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

## 作战任务（可交互）

任务本体（名称/分类/分级/背景故事）仍在 `agent_archive`（category=MISSION），
交互数据存两表：`mission_brief`（简报/目标/奖励/时限）+ `mission_progress`（个人进度）。
建表：`mysql -uroot -p123456 < sql/mission.sql`

状态流转：`IDLE（未接取）→ ACTIVE（进行中）→ READY（目标全完成待结算）→ DONE（已结算）`

| 方法 | 路径 | 入参 (JSON) | 返回 |
| --- | --- | --- | --- |
| POST | /api/mission/list | `{ token, status?, q?, sub?, tier? }` | `{code:0, data:{stats:{total,active,ready,done,points,rate,rewardTotal}, subs:[{code,name,count,done}], list:[…]}}`；任务项含 `objectives:[{index,text,done}]`、`progress`、`status`、`remainSec`、`deadline` |
| POST | /api/mission/accept | `{ token, code }` | `{code:0, data:{…任务项, status:ACTIVE}}`；重复接取→`code:409` |
| POST | /api/mission/objective | `{ token, code, index }` | 勾选/取消目标，全部完成自动转 READY；`data` 为刷新后的任务项 |
| POST | /api/mission/abandon | `{ token, code }` | 删除进度记录回到 IDLE；已结算→`code:409` |
| POST | /api/mission/claim | `{ token, code }` | `{code:0, data:{reward, points, mission}}`；目标未完成→`code:400` |

前端页面：`vue-login/src/components/home/MissionsPage.vue`（+ `MissionCard` / `MissionDetailModal`）。

## 找回密码 / RIOT 第三方登录

建表：`mysql -uroot -p123456 < sql/auth_extra.sql`
（新增 `agent_reset_code` 验证码表、`agent_oauth` 绑定与票据表）

找回密码：邮箱 → 6 位验证码（10 分钟有效、一次性）→ 重置密码并踢掉该账号所有会话。
演示环境无邮件服务，验证码由接口直接返回给前端展示。

| 方法 | 路径 | 入参 (JSON) | 返回 |
| --- | --- | --- | --- |
| POST | /api/auth/reset/request | `{ email }` | `{code:0, data:{email, code, expiresIn, name}}`；未注册邮箱→`code:404` |
| POST | /api/auth/reset/confirm | `{ email, code, newPass }` | `{code:0}`；换盐重算摘要 + 删除该用户全部会话 |

RIOT 登录：`/api/auth/riot/authorize`（可选传 `uid` 复用同一个 Riot 身份）
→ `callback` → 已绑定直接签发 token；未绑定返回 `bound:false` → `bind` 建档绑定。

| 方法 | 路径 | 入参 (JSON) | 返回 |
| --- | --- | --- | --- |
| POST | /api/auth/riot/authorize | `{ uid? }` | `{ticket, riotId, uid, region, bound, expiresIn}` |
| POST | /api/auth/riot/callback | `{ ticket }` | 已绑定：`{id,name,email,token,riotId,uid}`；未绑定：`{bound:false, riotId, ticket, suggestName}` |
| POST | /api/auth/riot/bind | `{ ticket, name, email, agentIndex }` | 建档绑定成功 → 账号 + token |

票据一次性使用（10 分钟有效），用掉即清空 `ticket` 列。
**注意**：清空列必须用 `UpdateWrapper.set("ticket", null)`，`updateById` 会跳过 null 字段。

前端：`vue-login/src/components/ForgotPasswordModal.vue`（三步）、`RiotAuthModal.vue`（connect→consent→callback→bind）。

## 情报中心（可交互）

情报本体在 `home_feed`，`sql/intel.sql` 给它加了 `source`（来源）、`body`（正文）、
`importance`（1 常规 / 2 重要 / 3 紧急）三个字段并灌入 8 条正文；
个人交互存 `feed_mark`（已读 / 收藏 / 点赞，一人一条情报一条记录）。

| 方法 | 路径 | 入参 (JSON) | 返回 |
| --- | --- | --- | --- |
| POST | /api/intel/list | `{ token, kind?, status?, q?, sort?, page?, size? }` | `{code:0, data:{stats:{total,unread,read,starred,rate,byKind}, list:[…], total, pages}}`；`status` 支持 `UNREAD / READ / STARRED`，`sort` 支持 `newest / heat` |
| POST | /api/intel/detail | `{ token, id }` | 详情含 `body` 正文；**打开即自动标记已读** |
| POST | /api/intel/read | `{ token, id, read }` | 设置已读 / 未读，返回该条 + 最新 `stats` |
| POST | /api/intel/star | `{ token, id }` | 收藏 / 取消收藏（收藏顺手标为已读），返回最新 `stats` |
| POST | /api/intel/like | `{ token, id }` | 点赞 / 取消点赞，返回 `likes`（全局点赞总数） |
| POST | /api/intel/mark-all | `{ token }` | 全部标为已读，返回 `changed` 变更条数（幂等） |
| POST | /api/intel/stats | `{ token }` | 未读 / 已读 / 收藏 / 点赞 / 阅读率统计 |

注意：`status` 为 `UNREAD / READ / STARRED` 时，筛选依赖当前用户的 mark，
服务层会先在全量数据上过滤再手动分页（否则只会筛掉当前分页内的条目）。

前端页面：`vue-login/src/components/home/IntelPage.vue`（+ `IntelDetailModal`）。

## 登录态（会话）

- 登录成功签发 32 位 token，存入 `agent_session` 表，有效期 **7 天**
- 前端保存 token（localStorage），刷新页面调 `/api/auth/me` 自动登录
- 登录时未勾选「保持登录」则不保存 token；`/api/auth/logout` 注销会话
- 每次登录顺手清理已过期会话

## 启动

```bash
# 1. 建库建表（首次，脚本均可重复执行）
mysql -uroot -p123456 < sql/schema.sql   # 账号 + 会话
mysql -uroot -p123456 < sql/home.sql     # 档案 / 分类 / 动态流
mysql -uroot -p123456 < sql/mission.sql  # 作战任务（简报 + 进度）
mysql -uroot -p123456 < sql/intel.sql    # 情报中心（正文 + 交互记录）
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
├─ controller/HomeController.java   # /api/home 首页（分类/检索/动态流）
├─ controller/MissionController.java# /api/mission 作战任务（接取/目标/结算）
├─ controller/IntelController.java  # /api/intel 情报中心（已读/收藏/点赞）
├─ entity/FeedMark.java             # feed_mark 情报交互实体
├─ entity/AgentUser.java            # agent_user 表实体
├─ entity/AgentSession.java         # agent_session 会话表实体
├─ entity/MissionBrief.java         # mission_brief 任务简报实体
├─ entity/MissionProgress.java      # mission_progress 个人任务进度实体
├─ mapper/AgentUserMapper.java      # MyBatis-Plus BaseMapper
├─ mapper/AgentSessionMapper.java
├─ service/AgentUserService.java    # 业务（查重、盐+SHA-256 校验、token 签发/校验）
└─ util/PasswordUtil.java           # 随机盐 + SHA-256 摘要
```

密码存储：`SHA-256(salt::password)` 十六进制摘要 + 每账号独立随机盐，与前端算法一致。

## 注意

- 原 Thymeleaf 演示页（/user/to_login 等）保留未动。
- 会话用数据库表实现（教学直观、重启不丢）；生产环境建议改 JWT 或 Redis 存会话，密码改 BCrypt。
