import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

/**
 * 后端地址：默认本机 8081。
 * 若后端跑在另一台机器上，启动前设置环境变量即可：
 *   set VITE_BACKEND=http://192.168.1.13:8081
 */
const BACKEND = process.env.VITE_BACKEND || 'http://127.0.0.1:8081'

const proxy = {
  '/api': {
    target: BACKEND,
    changeOrigin: true
  }
}

/**
 * 开发 / 预览服务器都监听 0.0.0.0，三个地址同时可用（换网络不用改任何东西）：
 *   本机        http://localhost:5173
 *   家里网络    http://192.168.1.13:5173
 *   工作时网络  http://192.168.68.29:5173
 *
 * 前端代码里只写相对路径 /api，由 Vite 代理转发到后端，
 * 所以浏览器用哪个 IP 打开都能正常调接口。
 * `npm run lan` 可随时查看当前生效的地址。
 */
export default defineConfig({
  plugins: [vue()],
  server: {
    host: true,
    port: 5173,
    strictPort: true,
    proxy
  },
  preview: {
    host: true,
    port: 4173,
    strictPort: true,
    proxy
  }
})
