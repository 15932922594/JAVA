<script setup>
/* ============================================================
   已登录面板：展示账号信息 + 退出登录
   登录成功 / 自动登录后由 AuthPanel 切换显示
   ============================================================ */
import { computed, ref } from 'vue'
import { state, currentAgent, authLogout, switchDashTab, useSession } from '../store/session'
import { beep } from '../composables/useSound'
import { useEffects } from '../composables/useEffects'

const { showToast } = useSession()
const { flash } = useEffects()
const loggingOut = ref(false)

const user = computed(() => state.user)
/** 在线设备数（含本机） */
const deviceCount = computed(() => state.sessions.length)
const maskedEmail = computed(() => {
  const e = user.value?.email || ''
  const at = e.indexOf('@')
  if (at <= 1) return e
  return e.slice(0, 2) + '•••' + e.slice(at)
})

function goSessions() {
  beep(640, 0.07)
  switchDashTab('sessions')
}

async function onLogout() {
  beep(500, 0.07)
  loggingOut.value = true
  await authLogout()
  loggingOut.value = false
  flash()
  showToast('已断开连接 · 期待你重返战场', true)
}
</script>

<template>
  <div class="usercard" v-if="user">
    <div class="badge">
      <img class="bimg" :src="currentAgent.img" :alt="currentAgent.name" draggable="false" />
    </div>

    <div class="meta">
      <div class="name">{{ user.name }}</div>
      <div class="mail">{{ maskedEmail }}</div>
      <div class="agent">当前特工 · {{ currentAgent.name }} — {{ currentAgent.role }}</div>
    </div>

    <div class="stat">
      <span class="k">CLEARANCE</span>
      <span class="v">LV-{{ String(10 + (user.agentIndex || 0) * 3).padStart(2, '0') }}</span>
    </div>

    <!-- 快捷数据条 -->
    <div class="quick" @click="goSessions">
      <div class="q">
        <span class="k">在线设备</span>
        <span class="v">{{ deviceCount || '—' }}</span>
      </div>
      <div class="q">
        <span class="k">会话有效期</span>
        <span class="v">7 天</span>
      </div>
      <div class="q">
        <span class="k">凭证算法</span>
        <span class="v">SHA-256</span>
      </div>
    </div>

    <button class="btn out" type="button" :disabled="loggingOut" @click="onLogout">
      <span>{{ loggingOut ? '正在断开…' : '断开连接（退出登录）' }}</span>
    </button>

    <div class="hint">会话有效期 7 天 · 勾选「保持登录」可自动接入</div>
  </div>
</template>

<style scoped>
.usercard {
  display: flex;
  flex-direction: column;
  align-items: center;
  gap: 14px;
  padding: 26px 10px 10px;
  text-align: center;
}

.badge {
  width: 74px;
  height: 74px;
  display: grid;
  place-items: center;
  color: var(--ac);
  border: 1px solid var(--line);
  background: rgba(236, 232, 225, .04);
  clip-path: polygon(18px 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%, 0 18px);
  box-shadow: 0 0 34px -14px var(--ac);
  overflow: hidden;
}
.badge .bimg {
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center 8%;
  filter: saturate(1.05);
}

.name {
  font-family: var(--disp);
  font-size: 30px;
  font-weight: 700;
  letter-spacing: 2px;
  text-transform: uppercase;
  color: var(--cream);
  line-height: 1.1;
}

.mail {
  font-family: var(--mono);
  font-size: 12.5px;
  color: var(--muted);
  letter-spacing: 1px;
}

.agent {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--ac);
  letter-spacing: 1.5px;
  margin-top: 2px;
}

.stat {
  display: flex;
  align-items: baseline;
  gap: 10px;
  font-family: var(--mono);
  border: 1px solid var(--line);
  padding: 8px 16px;
  background: rgba(236, 232, 225, .04);
  clip-path: polygon(10px 0, 100% 0, calc(100% - 10px) 100%, 0 100%);
}
.stat .k { font-size: 10px; color: var(--muted); letter-spacing: 2px; }
.stat .v { font-family: var(--disp); font-size: 20px; font-weight: 700; color: var(--cream); }

/* 快捷数据条：点击跳到会话管理 */
.quick {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 8px;
  width: 100%;
  cursor: pointer;
  border: 1px solid var(--line);
  padding: 10px 6px;
  background: rgba(236, 232, 225, .04);
  transition: .2s;
}
.quick:hover { border-color: var(--ac); box-shadow: 0 0 26px -16px var(--ac); }
.q { display: flex; flex-direction: column; gap: 3px; align-items: center; }
.q .k { font-family: var(--mono); font-size: 9.5px; color: var(--muted); letter-spacing: 1.5px; }
.q .v { font-family: var(--disp); font-size: 17px; font-weight: 700; color: var(--cream); }

.btn.out {
  width: 100%;
  margin-top: 6px;
  font-size: 15px;
}

.hint {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  letter-spacing: 1.5px;
}
</style>
