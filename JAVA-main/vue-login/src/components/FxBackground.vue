<script setup>
import { onMounted, onBeforeUnmount, ref } from 'vue'

/* 漂浮粒子 + 邻近连线（原 IIFE 逻辑原样迁移） */
const canvasEl = ref(null)
let raf = 0
let cleanupFns = []

onMounted(() => {
  const cv = canvasEl.value
  const ctx = cv.getContext('2d')
  const dpr = Math.min(window.devicePixelRatio || 1, 2)
  let W = 0
  let H = 0
  let P = []
  let mx = 0
  let my = 0
  let tx = 0
  let ty = 0

  function resize() {
    W = cv.width = innerWidth * dpr
    H = cv.height = innerHeight * dpr
    cv.style.width = innerWidth + 'px'
    cv.style.height = innerHeight + 'px'
  }

  function make() {
    P = []
    const n = Math.round(innerWidth / 16)
    for (let i = 0; i < n; i++) {
      P.push({
        x: Math.random() * W,
        y: Math.random() * H,
        r: Math.random() * 1.8 + 0.4,
        vx: (Math.random() - 0.5) * 0.28,
        vy: (Math.random() - 0.5) * 0.28,
        a: Math.random() * 0.5 + 0.15
      })
    }
  }

  function onResize() {
    resize()
    make()
  }

  function onMove(e) {
    mx = (e.clientX / innerWidth - 0.5) * 2
    my = (e.clientY / innerHeight - 0.5) * 2
  }

  function loop() {
    tx += (mx - tx) * 0.05
    ty += (my - ty) * 0.05
    ctx.clearRect(0, 0, W, H)

    for (let i = 0; i < P.length; i++) {
      const p = P[i]
      p.x += p.vx * dpr
      p.y += p.vy * dpr
      if (p.x < 0) p.x = W
      if (p.x > W) p.x = 0
      if (p.y < 0) p.y = H
      if (p.y > H) p.y = 0

      ctx.beginPath()
      ctx.fillStyle = 'rgba(236,232,225,' + p.a + ')'
      ctx.arc(p.x + tx * 22 * dpr, p.y + ty * 22 * dpr, p.r * dpr, 0, 6.283)
      ctx.fill()

      // 邻近连线
      for (let j = i + 1; j < P.length; j++) {
        const q = P[j]
        const dx = p.x - q.x
        const dy = p.y - q.y
        const d2 = dx * dx + dy * dy
        if (d2 < 20000 * dpr * dpr) {
          const o = (1 - d2 / (20000 * dpr * dpr)) * 0.14
          ctx.strokeStyle = 'rgba(255,70,85,' + o + ')'
          ctx.lineWidth = 1
          ctx.beginPath()
          ctx.moveTo(p.x + tx * 22 * dpr, p.y + ty * 22 * dpr)
          ctx.lineTo(q.x + tx * 22 * dpr, q.y + ty * 22 * dpr)
          ctx.stroke()
        }
      }
    }
    raf = requestAnimationFrame(loop)
  }

  resize()
  make()
  window.addEventListener('resize', onResize)
  window.addEventListener('mousemove', onMove)
  loop()

  cleanupFns = [
    () => window.removeEventListener('resize', onResize),
    () => window.removeEventListener('mousemove', onMove),
    () => cancelAnimationFrame(raf)
  ]
})

onBeforeUnmount(() => cleanupFns.forEach((fn) => fn()))
</script>

<template>
  <div class="fx">
    <canvas ref="canvasEl" id="fx"></canvas>
    <div class="grad"></div>
    <div class="diag"></div>
    <div class="grid"></div>
    <div class="sweep"></div>
    <span class="corner-mark cm1"></span>
    <span class="corner-mark cm2"></span>
  </div>
</template>

<style scoped>
.fx {
  position: fixed;
  inset: 0;
  z-index: 0;
  pointer-events: none;
  overflow: hidden;
}
#fx { position: absolute; inset: 0; }

.fx .grad {
  position: absolute;
  inset: 0;
  background:
    radial-gradient(1100px 700px at 22% 30%, rgba(255, 70, 85, .10), transparent 60%),
    radial-gradient(900px 600px at 82% 78%, rgba(70, 110, 160, .12), transparent 60%),
    linear-gradient(160deg, #0d1620, #0F1923 40%, #0a1119);
}

.fx .diag {
  position: absolute;
  inset: -20%;
  background-image: repeating-linear-gradient(58deg, rgba(236, 232, 225, .05) 0 1px, transparent 1px 64px);
  transform: translate3d(calc(var(--mx, 0) * -14px), calc(var(--my, 0) * -14px), 0);
  transition: transform .35s ease-out;
}

.fx .grid {
  position: absolute;
  inset: 0;
  opacity: .5;
  background-image:
    linear-gradient(rgba(236, 232, 225, .045) 1px, transparent 1px),
    linear-gradient(90deg, rgba(236, 232, 225, .045) 1px, transparent 1px);
  background-size: 78px 78px;
  -webkit-mask-image: radial-gradient(120% 90% at 50% 45%, #000 30%, transparent 78%);
  mask-image: radial-gradient(120% 90% at 50% 45%, #000 30%, transparent 78%);
  transform: translate3d(calc(var(--mx, 0) * 18px), calc(var(--my, 0) * 18px), 0);
  transition: transform .4s ease-out;
}

.fx .sweep {
  position: absolute;
  top: -40%;
  left: -30%;
  width: 60%;
  height: 180%;
  transform: rotate(18deg);
  background: linear-gradient(90deg, transparent, rgba(255, 70, 85, .09), transparent);
  animation: sweep 9s ease-in-out infinite;
}
@keyframes sweep {
  0%, 100% { left: -40%; }
  50% { left: 90%; }
}

.fx .corner-mark {
  position: absolute;
  width: 26px;
  height: 26px;
  border: 1px solid rgba(255, 70, 85, .5);
}
.fx .cm1 { top: 24px; left: 24px; border-right: 0; border-bottom: 0; }
.fx .cm2 { bottom: 24px; right: 24px; border-left: 0; border-top: 0; }
</style>
