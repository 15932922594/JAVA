/* ============================================================
   跨组件 UI 效果（全屏闪光等）通过 provide/inject 共享
   App 提供实现，深层表单组件按需注入，避免层层透传 props
   ============================================================ */
import { inject } from 'vue'

export const FX_KEY = Symbol('app-fx')

export function useEffects() {
  return inject(FX_KEY, { flash: () => {} })
}
