<script setup>
/* ============================================================
   首页（登录后落地页）
   组成：导航栏 + 战报头图区 + 搜索栏（含分级分类筛选）+ 档案网格 + 情报动态
   数据来源：后端 /api/home/*（见 src/store/api.js）
   数据表：archive_category / agent_archive / home_feed
   ============================================================ */
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { state, currentAgent, agentLevel, useSession } from '../../store/session'
import { search, homeCategories, homeOverview, homeFeed } from '../../store/api'
import HomeNav from './HomeNav.vue'
import HomeSearch from './HomeSearch.vue'
import AgentArchive from './AgentArchive.vue'
import AgentDetailModal from './AgentDetailModal.vue'

const { showToast } = useSession()

/** 每页条数 */
const PAGE_SIZE = 12
/** 热门检索词（含中文分类名，用于验证分类反查） */
const HOT = ['突击', '控场', '步枪', '狙击', '竞技', 'VECTOR']

/* ---------- 检索状态 ---------- */
const query = ref('')
const filter = reactive({ category: '', subCategory: '', tier: '' })
const list = ref([])
const total = ref(0)
const pages = ref(0)
const page = ref(1)
const loading = ref(false)

/* ---------- 首页展示数据 ---------- */
const categories = ref([])
const overview = ref(null)
const feeds = ref([])

const token = computed(() => state.token || '')

/** 是否处于搜索 / 筛选状态（决定空态文案） */
const active = computed(
  () => !!(query.value.trim() || filter.category || filter.subCategory || filter.tier)
)

/** 检索：reset=true 重新加载第一页，false 为「加载更多」追加 */
async function runSearch(reset = true) {
  if (!token.value) return
  if (reset) page.value = 1
  loading.value = true
  const r = await search(token.value, {
    q: query.value.trim(),
    category: filter.category,
    subCategory: filter.subCategory,
    tier: filter.tier,
    page: page.value,
    size: PAGE_SIZE
  })
  loading.value = false
  if (r.code !== 0) {
    showToast(`档案检索失败 · ${r.msg || '未知错误'}`, false)
    return
  }
  list.value = reset ? r.data.list : list.value.concat(r.data.list)
  total.value = r.data.total
  pages.value = r.data.pages
}

function loadMore() {
  if (page.value >= pages.value || loading.value) return
  page.value += 1
  runSearch(false)
}

function onSubmit(k) {
  if (!k && !filter.category && !filter.subCategory && !filter.tier) {
    showToast('请输入检索关键词或选择分类', false)
    return
  }
  runSearch(true).then(() => {
    showToast(total.value ? `检索完成 · 命中 ${total.value} 条档案` : '未检索到匹配档案', total.value > 0)
  })
}

/* 关键词防抖 350ms；分类 / 分级变化立即检索 */
let timer = null
watch(query, () => {
  clearTimeout(timer)
  timer = setTimeout(() => runSearch(true), 350)
})
watch(filter, () => runSearch(true))
watch(token, (v) => {
  if (v) runSearch(true)
})

/* ---------- 战报头图区数据 ---------- */
const today = computed(() => {
  const d = new Date()
  const p = (n) => String(n).padStart(2, '0')
  return `${d.getFullYear()}-${p(d.getMonth() + 1)}-${p(d.getDate())}`
})

/** 在线设备数（来自后端 /api/auth/sessions） */
const devices = computed(() => state.sessions.length)

/** 当前会话到期时间 */
const expires = computed(() => {
  const s = state.sessions.find((x) => x.current) || state.sessions[0]
  return s?.expiresAt ? String(s.expiresAt).slice(0, 10) : '—'
})

const STATS = computed(() => [
  { label: '当前特工', value: currentAgent.value.name, sub: currentAgent.value.role },
  { label: '特工等级', value: `LV.${agentLevel.value}`, sub: 'ACCESS CLEARANCE' },
  { label: '在线设备', value: String(devices.value), sub: 'ACTIVE SESSIONS' },
  { label: '凭证有效期', value: expires.value, sub: 'TOKEN EXPIRES' }
])

/** 档案库统计条（来自 /api/home/overview） */
const META = computed(() => {
  const o = overview.value
  if (!o) return []
  const t = o.tierCount || {}
  return [
    { label: '档案总数', value: o.archiveTotal },
    { label: '一级分类', value: o.categoryTotal },
    { label: '精选档案', value: o.featuredTotal },
    { label: '分级 S/A/B', value: `${t.S ?? 0}/${t.A ?? 0}/${t.B ?? 0}` }
  ]
})

/* ---------- 档案详情弹窗 ---------- */
/** 当前打开的档案代号，空串表示关闭 */
const detailCode = ref('')

function openDetail(code) {
  if (!code) return
  detailCode.value = code
}

/* ---------- 初始化：目录 + 概览 + 动态 + 首次检索 ---------- */
onMounted(async () => {
  if (!token.value) return
  const [c, o, f] = await Promise.all([
    homeCategories(token.value),
    homeOverview(token.value),
    homeFeed(token.value, 1, 5)
  ])
  if (c.code === 0) categories.value = c.data || []
  if (o.code === 0) overview.value = o.data
  if (f.code === 0) feeds.value = f.data?.list || []
  await runSearch(true)
})
</script>

<template>
  <div class="home">
    <HomeNav />

    <main class="main">
      <!-- ========== 战报头图区 ========== -->
      <section class="hero">
        <div class="hleft">
          <p class="eyebrow">
            <span class="dot"></span>
            SESSION AUTHORIZED · {{ today }}
          </p>
          <h1>
            特工<span class="hl">终端</span>
          </h1>
          <p class="sub">
            欢迎回来，<b>{{ state.user?.name || '未知' }}</b> 特工 ——
            当前接入 <b>{{ currentAgent.name }}</b>（{{ currentAgent.role }}）。
          </p>
        </div>

        <div class="hright">
          <div v-for="s in STATS" :key="s.label" class="tile">
            <span class="tlab">{{ s.label }}</span>
            <span class="tval">{{ s.value }}</span>
            <span class="tsub">{{ s.sub }}</span>
          </div>
        </div>
      </section>

      <!-- ========== 搜索栏（含分级分类筛选） ========== -->
      <section class="searchsec">
        <HomeSearch
          v-model="query"
          v-model:category="filter.category"
          v-model:subCategory="filter.subCategory"
          v-model:tier="filter.tier"
          :result="list.length"
          :total="total"
          :hot="HOT"
          :categories="categories"
          :loading="loading"
          @submit="onSubmit"
        />
      </section>

      <!-- ========== 档案库 ========== -->
      <section class="archive">
        <div class="sechead">
          <h2>档案库</h2>
          <span class="secsub">ARCHIVE</span>
          <span class="line"></span>
          <span class="secnum">{{ list.length }} / {{ total }}</span>
        </div>

        <div v-if="META.length" class="metarow">
          <span v-for="m in META" :key="m.label" class="mi">
            {{ m.label }}<b>{{ m.value }}</b>
          </span>
        </div>

        <AgentArchive
          :agents="list"
          :query="query.trim()"
          :loading="loading"
          :filtered="active"
          @open="openDetail"
        />

        <div v-if="!loading && page < pages" class="more">
          <button type="button" @click="loadMore">
            加载更多 · 剩余 {{ total - list.length }} 条
          </button>
        </div>
      </section>

      <!-- ========== 情报动态 ========== -->
      <section v-if="feeds.length" class="feed">
        <div class="sechead">
          <h2>情报动态</h2>
          <span class="secsub">INTEL FEED</span>
          <span class="line"></span>
        </div>
        <ul class="flist">
          <li v-for="f in feeds" :key="f.id">
            <span class="fkind">{{ f.tag || f.kind }}</span>
            <div class="fmain">
              <h4>{{ f.title }}</h4>
              <p>{{ f.summary }}</p>
            </div>
            <span class="ftime">{{ String(f.publishedAt).slice(0, 10) }}</span>
          </li>
        </ul>
      </section>
    </main>

    <footer class="foot">
      <span>AGENT ACCESS // TACTICAL TERMINAL v1.0</span>
      <span class="sp"></span>
      <span>SYS <b>OK</b> · 数据源 agent_archive · /api/home</span>
    </footer>

    <!-- ========== 档案详情（点击卡片打开：介绍 + 人物故事） ========== -->
    <AgentDetailModal
      v-if="detailCode"
      :code="detailCode"
      :token="token"
      @close="detailCode = ''"
    />
  </div>
</template>

<style scoped>
.home { min-height: 100vh; display: flex; flex-direction: column; }

.main {
  flex: 1;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 104px 26px 40px;
}

/* ========== 战报头图区 ========== */
.hero {
  display: grid;
  grid-template-columns: 1fr auto;
  gap: 34px;
  align-items: end;
  padding-bottom: 30px;
  border-bottom: 1px solid var(--line);
  animation: up .5s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes up {
  from { opacity: 0; transform: translateY(16px); }
  to { opacity: 1; transform: none; }
}

.eyebrow {
  display: flex;
  align-items: center;
  gap: 9px;
  margin: 0 0 12px;
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 2.4px;
  color: var(--muted);
}
.dot {
  width: 7px;
  height: 7px;
  background: #3ddc97;
  box-shadow: 0 0 12px 1px #3ddc97;
  animation: pulse 1.8s ease-in-out infinite;
}
@keyframes pulse {
  0%, 100% { opacity: 1; }
  50% { opacity: .35; }
}

.hleft h1 {
  margin: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 58px;
  line-height: .98;
  letter-spacing: 4px;
  text-transform: uppercase;
}
.hleft h1 .hl { color: var(--ac); }
.sub {
  margin: 12px 0 0;
  font-size: 13.5px;
  color: var(--muted);
  line-height: 1.7;
}
.sub b { color: var(--cream); }

.hright {
  display: grid;
  grid-template-columns: repeat(2, 158px);
  gap: 12px;
}
.tile {
  padding: 13px 15px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .9), rgba(15, 25, 35, .92));
  border: 1px solid var(--line);
  clip-path: polygon(11px 0, 100% 0, 100% calc(100% - 11px), calc(100% - 11px) 100%, 0 100%, 0 11px);
  transition: .24s;
}
.tile:hover { border-color: var(--ac); box-shadow: 0 0 26px -12px var(--ac); }
.tlab {
  display: block;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.8px;
  color: var(--muted);
}
.tval {
  display: block;
  margin: 5px 0 3px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 24px;
  letter-spacing: 1.6px;
  color: var(--cream);
  text-transform: uppercase;
}
.tsub {
  display: block;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.4px;
  color: var(--muted);
  opacity: .8;
}

/* ========== 搜索区 ========== */
.searchsec {
  padding: 30px 0 8px;
  animation: up .5s .06s cubic-bezier(.2, 1, .3, 1) both;
}

/* ========== 档案区 ========== */
.archive {
  padding-top: 26px;
  animation: up .5s .12s cubic-bezier(.2, 1, .3, 1) both;
}
.sechead {
  display: flex;
  align-items: center;
  gap: 14px;
  margin-bottom: 20px;
}
.sechead h2 {
  margin: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 26px;
  letter-spacing: 3px;
  text-transform: uppercase;
}
.secsub, .secnum {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--muted);
}
.line {
  flex: 1;
  height: 1px;
  background: linear-gradient(90deg, var(--line), transparent);
}

/* ========== 档案库统计条 ========== */
.metarow {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin-bottom: 18px;
}
.mi {
  display: inline-flex;
  align-items: center;
  gap: 7px;
  padding: 5px 11px;
  border: 1px solid var(--line);
  background: rgba(17, 26, 36, .5);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.mi b {
  font-family: var(--disp);
  font-size: 14px;
  letter-spacing: 1px;
  color: var(--ac);
}

/* ========== 加载更多 ========== */
.more { display: flex; justify-content: center; margin-top: 26px; }
.more button {
  padding: 12px 30px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--cream);
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  letter-spacing: 2.4px;
  cursor: pointer;
  clip-path: polygon(11px 0, 100% 0, calc(100% - 11px) 100%, 0 100%);
  transition: .2s;
}
.more button:hover {
  color: #fff;
  background: var(--ac);
  border-color: var(--ac);
  box-shadow: 0 0 28px -10px var(--ac);
}

/* ========== 情报动态 ========== */
.feed {
  padding-top: 42px;
  animation: up .5s .18s cubic-bezier(.2, 1, .3, 1) both;
}
.flist { list-style: none; margin: 0; padding: 0; display: grid; gap: 10px; }
.flist li {
  display: grid;
  grid-template-columns: 78px 1fr auto;
  align-items: center;
  gap: 16px;
  padding: 14px 18px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .85), rgba(15, 25, 35, .9));
  border: 1px solid var(--line);
  transition: .22s;
}
.flist li:hover {
  border-color: var(--ac);
  box-shadow: 0 0 26px -14px var(--ac);
  transform: translateX(4px);
}
.fkind {
  justify-self: start;
  padding: 4px 8px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.6px;
  color: var(--ac);
  border: 1px solid color-mix(in srgb, var(--ac) 50%, transparent);
}
.fmain h4 {
  margin: 0 0 4px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 16px;
  letter-spacing: 1.4px;
  color: var(--cream);
}
.fmain p {
  margin: 0;
  font-size: 12.5px;
  line-height: 1.6;
  color: var(--muted);
}
.ftime {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.2px;
  color: var(--muted);
}

@media (max-width: 640px) {
  .flist li { grid-template-columns: 1fr; gap: 8px; }
  .ftime { justify-self: start; }
}

/* ========== 页脚 ========== */
.foot {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 16px 26px;
  border-top: 1px solid var(--line);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.foot .sp { flex: 1; }
.foot b { color: #3ddc97; }

/* ========== 响应式 ========== */
@media (max-width: 1080px) {
  .hero { grid-template-columns: 1fr; align-items: start; gap: 24px; }
  .hright { grid-template-columns: repeat(4, 1fr); }
}
@media (max-width: 860px) {
  .main { padding: 96px 18px 32px; }
  .hleft h1 { font-size: 44px; letter-spacing: 3px; }
  .hright { grid-template-columns: repeat(2, 1fr); }
  .foot { padding: 14px 18px; }
}
@media (max-width: 560px) {
  .hleft h1 { font-size: 36px; }
  .hright { grid-template-columns: 1fr 1fr; }
  .foot span:last-child { display: none; }
}
</style>
