<script setup>
import { onBeforeUnmount, onMounted, ref, computed, watch, nextTick, provide } from 'vue'
import { state, accent, authRestore, switchView, useSession } from './store/session'
import { useParallax } from './composables/useParallax'
import { FX_KEY } from './composables/useEffects'
import { beep } from './composables/useSound'

import FxBackground from './components/FxBackground.vue'
import Crosshair from './components/Crosshair.vue'
import ClickEffects from './components/ClickEffects.vue'
import TopHud from './components/TopHud.vue'
import BootScreen from './components/BootScreen.vue'
import AgentShowcase from './components/AgentShowcase.vue'
import AgentStrip from './components/AgentStrip.vue'
import AuthPanel from './components/AuthPanel.vue'
import AppToast from './components/AppToast.vue'
import HomePage from './components/home/HomePage.vue'
import ArchivePage from './components/home/ArchivePage.vue'
import IntelPage from './components/home/IntelPage.vue'

const { showToast } = useSession()

/**
 * 当前视图：auth（登录页）| home（首页）| agents / arsenal / missions（分类浏览页）
 * | intel（情报中心）| dash（作战终端）
 * 项目尚未引入 vue-router，用 store 里的 state.view 做切换。
 */
const view = computed(() => state.view)

function backHome() {
  beep(520, 0.06)
  switchView('home')
}

/* 鼠标视差：写入 body 的 --mx / --my */
useParallax()

/* 特工主色同步到 :root，驱动表单强调色（原 selectAgent 中的行为） */
function applyAccent(color) {
  if (typeof document === 'undefined') return
  document.documentElement.style.setProperty('--ac', color)
}
watch(accent, applyAccent, { immediate: true })

/* ---------- 开机页 ---------- */
const bootVisible = ref(true)
const bootGone = ref(false)

function enterTerminal() {
  bootGone.value = true
  document.documentElement.style.setProperty('--mx', '0')
  // 700ms 后卸载开机层（对应原 .boot.gone 过渡时长）
  setTimeout(() => {
    bootVisible.value = false
    state.booted = true
  }, 700)
  setTimeout(() => {
    showToast(
      state.user
        ? `终端已就绪 · 已自动接入 ${state.user.name} 特工`
        : '终端已就绪 · 请选择你的特工',
      true
    )
  }, 780)
}

/* ---------- 自动登录：开机页期间用保存的 token 换账号信息 ---------- */
onMounted(() => {
  authRestore().then((ok) => {
    if (ok && state.booted) {
      // 开机页已经结束的情况（快速刷新）也要提示
      showToast(`已自动接入 ${state.user.name} 特工`, true)
    }
  })
})

/* ---------- 全屏闪光：登录 / 注册成功时触发 ---------- */
const flashEl = ref(null)
const flashing = ref(false)
let flashTimer = null

async function flash() {
  flashing.value = false
  await nextTick()
  if (flashEl.value) void flashEl.value.offsetWidth // 强制重排以重启动画
  flashing.value = true
  clearTimeout(flashTimer)
  flashTimer = setTimeout(() => {
    flashing.value = false
  }, 520)
}

provide(FX_KEY, { flash })

onBeforeUnmount(() => clearTimeout(flashTimer))
</script>

<template>
  <!-- 背景特效层 -->
  <FxBackground />
  <div class="scanline"></div>
  <div class="noise"></div>

  <!-- 准星跟随 -->
  <Crosshair />

  <!-- ---------- 登录页 ---------- -->
  <template v-if="view === 'auth'">
    <!-- 顶栏 -->
    <TopHud />

    <div class="wrap">
      <div class="stage">
        <AgentShowcase />
        <AuthPanel />
      </div>
      <AgentStrip />
    </div>
  </template>

  <!-- ---------- 首页（登录后） ---------- -->
  <HomePage v-else-if="view === 'home'" />

  <!-- ---------- 分类浏览页（导航栏进入） ---------- -->
  <ArchivePage
    v-else-if="view === 'agents'"
    category="AGENT"
    title="特工档案"
    name-en="AGENT ARCHIVE"
  />
  <ArchivePage
    v-else-if="view === 'arsenal'"
    category="GEAR"
    title="武器库"
    name-en="ARSENAL"
  />
  <ArchivePage
    v-else-if="view === 'missions'"
    category="MISSION"
    title="作战任务"
    name-en="OPERATIONS"
  />

  <!-- ---------- 情报中心 ---------- -->
  <IntelPage v-else-if="view === 'intel'" />

  <!-- ---------- 作战终端（从首页用户菜单进入） ---------- -->
  <div v-else class="wrap dashwrap">
    <div class="dashbox">
      <button class="back" type="button" @click="backHome">← 返回首页</button>
      <AuthPanel />
    </div>
  </div>

  <!-- 点击涟漪 -->
  <ClickEffects />

  <AppToast />
  <div ref="flashEl" class="flash" :class="{ go: flashing }"></div>

  <!-- 开机页 -->
  <BootScreen v-if="bootVisible" :gone="bootGone" @enter="enterTerminal" />
</template>

<style scoped>
/* ---------- 扫描线 / 噪点 ---------- */
.scanline {
  position: fixed;
  inset: 0;
  z-index: 5;
  pointer-events: none;
  background: repeating-linear-gradient(to bottom, transparent 0 2px, rgba(0, 0, 0, .14) 2px 3px);
  mix-blend-mode: overlay;
}
.noise {
  position: fixed;
  inset: 0;
  z-index: 5;
  pointer-events: none;
  opacity: .05;
  background-image: url("data:image/svg+xml,%3Csvg xmlns='http://www.w3.org/2000/svg' width='120' height='120'%3E%3Cfilter id='n'%3E%3CfeTurbulence type='fractalNoise' baseFrequency='.8' numOctaves='2'/%3E%3C/filter%3E%3Crect width='100%25' height='100%25' filter='url(%23n)'/%3E%3C/svg%3E");
}

/* ---------- 布局 ---------- */
.wrap {
  position: relative;
  z-index: 2;
  min-height: 100vh;
  display: flex;
  flex-direction: column;
  padding: 86px 26px 22px;
}
.stage {
  flex: 1;
  display: grid;
  grid-template-columns: 1.02fr 1fr;
  gap: 38px;
  align-items: center;
  max-width: 1240px;
  width: 100%;
  margin: 0 auto;
}

/* ---------- 成功闪光 ---------- */
.flash {
  position: fixed;
  inset: 0;
  z-index: 65;
  pointer-events: none;
  background: var(--red);
  opacity: 0;
  mix-blend-mode: screen;
}
.flash.go { animation: flash .5s ease-out; }
@keyframes flash {
  0% { opacity: .55; }
  100% { opacity: 0; }
}

/* ---------- 作战终端（dash 视图） ---------- */
.dashwrap { padding-top: 96px; }
.dashbox {
  width: 100%;
  max-width: 660px;
  margin: 0 auto;
  animation: up .45s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes up {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: none; }
}
.back {
  display: inline-flex;
  align-items: center;
  margin-bottom: 16px;
  padding: 9px 16px;
  background: rgba(17, 26, 36, .8);
  border: 1px solid var(--line);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.8px;
  cursor: pointer;
  clip-path: polygon(9px 0, 100% 0, calc(100% - 9px) 100%, 0 100%);
  transition: .2s;
}
.back:hover {
  color: var(--cream);
  border-color: var(--ac);
  box-shadow: 0 0 20px -8px var(--ac);
}

/* ---------- 响应式 ---------- */
@media (max-width: 1020px) {
  .stage { grid-template-columns: 1fr; gap: 26px; }
}
@media (max-width: 640px) {
  .wrap { padding: 78px 16px 18px; }
  .dashwrap { padding-top: 84px; }
}
</style>
