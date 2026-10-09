/* ============================================================
   音效 —— WebAudio 合成短音，默认静音
   对应原页面 beep(freq, dur, type)
   ============================================================ */
import { computed } from 'vue'
import { state } from '../store/session'

let actx = null

/** 播放一个短促的合成音；未开启音效时静默返回 */
export function beep(freq, dur, type = 'triangle') {
  if (!state.soundOn) return
  try {
    if (!actx) actx = new (window.AudioContext || window.webkitAudioContext)()
    const osc = actx.createOscillator()
    const gain = actx.createGain()
    osc.type = type
    osc.frequency.value = freq
    gain.gain.setValueAtTime(0.06, actx.currentTime)
    gain.gain.exponentialRampToValueAtTime(0.0001, actx.currentTime + dur)
    osc.connect(gain)
    gain.connect(actx.destination)
    osc.start()
    osc.stop(actx.currentTime + dur)
  } catch {
    /* 浏览器不支持 WebAudio 时静默降级 */
  }
}

/** 音效开关（只读视图，真正的状态在 store 里） */
export const soundOn = computed(() => state.soundOn)

/** 切换音效开关 */
export function toggleSound() {
  state.soundOn = !state.soundOn
  if (state.soundOn) beep(880, 0.09)
}

export function useSound() {
  return { soundOn, beep, toggleSound }
}
