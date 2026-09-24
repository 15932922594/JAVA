/* SSR 渲染入口：仅用于离线结构校验，不参与线上产物 */
import { createSSRApp } from 'vue'
import { renderToString } from 'vue/server-renderer'
import App from './App.vue'

export async function render() {
  const app = createSSRApp(App)
  return await renderToString(app)
}
