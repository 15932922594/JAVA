#!/usr/bin/env node
/**
 * CSS 选择器等价性校验 —— 单文件 HTML 重构为组件化工程后，确认样式一条没丢
 *
 * 做法：抽取「原版 HTML 的 <style>」与「构建产物 CSS」的全部选择器做集合比对，
 *       归一化掉两类无害差异：
 *         1. Vue scoped 注入的 [data-v-*] 属性
 *         2. 压缩器把 ::after / ::before 写成 :after / :before
 *
 * 用法：
 *   node verify-styles.mjs --original <原版.html> --dist <构建产物目录> [--original <更多.html>...]
 *
 * 例：
 *   node verify-styles.mjs --original ../index.html --dist ./dist
 *
 * 退出码：0 全部命中；1 有缺失（会逐条列出）
 */
import fs from 'node:fs'
import path from 'node:path'

/* ---------- 参数解析 ---------- */
function parseArgs(argv) {
  const out = { original: [], dist: null, verbose: false }
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i]
    if (a === '--original') out.original.push(argv[++i])
    else if (a === '--dist') out.dist = argv[++i]
    else if (a === '--verbose' || a === '-v') out.verbose = true
    else if (!a.startsWith('-') && !out.dist) out.dist = a
    else if (!a.startsWith('-')) out.original.push(a)
  }
  return out
}

const args = parseArgs(process.argv.slice(2))
if (!args.original.length) {
  console.error('用法: node verify-styles.mjs --original <原版.html> --dist <构建产物目录>')
  process.exit(2)
}

/* ---------- 1. 读取原版样式 ---------- */
function extractStyleBlocks(file) {
  const html = fs.readFileSync(file, 'utf8')
  const blocks = [...html.matchAll(/<style[^>]*>([\s\S]*?)<\/style>/gi)].map((m) => m[1])
  if (!blocks.length) throw new Error(`未在 ${file} 中找到 <style> 块`)
  return blocks.join('\n')
}

/* ---------- 2. 读取构建产物 CSS ---------- */
function collectBuiltCss(distDir) {
  const assets = path.join(distDir, 'assets')
  const dir = fs.existsSync(assets) ? assets : distDir
  const files = fs.readdirSync(dir, { withFileTypes: true })
    .filter((d) => d.isFile() && d.name.endsWith('.css'))
    .map((d) => path.join(dir, d.name))
  if (!files.length) throw new Error(`${dir} 下没有 CSS 文件，请先执行构建`)
  return files.map((f) => fs.readFileSync(f, 'utf8')).join('\n')
}

/* ---------- 3. 选择器抽取与归一化 ---------- */
function extractSelectors(css) {
  let s = css.replace(/\/\*[\s\S]*?\*\//g, '')
  // 移除 @keyframes（含嵌套花括号）
  s = s.replace(/@keyframes[^{]*\{(?:[^{}]*\{[^{}]*\})*[^{}]*\}/g, '')
  // 展平 @media / @supports 等，保留内部规则
  s = s.replace(/@(media|supports|layer|container)[^{]*\{/g, '\n')

  const out = []
  const re = /([^{}]+)\{([^{}]*)\}/g
  let m
  while ((m = re.exec(s))) {
    const sel = m[1].trim()
    if (!sel || sel.startsWith('@')) continue
    out.push(...sel.split(',').map((x) => x.trim()).filter(Boolean))
  }
  return out
}

function normalize(sel) {
  return sel
    .replace(/\[data-v-[a-z0-9]+\]/g, '')   // Vue scoped 注入
    .replace(/\s*([>+~,])\s*/g, '$1')
    .replace(/\s+/g, ' ')
    .trim()
}

function key(sel) {
  return normalize(sel)
    .replace(/::(before|after|first-line|first-letter|placeholder|selection|backdrop|marker)/g, ':$1')
    .replace(/"/g, "'")
}

/* ---------- 4. 比对 ---------- */
const originalCss = args.original.map(extractStyleBlocks).join('\n')
const builtCss = collectBuiltCss(path.resolve(args.dist))

const origSels = extractSelectors(originalCss)
const builtSet = new Set(extractSelectors(builtCss).map(key))

const seen = new Set()
const missing = []
for (const sel of origSels) {
  const k = key(sel)
  if (seen.has(k)) continue
  seen.add(k)
  if (!builtSet.has(k)) missing.push(sel)
}

console.log(`原版文件        : ${args.original.map((f) => path.basename(f)).join(', ')}`)
console.log(`产物 CSS 选择器 : ${builtSet.size}`)
console.log(`原版选择器(去重): ${seen.size}`)

if (missing.length === 0) {
  console.log('\n✅ 全部选择器均已迁移，无遗漏')
  process.exit(0)
}

console.log(`\n⚠️  有 ${missing.length} 条选择器未在产物中找到：`)
missing.forEach((s) => console.log('   - ' + s))
if (!args.verbose) {
  console.log('\n提示：若某条是「组件根元素前缀被省略」导致，请把选择器还原成与原版一致的完整写法，')
  console.log('      以保持校验透明可解释（--verbose 可查看全部原始选择器）。')
}
process.exit(1)
