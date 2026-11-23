<script setup>
/* ============================================================
   异常档案 · ANOMALY FILES —— 特工怪诞剧情游戏
   ------------------------------------------------------------
   数据驱动（src/data/anomalyStory.js），页面状态机：
     select  副本选择
     play    剧情推进（场景 → 选项 → 场景/结局）
     ending  结局展示（含结局图鉴解锁）
     gallery 结局图鉴（本地存档，集齐三关真相结局解锁终极结局）
   视觉沿用项目统一 HUD：斜切裁角 / 等宽小标签 / 红辉光 / 扫描线。
   ============================================================ */
import { computed, onBeforeUnmount, ref } from 'vue'
import {
  CASES, FINALE, GRADE, SAN_MAX, allEndings
} from '../../data/anomalyStory'
import { switchView, useSession } from '../../store/session'
import { beep } from '../../composables/useSound'
import HomeNav from '../home/HomeNav.vue'

const { showToast } = useSession()

/* ---------------- 本地存档 ---------------- */
const SAVE_KEY = 'anomaly_unlocked_v1'
const FINALE_KEY = 'anomaly_finale_v1'

function readSave() {
  try {
    const raw = JSON.parse(localStorage.getItem(SAVE_KEY) || '[]')
    return Array.isArray(raw) ? raw : []
  } catch {
    return []
  }
}

/** 已解锁结局，形如 'echo-ward:e_room0' */
const unlocked = ref(readSave())
const finaleUnlocked = ref(localStorage.getItem(FINALE_KEY) === '1')

function persist() {
  try {
    localStorage.setItem(SAVE_KEY, JSON.stringify(unlocked.value))
    localStorage.setItem(FINALE_KEY, finaleUnlocked.value ? '1' : '0')
  } catch {
    /* 隐私模式下 localStorage 不可用时静默降级（游戏仍可进行，只是不存档） */
  }
}

/** 三关真相结局，集齐后解锁终极结局 */
const TRUE_ENDINGS = [
  'echo-ward:e_room0',
  'mirror-protocol:e_shutdown',
  'room-zero:e_human'
]

function isUnlocked(caseId, endId) {
  return unlocked.value.includes(`${caseId}:${endId}`)
}

function checkFinale() {
  if (finaleUnlocked.value) return
  if (TRUE_ENDINGS.every((k) => unlocked.value.includes(k))) {
    finaleUnlocked.value = true
    persist()
    beep(1040, 0.18)
    showToast('终极结局已解锁 · 档案之外', true)
  }
}

/** 某副本的结局解锁进度 */
function caseProgress(c) {
  const total = Object.keys(c.endings).length
  const got = Object.keys(c.endings).filter((id) => isUnlocked(c.id, id)).length
  return { got, total, pct: Math.round((got / total) * 100) }
}

const allProgress = computed(() => {
  const all = allEndings()
  let got = 0
  let total = 0
  CASES.forEach((c) => {
    total += all[c.id].length
    got += all[c.id].filter((e) => isUnlocked(c.id, e.id)).length
  })
  return { got, total, pct: Math.round((got / total) * 100) }
})

/* ---------------- 页面状态机 ---------------- */
const phase = ref('select') // select | play | ending | gallery
const activeCase = ref(null)
const sceneId = ref(null)
const san = ref(SAN_MAX)
const clues = ref([])
const visited = ref([])
const currentEnding = ref(null)
const isNewEnding = ref(false)
const twistShow = ref(null)
const galleryTab = ref('echo-ward')

/** 反转演出的延迟定时器：连续推进场景时必须取消上一个，避免弹错反转；卸载时也要清理 */
let twistTimer = null
function clearTwistTimer() {
  if (twistTimer !== null) {
    window.clearTimeout(twistTimer)
    twistTimer = null
  }
}
onBeforeUnmount(clearTwistTimer)

const scene = computed(() => (activeCase.value ? activeCase.value.scenes[sceneId.value] : null))
const lowSan = computed(() => phase.value === 'play' && san.value <= 40)

function backHome() {
  beep(520, 0.06)
  switchView('home')
}

function toSelect() {
  beep(560, 0.06)
  clearTwistTimer()
  phase.value = 'select'
  twistShow.value = null
}

function toGallery() {
  beep(620, 0.06)
  clearTwistTimer()
  phase.value = 'gallery'
  twistShow.value = null
}

/* ---------------- 进入场景 ---------------- */
function enterScene(id) {
  const s = activeCase.value.scenes[id]
  if (!s) return
  sceneId.value = id

  // 每个场景只结算一次理智/线索，避免同一场景反复刷取
  if (!visited.value.includes(id)) {
    visited.value = [...visited.value, id]
    if (s.sanityDelta) san.value = Math.max(0, Math.min(SAN_MAX, san.value + s.sanityDelta))
    if (s.clues) {
      const next = new Set(clues.value)
      s.clues.forEach((c) => next.add(c))
      clues.value = [...next]
    }
  }

  // 反转演出：略延迟，给正文一点阅读时间
  // 双重保险：① 取消上一次的待触发定时器；② 回调里再校验场景未变，
  // 即使定时器因 HMR/竞态未被清除，也不会把上一个场景的反转弹到新场景
  clearTwistTimer()
  if (s.twist) {
    const twist = s.twist
    const fromScene = id
    twistTimer = window.setTimeout(() => {
      if (sceneId.value === fromScene) {
        twistShow.value = twist
        // 反转专属音效：低频锯齿波，制造不安感（受全局音效开关控制）
        beep(160, 0.22, 'sawtooth')
        window.setTimeout(() => beep(110, 0.3, 'sawtooth'), 120)
      }
      twistTimer = null
    }, 420)
  }
  beep(660, 0.05)
}

function startCase(c) {
  clearTwistTimer()
  activeCase.value = c
  san.value = SAN_MAX
  clues.value = []
  visited.value = []
  currentEnding.value = null
  twistShow.value = null
  phase.value = 'play'
  enterScene(c.start)
  showToast(`${c.code} ${c.title} · 接入开始`, true)
}

/* ---------------- 选项条件 ---------------- */
function meets(ch) {
  const r = ch.requires
  if (!r) return true
  if (r.clue && !clues.value.includes(r.clue)) return false
  if (r.sanMin != null && san.value < r.sanMin) return false
  if (r.sanMax != null && san.value > r.sanMax) return false
  return true
}

function lockReason(ch) {
  const r = ch.requires
  if (!r) return ''
  if (r.clue) return '需真相碎片'
  if (r.sanMin != null) return '需冷静'
  if (r.sanMax != null) return '需失控'
  return ''
}

/* ---------------- 做出选择 ---------------- */
function choose(ch) {
  if (!meets(ch)) return
  beep(700, 0.06)
  const to = ch.to
  const ending = activeCase.value.endings[to]
  if (ending) {
    finish(ending, to)
  } else {
    enterScene(to)
  }
}

function finish(ending, endId) {
  const key = `${activeCase.value.id}:${endId}`
  isNewEnding.value = !unlocked.value.includes(key)
  if (isNewEnding.value) {
    unlocked.value = [...unlocked.value, key]
    persist()
    checkFinale()
  }
  currentEnding.value = { id: endId, ...ending }
  currentEnding.value.gradeInfo = GRADE[ending.grade] || GRADE.normal
  phase.value = 'ending'
  beep(ending.grade === 'true' ? 1040 : 880, 0.16)
}

function replayCase() {
  if (activeCase.value) startCase(activeCase.value)
}

/* ---------------- 图鉴条目 ---------------- */
const galleryCases = computed(() => CASES.map((c) => ({
  ...c,
  endings: Object.entries(c.endings).map(([id, e]) => ({
    id,
    ...e,
    got: isUnlocked(c.id, id),
    gradeInfo: GRADE[e.grade] || GRADE.normal
  }))
})))

const galleryFinale = computed(() => ({
  ...FINALE,
  got: finaleUnlocked.value,
  gradeInfo: GRADE[FINALE.grade]
}))
</script>

<template>
  <div class="page" :style="{ '--case-ac': activeCase?.accent || 'var(--red)' }">
    <HomeNav />

    <main class="wrap">
      <!-- ============ 页头 ============ -->
      <header class="phead">
        <p class="crumbs">
          <button type="button" class="crumb" @click="backHome">首页</button>
          <span class="sep">/</span>
          <span class="cur">异常档案</span>
          <template v-if="phase === 'play' || phase === 'ending'">
            <span class="sep">/</span>
            <span class="cur">{{ activeCase?.code }}</span>
          </template>
        </p>
        <div class="hrow">
          <div>
            <h1 class="title">异常档案 <i>ANOMALY FILES</i></h1>
            <p class="sub">三宗特工怪诞案件 · 27 个结局 · 每一次选择都是一次复制</p>
          </div>
          <div class="hactions">
            <button class="hbtn" type="button" @click="toGallery">
              结局图鉴 <b>{{ allProgress.got }}/{{ allProgress.total }}</b>
            </button>
          </div>
        </div>
        <div class="progress" :title="`已解锁 ${allProgress.got} / ${allProgress.total}`">
          <em :style="{ width: allProgress.pct + '%' }"></em>
        </div>
      </header>

      <!-- ============ 副本选择 ============ -->
      <section v-if="phase === 'select'" class="select">
        <div class="intro">
          <span class="tag">// 任务简报</span>
          <p>
            你是特工 <b>K</b>。三份被封存的档案，记录了你三次"不可能的出任务"。
            病房的门牌比记忆更早，大厦里每一层都有一个你，总部的局长坐在【00】号房间。
            <b>结局由你决定——但真相，藏在那些藏起来的选项里。</b>
          </p>
        </div>

        <div class="cases">
          <article
            v-for="(c, i) in CASES"
            :key="c.id"
            class="case"
            :style="{ '--case-ac': c.accent }"
          >
            <div class="ctop">
              <span class="cno">{{ String(i + 1).padStart(2, '0') }}</span>
              <span class="ccode">{{ c.code }}</span>
              <span class="cthreat">{{ c.threat }}</span>
            </div>
            <h2 class="cname">{{ c.title }} <i>{{ c.en }}</i></h2>
            <p class="ctag">{{ c.tagline }}</p>
            <div class="cmeta">
              <span>{{ Object.keys(c.scenes).length }} 场景</span>
              <span>{{ Object.keys(c.endings).length }} 结局</span>
              <span>{{ Object.values(c.scenes).filter((s) => s.twist).length }} 反转</span>
            </div>
            <div class="cprog">
              <div class="cbar"><em :style="{ width: caseProgress(c).pct + '%' }"></em></div>
              <span>结局 {{ caseProgress(c).got }}/{{ caseProgress(c).total }}</span>
            </div>
            <button class="enter" type="button" @click="startCase(c)">
              <span>接入副本</span>
              <svg width="16" height="16" viewBox="0 0 24 24" fill="none">
                <path d="M5 12h13m-5-5 5 5-5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
            </button>
          </article>
        </div>

        <div v-if="finaleUnlocked" class="finale-card" @click="toGallery">
          <span class="tag">// 终极结局已解锁</span>
          <strong>F-00 · 档案之外</strong>
          <span class="hint">集齐三关真相结局 · 点击查看 →</span>
        </div>
      </section>

      <!-- ============ 剧情进行 ============ -->
      <section v-else-if="phase === 'play' && scene" class="stage" :class="{ 'low-san': lowSan }">
        <div class="gamehud">
          <div class="hud-loc">
            <span class="dot"></span>
            {{ scene.loc }}
            <i>{{ scene.meta }}</i>
          </div>
          <div class="hud-stats">
            <div class="san">
              <span>理智</span>
              <div class="sanbar"><em :style="{ width: san + '%', background: san <= 40 ? 'var(--red)' : '#5fd0a6', boxShadow: '0 0 8px ' + (san <= 40 ? 'var(--red)' : '#5fd0a6') }"></em></div>
              <b :class="{ danger: san <= 40 }">{{ san }}</b>
            </div>
            <div class="clue" :title="`已收集 ${clues.length} 枚真相碎片`">
              <svg width="14" height="14" viewBox="0 0 24 24" fill="none">
                <path d="M12 3 4 7v5c0 5 3.4 8.4 8 9 4.6-.6 8-4 8-9V7l-8-4Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" />
                <path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" />
              </svg>
              {{ clues.length }}
            </div>
          </div>
        </div>

        <div class="story">
          <div class="scan"></div>
          <p
            v-for="(line, i) in scene.lines"
            :key="i"
            class="line"
            :class="{ speech: typeof line === 'object' }"
            :style="{ animationDelay: (i * 0.08) + 's' }"
          >
            <template v-if="typeof line === 'object'">
              <span class="who">{{ line.who }}</span>
              <span class="txt">{{ line.text }}</span>
            </template>
            <template v-else>{{ line }}</template>
          </p>
        </div>

        <div class="choices">
          <p class="choosehint">// 选择你的行动</p>
          <button
            v-for="(ch, i) in scene.choices"
            :key="i"
            type="button"
            class="choice"
            :class="{ locked: !meets(ch) }"
            :disabled="!meets(ch)"
            @click="choose(ch)"
          >
            <span class="idx">{{ String(i + 1).padStart(2, '0') }}</span>
            <span class="ctext">
              {{ ch.text }}
              <em v-if="ch.note">{{ ch.note }}</em>
            </span>
            <span v-if="!meets(ch)" class="lock">{{ lockReason(ch) }} · 未解锁</span>
            <svg v-else class="arrow" width="15" height="15" viewBox="0 0 24 24" fill="none">
              <path d="M5 12h13m-5-5 5 5-5 5" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </button>
        </div>
      </section>

      <!-- ============ 结局 ============ -->
      <section v-else-if="phase === 'ending' && currentEnding" class="ending">
        <div class="ebox" :style="{ '--g': currentEnding.gradeInfo.color }">
          <div class="etop">
            <span class="ecode">{{ currentEnding.code }}</span>
            <span class="egrade">{{ currentEnding.gradeInfo.label }}</span>
            <span v-if="isNewEnding" class="enew">✦ 新解锁</span>
          </div>
          <h2 class="etitle">{{ currentEnding.title }}</h2>
          <div class="ebody">
            <p
              v-for="(line, i) in currentEnding.lines"
              :key="i"
              class="line"
              :class="{ speech: typeof line === 'object' }"
              :style="{ animationDelay: (i * 0.1) + 's' }"
            >
              <template v-if="typeof line === 'object'">
                <span class="who">{{ line.who }}</span>
                <span class="txt">{{ line.text }}</span>
              </template>
              <template v-else>{{ line }}</template>
            </p>
          </div>
          <blockquote class="equote">{{ currentEnding.quote }}</blockquote>
          <p class="eunlock">解锁条件：{{ currentEnding.unlock }}</p>
          <div class="eactions">
            <button class="act primary" type="button" @click="replayCase">重玩本副本</button>
            <button class="act" type="button" @click="toSelect">返回副本选择</button>
            <button class="act" type="button" @click="toGallery">查看结局图鉴</button>
          </div>
        </div>

        <!-- 结局列表速览：引导收集 -->
        <div class="quicklist">
          <p class="qltitle">
            // {{ activeCase.title }} 结局收集
            <b>{{ caseProgress(activeCase).got }}/{{ caseProgress(activeCase).total }}</b>
          </p>
          <div class="qlgrid">
            <span
              v-for="(e, id) in activeCase.endings"
              :key="id"
              class="qlitem"
              :class="{ got: isUnlocked(activeCase.id, id), now: id === currentEnding.id }"
              :title="e.title"
            >{{ isUnlocked(activeCase.id, id) ? e.code : '· · ·' }}</span>
          </div>
        </div>
      </section>

      <!-- ============ 结局图鉴 ============ -->
      <section v-else-if="phase === 'gallery'" class="gallery">
        <div class="gtabs">
          <button
            v-for="c in galleryCases"
            :key="c.id"
            class="gtab"
            :class="{ on: galleryTab === c.id }"
            type="button"
            :style="{ '--case-ac': c.accent }"
            @click="galleryTab = c.id"
          >
            {{ c.code }} {{ c.title }}
            <b>{{ caseProgress(c).got }}/{{ caseProgress(c).total }}</b>
          </button>
          <button
            class="gtab finaletab"
            :class="{ on: galleryTab === 'finale' }"
            type="button"
            @click="galleryTab = 'finale'"
          >
            F-00 档案之外
            <b>{{ finaleUnlocked ? '1/1' : '0/1' }}</b>
          </button>
        </div>

        <template v-if="galleryTab !== 'finale'">
          <div class="ggrid">
            <article
              v-for="e in galleryCases.find((c) => c.id === galleryTab).endings"
              :key="e.id"
              class="gcard"
              :class="{ locked: !e.got }"
              :style="{ '--g': e.gradeInfo.color }"
            >
              <div class="gtop">
                <span class="gcode">{{ e.code }}</span>
                <span class="ggrade">{{ e.got ? e.gradeInfo.label : '未解锁' }}</span>
              </div>
              <h3>{{ e.got ? e.title : '? ? ?' }}</h3>
              <p class="gquote">{{ e.got ? e.quote : '这段结局尚未被记录。' }}</p>
              <p class="ghint">线索：{{ e.unlock }}</p>
            </article>
          </div>
        </template>

        <template v-else>
          <article
            class="gcard finalecard"
            :class="{ locked: !finaleUnlocked }"
            :style="{ '--g': GRADE.true.color }"
          >
            <div class="gtop">
              <span class="gcode">{{ galleryFinale.code }}</span>
              <span class="ggrade">{{ finaleUnlocked ? '真相结局' : '未解锁' }}</span>
            </div>
            <h3>{{ finaleUnlocked ? galleryFinale.title : '? ? ?' }}</h3>
            <div v-if="finaleUnlocked" class="gfinalbody">
              <p v-for="(line, i) in galleryFinale.lines" :key="i" class="line">{{ line }}</p>
              <blockquote class="equote">{{ galleryFinale.quote }}</blockquote>
            </div>
            <template v-else>
              <p class="gquote">三份档案的真相结局，全部集齐后才会显现。</p>
            </template>
            <p class="ghint">解锁：{{ galleryFinale.unlock }}</p>
          </article>
        </template>

        <div class="gfooter">
          <button class="act primary" type="button" @click="toSelect">接入副本</button>
          <button class="act" type="button" @click="backHome">返回首页</button>
        </div>
      </section>
    </main>

    <!-- ============ 反转演出弹层 ============ -->
    <Transition name="twist">
      <div v-if="twistShow" class="twistmask" @click="twistShow = null">
        <div class="twistbox" @click.stop>
          <span class="twbadge">{{ twistShow.label }} // TWIST</span>
          <p class="twtext">{{ twistShow.text }}</p>
          <button class="twbtn" type="button" @click="twistShow = null">继续 ›</button>
        </div>
      </div>
    </Transition>
  </div>
</template>

<style scoped>
.page {
  position: relative;
  min-height: 100vh;
  padding-top: 74px;
}
.wrap {
  position: relative;
  z-index: 2;
  max-width: 1120px;
  margin: 0 auto;
  padding: 34px 26px 70px;
}

/* ---------- 页头 ---------- */
.phead { margin-bottom: 26px; animation: rise .5s cubic-bezier(.2, 1, .3, 1) both; }
@keyframes rise { from { opacity: 0; transform: translateY(12px); } to { opacity: 1; transform: none; } }
.crumbs { display: flex; align-items: center; gap: 8px; margin: 0 0 16px; font-family: var(--mono); font-size: 11px; letter-spacing: 1.4px; color: var(--muted); }
.crumb { border: 0; background: none; color: var(--muted); cursor: pointer; padding: 0; font: inherit; letter-spacing: inherit; }
.crumb:hover { color: var(--red); }
.sep { opacity: .5; }
.cur { color: var(--cream); }
.hrow { display: flex; align-items: flex-end; justify-content: space-between; gap: 20px; }
.title { margin: 0; font-family: var(--disp); font-weight: 700; font-size: 40px; letter-spacing: 2px; line-height: 1; }
.title i { font-family: var(--mono); font-style: normal; font-size: 13px; letter-spacing: 3px; color: var(--red); margin-left: 10px; vertical-align: middle; }
.sub { margin: 10px 0 0; color: var(--muted); font-size: 13px; letter-spacing: .5px; }
.hbtn { display: inline-flex; align-items: center; gap: 8px; padding: 10px 16px; background: rgba(17, 26, 36, .85); border: 1px solid var(--line); color: var(--cream); font-family: var(--disp); font-weight: 700; font-size: 14px; letter-spacing: 1.5px; cursor: pointer; clip-path: polygon(9px 0, 100% 0, calc(100% - 9px) 100%, 0 100%); transition: .2s; }
.hbtn b { font-family: var(--mono); font-size: 11px; color: var(--red); }
.hbtn:hover { border-color: var(--red); box-shadow: 0 0 18px -6px var(--red); }
.progress { margin-top: 18px; height: 3px; background: rgba(236, 232, 225, .12); overflow: hidden; }
.progress em { display: block; height: 100%; background: linear-gradient(90deg, var(--red), #ffd166); box-shadow: 0 0 12px var(--red); transition: width .4s; }

/* ---------- 副本选择 ---------- */
.tag { font-family: var(--mono); font-size: 11px; letter-spacing: 2px; color: var(--red); }
.intro { padding: 18px 22px; margin-bottom: 24px; background: rgba(17, 26, 36, .7); border: 1px solid var(--line); border-left: 3px solid var(--red); }
.intro p { margin: 10px 0 0; color: var(--cream); font-size: 13.5px; line-height: 1.9; }
.intro b { color: var(--red); }
.cases { display: grid; grid-template-columns: repeat(3, 1fr); gap: 18px; }
.case { position: relative; padding: 20px; background: linear-gradient(160deg, rgba(22, 33, 44, .95), rgba(10, 17, 25, .95)); border: 1px solid var(--line); border-top: 2px solid var(--case-ac); clip-path: polygon(0 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%); transition: .25s; overflow: hidden; animation: rise .5s both; }
.case:nth-child(2) { animation-delay: .06s; }
.case:nth-child(3) { animation-delay: .12s; }
.case::after { content: ''; position: absolute; right: -40px; top: -40px; width: 120px; height: 120px; background: radial-gradient(circle, var(--case-ac), transparent 70%); opacity: .12; pointer-events: none; }
.case:hover { transform: translateY(-4px); border-color: var(--case-ac); box-shadow: 0 20px 40px -28px var(--case-ac); }
.ctop { display: flex; align-items: center; gap: 10px; }
.cno { font-family: var(--disp); font-size: 30px; font-weight: 700; color: var(--case-ac); line-height: 1; }
.ccode { font-family: var(--mono); font-size: 10px; letter-spacing: 1.5px; color: var(--muted); }
.cthreat { margin-left: auto; font-family: var(--mono); font-size: 9px; letter-spacing: 1px; color: var(--case-ac); border: 1px solid currentColor; padding: 3px 6px; opacity: .85; }
.cname { margin: 16px 0 0; font-family: var(--disp); font-size: 24px; font-weight: 700; letter-spacing: 1px; }
.cname i { display: block; margin-top: 4px; font-family: var(--mono); font-style: normal; font-size: 10px; letter-spacing: 2px; color: var(--muted); }
.ctag { min-height: 62px; margin: 14px 0; font-size: 12.5px; line-height: 1.7; color: var(--muted); }
.cmeta { display: flex; gap: 12px; padding-bottom: 14px; border-bottom: 1px solid var(--line); font-family: var(--mono); font-size: 10px; letter-spacing: 1px; color: var(--muted); }
.cprog { display: flex; align-items: center; gap: 10px; margin: 14px 0 16px; }
.cbar { flex: 1; height: 3px; background: rgba(236, 232, 225, .12); }
.cbar em { display: block; height: 100%; background: var(--case-ac); transition: width .4s; }
.cprog span { font-family: var(--mono); font-size: 10px; color: var(--muted); white-space: nowrap; }
.enter { width: 100%; display: flex; align-items: center; justify-content: center; gap: 10px; padding: 11px; background: var(--case-ac); border: 0; color: #0a1119; font-family: var(--disp); font-weight: 700; font-size: 15px; letter-spacing: 2px; cursor: pointer; clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%); transition: .2s; }
.enter:hover { filter: brightness(1.15); box-shadow: 0 0 22px -6px var(--case-ac); }
.enter svg { transition: transform .2s; }
.enter:hover svg { transform: translateX(4px); }
.finale-card { display: flex; align-items: center; gap: 18px; margin-top: 20px; padding: 16px 22px; background: rgba(255, 209, 102, .07); border: 1px solid rgba(255, 209, 102, .4); cursor: pointer; }
.finale-card strong { font-family: var(--disp); font-size: 18px; color: #ffd166; }
.finale-card .hint { margin-left: auto; font-family: var(--mono); font-size: 11px; color: var(--muted); }

/* ---------- 剧情 ---------- */
.stage { animation: rise .45s both; }
.gamehud { display: flex; align-items: center; justify-content: space-between; gap: 16px; margin-bottom: 14px; }
.hud-loc { display: flex; align-items: center; gap: 9px; font-family: var(--mono); font-size: 12px; letter-spacing: 1.4px; color: var(--cream); }
.hud-loc .dot { width: 7px; height: 7px; background: var(--case-ac); box-shadow: 0 0 10px var(--case-ac); border-radius: 50%; }
.hud-loc i { font-style: normal; color: var(--muted); font-size: 10px; }
.hud-stats { display: flex; align-items: center; gap: 20px; }
.san { display: flex; align-items: center; gap: 8px; font-family: var(--mono); font-size: 10px; letter-spacing: 1px; color: var(--muted); }
.sanbar { width: 96px; height: 5px; background: rgba(236, 232, 225, .12); }
.sanbar em { display: block; height: 100%; background: #5fd0a6; box-shadow: 0 0 8px #5fd0a6; transition: width .4s, background .3s, box-shadow .3s; }
.san b { color: #5fd0a6; min-width: 22px; }
.san b.danger { color: var(--red); }
.clue { display: flex; align-items: center; gap: 5px; font-family: var(--mono); font-size: 12px; color: #c79bff; }
.story { position: relative; padding: 30px 32px; min-height: 240px; background: linear-gradient(150deg, rgba(22, 33, 44, .92), rgba(10, 17, 25, .92)); border: 1px solid var(--line); border-left: 2px solid var(--case-ac); overflow: hidden; }
.story .scan { position: absolute; inset: 0; pointer-events: none; background: repeating-linear-gradient(to bottom, transparent 0 3px, rgba(0, 0, 0, .1) 3px 4px); opacity: .5; }
.line { position: relative; margin: 0 0 14px; font-size: 14.5px; line-height: 1.9; color: var(--cream); animation: fadein .45s both; }
.line:last-child { margin-bottom: 0; }
@keyframes fadein { from { opacity: 0; transform: translateY(6px); } to { opacity: 1; transform: none; } }
.line.speech { padding-left: 14px; border-left: 2px solid var(--case-ac); }
.line .who { display: block; font-family: var(--mono); font-size: 10px; letter-spacing: 2px; color: var(--case-ac); margin-bottom: 3px; }
.line .txt { font-style: italic; }
.low-san .story { animation: glitch 2.4s infinite; }
.low-san .story::before { content: ''; position: absolute; inset: 0; pointer-events: none; background: linear-gradient(transparent 50%, rgba(255, 70, 85, .05) 50%); background-size: 100% 4px; }
@keyframes glitch { 0%, 92%, 100% { transform: none; filter: none; } 94% { transform: translateX(2px); filter: hue-rotate(20deg); } 96% { transform: translateX(-2px); } 98% { transform: translateX(1px); } }
.choices { margin-top: 22px; display: grid; gap: 10px; }
.choosehint { margin: 0 0 4px; font-family: var(--mono); font-size: 11px; letter-spacing: 2px; color: var(--muted); }
.choice { position: relative; display: flex; align-items: center; gap: 14px; width: 100%; padding: 14px 18px; text-align: left; background: rgba(17, 26, 36, .85); border: 1px solid var(--line); color: var(--cream); cursor: pointer; clip-path: polygon(10px 0, 100% 0, calc(100% - 10px) 100%, 0 100%); transition: .2s; animation: fadein .4s both; }
.choice:hover:not(:disabled) { border-color: var(--case-ac); background: rgba(255, 70, 85, .08); transform: translateX(4px); box-shadow: 0 0 20px -10px var(--case-ac); }
.choice .idx { font-family: var(--mono); font-size: 11px; color: var(--case-ac); }
.choice .ctext { flex: 1; font-size: 14px; font-weight: 600; letter-spacing: .3px; }
.choice .ctext em { display: inline-block; margin-left: 10px; font-family: var(--mono); font-style: normal; font-size: 10px; letter-spacing: 1px; color: var(--muted); border: 1px solid var(--line); padding: 1px 6px; }
.choice .arrow { color: var(--case-ac); }
.choice .lock { font-family: var(--mono); font-size: 10px; letter-spacing: 1px; color: var(--muted); }
.choice.locked { opacity: .45; cursor: not-allowed; border-style: dashed; }

/* ---------- 结局 ---------- */
.ebox { position: relative; padding: 30px 34px; background: linear-gradient(150deg, rgba(22, 33, 44, .95), rgba(10, 17, 25, .95)); border: 1px solid var(--line); border-top: 3px solid var(--g); clip-path: polygon(0 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%); animation: rise .5s both; }
.etop { display: flex; align-items: center; gap: 12px; font-family: var(--mono); font-size: 11px; letter-spacing: 1.5px; }
.ecode { color: var(--g); }
.egrade { color: var(--g); border: 1px solid currentColor; padding: 3px 8px; }
.enew { color: #ffd166; margin-left: auto; }
.etitle { margin: 18px 0 22px; font-family: var(--disp); font-size: 42px; letter-spacing: 3px; color: var(--g); text-shadow: 0 0 30px -8px var(--g); }
.ebody { padding: 20px 0; border-top: 1px solid var(--line); border-bottom: 1px solid var(--line); }
.equote { margin: 22px 0 0; padding-left: 16px; border-left: 3px solid var(--g); font-size: 15px; line-height: 1.8; color: var(--cream); font-style: italic; }
.eunlock { margin: 16px 0 0; font-family: var(--mono); font-size: 11px; color: var(--muted); }
.eactions { display: flex; flex-wrap: wrap; gap: 10px; margin-top: 26px; }
.act { padding: 11px 20px; background: rgba(17, 26, 36, .9); border: 1px solid var(--line); color: var(--cream); font-family: var(--disp); font-weight: 700; font-size: 14px; letter-spacing: 1.6px; cursor: pointer; clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%); transition: .2s; }
.act:hover { border-color: var(--ac); box-shadow: 0 0 18px -8px var(--ac); }
.act.primary { background: var(--ac); border-color: var(--ac); color: #fff; }
.act.primary:hover { filter: brightness(1.12); }
.quicklist { margin-top: 22px; }
.qltitle { font-family: var(--mono); font-size: 11px; letter-spacing: 1.5px; color: var(--muted); }
.qltitle b { color: var(--cream); }
.qlgrid { display: flex; flex-wrap: wrap; gap: 8px; margin-top: 10px; }
.qlitem { min-width: 52px; text-align: center; padding: 8px 10px; font-family: var(--mono); font-size: 11px; color: var(--muted); border: 1px solid var(--line); background: rgba(17, 26, 36, .6); }
.qlitem.got { color: var(--cream); border-color: var(--ac); }
.qlitem.now { background: var(--ac); color: #fff; border-color: var(--ac); }

/* ---------- 图鉴 ---------- */
.gtabs { display: flex; flex-wrap: wrap; gap: 8px; margin-bottom: 22px; }
.gtab { display: flex; align-items: center; gap: 10px; padding: 10px 16px; background: rgba(17, 26, 36, .85); border: 1px solid var(--line); color: var(--muted); font-family: var(--disp); font-size: 14px; letter-spacing: 1px; cursor: pointer; clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%); transition: .2s; }
.gtab b { font-family: var(--mono); font-size: 10px; }
.gtab:hover { color: var(--cream); }
.gtab.on { color: #fff; background: var(--case-ac, var(--ac)); border-color: var(--case-ac, var(--ac)); }
.gtab.finaletab.on { background: #ffd166; border-color: #ffd166; color: #0a1119; }
.ggrid { display: grid; grid-template-columns: repeat(3, 1fr); gap: 14px; }
.gcard { padding: 18px; background: linear-gradient(150deg, rgba(22, 33, 44, .9), rgba(10, 17, 25, .9)); border: 1px solid var(--line); border-left: 2px solid var(--g); animation: rise .4s both; }
.gcard.locked { opacity: .55; border-left-style: dashed; }
.gtop { display: flex; justify-content: space-between; font-family: var(--mono); font-size: 10px; letter-spacing: 1.2px; }
.gcode { color: var(--g); }
.ggrade { color: var(--muted); }
.gcard h3 { margin: 14px 0 10px; font-family: var(--disp); font-size: 20px; letter-spacing: 1px; }
.gquote { margin: 0 0 12px; min-height: 48px; font-size: 12px; line-height: 1.7; color: var(--cream); opacity: .85; }
.ghint { margin: 0; padding-top: 10px; border-top: 1px solid var(--line); font-family: var(--mono); font-size: 10px; line-height: 1.5; color: var(--muted); }
.finalecard { grid-column: 1 / -1; }
.gfinalbody { margin: 16px 0; padding: 16px; background: rgba(255, 209, 102, .05); }
.gfinalbody .line { font-size: 13px; margin-bottom: 8px; }
.gfooter { display: flex; gap: 10px; margin-top: 24px; }

/* ---------- 反转演出 ---------- */
.twistmask { position: fixed; inset: 0; z-index: 80; display: grid; place-items: center; padding: 24px; background: rgba(5, 9, 13, .86); backdrop-filter: blur(6px); }
.twistbox { position: relative; width: min(560px, 100%); padding: 40px; background: linear-gradient(150deg, #16212c, #0a1119); border: 1px solid var(--red); box-shadow: 0 0 60px -20px var(--red); clip-path: polygon(0 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%); animation: twistin .45s cubic-bezier(.2, 1, .3, 1) both; }
.twistbox::before { content: ''; position: absolute; inset: 0; pointer-events: none; background: repeating-linear-gradient(to bottom, transparent 0 3px, rgba(255, 70, 85, .05) 3px 4px); }
@keyframes twistin { from { opacity: 0; transform: scale(.9) rotate(-1deg); } to { opacity: 1; transform: none; } }
.twbadge { font-family: var(--mono); font-size: 12px; letter-spacing: 4px; color: var(--red); }
.twtext { margin: 22px 0 30px; font-size: 18px; line-height: 1.9; color: #fff; font-weight: 600; }
.twbtn { padding: 10px 26px; background: var(--red); border: 0; color: #fff; font-family: var(--disp); font-size: 15px; letter-spacing: 2px; cursor: pointer; clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%); }
.twbtn:hover { filter: brightness(1.15); }
.twist-enter-active, .twist-leave-active { transition: opacity .3s; }
.twist-enter-from, .twist-leave-to { opacity: 0; }

/* ---------- 响应式 ---------- */
@media (max-width: 900px) {
  .cases, .ggrid { grid-template-columns: 1fr; }
  .title { font-size: 30px; }
  .title i { display: block; margin: 6px 0 0; }
  .hrow { flex-direction: column; align-items: flex-start; }
  .story, .ebox { padding: 22px; }
}
</style>
