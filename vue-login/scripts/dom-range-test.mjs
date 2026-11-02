/* 端到端 DOM 验证：在 jsdom 里运行 dist 构建产物，
   模拟「带 token 打开 → 自动登录 → 点导航进训练场」，
   检查「最近训练记录」表格是否真的渲染出来。
   用法：npm run build && node scripts/dom-range-test.mjs */
import { readFileSync, readdirSync } from 'node:fs'
import { JSDOM } from 'jsdom'

const dist = new URL('../dist/', import.meta.url).pathname.replace(/^\/([A-Za-z]:)/, '$1')
const html = readFileSync(dist + 'index.html', 'utf8')
const jsFile = readdirSync(dist + 'assets').find((f) => f.endsWith('.js'))
const js = readFileSync(dist + 'assets/' + jsFile, 'utf8')

const dom = new JSDOM(html, {
  url: 'http://localhost:5173/',
  runScripts: 'outside-only',
  pretendToBeVisual: true
})
const { window } = dom
window.requestAnimationFrame = (cb) => setTimeout(cb, 16)
window.cancelAnimationFrame = clearTimeout

// canvas 2d 上下文桩（FxBackground 用到）
const ctx2d = new Proxy({}, {
  get: (t, k) => {
    if (k === 'canvas') return {}
    return typeof k === 'string' ? (() => ctx2d) : undefined
  },
  set: () => true
})
window.HTMLCanvasElement.prototype.getContext = () => ctx2d

// 假登录态：localStorage 有 token
window.localStorage.setItem('agent_token', 'fake-token-for-verify')

// mock 全部接口
window.fetch = async (url) => {
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
  if (path.includes('/api/auth/sessions')) {
    return json({ code: 0, data: [{ id: 1, createTime: 'x', expiresAt: 'x', current: true }] })
  }
  if (path.includes('/api/home/overview')) {
    return json({ code: 0, data: {
      stats: { archives: 0, agents: 0, gears: 0, feeds: 0, missions: 0 },
      featured: [], feeds: [], marks: {}
    } })
  }
  if (path.includes('/api/home/feed')) {
    return json({ code: 0, data: { list: [], total: 0, pages: 0 } })
  }
  if (path.includes('/api/home/categories')) {
    return json({ code: 0, data: { tree: [], flat: [] } })
  }
  if (path.includes('/api/home/search')) {
    return json({ code: 0, data: { list: [], total: 0, pages: 0 } })
  }
  if (path.includes('/api/mission/list')) {
    return json({ code: 0, data: { stats: {}, subs: [], list: [], total: 0 } })
  }
  return json({ code: 0, data: {} })
}

const sleep = (ms) => new Promise((r) => setTimeout(r, ms))

// 运行构建产物
window.eval(js)
await sleep(1200)

// 1. 过开机页
window.document.body.dispatchEvent(new window.MouseEvent('click', { bubbles: true }))
await sleep(1200)

const step = (name, ok) => console.log((ok ? 'PASS' : 'FAIL') + '  ' + name)

// 2. 自动登录后应到首页
step('自动登录进入首页', window.document.body.textContent.includes('TESTAGENT'))

// 3. 点「训练场」导航
const navBtn = [...window.document.querySelectorAll('button')].find((b) => b.textContent.trim() === '训练场')
step('导航存在「训练场」入口', !!navBtn)
if (navBtn) {
  navBtn.dispatchEvent(new window.MouseEvent('click', { bubbles: true }))
  await sleep(1200)
}

const body = window.document.body.innerHTML
step('训练场页面标题', body.includes('训练设施'))
step('模式卡渲染', body.includes('压枪练习') && body.includes('反应测试'))
step('「最近训练记录」区域存在', body.includes('最近训练记录'))
step('记录数据行渲染（09:21 靶场）', body.includes('09:21'))
step('记录数据行渲染（09:16 反应）', body.includes('09:16'))
step('不是空态', !body.includes('暂无训练记录'))

// 打印记录表附近的 HTML 片段方便排查
const i = body.indexOf('最近训练记录')
if (i >= 0) {
  console.log('\n--- 记录区 HTML 片段 ---\n' + body.slice(i - 100, i + 600).replace(/></g, '>\n<').split('\n').slice(0, 25).join('\n'))
}
process.exit(0)
