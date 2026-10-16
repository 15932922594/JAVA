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
