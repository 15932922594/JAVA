<script setup>
/* ============================================================
   全局点击反馈：涟漪扩散 + 短音效
   原页面往 body 手插 DOM，这里改为响应式数组驱动渲染
   ============================================================ */
import { onMounted, onBeforeUnmount, ref } from 'vue'
import { beep } from '../composables/useSound'

const rings = ref([])
let uid = 0

function onClick(e) {
  const id = ++uid
  rings.value.push({ id, x: e.clientX, y: e.clientY })
  beep(420, 0.05, 'sine')
  setTimeout(() => {
    rings.value = rings.value.filter((r) => r.id !== id)
  }, 720)
}

onMounted(() => document.addEventListener('click', onClick))
onBeforeUnmount(() => document.removeEventListener('click', onClick))
</script>

<template>
  <span
    v-for="r in rings"
    :key="r.id"
    class="ring go"
    :style="{ left: r.x + 'px', top: r.y + 'px' }"
  ></span>
</template>

<style scoped>
.ring {
  position: fixed;
  z-index: 64;
  width: 10px;
  height: 10px;
  border: 2px solid var(--red);
  border-radius: 50%;
  pointer-events: none;
  transform: translate(-50%, -50%);
  opacity: 0;
}
.ring.go { animation: ring .7s ease-out; }
@keyframes ring {
  0% { opacity: .9; width: 10px; height: 10px; }
  100% { opacity: 0; width: 520px; height: 520px; }
}
</style>
