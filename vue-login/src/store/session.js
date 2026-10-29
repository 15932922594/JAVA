/* ============================================================
   会话状态仓库
   原页面用 DOM 直接读写 + 一堆 document.getElementById 串联逻辑，
   这里统一收敛成一份响应式 state，组件只做展示与事件派发。
   ============================================================ */
import { reactive, computed } from 'vue'
import { AGENTS } from '../data/agents'
import * as api from './api'

/** 与原页面完全一致的邮箱校验正则 */
export const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

/** localStorage 中保存会话 token 的键 */
const TOKEN_KEY = 'agent_token'

/** localStorage 中保存后台管理员 token 的键（与前台账号互不影响） */
const ADMIN_TOKEN_KEY = 'admin_token'

/**
 * 权限取值（与后端 agent_user.permission 一致）
 *   1 = 默认权限（注册用户默认）：看不到后台入口，也登录不了后台
 *   0 = 管理员权限：首页显示「后台管理」按钮，可用本人账号登录后台
 */
export const PERMISSION_USER = 1
export const PERMISSION_ADMIN = 0

export const state = reactive({
  /** 当前选中的特工下标 */
  agentIndex: 0,
  /** 当前面板：login | register */
  mode: 'login',
  /**
   * 当前视图：auth（登录页） | home（首页） | agents / arsenal / missions（分类浏览页）
   * | intel（情报中心） | dash（作战终端）
   * 项目暂未引入 vue-router，用这一份状态做页面切换；
   * 后续接路由时把 switchView 换成 router.push 即可。
   */
  view: 'auth',
  /** 开机页是否已结束 */
  booted: false,
  /** 音效开关（默认静音，与原页面一致） */
  soundOn: false,
  /** Toast */
  toast: { visible: false, text: '', ok: false },

  /** 登录态：user = { id, name, email, agentIndex, permission } | null */
  user: null,
  token: null,

  /** 后台管理登录态：admin = { id, username, displayName, permission, source } | null */
  admin: null,
  adminToken: null,

  /** 登录后的主页（作战终端） */
  dashTab: 'overview',            // overview | sessions | security
  sessions: [],                   // [{id, createTime, expiresAt, current}]
  sessionsLoading: false,

  /** 登录表单 */
  login: {
    id: '',
    pass: '',
    remember: false
  },

  /** 注册表单 */
  register: {
    name: '',
    email: '',
    pass: '',
    pass2: '',
    terms: false
  }
})

/** 当前特工对象 */
export const currentAgent = computed(() => AGENTS[state.agentIndex])

/** 特工主色，作为 CSS 变量 --ac 驱动整站强调色 */
export const accent = computed(() => currentAgent.value.color)

/** 填写进度 0~1（原 setXp 中的 p 值） */
export const progress = computed(() => {
  if (state.mode === 'login') {
    const a = state.login.id.trim().length >= 3 ? 1 : 0
    const b = state.login.pass.length >= 6 ? 1 : 0
    return (a + b) / 2
  }
  const n = state.register.name.trim().length >= 2 ? 1 : 0
  const e = EMAIL.test(state.register.email.trim()) ? 1 : 0
  const s = state.register.pass.length >= 6 ? 1 : 0
  const c =
    state.register.pass2 !== '' && state.register.pass2 === state.register.pass ? 1 : 0
  const t = state.register.terms ? 1 : 0
  const g = 1 // 特工始终已选
  return (n + e + s + c + t + g) / 6
})

/** 特工等级：随填写进度与所选特工变化（原 setXp 逻辑） */
export const agentLevel = computed(() =>
  String(1 + Math.floor(progress.value * 9) + state.agentIndex * 3).padStart(2, '0')
)

/** 注册页密码加密等级 0~4（原 #segs 逻辑） */
export const SEC_COLORS = ['#FF4655', '#FFB443', '#3ddc97', '#00E0C6']
export const SEC_TEXTS = ['低', '中', '高', '极高']

export const securityLevel = computed(() => {
  const v = state.register.pass
  if (!v.length) return 0
  let s = 0
  if (v.length >= 6) s++
  if (v.length >= 10) s++
  if (/[A-Z]/.test(v) && /[a-z]/.test(v)) s++
  if (/\d/.test(v) || /[^A-Za-z0-9]/.test(v)) s++
  return Math.min(4, Math.max(1, s))
})

/* ---------------- 认证（对接后端 /api/auth） ---------------- */

/** 登录态派生 */
export const isLoggedIn = computed(() => !!state.user)

/**
 * 当前登录账号是否为管理员权限（permission === 0）。
 * 决定首页「后台管理」按钮是否显示、以及能否进入 / 登录后台管理系统。
 */
export const canAdmin = computed(
  () => !!state.user && state.user.permission === PERMISSION_ADMIN
)

/** 登录成功后写入本地状态；remember 为 true 时持久化 token */
function applyLogin(data, remember) {
  state.user = {
    id: data.id,
    name: data.name,
    email: data.email,
    agentIndex: data.agentIndex,
    permission: data.permission ?? PERMISSION_USER
  }
  state.token = data.token || null
  // 后端记录了注册时选择的特工，登录后切回该特工
  if (typeof data.agentIndex === 'number' && AGENTS[data.agentIndex]) {
    state.agentIndex = data.agentIndex
  }
  if (remember && data.token) {
    localStorage.setItem(TOKEN_KEY, data.token)
  } else {
    localStorage.removeItem(TOKEN_KEY)
  }
  // 接入成功 -> 跳转首页
  state.view = 'home'
  // 顺带拉取会话列表（首页状态栏 / 作战终端都要显示在线设备数）
  loadSessions()
}

/** 登录。成功返回 { ok: true }，失败返回 { ok: false, reason } */
export async function authLogin(id, pass, remember) {
  const r = await api.login(id.trim(), pass)
  if (r.code === 0) {
    applyLogin(r.data, remember)
    return { ok: true, data: r.data }
  }
  return { ok: false, reason: r.msg }
}

/** 注册。成功返回 { ok: true }，失败返回 { ok: false, reason } */
export async function authRegister(name, email, pass, agentIndex) {
  const r = await api.register(name.trim(), email.trim(), pass, agentIndex)
  return r.code === 0 ? { ok: true } : { ok: false, reason: r.msg }
}

/** 退出登录：注销后端会话 + 清理本地状态 */
export async function authLogout() {
  // 后台管理登录态一并退掉：避免管理员退出后，同一台机器上的下一个用户
  // 还能从 localStorage 里拿到上一个管理员的 admin_token 直接调后台接口。
  if (state.admin || localStorage.getItem(ADMIN_TOKEN_KEY)) {
    await adminSignOut()
  }
  const token = state.token || localStorage.getItem(TOKEN_KEY)
  if (token) {
    await api.logout(token)
  }
  state.user = null
  state.token = null
  state.dashTab = 'overview'
  state.sessions = []
  state.view = 'auth'
  localStorage.removeItem(TOKEN_KEY)
  // 清空密码输入，避免残留
  state.login.pass = ''
}

/* ---------------- 找回密码 ---------------- */

/** 请求验证码。成功返回 { ok:true, code, expiresIn, name } */
export async function authResetRequest(email) {
  const r = await api.resetRequest(email.trim())
  return r.code === 0
    ? { ok: true, data: r.data }
    : { ok: false, reason: r.msg }
}

/** 用验证码重置密码：{ email, code, newPass } */
export async function authResetConfirm(email, code, newPass) {
  const r = await api.resetConfirm(email.trim(), code.trim(), newPass)
  return r.code === 0 ? { ok: true, data: r.data } : { ok: false, reason: r.msg }
}

/* ---------------- RIOT 第三方登录 ---------------- */

/** localStorage 中记住的 Riot 身份（相当于 Riot 侧的登录态，用于复用同一个账号） */
const RIOT_UID_KEY = 'agent_riot_uid'

/** 第一步：发起授权 → { ticket, riotId, uid, region, bound } */
export async function authRiotAuthorize() {
  const uid = localStorage.getItem(RIOT_UID_KEY) || ''
  const r = await api.riotAuthorize(uid)
  return r.code === 0 ? { ok: true, data: r.data } : { ok: false, reason: r.msg }
}

/** 记住本次授权的 Riot 身份，下次授权就能走「已绑定 → 直接登录」 */
function rememberRiot(data) {
  if (data && data.uid) localStorage.setItem(RIOT_UID_KEY, data.uid)
}

/**
 * 第二步：授权回调
 * 已绑定 → 直接写入登录态并返回 { ok:true, bound:true, data }
 * 未绑定 → 返回 { ok:true, bound:false, data:{ riotId, ticket, suggestName } }
 */
export async function authRiotCallback(ticket, remember = true) {
  const r = await api.riotCallback(ticket)
  if (r.code !== 0) return { ok: false, reason: r.msg }
  if (r.data.bound === false) {
    rememberRiot(r.data)
    return { ok: true, bound: false, data: r.data }
  }
  rememberRiot(r.data)
  applyLogin(r.data, remember)
  return { ok: true, bound: true, data: r.data }
}

/** 第三步：首次授权建档并绑定，成功后直接进入登录态 */
export async function authRiotBind(ticket, name, email, agentIndex, remember = true) {
  const r = await api.riotBind(ticket, name.trim(), email.trim(), agentIndex)
  if (r.code !== 0) return { ok: false, reason: r.msg }
  rememberRiot(r.data)
  applyLogin(r.data, remember)
  return { ok: true, data: r.data }
}

/** 自动登录：用 localStorage 里的 token 换账号信息（页面刷新时调用） */
export async function authRestore() {
  const token = localStorage.getItem(TOKEN_KEY)
  if (!token) return false
  const r = await api.me(token)
  if (r.code === 0) {
    applyLogin({ ...r.data, token }, true)
    return true
  }
  // token 失效/过期：清掉，走正常登录
  localStorage.removeItem(TOKEN_KEY)
  return false
}

/* ---------------- 页面视图切换 ---------------- */

/**
 * 切换视图：
 *   auth     登录页
 *   home     首页
 *   agents   特工档案（category=AGENT）
 *   arsenal  武器库（category=GEAR）
 *   missions 作战任务（category=MISSION）
 *   intel    情报中心（home_feed 动态流）
 *   dash     作战终端（账号管理面板）
 * 后续若引入 vue-router，把这里改成 router.push 即可，调用方不用动。
 */
export function switchView(view) {
  if (!['auth', 'home', 'agents', 'arsenal', 'missions', 'intel', 'dash', 'admin'].includes(view)) {
    return
  }
  // 后台管理系统：仅管理员权限（permission = 0）可进入，默认权限一律拦下
  if (view === 'admin' && !canAdmin.value) {
    showToast('无后台管理权限 · 仅管理员可进入', false)
    state.view = state.user ? 'home' : 'auth'
    return
  }
  state.view = view
  if (view === 'dash') loadSessions()
}

/* ---------------- 后台管理（AdminController） ---------------- */

/**
 * 进入后台：仅 permission = 0（管理员权限）可进入，进到后台登录页后用本人账号登录。
 * 默认权限（permission = 1）直接拦截并提示。
 */
export function enterAdmin() {
  if (!canAdmin.value) {
    showToast('无后台管理权限 · 仅管理员可进入', false)
    return false
  }
  state.view = 'admin'
  return true
}

/**
 * 后台登录：使用前台账号（代号或邮箱）+ 密码。
 * 后端只放行 permission = 0 的账号，默认权限会返回「该账号无后台管理权限」。
 */
export async function adminLogin(username, pass) {
  const r = await api.adminLogin(username.trim(), pass)
  if (r.code !== 0) return { ok: false, reason: r.msg }
  state.admin = {
    id: r.data.id,
    username: r.data.username,
    displayName: r.data.displayName,
    permission: r.data.permission ?? PERMISSION_ADMIN,
    source: r.data.source || 'ADMIN'
  }
  state.adminToken = r.data.token
  localStorage.setItem(ADMIN_TOKEN_KEY, r.data.token)
  return { ok: true, data: r.data }
}

/** 后台自动登录：用本地 token 校验（刷新页面时调用） */
export async function adminRestore() {
  const token = localStorage.getItem(ADMIN_TOKEN_KEY)
  if (!token) return false
  const r = await api.adminVerify(token)
  if (r.code === 0) {
    state.admin = {
      id: r.data.id,
      username: r.data.username,
      displayName: r.data.displayName,
      permission: r.data.permission ?? PERMISSION_ADMIN,
      source: r.data.source || 'ADMIN'
    }
    state.adminToken = token
    return true
  }
  localStorage.removeItem(ADMIN_TOKEN_KEY)
  return false
}

/** 后台授权：把某个前台账号设为管理员（0）或恢复默认权限（1） */
export async function adminSetPermission(userId, permission) {
  const r = await api.adminUserPermission(state.adminToken, userId, permission)
  return r.code === 0 ? { ok: true } : { ok: false, reason: r.msg }
}

/** 退出后台 */
export async function adminSignOut() {
  if (state.adminToken) await api.adminLogout(state.adminToken)
  state.admin = null
  state.adminToken = null
  localStorage.removeItem(ADMIN_TOKEN_KEY)
}

/** 后台管理员是否登录 */
export const isAdmin = computed(() => !!state.admin)

/* ---------------- 登录后主页（作战终端） ---------------- */

/** 切换主页标签 */
export function switchDashTab(tab) {
  state.dashTab = tab
  if (tab === 'sessions') loadSessions()
}

/** 拉取会话（登录设备）列表 */
export async function loadSessions() {
  const token = state.token || localStorage.getItem(TOKEN_KEY)
  if (!token) return
  state.sessionsLoading = true
  const r = await api.sessions(token)
  state.sessionsLoading = false
  if (r.code === 0) {
    state.sessions = r.data || []
  }
}

/** 踢出指定会话（其他设备） */
export async function revokeSession(sessionId) {
  const token = state.token || localStorage.getItem(TOKEN_KEY)
  if (!token) return false
  const r = await api.revoke(token, sessionId)
  if (r.code === 0) {
    state.sessions = state.sessions.filter((s) => s.id !== sessionId)
    return true
  }
  return false
}

/** 修改密码。成功返回 { ok: true }，失败返回 { ok: false, reason } */
export async function authChangePass(oldPass, newPass) {
  const token = state.token || localStorage.getItem(TOKEN_KEY)
  if (!token) return { ok: false, reason: 'notfound' }
  const r = await api.changePass(token, oldPass, newPass)
  return r.code === 0 ? { ok: true } : { ok: false, reason: r.msg }
}

/* ---------------- 行为 ---------------- */

export function selectAgent(i) {
  state.agentIndex = i
}

export function switchMode(mode) {
  state.mode = mode
}

let toastTimer = null
export function showToast(text, ok = false) {
  state.toast.text = text
  state.toast.ok = !!ok
  state.toast.visible = true
  clearTimeout(toastTimer)
  toastTimer = setTimeout(() => {
    state.toast.visible = false
  }, 3000)
}

/** 表单重置（注册成功后调用） */
export function resetRegister() {
  Object.assign(state.register, {
    name: '',
    email: '',
    pass: '',
    pass2: '',
    terms: false
  })
}

/** 组合式入口，便于组件内 import 一次拿全 */
export function useSession() {
  return {
    state,
    currentAgent,
    accent,
    progress,
    agentLevel,
    securityLevel,
    isLoggedIn,
    isAdmin,
    canAdmin,
    enterAdmin,
    adminLogin,
    adminRestore,
    adminSignOut,
    adminSetPermission,
    authLogin,
    authRegister,
    authLogout,
    authRestore,
    authResetRequest,
    authResetConfirm,
    authRiotAuthorize,
    authRiotCallback,
    authRiotBind,
    authChangePass,
    switchView,
    switchDashTab,
    loadSessions,
    revokeSession,
    selectAgent,
    switchMode,
    showToast,
    resetRegister
  }
}
