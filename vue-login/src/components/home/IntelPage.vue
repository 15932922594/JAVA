<script setup>
/* ============================================================
   情报中心：首页动态流（home_feed）的完整列表页
   数据来源：后端 /api/home/feed，支持按类型过滤 + 分页加载
   ============================================================ */
import { computed, onMounted, ref, watch } from 'vue'
import { state, switchView, useSession } from '../../store/session'
import { homeFeed } from '../../store/api'
import HomeNav from './HomeNav.vue'
import { beep } from '../../composables/useSound'

const { showToast } = useSession()

/** 类型筛选：与 home_feed.kind 一致 */
const KINDS = [
  { code: '', label: '全部' },
  { code: 'NEWS', label: '情报' },
  { code: 'PATCH', label: '版本' },
  { code: 'MISSION', label: '任务' }
]

const PAGE_SIZE = 6

const token = computed(() => state.token || '')

const list = ref([])
const total = ref(0)
const pages = ref(0)
const page = ref(1)
const loading = ref(false)
const kind = ref('')

async function load(reset = true) {
  if (!token.value) return
  if (reset) page.value = 1
  loading.value = true
  const r = await homeFeed(token.value, page.value, PAGE_SIZE, kind.value)
  loading.value = false
  if (r.code !== 0) {
    showToast(`动态加载失败 · ${r.msg || '未知错误'}`, false)
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

function pickKind(code) {
  if (kind.value === code) return
  kind.value = code
  beep(560, 0.05)
}

function backHome() {
  beep(520, 0.06)
  switchView('home')
}

watch(kind, () => load(true))
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
        <h1>情报中心<i>INTEL CENTER</i></h1>
        <p class="sub">共 <b>{{ total }}</b> 条动态 · 版本 / 任务 / 情报</p>
      </header>

      <!-- ========== 类型筛选 ========== -->
      <section class="tools">
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
          </button>
        </div>
      </section>

      <!-- ========== 列表 ========== -->
      <section class="list">
        <template v-if="loading">
          <div v-for="i in 3" :key="'sk' + i" class="row skel">
            <span class="bl w70"></span>
            <span class="bl w90"></span>
          </div>
        </template>

        <template v-else>
          <article v-for="f in list" :key="f.id" class="row">
            <span class="fkind" :data-kind="f.kind">{{ f.tag || f.kind }}</span>
            <div class="fmain">
              <h3>{{ f.title }}</h3>
              <p>{{ f.summary }}</p>
            </div>
            <span class="ftime">{{ String(f.publishedAt).slice(0, 16) }}</span>
          </article>
        </template>

        <div v-if="!loading && !list.length" class="empty">
          <div class="ex">!</div>
          <h4>暂无动态</h4>
          <p>当前类型下没有已发布的条目。</p>
        </div>

        <div v-if="!loading && page < pages" class="more">
          <button type="button" @click="loadMore">加载更多 · 剩余 {{ total - list.length }} 条</button>
        </div>
      </section>
    </main>
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

/* ========== 筛选 ========== */
.tools {
  padding: 22px 0 18px;
  animation: up .45s .05s cubic-bezier(.2, 1, .3, 1) both;
}
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
  border: 1px solid var(--line);
  background: transparent;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1px;
  padding: 6px 14px;
  cursor: pointer;
  transition: .18s;
}
.f:hover { color: var(--cream); border-color: rgba(236, 232, 225, .38); }
.f.on {
  color: #fff;
  background: var(--ac);
  border-color: var(--ac);
  box-shadow: 0 0 18px -8px var(--ac);
}

/* ========== 列表 ========== */
.list {
  display: grid;
  gap: 12px;
  animation: up .45s .1s cubic-bezier(.2, 1, .3, 1) both;
}
.row {
  display: grid;
  grid-template-columns: 86px 1fr auto;
  align-items: center;
  gap: 18px;
  padding: 18px 20px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .9), rgba(15, 25, 35, .93));
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
  transition: .22s;
}
.row:hover {
  border-color: var(--ac);
  box-shadow: 0 0 30px -16px var(--ac);
  transform: translateX(4px);
}
.fkind {
  justify-self: start;
  padding: 5px 9px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.6px;
  color: var(--ac);
  border: 1px solid color-mix(in srgb, var(--ac) 50%, transparent);
}
.fmain h3 {
  margin: 0 0 5px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 18px;
  letter-spacing: 1.6px;
  color: var(--cream);
}
.fmain p {
  margin: 0;
  font-size: 12.8px;
  line-height: 1.65;
  color: var(--muted);
}
.ftime {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.2px;
  color: var(--muted);
  white-space: nowrap;
}

/* ========== 骨架 / 空态 / 更多 ========== */
.skel { pointer-events: none; }
.skel .bl {
  display: block;
  height: 12px;
  margin-bottom: 10px;
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

.empty {
  text-align: center;
  padding: 52px 20px;
  border: 1px dashed var(--line);
  background: rgba(17, 26, 36, .5);
}
.ex {
  width: 46px;
  height: 46px;
  margin: 0 auto 14px;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 24px;
  color: var(--red);
  border: 1px solid var(--red);
  transform: skewX(-10deg);
  box-shadow: 0 0 26px -8px var(--red);
}
.empty h4 {
  margin: 0 0 6px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 19px;
  letter-spacing: 2px;
}
.empty p { margin: 0; font-size: 12.5px; color: var(--muted); }

.more { display: flex; justify-content: center; margin-top: 24px; }
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
@media (max-width: 640px) {
  .row { grid-template-columns: 1fr; gap: 10px; }
  .ftime { justify-self: start; }
  .phead h1 { font-size: 27px; }
  .phead h1 i { display: none; }
}
</style>
