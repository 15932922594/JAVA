<script setup>
/* ============================================================
   开机页：进度条跑满后提示「点击任意位置」
   点击或按键进入主界面
   ============================================================ */
import { onMounted, onBeforeUnmount, ref } from 'vue'
import { beep } from '../composables/useSound'

defineProps({
  /** 淡出中（父级控制，用于启动 CSS 过渡） */
  gone: { type: Boolean, default: false }
})

const emit = defineEmits(['enter'])

const width = ref(0)
const ready = ref(false)
let timer = null
let entered = false

function enter() {
  if (entered) return
  entered = true
  beep(960, 0.12)
  setTimeout(() => beep(1320, 0.16), 110)
  emit('enter')
}

function onKey() {
  enter()
}

onMounted(() => {
  timer = setInterval(() => {
    width.value = Math.min(100, width.value + Math.random() * 11 + 4)
    if (width.value >= 100) {
      clearInterval(timer)
      ready.value = true
    }
  }, 90)
  window.addEventListener('keydown', onKey)
})

onBeforeUnmount(() => {
  clearInterval(timer)
  window.removeEventListener('keydown', onKey)
})
</script>

<template>
  <div class="boot" :class="{ gone }" @click="enter">
    <div class="blogo">
      <span class="sl"></span><span>AGENT ACCESS</span>
    </div>
    <div class="bbar"><i :style="{ width: width + '%' }"></i></div>
    <div class="bhint" :class="{ on: ready }">点击任意位置 / PRESS ANY KEY</div>
  </div>
</template>

<style scoped>
.boot {
  position: fixed;
  inset: 0;
  z-index: 100;
  background: var(--bg2);
  display: flex;
  flex-direction: column;
  align-items: center;
  justify-content: center;
  gap: 22px;
  cursor: pointer;
  transition: opacity .6s, transform .6s;
}
.boot.gone {
  opacity: 0;
  transform: scale(1.06);
  pointer-events: none;
}

.boot .blogo {
  display: flex;
  align-items: center;
  gap: 16px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: clamp(34px, 7vw, 72px);
  letter-spacing: 6px;
  text-transform: uppercase;
  position: relative;
}
.boot .blogo .sl {
  width: clamp(20px, 3vw, 30px);
  height: clamp(34px, 6vw, 62px);
  background: var(--red);
  transform: skewX(-14deg);
  box-shadow: 0 0 34px -4px var(--red);
  animation: slIn .7s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes slIn {
  from { transform: skewX(-14deg) scaleY(0); }
  to { transform: skewX(-14deg) scaleY(1); }
}
.boot .blogo span { animation: glitch 2.6s infinite; }
@keyframes glitch {
  0%, 92%, 100% { text-shadow: 0 0 0 transparent; }
  93% { text-shadow: 3px 0 var(--red), -3px 0 #46e0ff; }
  96% { text-shadow: -3px 0 var(--red), 3px 0 #46e0ff; }
}

.boot .bbar {
  width: min(360px, 70vw);
  height: 3px;
  background: rgba(236, 232, 225, .14);
  overflow: hidden;
}
.boot .bbar i {
  display: block;
  height: 100%;
  width: 0;
  background: var(--red);
  box-shadow: 0 0 14px var(--red);
}

.boot .bhint {
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 3px;
  color: var(--muted);
  opacity: 0;
  transition: opacity .4s;
}
.boot .bhint.on {
  opacity: 1;
  animation: pulse 1.5s ease-in-out infinite;
}
@keyframes pulse {
  50% { opacity: .35; }
}
</style>
