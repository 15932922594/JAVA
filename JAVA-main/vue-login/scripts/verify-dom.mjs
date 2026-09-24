#!/usr/bin/env node
/**
 * 结构等价性校验 —— 用 Vue SSR 渲染整个应用，与原版 DOM 逐项比对
 *
 * 比什么：
 *   - class 名是否齐全      → 样式挂点没丢
 *   - placeholder / 可见文案 → 界面没写错
 * 同时验证「所有组件能正常执行 setup」这一运行时前提（SSR 会抛出 setup 里的错误）。
 *
 * 前置：需要先构建一个 SSR 入口。在项目里加 src/ssr-entry.js：
 *
 *   import { createSSRApp } from 'vue'
 *   import { renderToString } from 'vue/server-renderer'
 *   import App from './App.vue'
 *   export async function render() {
 *     const app = createSSRApp(App)
 *     return await renderToString(app)
 *   }
 *
 * 然后：npx vite build --ssr src/ssr-entry.js --outDir dist-ssr
 *
 * 用法：
 *   node verify-dom.mjs --original <原版.html> --ssr-entry <dist-ssr/ssr-entry.js> [--allow "文案A" --allow "文案B"]
 *
 * --allow 用于登记「已知且预期」的文案差异（例如原版静态占位被首屏 JS 覆盖），
 *         这条会被打印为已登记差异而非失败。
 *
 * 退出码：0 通过；1 有未预期的缺失
 */
import fs from 'node:fs'
import path from 'node:path'
import { pathToFileURL } from 'node:url'

/* ---------- 参数解析 ---------- */
function parseArgs(argv) {
  const out = { original: null, ssrEntry: null, allow: [] }
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a === '--original') out.original = argv[++i]
    else if (a === '--ssr-entry') out.ssrEntry = argv[++i]
    else if (a === '--allow') out.allow.push(argv[++i])
  }
  return out
}

const args = parseArgs(process.argv.slice(2))
if (!args.original || !args.ssrEntry) {
  console.error('用法: node verify-dom.mjs --original <原版.html> --ssr-entry <dist-ssr/ssr-entry.js> [--allow "文案"]')
  process.exit(2)
}

/* ---------- 1. SSR 渲染 ---------- */
const ssrEntry = path.resolve(args.ssrEntry)
if (!fs.existsSync(ssrEntry)) {
  console.error(`找不到 SSR 产物：${ssrEntry}`)
  console.error('请先执行：npx vite build --ssr src/ssr-entry.js --outDir dist-ssr')
  process.exit(2)
}
// Windows 上动态 import 绝对路径必须转成 file:// URL
const { render } = await import(pathToFileURL(ssrEntry).href)
const rendered = await render()

/* ---------- 2. 原版 body（去脚本） ---------- */
const originalHtml = fs.readFileSync(path.resolve(args.original), 'utf8')
const bodyMatch = originalHtml.match(/<body[^>]*>([\s\S]*?)<\/body>/i)
if (!bodyMatch) {
  console.error(`未在 ${args.original} 中找到 <body>`)
  process.exit(2)
}
const body = bodyMatch[1].replace(/<script[\s\S]*?<\/script>/gi, '')

/* ---------- 3. 提取与比对 ---------- */
const classTokens = (html) => {
  const set = new Set()
  for (const m of html.matchAll(/class="([^"]*)"/g)) {
    m[1].split(/\s+/).filter(Boolean).forEach((c) => set.add(c))
  }
  return set
}
const placeholders = (html) => new Set([...html.matchAll(/placeholder="([^"]*)"/g)].map((m) => m[1]))
const texts = (html) => {
  const stripped = html
    .replace(/<svg[\s\S]*?<\/svg>/g, ' ')
    .replace(/<[^>]+>/g, '\u0001')
  return stripped.split('\u0001').map((s) => s.replace(/\s+/g, ' ').trim()).filter(Boolean)
}

const origClasses = classTokens(body)
const renderedClasses = classTokens(rendered)

const missingClasses = [...origClasses].filter((c) => !renderedClasses.has(c))
const missingPlaceholders = [...placeholders(body)].filter((p) => !rendered.includes(p))
const missingTexts = [...new Set(texts(body))].filter((t) => !rendered.includes(t))

/* ---------- 4. 报告 ---------- */
console.log(`SSR 输出长度     : ${rendered.length} 字符`)
console.log(`原版 class 名    : ${origClasses.size}`)
console.log(`原版 placeholder : ${placeholders(body).size}`)
console.log(`原版可见文案片段 : ${new Set(texts(body)).size}`)

let failed = false
const report = (label, arr) => {
  if (!arr.length) return console.log(`✅ ${label}：全部命中`)
  failed = true
  console.log(`⚠️  ${label}：缺失 ${arr.length} 项`)
  arr.forEach((x) => console.log('     - ' + x))
}
report('class 名', missingClasses)
report('placeholder', missingPlaceholders)

// 文案：拆成「已登记预期差异」和「真缺失」
const allowSet = new Set(args.allow)
const allowedHits = missingTexts.filter((t) => allowSet.has(t))
const realMissing = missingTexts.filter((t) => !allowSet.has(t))
report('可见文案', realMissing)

if (allowedHits.length) {
  console.log('\nℹ️  已知且预期的差异（原版静态占位 → 最终渲染态）：')
  allowedHits.forEach((t) => console.log('     ' + t))
}

// 多出的 class：原版靠 JS 动态生成的类名会出现在 SSR 输出里，属预期
const extra = [...renderedClasses].filter(
  (c) => !origClasses.has(c) && !c.startsWith('data-v-')
)
console.log(
  extra.length
    ? `ℹ️  产物多出 class（多为原版 JS 动态生成项，请人工确认）：${extra.join(', ')}`
    : '✅ 无多余 class'
)

process.exit(failed ? 1 : 0)
