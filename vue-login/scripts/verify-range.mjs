/* 离线验证：渲染训练场页面，检查「最近训练记录」是否出现在 DOM 里。
   用法：node scripts/verify-range.mjs */
import { readFileSync } from 'node:fs'
import { JSDOM } from 'jsdom'

const dom = new JSDOM('<!doctype html><html><body><div id="app"></div></body></html>', {
  url: 'http://localhost:5173/',
  pretendToBeVisual: true
})

globalThis.window = dom.window
globalThis.document = dom.window.document
globalThis.localStorage = dom.window.localStorage
try { Object.defineProperty(globalThis, 'navigator', { value: dom.window.navigator, configurable: true }) } catch {}
globalThis.performance = dom.window.performance
globalThis.requestAnimationFrame = (cb) => setTimeout(cb, 16)
globalThis.cancelAnimationFrame = clearTimeout

// 拦截所有 fetch（登录态 / 训练接口），返回假数据
globalThis.fetch = async (url) => {
  const path = String(url).replace(/^https?:\/\/[^/]+/, '')
  const json = (obj) => ({ ok: true, json: async () => obj })
  if (path.includes('/api/auth/me')) {
    return json({ code: 0, data: { id: 1, name: 'TESTAGENT', email: 't@t.com', agentIndex: 0 } })
  }
  if (path.includes('/api/game/stats')) {
    return json({ code: 0, data: { total: 3, modes: {
      TARGET: { games: 2, units: 26, bestScore: 293, bestAvgMs: 0 },
      RECOIL: { games: 6, units: 5, bestScore: 8979, bestAvgMs: 0 },
      REACTION: { games: 4, units: 1, bestScore: 1015, bestAvgMs: 397 }
    } } })
  }
  if (path.includes('/api/game/records')) {
    return json({ code: 0, data: [
      { id: 12, mode: 'TARGET', score: 27, units: 1, shots: 3, hits: 1, avgMs: 0, time: '2026-11-02 09:21' },
      { id: 11, mode: 'REACTION', score: 1015, units: 1, shots: 5, hits: 5, avgMs: 397, time: '2026-11-02 09:16' }
    ] })
  }
  return json({ code: 0, data: {} })
}

// 动态 import 避免顶层报错
const { createSSRApp } = await import('vue')
const { renderToString } = await import('vue/server-renderer')
const App = (await import('../src/App.vue')).default
const session = await import('../src/store/session.js')

// 直接把视图切到训练场（跳过登录页）
session.state.view = 'range'
session.state.booted = true
session.state.token = 'fake-token-for-verify'
session.state.user = { id: 1, name: 'TESTAGENT', email: 't@t.com', agentIndex: 0 }

const html = await renderToString(createSSRApp(App))

const checks = [
  ['最近训练记录', html.includes('最近训练记录')],
  ['记录行（靶场点击）', html.includes('靶场点击')],
  ['记录行（反应测试）', html.includes('反应测试')],
  ['模式卡', html.includes('靶场点击') && html.includes('压枪练习')],
  ['页面标题', html.includes('训练设施')],
  ['导航入口', html.includes('训练场')]
]

let fail = 0
for (const [name, ok] of checks) {
  console.log((ok ? 'PASS' : 'FAIL') + '  ' + name)
  if (!ok) fail++
}
if (html.includes('暂无训练记录')) {
  console.log('WARN  渲染成了空态「暂无训练记录」—— records 没加载进来')
}
process.exit(fail ? 1 : 0)
