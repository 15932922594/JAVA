<script setup>
/* ============================================================
   作战任务页（OPERATIONS）—— 可交互任务作战台
   取代原先复用 ArchivePage 的静态地图档案列表：
   - 四块统计卡：进行中 / 待结算 / 已完成 / 特工积分
   - 状态 / 细分 / 分级 / 关键词筛选（服务端过滤）
   - 任务卡片倒计时（每秒刷新）
   - 点击卡片打开简报弹窗：勾选目标、接取、放弃、结算
   数据来源：/api/mission/list 等（MissionController）
   ============================================================ */
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { state, switchView, useSession } from '../../store/session'
import { missionAccept, missionList } from '../../store/api'
import HomeNav from './HomeNav.vue'
import MissionCard from './MissionCard.vue'
import MissionDetailModal from './MissionDetailModal.vue'
import { beep } from '../../composables/useSound'

const { showToast } = useSession()

const token = computed(() => state.token || '')

/** 状态筛选（与后端 status 字段一致） */
const STATUSES = [
  { code: 'ALL', name: '全部' },
  { code: 'IDLE', name: '待接取' },
  { code: 'ACTIVE', name: '执行中' },
  { code: 'READY', name: '待结算' },
  { code: 'DONE', name: '已完成' }
]
const TIERS = ['S', 'A', 'B']

const loading = ref(false)
const query = ref('')
const status = ref('ALL')
const sub = ref('')
const tier = ref('')

const stats = ref({ total: 0, active: 0, ready: 0, done: 0, points: 0, rate: 0, rewardTotal: 0 })
const subs = ref([])
const list = ref([])
const total = ref(0)

/** 每秒推进的时间戳，驱动卡片倒计时 */
const now = ref(Date.now())
let ticker = null

const detailCode = ref('')

const active = computed(() => !!(query.value.trim() || sub.value || tier.value || status.value !== 'ALL'))

/** 统计卡数据 */
const cards = computed(() => [
  { k: 'active', label: '执行中', en: 'ACTIVE', v: stats.value.active || 0, tone: 'live' },
  { k: 'ready', label: '待结算', en: 'READY', v: stats.value.ready || 0, tone: 'warn' },
  { k: 'done', label: '已完成', en: 'CLEARED', v: stats.value.done || 0, tone: 'ok' },
  { k: 'points', label: '特工积分', en: 'POINTS', v: stats.value.points || 0, tone: 'accent' }
])

async function load() {
  if (!token.value) return
  loading.value = true
  const r = await missionList(token.value, {
    status: status.value === 'ALL' ? '' : status.value,
    q: query.value.trim(),
    sub: sub.value,
    tier: tier.value
  })
  loading.value = false
  if (r.code !== 0) {
    showToast(`任务列表加载失败 · ${r.msg || '未知错误'}`, false)
    return
  }
  stats.value = r.data.stats || stats.value
  subs.value = r.data.subs || []
  list.value = r.data.list || []
  total.value = r.data.total || 0
}

/* 关键词防抖，其余筛选立即请求 */
let timer = null
watch(query, () => {
  clearTimeout(timer)
  timer = setTimeout(load, 320)
})
watch([status, sub, tier], load)
watch(token, (v) => v && load())

/* ---------- 交互 ---------- */
function pickStatus(code) {
  if (status.value === code) return
  status.value = code
  beep(560, 0.05)
}

function pickSub(code) {
  sub.value = sub.value === code ? '' : code
  beep(600, 0.05)
}

function pickTier(t) {
  tier.value = tier.value === t ? '' : t
  beep(640, 0.05)
}

function resetAll() {
  query.value = ''
  status.value = 'ALL'
  sub.value = ''
  tier.value = ''
  beep(420, 0.05)
  load()
}

function openDetail(code) {
  detailCode.value = code
  beep(700, 0.05)
}

/** 卡片上的快捷「接取」 */
async function accept(code) {
  const item = list.value.find((m) => m.code === code)
  const r = await missionAccept(token.value, code)
  if (r.code !== 0) {
    showToast(r.msg || '接取失败', false)
    return
  }
  beep(680, 0.08)
  showToast(`任务已接取 · ${item?.name || code}`, true)
  await load()
  // 接取后直接展开简报，方便继续勾目标
  detailCode.value = code
}

/** 弹窗内动作完成后刷新列表与统计 */
function onChanged() {
  load()
}

/** 当前打开的任务对象（列表刷新后自动指向新对象） */
const detailMission = computed(() => list.value.find((m) => m.code === detailCode.value) || null)

function backHome() {
  beep(520, 0.06)
  switchView('home')
}

onMounted(() => {
  load()
  ticker = setInterval(() => {
    now.value = Date.now()
  }, 1000)
})

onBeforeUnmount(() => clearInterval(ticker))
</script>

<template>
  <div class="page">
    <HomeNav />

    <main class="main">
      <!-- ========== 页头 ========== -->
      <header class="phead">
        <p class="crumbs">
          <button type="button" class="crumb" @click="backHome">首页</button>
          <span class="sep">/</span>
          <span class="cur">作战任务</span>
        </p>
        <div class="hrow">
          <h1>作战任务<i>OPERATIONS</i></h1>
          <p class="sub">
            共 <b>{{ stats.total }}</b> 项行动 · 完成率 <b>{{ stats.rate }}%</b>
            <span v-if="stats.rewardTotal"> · 可获积分上限 {{ stats.rewardTotal }}</span>
          </p>
        </div>
      </header>

      <!-- ========== 统计卡 ========== -->
      <section class="stats">
        <div v-for="c in cards" :key="c.k" class="scard" :class="'t-' + c.tone">
          <span class="sk">{{ c.en }}</span>
          <b>{{ c.v }}</b>
          <span class="sl">{{ c.label }}</span>
        </div>
      </section>

      <!-- ========== 工具行 ========== -->
      <section class="tools">
        <div class="searchbox">
          <span class="prompt">//</span>
          <input
            v-model="query"
            class="ipt"
            type="text"
            placeholder="检索任务名称、代号、区域…"
            autocomplete="off"
            spellcheck="false"
          />
          <button v-if="query" class="clear" type="button" aria-label="清空" @click="query = ''">
            <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
              <path d="M6 6l12 12M18 6 6 18" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" />
            </svg>
          </button>
        </div>

        <div class="rows">
          <div class="frow">
            <span class="flab">状态</span>
            <button
              v-for="s in STATUSES"
              :key="s.code"
              class="f"
              :class="{ on: status === s.code }"
              type="button"
              @click="pickStatus(s.code)"
            >
              {{ s.name }}
              <i v-if="s.code === 'ACTIVE' && stats.active">{{ stats.active }}</i>
              <i v-else-if="s.code === 'READY' && stats.ready">{{ stats.ready }}</i>
              <i v-else-if="s.code === 'DONE' && stats.done">{{ stats.done }}</i>
            </button>
          </div>

          <div class="frow" v-if="subs.length">
            <span class="flab">细分</span>
            <button
              v-for="s in subs"
              :key="s.code"
              class="f"
              :class="{ on: sub === s.code }"
              type="button"
              @click="pickSub(s.code)"
            >
              {{ s.name }}<i>{{ s.done }}/{{ s.count }}</i>
            </button>
          </div>

          <div class="frow">
            <span class="flab">分级</span>
            <button
              v-for="t in TIERS"
              :key="t"
              class="f tier"
              :class="{ on: tier === t }"
              type="button"
              @click="pickTier(t)"
            >
              {{ t }}
            </button>
            <button v-if="active" class="reset" type="button" @click="resetAll">重置</button>
          </div>
        </div>
      </section>

      <!-- ========== 任务网格 ========== -->
      <section class="grid-wrap">
        <div v-if="loading && !list.length" class="grid">
          <div v-for="i in 4" :key="'sk' + i" class="skel"></div>
        </div>

        <div v-else-if="list.length" class="grid">
          <MissionCard
            v-for="m in list"
            :key="m.code"
            :mission="m"
            :now="now"
            @open="openDetail"
            @accept="accept"
          />
        </div>

        <div v-else class="empty">
          <div class="ex">!</div>
          <h4>没有符合条件的任务</h4>
          <p>{{ active ? '换个状态或关键词试试，或点「重置」查看全部任务。' : '任务库暂无数据。' }}</p>
        </div>

        <p v-if="list.length" class="count">
          当前显示 {{ list.length }} / {{ total }} 项任务
        </p>
      </section>
    </main>

    <!-- ========== 任务简报弹窗 ========== -->
    <MissionDetailModal
      v-if="detailMission"
      :key="detailMission.code"
      :mission="detailMission"
      :token="token"
      @close="detailCode = ''"
      @changed="onChanged"
    />
  </div>
</template>

<style scoped>
.page { min-height: 100vh; display: flex; flex-direction: column; }

.main {
  flex: 1;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 104px 26px 54px;
}

/* ========== 页头 ========== */
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
  border: 0;
  background: transparent;
  padding: 0;
  color: var(--muted);
  cursor: pointer;
  font: inherit;
  letter-spacing: inherit;
  transition: .18s;
}
.crumb:hover { color: var(--ac); }
.sep { opacity: .5; }
.cur { color: var(--cream); }

.hrow { display: flex; align-items: flex-end; justify-content: space-between; gap: 18px; flex-wrap: wrap; }
.phead h1 {
  margin: 0;
  display: flex;
  align-items: baseline;
  gap: 12px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 46px;
  letter-spacing: 3.4px;
  text-transform: uppercase;
}
.phead h1 i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 11px;
  letter-spacing: 2.4px;
  color: var(--muted);
}
.sub {
  margin: 0 0 6px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.sub b { color: var(--ac); font-size: 13px; }

/* ========== 统计卡 ========== */
.stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin: 20px 0 4px;
  animation: up .45s .04s cubic-bezier(.2, 1, .3, 1) both;
}
.scard {
  position: relative;
  padding: 13px 15px 12px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .9), rgba(14, 23, 33, .94));
  border: 1px solid var(--line);
  clip-path: polygon(11px 0, 100% 0, 100% calc(100% - 11px), calc(100% - 11px) 100%, 0 100%, 0 11px);
  display: grid;
  gap: 2px;
}
.scard::after {
  content: '';
  position: absolute;
  left: 0; top: 0; bottom: 0;
  width: 2px;
  background: var(--muted);
  opacity: .5;
}
.scard .sk {
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 1.9px;
  color: var(--muted);
}
.scard b {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 27px;
  letter-spacing: 1px;
  line-height: 1.15;
  color: var(--cream);
}
.scard .sl {
  font-size: 11px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.t-live::after { background: var(--ac); opacity: 1; box-shadow: 0 0 14px var(--ac); }
.t-warn::after { background: #FFB443; opacity: 1; }
.t-ok::after { background: #3ddc97; opacity: 1; }
.t-accent b { color: #FFB443; }
.t-accent::after { background: #FFB443; opacity: 1; }

/* ========== 工具行 ========== */
.tools {
  padding: 18px 0 16px;
  display: grid;
  gap: 12px;
  animation: up .45s .08s cubic-bezier(.2, 1, .3, 1) both;
}
.searchbox {
  display: flex;
  align-items: center;
  gap: 11px;
  height: 50px;
  padding: 0 12px 0 16px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .94), rgba(15, 25, 35, .96));
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
  transition: border-color .2s;
}
.searchbox:focus-within { border-color: var(--ac); }
.prompt { font-family: var(--mono); font-size: 13px; color: var(--ac); user-select: none; }
.ipt {
  flex: 1;
  min-width: 0;
  height: 100%;
  border: 0;
  outline: 0;
  background: transparent;
  color: var(--cream);
  font-family: var(--sans);
  font-size: 15px;
}
.ipt::placeholder { color: var(--muted); }
.clear {
  width: 26px; height: 26px;
  display: grid; place-items: center;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  transition: .18s;
}
.clear:hover { color: var(--red); border-color: var(--red); }

.rows { display: grid; gap: 9px; }
.frow { display: flex; align-items: center; gap: 7px; flex-wrap: wrap; }
.flab {
  width: 34px;
  flex-shrink: 0;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--muted);
}
.f {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1px;
  padding: 5px 10px;
  cursor: pointer;
  transition: .18s;
}
.f i { font-style: normal; font-size: 9px; opacity: .65; }
.f:hover { color: var(--cream); border-color: rgba(236, 232, 225, .38); }
.f.on { color: #fff; background: var(--ac); border-color: var(--ac); box-shadow: 0 0 18px -8px var(--ac); }
.f.on i { opacity: .9; }
.f.tier { min-width: 38px; justify-content: center; }

.reset {
  margin-left: 4px;
  border: 1px dashed var(--line);
  background: transparent;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1px;
  padding: 5px 10px;
  cursor: pointer;
  transition: .18s;
}
.reset:hover { color: var(--red); border-color: var(--red); }

/* ========== 网格 ========== */
.grid-wrap { animation: up .45s .12s cubic-bezier(.2, 1, .3, 1) both; }
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(330px, 1fr));
  gap: 16px;
}
.skel {
  height: 236px;
  background: linear-gradient(100deg, rgba(236, 232, 225, .04) 30%, rgba(236, 232, 225, .09) 50%, rgba(236, 232, 225, .04) 70%);
  background-size: 220% 100%;
  border: 1px solid var(--line);
  animation: shine 1.2s linear infinite;
}
@keyframes shine { to { background-position: -120% 0; } }

.count {
  margin: 16px 0 0;
  text-align: right;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.4px;
  color: var(--muted);
}

.empty {
  display: grid;
  place-items: center;
  gap: 8px;
  padding: 66px 20px;
  border: 1px dashed var(--line);
  text-align: center;
}
.empty .ex {
  width: 38px; height: 38px;
  display: grid; place-items: center;
  border: 1px solid var(--red);
  color: var(--red);
  font-family: var(--disp);
  font-size: 20px;
}
.empty h4 {
  margin: 4px 0 0;
  font-family: var(--disp);
  font-size: 18px;
  letter-spacing: 2px;
  color: var(--cream);
}
.empty p { margin: 0; font-size: 12px; color: var(--muted); }

/* ========== 响应式 ========== */
@media (max-width: 900px) {
  .main { padding: 96px 18px 40px; }
  .phead h1 { font-size: 34px; letter-spacing: 2.4px; }
  .stats { grid-template-columns: repeat(2, 1fr); }
  .grid { grid-template-columns: 1fr; }
}
@media (max-width: 560px) {
  .phead h1 { font-size: 27px; }
  .phead h1 i { display: none; }
}
</style>
