<script setup>
/* ============================================================
   认证面板：登录 / 注册 切换 + 标题 + 底部提示
   ============================================================ */
import { ref, computed, watch, onMounted } from 'vue'
import LoginForm from './LoginForm.vue'
import RegisterForm from './RegisterForm.vue'
import { state, currentAgent, switchMode } from '../store/session'
import { beep } from '../composables/useSound'

const hint = ref('')

const isLogin = computed(() => state.mode === 'login')
const title = computed(() => (isLogin.value ? '特工接入' : '注册新特工'))
const subtitle = computed(() =>
  isLogin.value ? '使用你的 Riot ID 凭证继续执行任务' : '创建你的账号，加入战场'
)

/* 切换特工后提示当前特工信息（原 refreshIdle） */
function syncAgentHint() {
  hint.value = `当前特工： ${currentAgent.value.name} · ${currentAgent.value.role}`
}

function onSwitch(mode) {
  if (state.mode === mode) {
    // 与原实现一致：点击当前标签也会重播提示与音效
    hint.value = mode === 'login' ? '↑ 从下方选择你的特工' : '↑ 选择一位特工作为你的角色'
    beep(mode === 'login' ? 640 : 500, 0.07)
    return
  }
  switchMode(mode)
  hint.value = mode === 'login' ? '↑ 从下方选择你的特工' : '↑ 选择一位特工作为你的角色'
  beep(mode === 'login' ? 640 : 500, 0.07)
}

watch(() => state.agentIndex, syncAgentHint)
onMounted(syncAgentHint)
</script>

<template>
  <section class="auth">
    <div class="tabs">
      <button class="tab" :class="{ on: isLogin }" type="button" @click="onSwitch('login')">登录</button>
      <button class="tab" :class="{ on: !isLogin }" type="button" @click="onSwitch('register')">创建账号</button>
    </div>

    <div class="ahead">
      <h1>{{ title }}</h1>
      <p>{{ subtitle }}</p>
    </div>

    <!-- 两个表单都保持挂载，靠 .on 控制显隐，以保留入场动画 -->
    <LoginForm :class="{ on: isLogin }" />
    <RegisterForm :class="{ on: !isLogin }" />

    <div class="hint">{{ hint }}</div>
  </section>
</template>

<style scoped>
.auth {
  background: linear-gradient(160deg, rgba(22, 33, 44, .92), rgba(15, 25, 35, .94));
  border: 1px solid var(--line);
  backdrop-filter: blur(8px);
  padding: 30px 32px;
  clip-path: polygon(22px 0, 100% 0, 100% calc(100% - 22px), calc(100% - 22px) 100%, 0 100%, 0 22px);
  box-shadow: 0 30px 80px -40px rgba(0, 0, 0, .9), inset 0 0 60px -40px var(--red);
  animation: slideR .7s .08s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes slideR {
  from { opacity: 0; transform: translateX(26px); }
  to { opacity: 1; transform: none; }
}

.tabs {
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 2px;
  background: rgba(236, 232, 225, .06);
  padding: 2px;
  margin-bottom: 24px;
}
.tab {
  border: 0;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 16px;
  letter-spacing: 2.5px;
  text-transform: uppercase;
  padding: 12px 6px;
  clip-path: polygon(9px 0, 100% 0, calc(100% - 9px) 100%, 0 100%);
  transition: .25s;
  position: relative;
}
.tab:hover { color: var(--cream); }
.tab.on {
  background: var(--red);
  color: #fff;
  box-shadow: 0 0 26px -8px var(--red);
}

.ahead { margin-bottom: 20px; }
.ahead h1 {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 34px;
  letter-spacing: 2px;
  margin: 0 0 4px;
  text-transform: uppercase;
}
.ahead p { margin: 0; color: var(--muted); font-size: 13px; }

.hint {
  margin-top: 16px;
  text-align: center;
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 2px;
  color: var(--muted);
}

@media (max-width: 640px) {
  .auth { padding: 24px 20px; }
}
</style>
