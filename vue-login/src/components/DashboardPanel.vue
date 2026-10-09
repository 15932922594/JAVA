<script setup>
/* ============================================================
   作战终端 —— 登录后的主页
   三个标签页：概览 / 会话（登录设备） / 安全（修改密码）
   ============================================================ */
import { computed } from 'vue'
import { state, switchDashTab, useSession } from '../store/session'
import { beep } from '../composables/useSound'
import UserPanel from './UserPanel.vue'
import SessionsPanel from './SessionsPanel.vue'
import SecurityPanel from './SecurityPanel.vue'

const { showToast } = useSession()

const tab = computed(() => state.dashTab)

const TABS = [
  { key: 'overview', label: '概览' },
  { key: 'sessions', label: '会话' },
  { key: 'security', label: '安全' }
]

function onTab(key) {
  if (tab.value === key) return
  beep(640, 0.07)
  switchDashTab(key)
}
</script>

<template>
  <div class="dash">
    <div class="tabs">
      <button
        v-for="t in TABS"
        :key="t.key"
        class="tab"
        :class="{ on: tab === t.key }"
        type="button"
        @click="onTab(t.key)"
      >{{ t.label }}</button>
    </div>

    <div class="pane">
      <UserPanel v-if="tab === 'overview'" />
      <SessionsPanel v-else-if="tab === 'sessions'" />
      <SecurityPanel v-else />
    </div>
  </div>
</template>

<style scoped>
.tabs {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 2px;
  background: rgba(236, 232, 225, .06);
  padding: 2px;
  margin-bottom: 22px;
}
.tab {
  border: 0;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 2.5px;
  text-transform: uppercase;
  padding: 11px 6px;
  clip-path: polygon(9px 0, 100% 0, calc(100% - 9px) 100%, 0 100%);
  transition: .25s;
}
.tab:hover { color: var(--cream); }
.tab.on {
  background: var(--ac);
  color: #fff;
  box-shadow: 0 0 26px -8px var(--ac);
}

.pane { animation: fadeUp .35s cubic-bezier(.2, 1, .3, 1) both; }
@keyframes fadeUp {
  from { opacity: 0; transform: translateY(8px); }
  to { opacity: 1; transform: none; }
}
</style>
