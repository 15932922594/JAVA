import { createApp } from 'vue'
import App from './App.vue'

// 全局基础变量与重置
import './styles/base.css'
// 认证面板通用样式（跨组件复用）
import './styles/auth.css'
// 头像框阶梯（11 档，等级解锁）
import './styles/frames.css'

createApp(App).mount('#app')
