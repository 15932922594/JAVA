<script setup>
/* ============================================================
   RANGE 训练场 —— 可玩的训练小游戏
   三个模式：
     TARGET   靶场点击：30 秒限时打靶，统计命中 / 命中率 / 平均反应
     RECOIL   压枪练习：按住鼠标对抗枪口上抬，把弹道压在目标区内
     REACTION 反应测试：5 次随机出靶，测平均反应速度
   每局结束调 /api/game/report 上报成绩，
   后端累计成绩自动完成作战任务里的对应目标（如「靶机命中 30 次」）。
   ============================================================ */
import { nextTick, onBeforeUnmount, onMounted, reactive, ref } from 'vue'
import { state, switchView, useSession, applyLevelInfo } from '../../store/session'
import { gameReport, gameStats, gameRecords } from '../../store/api'
import { beep } from '../../composables/useSound'
import { useEffects } from '../../composables/useEffects'
import HomeNav from './HomeNav.vue'

const { showToast } = useSession()
const { flash } = useEffects()

/** 返回首页（与其他页面一致） */
function backHome() {
  stopAll()
  beep(520, 0.06)
  switchView('home')
}

const MODES = [
  { key: 'TARGET', name: '靶场点击', desc: '30 秒内点掉尽可能多的靶机', unit: '命中' },
  { key: 'RECOIL', name: '压枪练习', desc: '按住鼠标对抗上抬，把弹道压进目标圈', unit: '完成组' },
  { key: 'REACTION', name: '反应测试', desc: '5 次随机出靶，测平均反应速度', unit: '达标' }
]

/* ---------- 个人统计 / 历史记录 ---------- */
const stats = ref({ modes: {}, total: 0 })
const records = ref([])

async function loadAll() {
  const token = state.token
  if (!token) return
  const s = await gameStats(token)
  if (s.code === 0) stats.value = s.data
  const r = await gameRecords(token, 8)
  if (r.code === 0) records.value = r.data
}
onMounted(loadAll)

/* ---------- 对局状态 ---------- */
const phase = ref('idle') // idle（未开始）| playing | done
const mode = ref('TARGET')
const result = reactive({ score: 0, units: 0, detail: '', completed: [], creditsEarned: 0, expEarned: 0 })
const recordsEl = ref(null)

/** 结算后自动滚动到「最近训练记录」，让新记录直接可见 */
async function scrollToRecords() {
  await nextTick()
  recordsEl.value?.scrollIntoView({ behavior: 'smooth', block: 'start' })
}

function pick(m) {
  if (phase.value === 'playing') return
  mode.value = m.key
  beep(660, 0.06)
}

async function report(payload) {
  const res = await gameReport(state.token, payload)
  if (res.code === 0) {
    result.completed = res.data.missionCompleted || []
    stats.value = res.data.stats
    // 训练奖励：信用点入账（军械商店消费用）
    if (typeof res.data.creditsEarned === 'number') {
      result.creditsEarned = res.data.creditsEarned
      if (state.user) state.user.credits = res.data.credits ?? state.user.credits
    }
    // 训练奖励：经验值 + 升级判定
    const lv = res.data.level
    if (lv && typeof lv.expGained === 'number') {
      result.expEarned = lv.expGained
      applyLevelInfo(lv)
      if (lv.levelUp) {
        // 升级：全屏闪光 + 上扬音效 + 升级弹窗提示
        flash()
        beep(660, 0.08)
        setTimeout(() => beep(880, 0.1), 100)
        setTimeout(() => beep(1320, 0.18), 210)
        // 边框里程碑：额外 +300 信用点 + 解锁新头像框
        const frameMsg =
          lv.frameUnlocked && lv.unlockedFrames?.length
            ? ` · 解锁边框 ${lv.unlockedFrames.join('、')}`
            : ''
        showToast(
          `LV.UP · 英雄升至 ${lv.level} 级 · 奖励 ${lv.creditsGained} 信用点${frameMsg}`,
          true
        )
      } else if (lv.expGained > 0) {
        showToast(
          `训练完成 · 经验 +${lv.expGained} EXP · 信用点 +${res.data.creditsEarned || 0}`,
          true
        )
      }
    } else if (typeof res.data.creditsEarned === 'number') {
      showToast(`训练津贴 +${res.data.creditsEarned} 信用点 · 可在军械商店购买武器`, true)
    }
    const rr = await gameRecords(state.token, 8)
    if (rr.code === 0) records.value = rr.data
  }
  phase.value = 'done'
  scrollToRecords()
  if (result.completed.length) {
    showToast(`作战目标自动完成：${result.completed.join('、')}`, true)
    beep(920, 0.12)
  }
}

/* ============================================================
   模式一：靶场点击 TARGET
   ============================================================ */
const field = ref(null)
const tg = reactive({ targets: [], timeLeft: 30, hits: 0, shots: 0 })
let tgTick = null
let tgSpawn = null
let tgSeq = 0

function startTarget() {
  phase.value = 'playing'
  tg.targets = []
  tg.timeLeft = 30
  tg.hits = 0
  tg.shots = 0
  tgSeq = 0
  tgTick = setInterval(() => {
    tg.timeLeft--
    if (tg.timeLeft <= 0) endTarget()
  }, 1000)
  spawnTarget()
}

function spawnTarget() {
  if (phase.value !== 'playing' || mode.value !== 'TARGET') return
  if (tg.targets.length < 4) {
    const size = 34 + Math.round(Math.random() * 26)
    tgSeq++
    tg.targets.push({
      id: tgSeq,
      x: 6 + Math.random() * 82,
      y: 8 + Math.random() * 78,
      size,
      born: performance.now()
    })
  }
  tgSpawn = setTimeout(spawnTarget, 550 + Math.random() * 550)
}

function hitTarget(t) {
  tg.hits++
  tg.shots++
  t.hitAt = performance.now()
  tg.targets = tg.targets.filter((x) => x.id !== t.id)
  beep(880, 0.05)
}

function missClick() {
  tg.shots++
  beep(180, 0.06, 'square')
}

function endTarget() {
  clearInterval(tgTick)
  clearTimeout(tgSpawn)
  tg.targets = []
  const acc = tg.shots ? Math.round((tg.hits / tg.shots) * 100) : 0
  const score = tg.hits * 10 + Math.round(acc / 2)
  result.score = score
  result.units = tg.hits
  result.detail = `命中 ${tg.hits} / 射击 ${tg.shots} · 命中率 ${acc}%`
  report({ mode: 'TARGET', score, units: tg.hits, shots: tg.shots, hits: tg.hits, avgMs: 0 })
}

/* ============================================================
   模式二：压枪练习 RECOIL
   ============================================================ */
const rc = reactive({ timeLeft: 12, firing: false, onTargetMs: 0, firingMs: 0 })
const cross = ref(null)
let rcTick = null
let rcRaf = null
let rcX = 50
let rcY = 50
let rcKick = 0
let rcLast = 0
let rcTargetX = 50

function startRecoil() {
  phase.value = 'playing'
  rc.timeLeft = 12
  rc.firing = false
  rc.onTargetMs = 0
  rc.firingMs = 0
  rcX = 50
  rcY = 62
  rcKick = 0
  rcTargetX = 50
  rcLast = performance.now()
  rcTick = setInterval(() => {
    rc.timeLeft--
    if (rc.timeLeft <= 0) endRecoil()
  }, 1000)
  loopRecoil()
}

function loopRecoil() {
  const now = performance.now()
  const dt = now - rcLast
  rcLast = now

  // 目标圈左右缓慢游走
  rcTargetX = 50 + Math.sin(now / 1700) * 22

  if (rc.firing) {
    rc.firingMs += dt
    // 后坐：越打越抖，枪口持续上抬
    rcKick = Math.min(rcKick + dt * 0.004, 0.12)
    rcY -= (0.018 + rcKick) * dt
    if (rcY < 4) rcY = 4
    // 判定是否在目标圈内（圆心 rcTargetX,50 半径 9%）
    const dx = (rcX - rcTargetX) * 1.78 // 宽高比补偿
    const dy = rcY - 50
    if (dx * dx + dy * dy < 81) rc.onTargetMs += dt
  } else {
    rcKick = Math.max(0, rcKick - dt * 0.01)
  }

  if (cross.value) {
    cross.value.style.left = rcX + '%'
    cross.value.style.top = rcY + '%'
  }
  rcRaf = requestAnimationFrame(loopRecoil)
}

function rcMove(e) {
  const r = field.value.getBoundingClientRect()
  rcX = Math.min(100, Math.max(0, ((e.clientX - r.left) / r.width) * 100))
  rcY = Math.min(100, Math.max(0, ((e.clientY - r.top) / r.height) * 100))
}

function rcDown(e) {
  if (mode.value !== 'RECOIL' || phase.value !== 'playing') return
  rc.firing = true
  rcMove(e)
  beep(320, 0.03)
}

function rcUp() {
  rc.firing = false
}

function endRecoil() {
  clearInterval(rcTick)
  cancelAnimationFrame(rcRaf)
  rc.firing = false
  const ratio = rc.firingMs ? rc.onTargetMs / rc.firingMs : 0
  const ok = ratio >= 0.6
  result.score = Math.round(rc.onTargetMs)
  result.units = ok ? 1 : 0
  result.detail = `压枪在圈 ${Math.round(rc.onTargetMs)} ms · 命中率 ${Math.round(ratio * 100)}%（≥60% 记 1 组）`
  report({ mode: 'RECOIL', score: Math.round(rc.onTargetMs), units: ok ? 1 : 0, shots: 1, hits: ok ? 1 : 0, avgMs: 0 })
}

/* ============================================================
   模式三：反应测试 REACTION
   ============================================================ */
const rt = reactive({ trial: 1, total: 5, showTarget: false, born: 0, times: [], early: 0 })
let rtDelay = null

function startReaction() {
  phase.value = 'playing'
  rt.trial = 1
  rt.showTarget = false
  rt.times = []
  rt.early = 0
  nextTrial()
}

function nextTrial() {
  rt.showTarget = false
  rtDelay = setTimeout(() => {
    rt.born = performance.now()
    rt.showTarget = true
    beep(760, 0.04)
  }, 800 + Math.random() * 2000)
}

function rtClick() {
  if (phase.value !== 'playing' || mode.value !== 'REACTION') return
  if (!rt.showTarget) {
    // 抢跑：本轮重来并记一次失误
    rt.early++
    clearTimeout(rtDelay)
    beep(160, 0.08, 'square')
    showToast('抢跑！本轮重来', false)
    nextTrial()
    return
  }
  const ms = Math.round(performance.now() - rt.born)
  rt.times.push(ms)
  beep(920, 0.05)
  if (rt.trial >= rt.total) {
    endReaction()
  } else {
    rt.trial++
    nextTrial()
  }
}

function endReaction() {
  clearTimeout(rtDelay)
  rt.showTarget = false
  const avg = Math.round(rt.times.reduce((a, b) => a + b, 0) / rt.times.length)
  const ok = avg <= 400
  result.score = Math.max(0, 600 - avg) * 5
  result.units = ok ? 1 : 0
  result.detail = `平均反应 ${avg} ms · 抢跑 ${rt.early} 次（≤400ms 记 1 次达标）`
  report({ mode: 'REACTION', score: Math.max(0, 600 - avg) * 5, units: ok ? 1 : 0, shots: rt.total, hits: rt.times.length, avgMs: avg })
}

/* ---------- 统一入口 ---------- */
function start() {
  if (phase.value === 'playing') return
  beep(700, 0.08)
  if (mode.value === 'TARGET') startTarget()
  else if (mode.value === 'RECOIL') startRecoil()
  else startReaction()
}

function again() {
  result.score = 0
  result.units = 0
  result.detail = ''
  result.completed = []
  phase.value = 'idle'
}

function stopAll() {
  clearInterval(tgTick)
  clearTimeout(tgSpawn)
  clearInterval(rcTick)
  cancelAnimationFrame(rcRaf)
  clearTimeout(rtDelay)
}

onBeforeUnmount(stopAll)

const modeStats = (key) => stats.value.modes?.[key] || { games: 0, units: 0, bestScore: 0, bestAvgMs: 0 }
</script>

<template>
  <div class="page">
    <HomeNav />

    <main class="wrap">
      <!-- 面包屑 + 页头 -->
      <header class="phead">
        <p class="crumbs">
          <button type="button" class="crumb" @click="backHome">首页</button>
          <span class="sep">/</span>
          <span class="cur">训练场</span>
        </p>
        <div class="hrow">
          <h1>训练设施<i>RANGE</i></h1>
          <p class="sub">训练成绩自动推进作战任务里对应的目标（如「靶机命中 30 次」为累计值）</p>
        </div>
      </header>

    <!-- 模式选择 -->
    <div class="modes">
      <button
        v-for="m in MODES"
        :key="m.key"
        class="mode"
        :class="{ on: mode === m.key, lock: phase === 'playing' }"
        type="button"
        @click="pick(m)"
      >
        <b>{{ m.name }}</b>
        <i>{{ m.desc }}</i>
        <span class="mstat">
          <em>{{ modeStats(m.key).games }}</em> 局 ·
          <em>{{ modeStats(m.key).units }}</em> {{ m.unit }} ·
          最佳 <em>{{ modeStats(m.key).bestScore }}</em>
        </span>
      </button>
    </div>

    <!-- 训练场 -->
    <div
      ref="field"
      class="field"
      :class="{ play: phase === 'playing' }"
      @click="mode === 'TARGET' ? missClick() : mode === 'REACTION' && rtClick()"
      @pointerdown="rcDown"
      @pointerup="rcUp"
      @pointerleave="rcUp"
      @pointermove="rcMove"
    >
      <!-- 未开始 -->
      <div v-if="phase === 'idle'" class="idle">
        <p class="rule">
          {{ MODES.find((m) => m.key === mode)?.desc }}
        </p>
        <button class="go" type="button" @click.stop="start">开始训练</button>
      </div>

      <!-- 靶场点击 -->
      <template v-if="phase !== 'idle' && mode === 'TARGET'">
        <div v-for="t in tg.targets" :key="t.id" class="target" :style="{
          left: t.x + '%', top: t.y + '%', width: t.size + 'px', height: t.size + 'px'
        }" @click.stop="hitTarget(t)"></div>
      </template>

      <!-- 压枪练习 -->
      <template v-if="phase !== 'idle' && mode === 'RECOIL'">
        <div class="zone" :style="{ left: rcTargetX + '%' }"></div>
        <div ref="cross" class="cross" :class="{ fire: rc.firing }"></div>
      </template>

      <!-- 反应测试 -->
      <template v-if="phase === 'playing' && mode === 'REACTION'">
        <div v-if="rt.showTarget" class="target big" @click.stop="rtClick"></div>
        <div v-else class="rt-wait">
          <b>{{ rt.trial }} / {{ rt.total }}</b>
          <i>等待出靶…抢跑本轮重来</i>
        </div>
      </template>

      <!-- 结算 -->
      <div v-if="phase === 'done'" class="done" @click.stop>
        <h3>训练完成</h3>
        <div class="score">{{ result.score }}<i>分</i></div>
        <p class="detail">{{ result.detail }}</p>
        <p v-if="result.completed.length" class="comp">
          作战目标已完成：{{ result.completed.join('、') }}
        </p>
        <p class="saved">本局成绩已录入下方「最近训练记录」</p>
        <div class="btns">
          <button class="go" type="button" @click.stop="start">再来一局</button>
          <button class="ghost" type="button" @click.stop="again">返回选择</button>
        </div>
      </div>

      <!-- 顶部 HUD -->
      <div v-if="phase === 'playing'" class="hud">
        <template v-if="mode === 'TARGET'">命中 {{ tg.hits }} · 射击 {{ tg.shots }} · 剩余 {{ tg.timeLeft }}s</template>
        <template v-else-if="mode === 'RECOIL'">在圈 {{ Math.round(rc.onTargetMs) }}ms · 开火 {{ Math.round(rc.firingMs) }}ms · 剩余 {{ rc.timeLeft }}s</template>
        <template v-else>第 {{ rt.trial }} / {{ rt.total }} 次 · 抢跑 {{ rt.early }}</template>
      </div>
    </div>

    <!-- 最近成绩 -->
    <div ref="recordsEl" class="records">
      <h2>最近训练记录</h2>
      <table v-if="records.length">
        <thead>
          <tr><th>时间</th><th>模式</th><th>得分</th><th>有效单位</th><th>射击</th><th>命中</th><th>平均反应</th></tr>
        </thead>
        <tbody>
          <tr v-for="(r, i) in records" :key="r.id" :class="{ fresh: i === 0 }">
            <td class="mono">{{ r.time }}</td>
            <td>{{ ({ TARGET: '靶场点击', RECOIL: '压枪练习', REACTION: '反应测试' })[r.mode] }}</td>
            <td class="hi">{{ r.score }}</td>
            <td>{{ r.units }}</td>
            <td>{{ r.shots }}</td>
            <td>{{ r.hits }}</td>
            <td class="mono">{{ r.avgMs ? r.avgMs + 'ms' : '—' }}</td>
          </tr>
        </tbody>
      </table>
      <p v-else class="empty">暂无训练记录 —— 打完第一局就会出现在这里</p>
    </div>
    </main>
  </div>
</template>

<style scoped>
.page { min-height: 100vh; display: flex; flex-direction: column; }
.wrap {
  flex: 1;
  max-width: 1080px;
  margin: 0 auto;
  padding: 104px 26px 48px;
}

/* ---------- 页头 ---------- */
.phead {
  padding-bottom: 18px;
  border-bottom: 1px solid var(--line);
  animation: up .45s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes up {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: none; }
}
.crumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 10px;
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.8px;
  color: var(--muted);
}
.crumb {
  border: 0; background: transparent; padding: 0;
  color: var(--muted); cursor: pointer; font: inherit;
  letter-spacing: inherit; transition: .18s;
}
.crumb:hover { color: var(--ac); }
.sep { opacity: .5; }
.cur { color: var(--cream); }
.hrow { display: flex; align-items: flex-end; justify-content: space-between; gap: 16px; flex-wrap: wrap; }
.phead h1 {
  margin: 0;
  display: flex;
  align-items: baseline;
  gap: 12px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 38px;
  letter-spacing: 3.4px;
  color: var(--cream);
  text-transform: uppercase;
}
.phead h1 i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 11px;
  letter-spacing: 2.4px;
  color: var(--red);
}
.sub {
  margin: 0 0 6px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.6px;
  color: var(--muted);
}

/* ---------- 模式卡 ---------- */
.modes {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 12px;
  margin: 22px 0 16px;
}
.mode {
  text-align: left;
  padding: 14px 16px;
  background: rgba(17, 26, 36, .8);
  border: 1px solid var(--line);
  cursor: pointer;
  transition: .2s;
  clip-path: polygon(10px 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%, 0 10px);
  display: flex;
  flex-direction: column;
  gap: 6px;
}
.mode b {
  font-family: var(--disp);
  font-size: 16px;
  letter-spacing: 2px;
  color: var(--cream);
}
.mode i { font-style: normal; font-size: 12px; color: var(--muted); line-height: 1.5; }
.mode .mstat { font-family: var(--mono); font-size: 11px; color: var(--muted); letter-spacing: .5px; }
.mode .mstat em { font-style: normal; color: var(--ac); font-weight: 700; }
.mode:hover { border-color: var(--ac); }
.mode.on {
  border-color: var(--ac);
  background: rgba(255, 70, 85, .08);
  box-shadow: 0 0 26px -10px var(--ac);
}
.mode.lock { pointer-events: none; opacity: .75; }

/* ---------- 训练场 ---------- */
.field {
  position: relative;
  height: 400px;
  background:
    linear-gradient(rgba(10, 17, 25, .92), rgba(10, 17, 25, .92)),
    repeating-linear-gradient(0deg, transparent 0 39px, rgba(236, 232, 225, .06) 39px 40px),
    repeating-linear-gradient(90deg, transparent 0 39px, rgba(236, 232, 225, .06) 39px 40px);
  border: 1px solid var(--line);
  overflow: hidden;
  cursor: crosshair;
  user-select: none;
  touch-action: none;
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
}
.field.play { cursor: none; }

/* 未开始 / 结算遮罩 */
.idle, .done {
  position: absolute;
  inset: 0;
  z-index: 4;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 14px;
  background: rgba(10, 17, 25, .55);
  backdrop-filter: blur(2px);
}
.rule { color: var(--muted); font-size: 13px; letter-spacing: 1px; }
.go {
  padding: 12px 34px;
  background: var(--red);
  border: 0;
  color: #fff;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 16px;
  letter-spacing: 3px;
  cursor: pointer;
  clip-path: polygon(10px 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%, 0 10px);
  transition: .2s;
}
.go:hover { box-shadow: 0 0 30px -6px var(--red); transform: translateY(-1px); }
.ghost {
  padding: 12px 26px;
  background: transparent;
  border: 1px solid var(--line);
  color: var(--muted);
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  letter-spacing: 2px;
  cursor: pointer;
  clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
  transition: .2s;
}
.ghost:hover { color: var(--cream); border-color: var(--ac); }
.btns { display: flex; gap: 12px; }

.done h3 {
  font-family: var(--disp);
  font-size: 18px;
  letter-spacing: 4px;
  color: var(--cream);
  margin: 0;
}
.score {
  font-family: var(--disp);
  font-size: 52px;
  font-weight: 700;
  color: var(--ac);
  line-height: 1;
}
.score i { font-style: normal; font-size: 15px; color: var(--muted); margin-left: 6px; }
.detail { color: var(--muted); font-size: 13px; margin: 0; }
.saved {
  margin: 0;
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.comp {
  color: #8fe6b5;
  font-size: 13px;
  margin: 0;
  padding: 6px 12px;
  background: rgba(31, 111, 74, .18);
  border: 1px solid rgba(31, 111, 74, .5);
}

/* 顶部 HUD */
.hud {
  position: absolute;
  top: 10px;
  left: 50%;
  transform: translateX(-50%);
  z-index: 3;
  padding: 6px 18px;
  font-family: var(--mono);
  font-size: 13px;
  letter-spacing: 1.5px;
  color: var(--cream);
  background: rgba(10, 17, 25, .8);
  border: 1px solid var(--line);
  pointer-events: none;
}

/* 靶子 */
.target {
  position: absolute;
  border-radius: 50%;
  background: radial-gradient(circle, var(--red) 0 26%, #fff 26% 44%, var(--red) 44% 62%, #0a1119 62%);
  border: 2px solid rgba(255, 255, 255, .35);
  transform: translate(-50%, -50%);
  cursor: none;
  animation: pop .12s ease-out both;
}
@keyframes pop {
  from { transform: translate(-50%, -50%) scale(.3); opacity: 0; }
  to { transform: translate(-50%, -50%) scale(1); opacity: 1; }
}
.target.big {
  width: 120px;
  height: 120px;
  left: 50%;
  top: 50%;
  cursor: none;
}

/* 压枪：目标圈 + 准星 */
.zone {
  position: absolute;
  top: 50%;
  width: 150px;
  height: 150px;
  transform: translate(-50%, -50%);
  border: 2px dashed rgba(143, 230, 181, .8);
  border-radius: 50%;
  pointer-events: none;
  box-shadow: inset 0 0 40px -18px rgba(143, 230, 181, .8);
}
.cross {
  position: absolute;
  width: 26px;
  height: 26px;
  transform: translate(-50%, -50%);
  pointer-events: none;
}
.cross::before, .cross::after {
  content: '';
  position: absolute;
  background: var(--cream);
}
.cross::before { left: 50%; top: 0; bottom: 0; width: 2px; transform: translateX(-50%); }
.cross::after { top: 50%; left: 0; right: 0; height: 2px; transform: translateY(-50%); }
.cross.fire::before, .cross.fire::after { background: var(--red); box-shadow: 0 0 8px var(--red); }

/* 反应测试等待 */
.rt-wait {
  position: absolute;
  inset: 0;
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 8px;
}
.rt-wait b { font-family: var(--disp); font-size: 30px; color: var(--cream); letter-spacing: 3px; }
.rt-wait i { font-style: normal; font-size: 12px; color: var(--muted); letter-spacing: 2px; }

/* ---------- 记录表 ---------- */
.records { margin-top: 26px; scroll-margin-top: 90px; }
.records h2 {
  font-family: var(--disp);
  font-size: 16px;
  letter-spacing: 3px;
  color: var(--cream);
  margin: 0 0 12px;
}
table { width: 100%; border-collapse: collapse; }
th, td {
  padding: 9px 12px;
  text-align: left;
  font-size: 13px;
  border-bottom: 1px solid rgba(236, 232, 225, .08);
}
th {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.5px;
  color: var(--muted);
  text-transform: uppercase;
}
td { color: var(--cream); }
td.hi { color: var(--ac); font-weight: 700; }
td.mono { font-family: var(--mono); color: var(--muted); }
tr.fresh td {
  background: rgba(255, 70, 85, .08);
  border-bottom-color: rgba(255, 70, 85, .35);
}
.empty { color: var(--muted); font-size: 13px; }

/* ---------- 响应式 ---------- */
@media (max-width: 860px) {
  .modes { grid-template-columns: 1fr; }
  .field { height: 360px; }
}
</style>
