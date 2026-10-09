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
