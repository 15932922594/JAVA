#!/usr/bin/env node
/**
 * 交互冒烟测试 —— 在 jsdom 里直接求值「生产构建产物」，实测交互流程
 *
 * 为什么这样做：
 *   1. 测的是真正要上线的 dist 产物，不是源码的另一份编译结果
 *   2. 不需要 Chromium / Playwright，装不上浏览器的环境也能跑
 *   3. 覆盖 SSR 校验覆盖不到的部分：点击、切换、表单提交、动画状态
 *
 * 前置：npm run build
 * 用法：node scripts/smoke-test.mjs
 * 退出码：0 全部通过；1 有断言失败
 */
import fs from 'node:fs'
import path from 'node:path'
import { JSDOM, VirtualConsole } from 'jsdom'

const ROOT = path.resolve(import.meta.dirname, '..')
const DIST = path.join(ROOT, 'dist')

/* ============ 0. 读取构建产物 ============ */
if (!fs.existsSync(DIST)) {
  console.error('缺少 dist/，请先执行 npm run build')
  process.exit(2)
}
const indexHtml = fs.readFileSync(path.join(DIST, 'index.html'), 'utf8')
const assetsDir = path.join(DIST, 'assets')
const jsFile = fs.readdirSync(assetsDir).find((f) => f.endsWith('.js'))
if (!jsFile) {
  console.error('dist/assets 下没有 JS，请先执行 npm run build')
  process.exit(2)
}
const bundle = fs.readFileSync(path.join(assetsDir, jsFile), 'utf8')

/* ============ 1. 启动 jsdom ============ */
const virtualConsole = new VirtualConsole()
const consoleErrors = []
virtualConsole.on('jsdomError', (e) => consoleErrors.push(e.message))
virtualConsole.on('error', (msg) => consoleErrors.push(String(msg)))

const dom = new JSDOM(indexHtml, {
  runScripts: 'outside-only',   // 只允许我们手动求值，不让 jsdom 自己加载 module 脚本
  pretendToBeVisual: true,      // 提供 requestAnimationFrame
  url: 'http://localhost/',
  virtualConsole
})
const { window } = dom

/* ---- 补上 jsdom 缺失的浏览器能力 ---- */
// canvas：粒子背景与准星会用到 2D context
const ctxStub = {
  clearRect() {}, beginPath() {}, arc() {}, fill() {}, moveTo() {}, lineTo() {}, stroke() {},
  fillRect() {}, save() {}, restore() {}, translate() {}, scale() {}, rotate() {}, closePath() {},
  set fillStyle(_) {}, get fillStyle() { return '' },
  set strokeStyle(_) {}, get strokeStyle() { return '' },
  set lineWidth(_) {}, get lineWidth() { return 1 },
  set globalAlpha(_) {}, get globalAlpha() { return 1 }
}
window.HTMLCanvasElement.prototype.getContext = function () { return ctxStub }

// WebAudio：音效开关打开时会用到
window.AudioContext = class {
  constructor() { this.currentTime = 0; this.destination = {} }
  createOscillator() {
    return { type: '', frequency: { value: 0 }, connect() {}, start() {}, stop() {} }
  }
  createGain() {
    return { gain: { setValueAtTime() {}, exponentialRampToValueAtTime() {} }, connect() {} }
  }
}

/* ============ 2. 求值产物（相当于浏览器加载脚本） ============ */
const domErrorsBefore = consoleErrors.length
window.eval(bundle)

/* ============ 3. 断言工具 ============ */
const doc = window.document
const $ = (s, r = doc) => r.querySelector(s)
const $$ = (s, r = doc) => [...r.querySelectorAll(s)]
const sleep = (ms) => new Promise((r) => setTimeout(r, ms))
const tick = () => new Promise((r) => setTimeout(r, 0))

/**
 * 点击并等待 Vue 把状态刷新到 DOM。
 * Vue 的更新是异步（微任务）的，点完立刻断言会读到旧 DOM —— 这是写这类
 * 测试最容易踩的坑。setTimeout(0) 是宏任务，会排在所有微任务之后，足以保证刷新。
 */
async function click(el) {
  el.dispatchEvent(new window.MouseEvent('click', { bubbles: true }))
  await tick()
}

/** 原生 click：复选框需要它才会触发浏览器默认的勾选行为 */
async function clickNative(el) {
  el.click()
  await tick()
}

const type = (el, v) => {
  el.value = v
  el.dispatchEvent(new window.Event('input', { bubbles: true }))
}

let pass = 0
let fail = 0
const failures = []

function group(name) {
  console.log(`\n▸ ${name}`)
}
function check(label, cond, extra = '') {
  if (cond) {
    pass++
    console.log('  ✅ ' + label)
  } else {
    fail++
    failures.push(label)
    console.log('  ❌ ' + label + (extra ? `\n       ${extra}` : ''))
  }
}

/** 轮询直到条件成立或超时 */
async function waitFor(fn, ms = 4000) {
  const t0 = Date.now()
  while (Date.now() - t0 < ms) {
    if (fn()) return true
    await sleep(50)
  }
  return false
}

/* ============ 4. 用例 ============ */
await tick()

/* ---------- 4.1 首屏渲染 ---------- */
group('首屏渲染')
check('应用已挂载到 #app', doc.getElementById('app').children.length > 0)
check('背景粒子画布存在', !!$('#fx'))
check('自定义准星存在', !!$('.reticle'))
check('开机页存在', !!$('.boot'))
check('音效开关渲染且默认静音', !!$('.icon-btn') && $('.icon-btn').classList.contains('muted'))
check('特工选择条渲染出 6 张卡片', $$('.strip .card').length === 6, `实际 ${$$('.strip .card').length}`)
check('默认选中第 1 张卡片', $$('.strip .card')[0].classList.contains('sel'))
check('默认特工为 VECTOR', $('.aname').textContent.trim() === 'VECTOR', $('.aname')?.textContent)
check('默认定位为 突击', $('.arole').textContent.includes('突击'))
check('立绘标签为 SELECTED · VECTOR', $('.ptag').textContent.trim() === 'SELECTED · VECTOR', $('.ptag')?.textContent)
check('初始等级为 01', $('.plvl').textContent.trim() === 'LV.01', $('.plvl')?.textContent)
check('属性条 4 行', $$('.stat-row').length === 4)
check('面板标题为「特工接入」', $('.ahead h1').textContent.trim() === '特工接入')
check('底部提示显示当前特工', $('.hint').textContent.includes('当前特工： VECTOR · 突击 · ASSAULT'), $('.hint')?.textContent)

/* ---------- 4.2 表单显隐初始态 ---------- */
group('登录 / 注册表单初始态')
const forms = $$('form.form')
const loginForm = forms.find((f) => f.textContent.includes('Riot ID'))
const regForm = forms.find((f) => f.textContent.includes('特工代号'))
check('两个表单都已挂载', !!loginForm && !!regForm)
check('登录表单默认可见', loginForm.classList.contains('on'))
check('注册表单默认隐藏', !regForm.classList.contains('on'))
check('加密等级条默认隐藏', !$('.secu').classList.contains('on'))

/* ---------- 4.3 开机页流程 ---------- */
group('开机页流程')
const ready = await waitFor(() => $('.bhint')?.classList.contains('on'), 5000)
check('进度条跑满后出现「点击任意位置」提示', ready)
await click($('.boot'))
check('点击后开机页进入淡出态', $('.boot').classList.contains('gone'))
await sleep(850)
check('淡出结束后开机页从 DOM 移除', !$('.boot'))
check('移除后弹出「终端已就绪」提示', $('.toast').classList.contains('on') && $('.toast').textContent.includes('终端已就绪'), $('.toast')?.textContent)
check('该提示为成功样式（ok）', $('.toast').classList.contains('ok'))

/* ---------- 4.4 特工切换 ---------- */
group('特工切换')
const cards = $$('.strip .card')
await click(cards[2]) // PHANTOM
check('名称切换为 PHANTOM', $('.aname').textContent.trim() === 'PHANTOM', $('.aname')?.textContent)
check('定位切换为 控场', $('.arole').textContent.includes('控场'))
check('简介已更新', $('.abio').textContent.includes('幻象与烟幕'))
check('第 3 张卡片选中、第 1 张取消选中',
  cards[2].classList.contains('sel') && !cards[0].classList.contains('sel'))
check('立绘主色切到 #A66CFF', $('.portrait').style.getPropertyValue('--ac') === '#A66CFF',
  $('.portrait').style.getPropertyValue('--ac'))
check('主题色同步到 :root', doc.documentElement.style.getPropertyValue('--ac') === '#A66CFF',
  doc.documentElement.style.getPropertyValue('--ac'))
check('等级随特工提升为 07', $('.plvl').textContent.trim() === 'LV.07', $('.plvl')?.textContent)
check('底部提示更新为当前特工', $('.hint').textContent.includes('当前特工： PHANTOM · 控场 · CONTROL'), $('.hint')?.textContent)
await sleep(250) // 等属性条动画
const barW = $$('.stat-row .trk i')[0].style.width
check('属性条宽度动画到位（52%）', barW === '52%', `实际 ${barW}`)

/* ---------- 4.5 标签切换 ---------- */
group('标签切换')
const tabs = $$('.tab')
await click(tabs[1])
check('标题切为「注册新特工」', $('.ahead h1').textContent.trim() === '注册新特工')
check('副标题切为注册文案', $('.ahead p').textContent.includes('创建你的账号'))
check('注册表单显示、登录表单隐藏', regForm.classList.contains('on') && !loginForm.classList.contains('on'))
check('注册标签高亮', tabs[1].classList.contains('on') && !tabs[0].classList.contains('on'))
await click(tabs[0])
check('可切回登录', $('.ahead h1').textContent.trim() === '特工接入' && loginForm.classList.contains('on'))

/* ---------- 4.6 登录表单校验失败 ---------- */
group('登录表单校验失败')
await click(loginForm.querySelector('.btn'))
const badFields = $$('.field.bad', loginForm)
check('空提交时两个字段都标红', badFields.length === 2, `实际 ${badFields.length}`)
check('错误文案为「请输入 Riot ID 或有效邮箱」',
  $$('.emsg', loginForm)[0].textContent.includes('请输入 Riot ID 或有效邮箱'))
check('弹出失败提示', $('.toast').textContent.includes('凭证校验失败') && !$('.toast').classList.contains('ok'),
  $('.toast')?.textContent)

/* 输入后错误态应自动清除 */
type(loginForm.querySelector('input[autocomplete="username"]'), 'agent#0001')
await tick()
check('输入后该字段错误态自动清除', $$('.field.bad', loginForm).length === 1,
  `实际 ${$$('.field.bad', loginForm).length}`)

/* 只填一半仍应被拦截 */
type(loginForm.querySelector('input[autocomplete="current-password"]'), '123')
await click(loginForm.querySelector('.btn'))
check('密码不足 6 位被拦截', $('.toast').textContent.includes('凭证校验失败'))

/* ---------- 4.7 注册表单完整流程 ---------- */
group('注册表单完整流程')
await click(tabs[1])
const rName = regForm.querySelector('input[autocomplete="username"]')
const rEmail = regForm.querySelector('input[autocomplete="email"]')
const rPass = $$('input[autocomplete="new-password"]', regForm)[0]
const rPass2 = $$('input[autocomplete="new-password"]', regForm)[1]
check('注册表单 4 个输入框齐全', !!(rName && rEmail && rPass && rPass2))

type(rName, 'GHOST')
type(rEmail, 'ghost@nexus.net')
type(rPass, 'Abcd1234!')          // 9 位：长度+1、大小写+1、含数字或符号+1 → 3 档「高」
await tick()
check('输入密码后出现加密等级条', $('.secu').classList.contains('on'))
const litCount = () => $$('.segs i').filter((i) => i.style.background !== 'rgba(236, 232, 225, 0.1)').length
check('9 位混合密码点亮 3 段', litCount() === 3, `实际点亮 ${litCount()} 段`)
check('等级文案为「高」', $('.secu .lb span:last-child').textContent.trim() === '高',
  $('.secu .lb span:last-child')?.textContent)

// 再加长：长度 ≥ 10 再 +1 → 4 档（与原版评分规则一致）
type(rPass, 'Abcd1234!@xyz')
await tick()
check('加长到 13 位后点亮全部 4 段', litCount() === 4, `实际点亮 ${litCount()} 段`)
check('等级文案升为「极高」', $('.secu .lb span:last-child').textContent.trim() === '极高',
  $('.secu .lb span:last-child')?.textContent)

type(rPass2, 'Abcd1234!@xyz')
await tick()
check('两次密码一致时无错误态', !$$('.field.bad', regForm).length)

const terms = regForm.querySelector('input[type="checkbox"]')
await clickNative(terms)
check('勾选条款', terms.checked)

await tick()
check('表单填满后特工等级升至 16', $('.plvl').textContent.trim() === 'LV.16', $('.plvl')?.textContent)

await click(regForm.querySelector('.btn'))
check('提交后按钮进入 loading 并禁用',
  regForm.querySelector('.btn').classList.contains('loading') && regForm.querySelector('.btn').disabled)
await sleep(1150)
check('弹出创建成功提示', $('.toast').textContent.includes('特工已创建') && $('.toast').classList.contains('ok'),
  $('.toast')?.textContent)
check('全屏闪光被触发', $('.flash').classList.contains('go'))
check('成功后表单已重置', rName.value === '' && rPass.value === '')
check('重置后加密等级条隐藏', !$('.secu').classList.contains('on'))

/* ---------- 4.8 登录成功流程 ---------- */
group('登录成功流程')
await click(tabs[0])
type(loginForm.querySelector('input[autocomplete="username"]'), 'agent#0001')
type(loginForm.querySelector('input[autocomplete="current-password"]'), 'secret123')
await click(loginForm.querySelector('.btn'))
check('提交后按钮进入 loading', loginForm.querySelector('.btn').classList.contains('loading'))
await sleep(1150)
check('弹出接入成功提示且带当前特工名',
  $('.toast').textContent.includes('接入成功') && $('.toast').textContent.includes('PHANTOM'),
  $('.toast')?.textContent)
check('提示为成功样式', $('.toast').classList.contains('ok'))

/* ---------- 4.9 第三方登录按钮 ---------- */
group('第三方登录按钮')
const socs = $$('.soc', loginForm)
await click(socs[0])
check('点击 RIOT 账号给出连接提示', $('.toast').textContent.includes('Riot 授权网关'), $('.toast')?.textContent)
await click(socs[1])
check('点击 STEAM 给出连接提示', $('.toast').textContent.includes('Steam 授权网关'), $('.toast')?.textContent)

/* ---------- 4.10 分组框与密码显隐 ---------- */
group('密码显隐与分组框')
const passInputs = loginForm.querySelectorAll('.fin input')
const eyeBtn = loginForm.querySelector('.eye')
check('密码框类型为 password', passInputs[1].type === 'password')
await click(eyeBtn)
check('点击眼睛后切换为明文', passInputs[1].type === 'text', passInputs[1].type)
await click(eyeBtn)
check('再次点击切回密文', passInputs[1].type === 'password')
check('分组框渲染出方形选择框', $$('.chk .bx', loginForm).length === 1)

/* ---------- 4.11 运行时错误 ---------- */
group('运行时错误检查')
check('求值产物后无 jsdom 运行时错误', consoleErrors.length === domErrorsBefore,
  consoleErrors.slice(domErrorsBefore).join(' | '))

/* ============ 5. 收尾 ============ */
console.log(`\n${'─'.repeat(52)}`)
console.log(`通过 ${pass} 项，失败 ${fail} 项`)
if (fail) {
  console.log('\n失败明细：')
  failures.forEach((f) => console.log('  - ' + f))
}

dom.window.close()
process.exit(fail ? 1 : 0)
