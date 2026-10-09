<script setup>
/* ============================================================
   会话管理（登录设备）
   显示当前账号所有有效会话，可踢出其他设备
   ============================================================ */
import { computed, onMounted, ref } from 'vue'
import { state, loadSessions, revokeSession, useSession } from '../store/session'
import { beep } from '../composables/useSound'

const { showToast } = useSession()

const loading = computed(() => state.sessionsLoading)
const list = computed(() => state.sessions)
const current = computed(() => list.value.find((s) => s.current))
const others = computed(() => list.value.filter((s) => !s.current))
/** 正在注销的会话 id */
const revoking = ref(null)

async function onRevoke(s) {
  beep(500, 0.07)
  revoking.value = s.id
  const ok = await revokeSession(s.id)
  revoking.value = null
  if (ok) {
    showToast(`已注销会话 #${s.id} · 该设备需重新登录`, true)
  } else {
    showToast('注销失败 · 会话可能已失效', false)
  }
}

function shortTime(t) {
  return (t || '').slice(5, 16)
}

onMounted(loadSessions)
</script>

<template>
  <div class="sess">
    <div v-if="loading" class="tip">正在读取会话数据…</div>

    <template v-else>
      <!-- 当前会话 -->
      <div v-if="current" class="row cur">
        <div class="who">
          <span class="tag">本机</span>
          <span class="t">会话 #{{ current.id }} · {{ shortTime(current.createTime) }} 接入</span>
          <span class="exp">有效期至 {{ shortTime(current.expiresAt) }}</span>
        </div>
        <span class="live">● 在线</span>
      </div>

      <!-- 其他设备 -->
      <div class="sec-title" v-if="others.length">其他设备（{{ others.length }}）</div>
      <div v-for="s in others" :key="s.id" class="row">
        <div class="who">
          <span class="tag dim">远程</span>
          <span class="t">会话 #{{ s.id }} · {{ shortTime(s.createTime) }} 接入</span>
          <span class="exp">有效期至 {{ shortTime(s.expiresAt) }}</span>
        </div>
        <button class="kick" type="button" :disabled="revoking === s.id" @click="onRevoke(s)">
          {{ revoking === s.id ? '注销中…' : '踢出' }}
        </button>
      </div>

      <div v-if="!others.length && current" class="tip ok">安全状态良好 · 没有其他设备在线</div>
      <div v-if="!list.length" class="tip">暂无会话数据</div>
    </template>
  </div>
</template>

<style scoped>
.sess { display: flex; flex-direction: column; gap: 8px; }

.row {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 12px;
  border: 1px solid var(--line);
  background: rgba(236, 232, 225, .04);
  padding: 12px 14px;
  clip-path: polygon(10px 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%, 0 10px);
}
.row.cur { border-color: var(--ac); box-shadow: 0 0 26px -14px var(--ac); }

.who { display: flex; flex-direction: column; gap: 3px; min-width: 0; }

.tag {
  align-self: flex-start;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  padding: 2px 8px;
  color: #fff;
  background: var(--ac);
}
.tag.dim { background: rgba(236, 232, 225, .18); color: var(--muted); }

.t { font-family: var(--mono); font-size: 12.5px; color: var(--cream); letter-spacing: .5px; }
.exp { font-family: var(--mono); font-size: 10.5px; color: var(--muted); letter-spacing: 1px; }

.live {
  font-family: var(--mono);
  font-size: 11px;
  color: var(--ac);
  letter-spacing: 2px;
  white-space: nowrap;
}

.kick {
  font-family: var(--disp);
  font-size: 13px;
  font-weight: 700;
  letter-spacing: 2px;
  text-transform: uppercase;
  color: var(--red);
  background: transparent;
  border: 1px solid var(--red);
  padding: 7px 16px;
  cursor: pointer;
  clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
  transition: .2s;
  white-space: nowrap;
}
.kick:hover { color: #fff; background: var(--red); box-shadow: 0 0 22px -8px var(--red); }
.kick:disabled { opacity: .6; cursor: not-allowed; }

.sec-title {
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 2px;
  color: var(--muted);
  margin-top: 8px;
}

.tip {
  font-family: var(--mono);
  font-size: 11.5px;
  color: var(--muted);
  text-align: center;
  padding: 18px 0;
  letter-spacing: 1px;
}
.tip.ok { color: #3ddc97; }
</style>
