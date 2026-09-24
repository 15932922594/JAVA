<script setup>
/* ============================================================
   自定义准星：跟随鼠标缓动，悬停在可交互元素上时张开 + 变白
   位移直接写 DOM（不走响应式），保证每帧无额外开销
   ============================================================ */
import { onMounted, onBeforeUnmount, ref } from 'vue'

const el = ref(null)
const hot = ref(false)

const HOT_SELECTOR = 'button,a,input,.card,.chk,.tab,.soc,.btn'

let rx = 0
let ry = 0
let tx = 0
let ty = 0
let rot = 0
let raf = 0

function onMove(e) {
  rx = e.clientX
  ry = e.clientY
}
function onOver(e) {
  if (e.target.closest && e.target.closest(HOT_SELECTOR)) hot.value = true
}
function onOut(e) {
  if (e.target.closest && e.target.closest(HOT_SELECTOR)) hot.value = false
}

function loop() {
  tx += (rx - tx) * 0.2
  ty += (ry - ty) * 0.2
  const target = hot.value ? 45 : 0
  rot += (target - rot) * 0.15
  const node = el.value
  if (node) {
    node.style.transform = `translate(${tx}px,${ty}px) rotate(${rot.toFixed(2)}deg)`
  }
  raf = requestAnimationFrame(loop)
}

onMounted(() => {
  rx = tx = window.innerWidth / 2
  ry = ty = window.innerHeight / 2
  window.addEventListener('mousemove', onMove)
  document.addEventListener('mouseover', onOver)
  document.addEventListener('mouseout', onOut)
  raf = requestAnimationFrame(loop)
})

onBeforeUnmount(() => {
  window.removeEventListener('mousemove', onMove)
  document.removeEventListener('mouseover', onOver)
  document.removeEventListener('mouseout', onOut)
  cancelAnimationFrame(raf)
})
</script>

<template>
  <div ref="el" class="reticle" :class="{ hot }">
    <span class="r t"></span><span class="r b"></span><span class="r l"></span><span class="r rr"></span><span class="r dot"></span>
  </div>
</template>

<style scoped>
.reticle {
  position: fixed;
  z-index: 60;
  width: 34px;
  height: 34px;
  margin: -17px 0 0 -17px;
  pointer-events: none;
  opacity: 0;
  transition: width .2s, height .2s, opacity .3s;
}
.reticle .r {
  position: absolute;
  background: var(--red);
  box-shadow: 0 0 6px rgba(255, 70, 85, .9);
}
.reticle .t { top: 0; left: 50%; width: 2px; height: 9px; margin-left: -1px; }
.reticle .b { bottom: 0; left: 50%; width: 2px; height: 9px; margin-left: -1px; }
.reticle .l { left: 0; top: 50%; height: 2px; width: 9px; margin-top: -1px; }
.reticle .rr { right: 0; top: 50%; height: 2px; width: 9px; margin-top: -1px; }
.reticle .dot { left: 50%; top: 50%; width: 3px; height: 3px; margin: -1.5px 0 0 -1.5px; border-radius: 50%; }

.reticle.hot { width: 52px; height: 52px; margin: -26px 0 0 -26px; }
.reticle.hot .r { background: #fff; box-shadow: 0 0 10px #fff; }

@media (pointer: fine) {
  .reticle { opacity: .85; }
}
</style>
