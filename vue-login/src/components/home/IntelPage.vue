<script setup>
/* ============================================================
   情报中心（可交互）
   取代原先的静态动态流列表：
   - 统计卡：未读 / 已读 / 收藏 / 阅读率
   - 筛选：类型（带计数）× 状态（未读/已读/收藏）+ 排序（最新/热度）+ 关键词
   - 行内操作：标记已读 / 未读、收藏、认可（点赞），全部实时写库
   - 「全部已读」批量操作
   - 点击行 → 详情弹窗（正文、来源、重要度、关联档案跳转）
   数据来源：/api/intel/*（IntelController）
   ============================================================ */
import { computed, onMounted, ref, watch } from 'vue'
import { state, switchView, useSession } from '../../store/session'
import { intelLike, intelList, intelMarkAll, intelRead, intelStar } from '../../store/api'
import HomeNav from './HomeNav.vue'
import IntelDetailModal from './IntelDetailModal.vue'
import { beep } from '../../composables/useSound'

const { showToast } = useSession()

const token = computed(() => state.token || '')

const KINDS = [
  { code: '', label: '全部' },
  { code: 'NEWS', label: '情报' },
  { code: 'PATCH', label: '版本' },
  { code: 'MISSION', label: '任务' }
]
const STATUSES = [
  { code: '', label: '全部' },
  { code: 'UNREAD', label: '未读' },
  { code: 'READ', label: '已读' },
  { code: 'STARRED', label: '收藏' }
]
const SORTS = [
  { code: 'newest', label: '最新' },
  { code: 'heat', label: '热度' }
]

const PAGE_SIZE = 6

const list = ref([])
const total = ref(0)
const pages = ref(0)
const page = ref(1)
const loading = ref(false)
const markingAll = ref(false)

const kind = ref('')
const status = ref('')
const sort = ref('newest')
const query = ref('')

const stats = ref({ total: 0, unread: 0, read: 0, starred: 0, liked: 0, rate: 0, byKind: {} })
const busyId = ref(0)

const detailId = ref(0)

const active = computed(() => !!(query.value.trim() || kind.value || status.value || sort.value !== 'newest'))

const cards = computed(() => [
  { k: 'unread', en: 'UNREAD', label: '未读情报', v: stats.value.unread || 0, tone: 'live' },
  { k: 'read', en: 'READ', label: '已读情报', v: stats.value.read || 0, tone: 'ok' },
  { k: 'starred', en: 'STARRED', label: '收藏夹', v: stats.value.starred || 0, tone: 'warn' },
  { k: 'rate', en: 'PROGRESS', label: '阅读率', v: (stats.value.rate || 0) + '%', tone: 'accent' }
])

async function load(reset = true) {
  if (!token.value) return
  if (reset) page.value = 1
  loading.value = true
  const r = await intelList(token.value, {
    kind: kind.value,
    status: status.value,
    q: query.value.trim(),
    sort: sort.value,
    page: page.value,
    size: PAGE_SIZE
  })
  loading.value = false
  if (r.code !== 0) {
    showToast(`情报加载失败 · ${r.msg || '未知错误'}`, false)
    return
  }
  stats.value = r.data.stats || stats.value
  total.value = r.data.total || 0
  pages.value = r.data.pages || 0
  const rows = r.data.list || []
  list.value = reset ? rows : list.value.concat(rows)
}

function loadMore() {
  if (page.value >= pages.value || loading.value) return
  page.value += 1
  load(false)
}

/* ---------- 行内操作（乐观更新 + 失败回滚） ---------- */
async function toggleRead(row) {
  if (busyId.value === row.id) return
  const next = !row.read
  busyId.value = row.id
  row.read = next
  const r = await intelRead(token.value, row.id, next)
  busyId.value = 0
  if (r.code !== 0) {
    row.read = !next
    showToast(r.msg || '操作失败', false)
    return
  }
  beep(next ? 620 : 380, 0.05)
  syncStats(r.data.stats)
}

async function toggleStar(row) {
  if (busyId.value === row.id) return
  const next = !row.starred
  busyId.value = row.id
  row.starred = next
  if (next) row.read = true
  const r = await intelStar(token.value, row.id)
  busyId.value = 0
  if (r.code !== 0) {
    row.starred = !next
    showToast(r.msg || '操作失败', false)
    return
  }
  beep(next ? 820 : 380, 0.06)
  syncStats(r.data.stats)
}

async function toggleLike(row) {
  if (busyId.value === row.id) return
  const next = !row.liked
  busyId.value = row.id
  row.liked = next
  row.likes = (row.likes || 0) + (next ? 1 : -1)
  const r = await intelLike(token.value, row.id)
  busyId.value = 0
  if (r.code !== 0) {
    row.liked = !next
    row.likes = (row.likes || 0) + (next ? -1 : 1)
    showToast(r.msg || '操作失败', false)
    return
  }
  row.likes = r.data.likes
  beep(next ? 760 : 420, 0.05)
}

function syncStats(s) {
  if (s) stats.value = s
}

async function markAll() {
  if (markingAll.value || !stats.value.unread) return
  markingAll.value = true
  const r = await intelMarkAll(token.value)
  markingAll.value = false
  if (r.code !== 0) {
    showToast(r.msg || '操作失败', false)
    return
  }
  beep(700, 0.08)
  showToast(`已将 ${r.data.changed} 条情报标记为已读`, true)
  syncStats(r.data.stats)
  load(true)
}

/* ---------- 筛选 ---------- */
function pickKind(code) {
  kind.value = kind.value === code ? '' : code
  beep(560, 0.05)
}
function pickStatus(code) {
  status.value = status.value === code ? '' : code
  beep(600, 0.05)
}
function pickSort(code) {
  if (sort.value === code) return
  sort.value = code
  beep(640, 0.05)
}
function resetAll() {
  query.value = ''
  kind.value = ''
  status.value = ''
  sort.value = 'newest'
  beep(420, 0.05)
  load(true)
}

/* ---------- 详情 ---------- */
function openDetail(row) {
  if (!row.read) {
    row.read = true
    stats.value = { ...stats.value, unread: Math.max(0, (stats.value.unread || 0) - 1) }
  }
  detailId.value = row.id
  beep(700, 0.05)
}

/** 弹窗里的操作会改变数据，统一重新拉取保证统计一致 */
function onChanged() {
  const keepPage = page.value
  load(true)
  page.value = keepPage
}

function gotoView(view) {
  detailId.value = 0
  beep(660, 0.06)
  switchView(view)
}

function backHome() {
  beep(520, 0.06)
  switchView('home')
}

/* 关键词防抖，其余立即请求 */
let timer = null
watch(query, () => {
  clearTimeout(timer)
  timer = setTimeout(() => load(true), 320)
})
watch([kind, status, sort], () => load(true))
watch(token, (v) => v && load(true))

onMounted(() => load(true))
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
          <span class="cur">情报中心</span>
        </p>
        <div class="hrow">
          <h1>情报中心<i>INTEL CENTER</i></h1>
          <div class="hact">
            <p class="sub">
              共 <b>{{ stats.total }}</b> 条情报 · 未读 <b>{{ stats.unread }}</b> 条
            </p>
            <button
              class="allread"
              type="button"
              :disabled="markingAll || !stats.unread"
              @click="markAll"
            >
              {{ markingAll ? '处理中…' : '全部标为已读' }}
            </button>
          </div>
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
            placeholder="检索标题、摘要、来源…"
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
            <span class="flab">类型</span>
            <button
              v-for="k in KINDS"
              :key="k.code"
              class="f"
              :class="{ on: kind === k.code }"
              type="button"
              @click="pickKind(k.code)"
            >
              {{ k.label }}
              <i v-if="k.code && stats.byKind">{{ stats.byKind[k.code] || 0 }}</i>
            </button>

            <span class="flab sortlab">排序</span>
            <button
              v-for="s in SORTS"
              :key="s.code"
              class="f"
              :class="{ on: sort === s.code }"
              type="button"
              @click="pickSort(s.code)"
            >
              {{ s.label }}
            </button>
          </div>

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
              {{ s.label }}
              <i v-if="s.code === 'UNREAD' && stats.unread">{{ stats.unread }}</i>
              <i v-else-if="s.code === 'STARRED' && stats.starred">{{ stats.starred }}</i>
            </button>
            <button v-if="active" class="reset" type="button" @click="resetAll">重置</button>
          </div>
        </div>
      </section>

      <!-- ========== 列表 ========== -->
      <section class="list">
        <template v-if="loading && !list.length">
          <div v-for="i in 3" :key="'sk' + i" class="row skel">
            <span class="bl w70"></span>
            <span class="bl w90"></span>
          </div>
        </template>

        <template v-else>
          <article
            v-for="f in list"
            :key="f.id"
            class="row"
            :class="{ unread: !f.read, dim: f.read }"
            role="button"
            tabindex="0"
            @click="openDetail(f)"
            @keydown.enter.prevent="openDetail(f)"
          >
            <span class="bar" :data-kind="f.kind"></span>

            <div class="left">
              <div class="tags">
                <span class="kind" :data-kind="f.kind">{{ f.kindName }}</span>
                <span v-if="f.tag" class="tag">{{ f.tag }}</span>
                <span v-if="f.importance >= 2" class="imp" :data-i="f.importance">
                  {{ f.importanceName }}
                </span>
                <span v-if="!f.read" class="dot">NEW</span>
              </div>
              <h3>{{ f.title }}</h3>
              <p class="sum">{{ f.summary }}</p>
              <p class="src">
                <span v-if="f.source">{{ f.source }}</span>
                <span class="sep">·</span>
                <span>{{ f.publishedAt }}</span>
                <span v-if="f.categoryName" class="cat">关联 {{ f.categoryName }}</span>
              </p>
            </div>

            <div class="acts" @click.stop>
              <button
                class="mini read"
                type="button"
                :class="{ on: f.read }"
                :title="f.read ? '标记为未读' : '标记为已读'"
                :disabled="busyId === f.id"
                @click="toggleRead(f)"
              >
                {{ f.read ? '已读' : '未读' }}
              </button>

              <button
                class="mini star"
                type="button"
                :class="{ on: f.starred }"
                title="收藏"
                :disabled="busyId === f.id"
                @click="toggleStar(f)"
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                  <path d="M12 3.5l2.7 5.6 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1L3.2 10l6.1-.9z"
                    :fill="f.starred ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" />
                </svg>
              </button>

              <button
                class="mini like"
                type="button"
                :class="{ on: f.liked }"
                title="认可"
                :disabled="busyId === f.id"
                @click="toggleLike(f)"
              >
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                  <path d="M12 20s-7-4.35-7-9a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 4.65-7 9-7 9z"
                    :fill="f.liked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" />
                </svg>
                <b>{{ f.likes }}</b>
              </button>
            </div>
          </article>
        </template>

        <div v-if="!loading && !list.length" class="empty">
          <div class="ex">!</div>
          <h4>没有符合条件的情报</h4>
          <p>{{ active ? '换一种类型或状态筛选试试。' : '情报库暂无数据。' }}</p>
        </div>

        <div v-if="!loading && page < pages" class="more">
          <button type="button" @click="loadMore">加载更多 · 共 {{ total }} 条</button>
        </div>
      </section>
    </main>

    <!-- ========== 详情弹窗 ========== -->
    <IntelDetailModal
      v-if="detailId"
      :id="detailId"
      :token="token"
      @close="detailId = 0"
      @changed="onChanged"
      @goto="gotoView"
    />
  </div>
</template>

<style scoped>
.page { min-height: 100vh; display: flex; flex-direction: column; }

.main {
  flex: 1;
  width: 100%;
  max-width: 1080px;
  margin: 0 auto;
  padding: 104px 26px 48px;
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
  display: flex; align-items: baseline; gap: 12px;
  font-family: var(--disp); font-weight: 700;
  font-size: 46px; letter-spacing: 3.4px; text-transform: uppercase;
}
.phead h1 i {
  font-family: var(--mono); font-style: normal;
  font-size: 11px; letter-spacing: 2.4px; color: var(--muted);
}
.hact { display: flex; align-items: center; gap: 14px; }
.sub {
  margin: 0 0 4px;
  font-family: var(--mono); font-size: 11px; letter-spacing: 1.6px; color: var(--muted);
}
.sub b { color: var(--ac); font-size: 13px; }
.allread {
  padding: 8px 16px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--cream);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.4px;
  cursor: pointer;
  clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
  transition: .2s;
}
.allread:hover:not(:disabled) { color: #fff; background: var(--ac); border-color: var(--ac); box-shadow: 0 0 22px -10px var(--ac); }
.allread:disabled { opacity: .4; cursor: not-allowed; }

/* ========== 统计卡 ========== */
.stats {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 12px;
  margin: 18px 0 4px;
  animation: up .45s .04s cubic-bezier(.2, 1, .3, 1) both;
}
.scard {
  position: relative;
  padding: 13px 15px 12px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .9), rgba(14, 23, 33, .94));
  border: 1px solid var(--line);
  clip-path: polygon(11px 0, 100% 0, 100% calc(100% - 11px), calc(100% - 11px) 100%, 0 100%, 0 11px);
  display: grid; gap: 2px;
}
.scard::after {
  content: '';
  position: absolute; left: 0; top: 0; bottom: 0; width: 2px;
  background: var(--muted); opacity: .5;
}
.scard .sk { font-family: var(--mono); font-size: 8.5px; letter-spacing: 1.9px; color: var(--muted); }
.scard b {
  font-family: var(--disp); font-weight: 700; font-size: 27px; letter-spacing: 1px; line-height: 1.15; color: var(--cream);
}
.scard .sl { font-size: 11px; letter-spacing: 1.4px; color: var(--muted); }
.t-live::after { background: var(--ac); opacity: 1; box-shadow: 0 0 14px var(--ac); }
.t-ok::after { background: #3ddc97; opacity: 1; }
.t-warn::after { background: #FFB443; opacity: 1; }
.t-accent b { color: #FFB443; }
.t-accent::after { background: #FFB443; opacity: 1; }

/* ========== 工具行 ========== */
.tools {
  padding: 18px 0 16px;
  display: grid; gap: 12px;
  animation: up .45s .08s cubic-bezier(.2, 1, .3, 1) both;
}
.searchbox {
  display: flex; align-items: center; gap: 11px;
  height: 50px; padding: 0 12px 0 16px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .94), rgba(15, 25, 35, .96));
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
  transition: border-color .2s;
}
.searchbox:focus-within { border-color: var(--ac); }
.prompt { font-family: var(--mono); font-size: 13px; color: var(--ac); user-select: none; }
.ipt {
  flex: 1; min-width: 0; height: 100%;
  border: 0; outline: 0; background: transparent;
  color: var(--cream); font-family: var(--sans); font-size: 15px;
}
.ipt::placeholder { color: var(--muted); }
.clear {
  width: 26px; height: 26px; display: grid; place-items: center;
  border: 1px solid var(--line); background: transparent; color: var(--muted);
  cursor: pointer; transition: .18s;
}
.clear:hover { color: var(--red); border-color: var(--red); }

.rows { display: grid; gap: 9px; }
.frow { display: flex; align-items: center; gap: 7px; flex-wrap: wrap; }
.flab {
  width: 34px; flex-shrink: 0;
  font-family: var(--mono); font-size: 10px; letter-spacing: 2px; color: var(--muted);
}
.sortlab { margin-left: 12px; width: auto; }
.f {
  display: inline-flex; align-items: center; gap: 5px;
  border: 1px solid var(--line); background: transparent; color: var(--muted);
  font-family: var(--mono); font-size: 10.5px; letter-spacing: 1px;
  padding: 5px 10px; cursor: pointer; transition: .18s;
}
.f i { font-style: normal; font-size: 9px; opacity: .65; }
.f:hover { color: var(--cream); border-color: rgba(236, 232, 225, .38); }
.f.on { color: #fff; background: var(--ac); border-color: var(--ac); box-shadow: 0 0 18px -8px var(--ac); }
.f.on i { opacity: .9; }
.reset {
  margin-left: 4px; border: 1px dashed var(--line); background: transparent;
  color: var(--muted); font-family: var(--mono); font-size: 10px;
  letter-spacing: 1px; padding: 5px 10px; cursor: pointer; transition: .18s;
}
.reset:hover { color: var(--red); border-color: var(--red); }

/* ========== 列表 ========== */
.list {
  display: grid; gap: 12px;
  animation: up .45s .12s cubic-bezier(.2, 1, .3, 1) both;
}
.row {
  position: relative;
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 18px;
  align-items: center;
  padding: 16px 20px 16px 26px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .9), rgba(15, 25, 35, .93));
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
  cursor: pointer;
  transition: .22s;
}
.row:hover {
  border-color: var(--ac);
  box-shadow: 0 0 30px -16px var(--ac);
  transform: translateX(4px);
}
.row:focus-visible { outline: 2px solid var(--ac); outline-offset: 2px; }
.row.dim { opacity: .68; }
.row.dim:hover { opacity: 1; }

.bar {
  position: absolute;
  left: 0; top: 0; bottom: 0; width: 3px;
  background: var(--ac); opacity: .55;
}
.bar[data-kind="PATCH"] { background: #00E0C6; }
.bar[data-kind="MISSION"] { background: #FFB443; }
.row.unread .bar { opacity: 1; box-shadow: 0 0 14px currentColor; }

.left { min-width: 0; }
.tags { display: flex; align-items: center; gap: 6px; flex-wrap: wrap; margin-bottom: 7px; }
.kind, .tag, .imp, .dot {
  font-family: var(--mono); font-size: 9px; letter-spacing: 1.6px;
  padding: 3px 8px; border: 1px solid var(--line); color: var(--muted);
}
.kind[data-kind="PATCH"] { color: #00E0C6; border-color: rgba(0, 224, 198, .5); }
.kind[data-kind="MISSION"] { color: #FFB443; border-color: rgba(255, 180, 67, .5); }
.kind[data-kind="NEWS"] { color: var(--ac); border-color: rgba(255, 70, 85, .5); }
.tag { color: var(--cream); }
.imp[data-i="3"] { color: #fff; background: var(--red); border-color: var(--red); animation: blink 1.1s steps(2) infinite; }
.imp[data-i="2"] { color: #FFB443; border-color: rgba(255, 180, 67, .55); }
@keyframes blink { 50% { opacity: .5; } }
.dot { color: #0F1923; background: var(--ac); border-color: var(--ac); font-weight: 700; }

h3 {
  margin: 0 0 5px;
  font-family: var(--disp); font-weight: 700; font-size: 19px; letter-spacing: 1.6px; color: var(--cream);
}
.sum {
  margin: 0 0 7px;
  font-size: 12.8px; line-height: 1.65; color: var(--muted);
  display: -webkit-box; -webkit-line-clamp: 2; -webkit-box-orient: vertical; overflow: hidden;
}
.src {
  margin: 0;
  font-family: var(--mono); font-size: 9.5px; letter-spacing: 1.2px; color: var(--muted);
  display: flex; gap: 7px; flex-wrap: wrap;
}
.src .sep { opacity: .5; }
.src .cat { color: var(--ac); }

/* 行内操作 */
.acts { display: flex; gap: 7px; align-items: center; }
.mini {
  display: inline-flex; align-items: center; gap: 5px;
  border: 1px solid var(--line); background: transparent; color: var(--muted);
  font-family: var(--mono); font-size: 9.5px; letter-spacing: 1.2px;
  padding: 6px 9px; cursor: pointer; transition: .18s;
}
.mini b { font-weight: 700; }
.mini:hover:not(:disabled) { color: var(--cream); border-color: rgba(236, 232, 225, .4); }
.mini:disabled { opacity: .5; cursor: not-allowed; }
.mini.read.on { color: #3ddc97; border-color: rgba(61, 220, 151, .5); }
.mini.star.on { color: #FFB443; border-color: #FFB443; background: rgba(255, 180, 67, .12); }
.mini.like.on { color: var(--red); border-color: var(--red); background: rgba(255, 70, 85, .12); }

/* ========== 骨架 / 空态 / 更多 ========== */
.skel { pointer-events: none; }
.skel .bl {
  display: block; height: 12px; margin-bottom: 10px;
  background: linear-gradient(90deg, rgba(236, 232, 225, .06), rgba(236, 232, 225, .13), rgba(236, 232, 225, .06));
  background-size: 220% 100%;
  animation: sweep 1.3s linear infinite;
}
.skel .w70 { width: 70%; }
.skel .w90 { width: 90%; }
@keyframes sweep {
  from { background-position: 120% 0; }
  to { background-position: -120% 0; }
}

.empty { text-align: center; padding: 52px 20px; border: 1px dashed var(--line); background: rgba(17, 26, 36, .5); }
.ex {
  width: 46px; height: 46px; margin: 0 auto 14px;
  display: grid; place-items: center;
  font-family: var(--disp); font-weight: 700; font-size: 24px;
  color: var(--red); border: 1px solid var(--red);
  transform: skewX(-10deg); box-shadow: 0 0 26px -8px var(--red);
}
.empty h4 { margin: 0 0 6px; font-family: var(--disp); font-weight: 700; font-size: 19px; letter-spacing: 2px; }
.empty p { margin: 0; font-size: 12.5px; color: var(--muted); }

.more { display: flex; justify-content: center; margin-top: 24px; }
.more button {
  padding: 12px 30px; border: 1px solid var(--line); background: transparent;
  color: var(--cream); font-family: var(--disp); font-weight: 700;
  font-size: 14px; letter-spacing: 2.4px; cursor: pointer;
  clip-path: polygon(11px 0, 100% 0, calc(100% - 11px) 100%, 0 100%); transition: .2s;
}
.more button:hover {
  color: #fff; background: var(--ac); border-color: var(--ac); box-shadow: 0 0 28px -10px var(--ac);
}

/* ========== 响应式 ========== */
@media (max-width: 860px) {
  .main { padding: 96px 18px 36px; }
  .phead h1 { font-size: 34px; letter-spacing: 2.4px; }
  .stats { grid-template-columns: repeat(2, 1fr); }
}
@media (max-width: 640px) {
  .row { grid-template-columns: 1fr; gap: 12px; }
  .acts { justify-content: flex-start; }
  .phead h1 { font-size: 27px; }
  .phead h1 i { display: none; }
}
</style>
