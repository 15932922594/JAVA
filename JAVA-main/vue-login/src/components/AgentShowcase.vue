<script setup>
/* ============================================================
   特工展示区：立绘色块 + 代号 / 定位 / 简介 + 四维属性条
   切换特工时：代号字母弹出、属性条从 0 重新增长
   ============================================================ */
import { onMounted, ref, watch } from 'vue'
import { STAT_LABELS } from '../data/agents'
import { state, currentAgent, agentLevel } from '../store/session'

const monoEl = ref(null)

/** 属性条当前宽度（用于「归零 → 增长」动画） */
const widths = ref(currentAgent.value.stats.map(() => 0))

function playStats() {
  widths.value = currentAgent.value.stats.map(() => 0)
  setTimeout(() => {
    widths.value = [...currentAgent.value.stats]
  }, 120)
}

function playMono() {
  const el = monoEl.value
  if (!el) return
  el.style.transition = 'none'
  el.style.transform = 'translateY(20px)'
  el.style.opacity = '0'
  void el.offsetWidth
  setTimeout(() => {
    el.style.transition = '.45s cubic-bezier(.2,1,.3,1)'
    el.style.transform = 'none'
    el.style.opacity = '.6'
  }, 80)
}

// 初始进入时也要跑一次入场动画（对应原 selectAgent(0)）
onMounted(playStats)

watch(
  () => state.agentIndex,
  () => {
    playMono()
    playStats()
  }
)
</script>

<template>
  <section class="showcase">
    <div class="portrait" :style="{ '--ac': currentAgent.color }">
      <div class="pbg"></div>
      <div class="glow"></div>
      <div class="pscan"></div>
      <span class="ptag">SELECTED · {{ currentAgent.name }}</span>
      <span ref="monoEl" class="mono">{{ currentAgent.mono }}</span>
      <span class="plvl">LV.<span>{{ agentLevel }}</span></span>
    </div>

    <div class="ameta">
      <div class="arole">{{ currentAgent.role }}</div>
      <h2 class="aname">{{ currentAgent.name }}</h2>
      <p class="abio">{{ currentAgent.bio }}</p>
      <div class="stats">
        <div v-for="(v, k) in currentAgent.stats" :key="STAT_LABELS[k]" class="stat-row">
          <span>{{ STAT_LABELS[k] }}</span>
          <div class="trk"><i :style="{ width: widths[k] + '%', background: currentAgent.color }"></i></div>
          <span>{{ v }}</span>
        </div>
      </div>
    </div>
  </section>
</template>

<style scoped>
.showcase {
  display: flex;
  flex-direction: column;
  gap: 22px;
  animation: slideL .7s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes slideL {
  from { opacity: 0; transform: translateX(-26px); }
  to { opacity: 1; transform: none; }
}

/* ---------- 立绘 ---------- */
.portrait {
  position: relative;
  height: 300px;
  overflow: hidden;
  clip-path: polygon(0 0, 100% 0, 100% calc(100% - 34px), calc(100% - 34px) 100%, 0 100%);
  border: 1px solid var(--line);
  background: linear-gradient(140deg, rgba(255, 255, 255, .05), transparent);
  transition: border-color .4s;
}
.portrait .pbg {
  position: absolute;
  inset: 0;
  opacity: .9;
  background:
    repeating-linear-gradient(58deg, color-mix(in srgb, var(--ac) 26%, transparent) 0 2px, transparent 2px 26px),
    radial-gradient(70% 90% at 78% 30%, color-mix(in srgb, var(--ac) 40%, transparent), transparent 70%),
    linear-gradient(160deg, #0c141d, #0a1119);
  transform: translate3d(calc(var(--mx, 0) * 10px), calc(var(--my, 0) * 10px), 0);
  transition: transform .4s ease-out, background .5s;
}
.portrait .mono {
  position: absolute;
  right: 8px;
  bottom: -34px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 240px;
  line-height: .8;
  color: transparent;
  -webkit-text-stroke: 2px color-mix(in srgb, var(--ac) 75%, #fff 10%);
  letter-spacing: -6px;
  opacity: .6;
  transition: .5s;
  user-select: none;
}
.portrait .glow {
  position: absolute;
  inset: 0;
  background: radial-gradient(60% 70% at 30% 60%, color-mix(in srgb, var(--ac) 30%, transparent), transparent 70%);
  mix-blend-mode: screen;
}
.portrait .pscan {
  position: absolute;
  left: 0;
  right: 0;
  height: 22%;
  top: -30%;
  background: linear-gradient(to bottom, transparent, color-mix(in srgb, var(--ac) 45%, transparent), transparent);
  animation: pscan 4.5s linear infinite;
}
@keyframes pscan {
  0% { top: -30%; }
  100% { top: 110%; }
}
.portrait .ptag {
  position: absolute;
  top: 14px;
  left: 14px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 2px;
  color: var(--ac);
  background: rgba(9, 14, 20, .7);
  padding: 5px 10px;
  border-left: 3px solid var(--ac);
}
.portrait .plvl {
  position: absolute;
  bottom: 14px;
  left: 14px;
  font-family: var(--disp);
  font-size: 34px;
  letter-spacing: 2px;
}

/* ---------- 文字信息 ---------- */
.ameta .arole {
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 3px;
  color: var(--ac);
  margin-bottom: 6px;
}
.ameta .aname {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 56px;
  letter-spacing: 4px;
  line-height: .95;
  margin: 0 0 10px;
  text-transform: uppercase;
}
.ameta .abio {
  color: var(--muted);
  font-size: 14px;
  line-height: 1.7;
  margin: 0 0 16px;
  max-width: 46ch;
}

.stats { display: grid; gap: 9px; max-width: 420px; }
.stat-row {
  display: grid;
  grid-template-columns: 72px 1fr 34px;
  align-items: center;
  gap: 12px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 2px;
  color: var(--muted);
}
.stat-row .trk {
  height: 6px;
  background: rgba(236, 232, 225, .09);
  position: relative;
  overflow: hidden;
}
.stat-row .trk i {
  position: absolute;
  inset: 0 auto 0 0;
  width: 0;
  background: var(--ac);
  transition: width .6s cubic-bezier(.2, 1, .3, 1);
}
.stat-row .trk::after {
  content: "";
  position: absolute;
  inset: 0;
  background: repeating-linear-gradient(90deg, transparent 0 8px, rgba(15, 25, 35, .7) 8px 10px);
}

/* ---------- 响应式 ---------- */
@media (max-width: 1020px) {
  .showcase { flex-direction: row; gap: 20px; align-items: center; }
  .portrait { flex: 0 0 44%; height: 220px; }
  .ameta .aname { font-size: 40px; }
}
@media (max-width: 640px) {
  .showcase { flex-direction: column; }
  .portrait { width: 100%; height: 200px; }
  .stats { max-width: none; }
}
</style>
