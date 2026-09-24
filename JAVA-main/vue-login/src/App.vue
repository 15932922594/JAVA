<script setup>
import { onBeforeUnmount, ref, watch, nextTick, provide } from 'vue'
import { state, accent, useSession } from './store/session'
import { useParallax } from './composables/useParallax'
import { FX_KEY } from './composables/useEffects'

import FxBackground from './components/FxBackground.vue'
import Crosshair from './components/Crosshair.vue'
import ClickEffects from './components/ClickEffects.vue'
import TopHud from './components/TopHud.vue'
import BootScreen from './components/BootScreen.vue'
import AgentShowcase from './components/AgentShowcase.vue'
import AgentStrip from './components/AgentStrip.vue'
import AuthPanel from './components/AuthPanel.vue'
import AppToast from './components/AppToast.vue'

const { showToast } = useSession()

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
  setTimeout(() => showToast('终端已就绪 · 请选择你的特工', true), 780)
}

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

  <!-- 顶栏 -->
  <TopHud />

  <div class="wrap">
    <div class="stage">
      <AgentShowcase />
      <AuthPanel />
    </div>
    <AgentStrip />
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

/* ---------- 响应式 ---------- */
@media (max-width: 1020px) {
  .stage { grid-template-columns: 1fr; gap: 26px; }
}
@media (max-width: 640px) {
  .wrap { padding: 78px 16px 18px; }
}
</style>
