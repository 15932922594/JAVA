import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// base: './' —— 产物用相对路径引用资源，可直接部署到 GitHub Pages 子目录
export default defineConfig({
  base: './',
  plugins: [vue()],
  server: {
    port: 5173,
    open: false
  },
  build: {
    outDir: 'dist',
    assetsDir: 'assets'
  }
})
