import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 开发服务器：/api 代理到 Spring Boot（端口 8081，见 application-dev.properties）
export default defineConfig({
  plugins: [vue()],
  server: {
    host: '127.0.0.1',
    port: 5173,
    strictPort: true,
    proxy: {
      '/api': {
        target: 'http://127.0.0.1:8081',
        changeOrigin: true
      }
    }
  }
})
