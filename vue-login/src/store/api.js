/* ============================================================
   后端 API 客户端
   开发环境通过 Vite 代理（/api -> http://localhost:8081），
   生产环境可用 VITE_API_BASE 指定后端地址。
   统一返回 { code, msg, data }，code === 0 为成功。
   ============================================================ */

const BASE = import.meta.env.VITE_API_BASE || ''

/** 网络层失败时使用的统一错误码（后端不会返回负数） */
export const NET_ERROR = { code: -1, msg: 'network-error' }

async function post(path, body) {
  try {
    const res = await fetch(BASE + path, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(body)
    })
    if (!res.ok) {
      // 后端统一返回体走 200，这里兜底非 2xx 的情况
      return { code: res.status, msg: `http-${res.status}` }
    }
    return await res.json()
  } catch {
    return { ...NET_ERROR }
  }
}

/** 登录：id 可为邮箱或代号 */
export const login = (id, pass) => post('/api/auth/login', { id, pass })

/** 注册 */
export const register = (name, email, pass, agentIndex) =>
  post('/api/auth/register', { name, email, pass, agentIndex })

/** 用 token 换账号信息（自动登录） */
export const me = (token) => post('/api/auth/me', { token })

/** 注销会话 */
export const logout = (token) => post('/api/auth/logout', { token })

/** 修改密码 */
export const changePass = (token, oldPass, newPass) =>
  post('/api/auth/change-pass', { token, oldPass, newPass })

/** 会话列表（登录设备） */
export const sessions = (token) => post('/api/auth/sessions', { token })

/** 注销指定会话（踢出设备） */
export const revoke = (token, sessionId) => post('/api/auth/revoke', { token, sessionId })

/* ============================================================
   首页相关接口 —— 后端已实现（HomeController）
   ------------------------------------------------------------
   表：archive_category（分级分类目录）/ agent_archive（档案）/ home_feed（动态）
   建表脚本：springBootTest/sql/home.sql
   ============================================================ */

/**
 * 分级分类检索
 * @param {string} token
 * @param {object} params
 *   q            关键词（匹配名称 / 代号 / 简介 / 分类中文名）
 *   category     一级分类编码 AGENT | GEAR | MISSION
 *   subCategory  二级分类编码 ASSAULT | CONTROL | RIFLE …
 *   tier         分级 S | A | B
 *   page / size  分页
 */
export const search = (token, params = {}) => post('/api/home/search', { token, ...params })

/** 分级分类目录（两级树 + 每类档案数） */
export const homeCategories = (token) => post('/api/home/categories', { token })

/**
 * 档案详情（点击卡片展开）
 * 比检索列表多返回 story（人物故事，长文本）
 */
export const homeDetail = (token, code) => post('/api/home/detail', { token, code })

/** 首页概览：统计 / 精选档案 / 最新动态 */
export const homeOverview = (token) => post('/api/home/overview', { token })

/** 首页动态流（分页，kind 可选 NEWS | PATCH | MISSION） */
export const homeFeed = (token, page = 1, size = 5, kind = '') =>
  post('/api/home/feed', { token, page, size, kind })

/* ============================================================
   作战任务接口 —— 后端 MissionController
   ------------------------------------------------------------
   状态流转：IDLE（未接取）→ ACTIVE（进行中）→ READY（待结算）→ DONE（已结算）
   表：mission_brief（简报 / 目标 / 奖励）/ mission_progress（个人进度）
   建表脚本：springBootTest/sql/mission.sql
   ============================================================ */

/**
 * 任务列表 + 个人统计
 * @param {string} token
 * @param {object} params  status（IDLE|ACTIVE|READY|DONE）/ q / sub / tier
 */
export const missionList = (token, params = {}) => post('/api/mission/list', { token, ...params })

/** 接取任务 */
export const missionAccept = (token, code) => post('/api/mission/accept', { token, code })

/** 勾选 / 取消勾选某个目标，index 为目标下标 */
export const missionToggle = (token, code, index) =>
  post('/api/mission/objective', { token, code, index })

/** 放弃任务（进度记录删除，回到未接取） */
export const missionAbandon = (token, code) => post('/api/mission/abandon', { token, code })

/** 结算任务（目标全部完成后发放积分） */
export const missionClaim = (token, code) => post('/api/mission/claim', { token, code })

/* ============================================================
   情报中心接口 —— 后端 IntelController
   ------------------------------------------------------------
   表：home_feed（情报本体，新增 source / body / importance）
       feed_mark（个人已读 / 收藏 / 点赞）
   建表脚本：springBootTest/sql/intel.sql
   ============================================================ */

/**
 * 情报列表 + 统计
 * @param {string} token
 * @param {object} params kind（NEWS|PATCH|MISSION）/ status（UNREAD|READ|STARRED）
 *                        / q / sort（newest|heat）/ page / size
 */
export const intelList = (token, params = {}) => post('/api/intel/list', { token, ...params })

/** 情报详情（含正文；打开即自动标记已读） */
export const intelDetail = (token, id) => post('/api/intel/detail', { token, id })

/** 标记已读 / 未读 */
export const intelRead = (token, id, read) => post('/api/intel/read', { token, id, read })

/** 收藏 / 取消收藏 */
export const intelStar = (token, id) => post('/api/intel/star', { token, id })

/** 点赞 / 取消点赞 */
export const intelLike = (token, id) => post('/api/intel/like', { token, id })

/** 全部标记已读 */
export const intelMarkAll = (token) => post('/api/intel/mark-all', { token })

/** 统计（未读 / 已读 / 收藏 / 点赞） */
export const intelStats = (token) => post('/api/intel/stats', { token })

/* ============================================================
   找回密码 + RIOT 第三方登录 —— 后端 AuthController
   ------------------------------------------------------------
   表：agent_reset_code（验证码）/ agent_oauth（绑定与授权票据）
   建表脚本：springBootTest/sql/auth_extra.sql
   ============================================================ */

/** 请求找回密码验证码（演示环境直接返回 code） */
export const resetRequest = (email) => post('/api/auth/reset/request', { email })

/** 用验证码重置密码 */
export const resetConfirm = (email, code, newPass) =>
  post('/api/auth/reset/confirm', { email, code, newPass })

/** 发起 Riot 授权：uid 为本地记住的 Riot 身份（复用同一个账号），返回一次性票据 */
export const riotAuthorize = (uid = '') => post('/api/auth/riot/authorize', { uid })

/** 授权回调：已绑定直接返回账号 + token；未绑定返回 bound:false */
export const riotCallback = (ticket) => post('/api/auth/riot/callback', { ticket })

/** 首次授权：绑定新建特工档案并登录 */
export const riotBind = (ticket, name, email, agentIndex) =>
  post('/api/auth/riot/bind', { ticket, name, email, agentIndex })

/* ============================================================
   后台管理接口 —— 后端 AdminController
   ------------------------------------------------------------
   管理员账号与前台特工账号隔离（表 admin_user），后台只登录不注册。
   管理的对象即首页展示的数据：档案 / 分类 / 动态（情报）/ 任务简报 / 用户。
   建表脚本：springBootTest/sql/admin.sql
   ============================================================ */

/** 后台登录：{ username, pass } → { id, username, displayName, token } */
export const adminLogin = (username, pass) => post('/api/admin/login', { username, pass })

/** 校验令牌（刷新页面保持登录） */
export const adminVerify = (token) => post('/api/admin/verify', { token })

/** 退出后台 */
export const adminLogout = (token) => post('/api/admin/logout', { token })

/** 修改管理员密码 */
export const adminChangePass = (token, oldPass, newPass) =>
  post('/api/admin/change-pass', { token, oldPass, newPass })

/** 后台统计：各表记录数 */
export const adminStats = (token) => post('/api/admin/stats', { token })

/** 档案列表 */
export const adminArchiveList = (token, params = {}) =>
  post('/api/admin/archive/list', { token, ...params })

/** 档案新增 / 修改（data.id 为空即新增） */
export const adminArchiveSave = (token, data) => post('/api/admin/archive/save', { token, data })

/** 档案删除 */
export const adminArchiveDelete = (token, id) => post('/api/admin/archive/delete', { token, id })

/** 分类列表 */
export const adminCategoryList = (token) => post('/api/admin/category/list', { token })

/** 分类新增 / 修改 */
export const adminCategorySave = (token, data) => post('/api/admin/category/save', { token, data })

/** 分类删除（一级分类不可删） */
export const adminCategoryDelete = (token, id) => post('/api/admin/category/delete', { token, id })

/** 动态 / 情报列表 */
export const adminFeedList = (token, params = {}) => post('/api/admin/feed/list', { token, ...params })

/** 动态新增 / 修改 */
export const adminFeedSave = (token, data) => post('/api/admin/feed/save', { token, data })

/** 动态删除 */
export const adminFeedDelete = (token, id) => post('/api/admin/feed/delete', { token, id })

/** 任务简报列表 */
export const adminMissionList = (token, params = {}) =>
  post('/api/admin/mission/list', { token, ...params })

/** 任务简报新增 / 修改 */
export const adminMissionSave = (token, data) => post('/api/admin/mission/save', { token, data })

/** 任务简报删除 */
export const adminMissionDelete = (token, id) => post('/api/admin/mission/delete', { token, id })

/** 前台用户列表（只读） */
export const adminUserList = (token, params = {}) => post('/api/admin/user/list', { token, ...params })

/** 操作日志（target: archive/category/feed/mission/admin，action: CREATE/UPDATE/DELETE/LOGIN/PASSWORD） */
export const adminLogList = (token, params = {}) => post('/api/admin/log/list', { token, ...params })
