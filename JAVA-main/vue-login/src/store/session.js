/* ============================================================
   会话状态仓库
   原页面用 DOM 直接读写 + 一堆 document.getElementById 串联逻辑，
   这里统一收敛成一份响应式 state，组件只做展示与事件派发。
   ============================================================ */
import { reactive, computed } from 'vue'
import { AGENTS } from '../data/agents'

/** 与原页面完全一致的邮箱校验正则 */
export const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

export const state = reactive({
  /** 当前选中的特工下标 */
  agentIndex: 0,
  /** 当前面板：login | register */
  mode: 'login',
  /** 开机页是否已结束 */
  booted: false,
  /** 音效开关（默认静音，与原页面一致） */
  soundOn: false,
  /** Toast */
  toast: { visible: false, text: '', ok: false },

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
    selectAgent,
    switchMode,
    showToast,
    resetRegister
  }
}
