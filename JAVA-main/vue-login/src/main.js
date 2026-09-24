import { createApp } from 'vue'
import App from './App.vue'

// 全局基础变量与重置
import './styles/base.css'
// 认证面板通用样式（跨组件复用）
import './styles/auth.css'

createApp(App).mount('#app')
