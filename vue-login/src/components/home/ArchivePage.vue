<script setup>
/* ============================================================
   分类浏览页（特工档案 / 武器库 / 作战任务 共用）
   数据来源：后端 /api/home/search（一级分类由 props.category 固定）
   只在本大类内做「细分 + 分级 + 关键词」筛选，不展示一级分类切换。
   ============================================================ */
import { computed, onMounted, ref, watch } from 'vue'
import { state, switchView, useSession } from '../../store/session'
import { search, homeCategories } from '../../store/api'
import HomeNav from './HomeNav.vue'
import AgentArchive from './AgentArchive.vue'
import AgentDetailModal from './AgentDetailModal.vue'
import { beep } from '../../composables/useSound'

const props = defineProps({
  /** 一级分类编码：AGENT | GEAR | MISSION */
  category: { type: String, required: true },
  /** 页面标题 */
  title: { type: String, required: true },
  /** 英文副标题 */
  nameEn: { type: String, default: '' }
})

const { showToast } = useSession()

/** 分级档位（与 agent_archive.tier 一致） */
const TIERS = ['S', 'A', 'B']
const PAGE_SIZE = 12

const token = computed(() => state.token || '')

const list = ref([])
const total = ref(0)
const pages = ref(0)
const page = ref(1)
const loading = ref(false)

const query = ref('')
const sub = ref('')
const tier = ref('')
/** 本大类下的二级分类（含档案数） */
const subs = ref([])

/** 是否处于筛选状态 */
const active = computed(() => !!(query.value.trim() || sub.value || tier.value))

async function load(reset = true) {
  if (!token.value) return
  if (reset) page.value = 1
  loading.value = true
  const r = await search(token.value, {
    q: query.value.trim(),
    category: props.category,
    subCategory: sub.value,
    tier: tier.value,
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
  load(false)
}

function pickSub(code) {
  if (sub.value === code) return
  sub.value = code
  beep(560, 0.05)
}

function pickTier(t) {
  if (tier.value === t) return
  tier.value = t
  beep(600, 0.05)
}

function resetAll() {
  query.value = ''
  sub.value = ''
  tier.value = ''
  beep(420, 0.05)
  load(true)
}

/** 拉取分类目录，取出本大类的二级分类 */
async function init() {
  if (!token.value) return
  const r = await homeCategories(token.value)
  if (r.code === 0) {
    const root = (r.data || []).find((c) => c.code === props.category)
    subs.value = root?.children || []
  }
  await load(true)
}

/* 关键词防抖；筛选变化立即检索 */
let timer = null
watch(query, () => {
  clearTimeout(timer)
  timer = setTimeout(() => load(true), 350)
})
watch([sub, tier], () => load(true))
watch(token, (v) => v && init())

/* ---------- 档案详情弹窗（点击卡片打开：介绍 + 人物故事） ---------- */
const detailCode = ref('')

function openDetail(code) {
  if (!code) return
  beep(640, 0.05)
  detailCode.value = code
}

function backHome() {
  beep(520, 0.06)
  switchView('home')
}

onMounted(init)
</script>

<template>
  <div class="page">
    <HomeNav />

    <main class="main">
      <!-- ========== 页头 ========== -->
      <header class="phead">
        <p class="crumbs">
          <button type="button" class="crumb" @click="beep(520, .06), $emit('back')">首页</button>
          <span class="sep">/</span>
          <span class="cur">{{ title }}</span>
        </p>
        <h1>{{ title }}<i v-if="nameEn">{{ nameEn }}</i></h1>
        <p class="sub">
          共 <b>{{ total }}</b> 条档案 · 支持细分与分级筛选
        </p>
      </header>

      <!-- ========== 工具行 ========== -->
      <section class="tools">
        <div class="searchbox">
          <span class="prompt">//</span>
          <input
            v-model="query"
            class="ipt"
            type="text"
            :placeholder="`在${title}中检索…`"
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
          <div class="frow" v-if="subs.length">
            <span class="flab">细分</span>
            <button class="f" :class="{ on: !sub }" type="button" @click="pickSub('')">全部</button>
            <button
              v-for="s in subs"
              :key="s.code"
              class="f"
              :class="{ on: sub === s.code }"
              type="button"
              @click="pickSub(s.code)"
            >
              {{ s.name }}<i>{{ s.count }}</i>
            </button>
          </div>

          <div class="frow">
            <span class="flab">分级</span>
            <button class="f" :class="{ on: !tier }" type="button" @click="pickTier('')">全部</button>
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

      <!-- ========== 网格 ========== -->
      <section class="grid-wrap">
        <AgentArchive
          :agents="list"
          :query="query.trim()"
          :loading="loading"
          :filtered="active"
          @open="openDetail"
        />

        <div v-if="!loading && page < pages" class="more">
          <button type="button" @click="loadMore">加载更多 · 剩余 {{ total - list.length }} 条</button>
        </div>
      </section>
    </main>

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
.page { min-height: 100vh; display: flex; flex-direction: column; }

.main {
  flex: 1;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 104px 26px 48px;
}

/* ========== 页头 ========== */
.phead {
  padding-bottom: 22px;
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
  margin: 10px 0 0;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.sub b { color: var(--ac); font-size: 13px; }

/* ========== 工具行 ========== */
.tools {
  padding: 24px 0 20px;
  display: grid;
  gap: 12px;
  animation: up .45s .05s cubic-bezier(.2, 1, .3, 1) both;
}
.searchbox {
  display: flex;
  align-items: center;
  gap: 11px;
  height: 52px;
  padding: 0 12px 0 16px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .94), rgba(15, 25, 35, .96));
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
  transition: border-color .2s;
}
.searchbox:focus-within { border-color: var(--ac); }
.prompt {
  font-family: var(--mono);
  font-size: 13px;
  color: var(--ac);
  user-select: none;
}
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
  width: 26px;
  height: 26px;
  display: grid;
  place-items: center;
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
.f i { font-style: normal; font-size: 9px; opacity: .6; }
.f:hover { color: var(--cream); border-color: rgba(236, 232, 225, .38); }
.f.on {
  color: #fff;
  background: var(--ac);
  border-color: var(--ac);
  box-shadow: 0 0 18px -8px var(--ac);
}
.f.on i { opacity: .85; }
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
.grid-wrap { animation: up .45s .1s cubic-bezier(.2, 1, .3, 1) both; }
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

/* ========== 响应式 ========== */
@media (max-width: 860px) {
  .main { padding: 96px 18px 36px; }
  .phead h1 { font-size: 34px; letter-spacing: 2.4px; }
}
@media (max-width: 560px) {
  .phead h1 { font-size: 27px; }
  .phead h1 i { display: none; }
}
</style>
