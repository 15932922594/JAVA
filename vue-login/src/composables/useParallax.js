/* ============================================================
   鼠标视差 —— 把归一化后的指针位置写进 body 的 --mx / --my
   背景斜纹、网格、特工立绘都靠这两个变量做位移
   ============================================================ */
import { onMounted, onBeforeUnmount } from 'vue'

export function useParallax() {
  function onMove(e) {
    const mx = ((e.clientX / window.innerWidth - 0.5) * 2).toFixed(3)
    const my = ((e.clientY / window.innerHeight - 0.5) * 2).toFixed(3)
    document.body.style.setProperty('--mx', mx)
    document.body.style.setProperty('--my', my)
  }

  onMounted(() => window.addEventListener('mousemove', onMove))
  onBeforeUnmount(() => window.removeEventListener('mousemove', onMove))
}
