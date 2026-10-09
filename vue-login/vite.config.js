import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// base: './' —— 产物用相对路径引用资源，可直接部署到 GitHub Pages 子目录
export default defineConfig({
  base: './',
  plugins: [vue()],
  server: {
    port: 5173,
    open: false,
    // 开发代理：/api 转发到 Spring Boot 后端（端口见 application-dev.properties）
    proxy: {
      '/api': {
        target: 'http://localhost:8081',
        changeOrigin: true
      }
    }
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
