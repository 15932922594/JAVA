<script setup>
/* ============================================================
   RIOT 账号登录弹窗（模拟第三方授权，全流程可交互）
   connect（连接网关）→ consent（确认授权范围）→ callback（回调）
     → 已绑定：直接登录   /   未绑定：bind（建档绑定）→ 登录
   后端：/api/auth/riot/authorize · callback · bind（agent_oauth 表）
   ============================================================ */
import { onBeforeUnmount, onMounted, ref } from 'vue'
import { authRiotAuthorize, authRiotBind, authRiotCallback } from '../store/session'
import { beep } from '../composables/useSound'

const emit = defineEmits(['close', 'done'])

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

/** connect | consent | callback | bind | success */
const step = ref('connect')
const loading = ref(false)
const error = ref('')

const ticket = ref('')
const riotId = ref('')
const region = ref('CN')
const name = ref('')
const email = ref('')

/** 打开即向授权网关发起请求（带一点延迟，让连接动画有意义） */
let bootTimer = null
async function authorize() {
  error.value = ''
  const started = Date.now()
  const r = await authRiotAuthorize()
  const wait = Math.max(0, 900 - (Date.now() - started))
  setTimeout(() => {
    if (!r.ok) {
      error.value = r.reason || '无法连接 Riot 授权网关'
      step.value = 'consent'
      return
    }
    ticket.value = r.data.ticket
    riotId.value = r.data.riotId
    region.value = r.data.region || 'CN'
    name.value = r.data.riotId.split('#')[0]
    step.value = 'consent'
    beep(620, 0.06)
  }, wait)
}

/** 用户点「授权并接入」 */
async function consent() {
  if (loading.value || !ticket.value) return
  loading.value = true
  step.value = 'callback'
  error.value = ''
  const r = await authRiotCallback(ticket.value)
  loading.value = false
  if (!r.ok) {
    error.value = r.reason
    step.value = 'consent'
    beep(160, 0.18, 'sawtooth')
    return
  }
  if (r.bound === false) {
    // 首次授权：需要建一个特工档案来绑定
    name.value = r.data.suggestName || name.value
    step.value = 'bind'
    beep(560, 0.06)
    return
  }
  done(r.data)
}

/** 建档绑定 */
async function bind() {
  if (loading.value) return
  if (name.value.trim().length < 2) {
    error.value = '代号至少 2 个字符'
    beep(160, 0.18, 'sawtooth')
    return
  }
  if (!EMAIL.test(email.value.trim())) {
    error.value = '邮箱格式不正确'
    beep(160, 0.18, 'sawtooth')
    return
  }
  loading.value = true
  error.value = ''
  const r = await authRiotBind(ticket.value, name.value, email.value, 0)
  loading.value = false
  if (!r.ok) {
    error.value = r.reason
    beep(160, 0.18, 'sawtooth')
    return
  }
  done(r.data)
}

function done(data) {
  step.value = 'success'
  beep(880, 0.12)
  // 登录态已由 applyLogin 写入并切到首页，这里把弹窗收掉
  setTimeout(() => emit('done', data), 900)
}

function cancel() {
  beep(420, 0.07)
  emit('close')
}

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}

let savedOverflow = ''
onMounted(() => {
  window.addEventListener('keydown', onKey)
  savedOverflow = document.body.style.overflow
  document.body.style.overflow = 'hidden'
  bootTimer = setTimeout(authorize, 60)
})

onBeforeUnmount(() => {
  clearTimeout(bootTimer)
  window.removeEventListener('keydown', onKey)
  document.body.style.overflow = savedOverflow
})
</script>

<template>
  <Teleport to="body">
    <div class="mask" @click.self="cancel">
      <div class="panel" :class="'s-' + step">
        <button class="x" type="button" title="关闭（ESC）" @click="cancel">×</button>

        <header class="hd">
          <span class="logo">
            <svg width="20" height="20" viewBox="0 0 24 24" fill="none">
              <path d="M3 7l9-4 9 4v10l-9 4-9-4z" stroke="currentColor" stroke-width="1.6" />
              <path d="M12 8v8M8 10v4M16 10v4" stroke="currentColor" stroke-width="1.6" stroke-linecap="round" />
            </svg>
          </span>
          <div>
            <h2>RIOT ACCOUNT</h2>
            <p>accounts.riotgames.com</p>
          </div>
        </header>

        <!-- ---------- 连接中 ---------- -->
        <div v-if="step === 'connect'" class="state">
          <div class="spin"></div>
          <p>正在连接 Riot 授权网关…</p>
          <span class="hint">SECURE HANDSHAKE</span>
        </div>

        <!-- ---------- 授权确认 ---------- -->
        <template v-else-if="step === 'consent'">
          <div class="acct">
            <span class="ava">{{ riotId.slice(0, 1) }}</span>
            <div class="info">
              <b>{{ riotId }}</b>
              <span>区域 {{ region }} · 账号状态正常</span>
            </div>
          </div>

          <div class="scope">
            <p class="slab">AGENT ACCESS 请求获取以下权限</p>
            <ul>
              <li><i>✓</i>读取你的 Riot ID 与区域信息</li>
              <li><i>✓</i>创建并关联本站特工档案</li>
              <li><i>·</i>不会获取你的支付信息与好友列表</li>
            </ul>
          </div>

          <div class="acts">
            <button class="btn" type="button" :disabled="!ticket" @click="consent">
              授权并接入
            </button>
            <button class="ghost" type="button" @click="cancel">取消</button>
          </div>
        </template>

        <!-- ---------- 回调中 ---------- -->
        <div v-else-if="step === 'callback'" class="state">
          <div class="spin"></div>
          <p>正在校验授权票据…</p>
          <span class="hint">OAUTH CALLBACK</span>
        </div>

        <!-- ---------- 首次授权：建档 ---------- -->
        <template v-else-if="step === 'bind'">
          <p class="tip">
            检测到该 Riot 账号尚未绑定本站档案，创建一份特工档案即可完成接入。
          </p>
          <label class="fld">
            <span>特工代号</span>
            <input
              v-model="name"
              type="text"
              placeholder="至少 2 个字符"
              spellcheck="false"
              @keydown.enter.prevent="bind"
            />
          </label>
          <label class="fld">
            <span>关联邮箱</span>
            <input v-model="email" type="email" placeholder="agent@example.com" spellcheck="false"
              @keydown.enter.prevent="bind" />
          </label>
          <div class="acts">
            <button class="btn" type="button" :disabled="loading" @click="bind">
              {{ loading ? '绑定中…' : '创建并接入' }}
            </button>
            <button class="ghost" type="button" @click="cancel">取消</button>
          </div>
        </template>

        <!-- ---------- 成功 ---------- -->
        <div v-else class="state ok">
          <svg width="38" height="38" viewBox="0 0 24 24" fill="none">
            <path d="M4 12.5 9.5 18 20 6.5" stroke="currentColor" stroke-width="2.6"
              stroke-linecap="round" stroke-linejoin="round" />
          </svg>
          <p>已通过 Riot 授权接入</p>
          <span class="hint">WELCOME BACK, AGENT</span>
        </div>

        <p v-if="error" class="err"><b>!</b> {{ error }}</p>

        <p class="foot">
          演示授权流程：票据有效期 10 分钟且一次性使用，绑定关系存于 agent_oauth。
        </p>
      </div>
    </div>
  </Teleport>
</template>

<style scoped>
.mask {
  position: fixed;
  inset: 0;
  z-index: 300;
  display: grid;
  place-items: center;
  padding: 24px;
  background: rgba(6, 11, 17, .86);
  backdrop-filter: blur(6px);
  animation: fade .2s ease both;
}
@keyframes fade { from { opacity: 0; } to { opacity: 1; } }

.panel {
  position: relative;
  width: min(430px, 100%);
  max-height: 90vh;
  overflow: auto;
  padding: 24px 24px 16px;
  background: linear-gradient(168deg, rgba(20, 30, 41, .99), rgba(12, 20, 29, .99));
  border: 1px solid var(--line);
  clip-path: polygon(18px 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%, 0 18px);
  box-shadow: 0 40px 90px -30px #000, 0 0 60px -34px var(--red);
  animation: pop .28s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes pop {
  from { opacity: 0; transform: translateY(14px) scale(.98); }
  to { opacity: 1; transform: none; }
}
.panel::before {
  content: '';
  position: absolute; left: 0; right: 0; top: 0;
  height: 2px; background: var(--ac); box-shadow: 0 0 18px var(--ac);
}

.x {
  position: absolute; top: 10px; right: 12px;
  width: 30px; height: 30px;
  display: grid; place-items: center;
  font-size: 21px; line-height: 1;
  color: var(--muted);
  background: rgba(10, 17, 25, .7);
  border: 1px solid var(--line);
  cursor: pointer; transition: .2s;
}
.x:hover { color: #fff; background: var(--red); border-color: var(--red); }

.hd { display: flex; align-items: center; gap: 11px; margin-bottom: 18px; }
.logo {
  width: 38px; height: 38px;
  display: grid; place-items: center;
  color: var(--ac);
  border: 1px solid rgba(255, 70, 85, .5);
  background: rgba(255, 70, 85, .08);
  clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
}
.hd h2 {
  margin: 0;
  font-family: var(--disp); font-weight: 700;
  font-size: 17px; letter-spacing: 3px; text-transform: uppercase;
}
.hd p {
  margin: 2px 0 0;
  font-family: var(--mono); font-size: 9px; letter-spacing: 1.4px; color: var(--muted);
}

/* 状态区（连接 / 回调 / 成功） */
.state { display: grid; place-items: center; gap: 10px; padding: 34px 10px 26px; }
.state p { margin: 0; font-size: 13px; letter-spacing: .6px; color: var(--cream); }
.state .hint {
  font-family: var(--mono); font-size: 8.5px; letter-spacing: 2.2px; color: var(--muted);
}
.state.ok { color: #3ddc97; }
.state.ok p { color: #3ddc97; }
.spin {
  width: 34px; height: 34px;
  border: 2px solid rgba(236, 232, 225, .16);
  border-top-color: var(--ac);
  border-radius: 50%;
  animation: spin .8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }

/* 账号卡 */
.acct {
  display: flex; align-items: center; gap: 12px;
  padding: 13px 14px;
  margin-bottom: 14px;
  background: rgba(236, 232, 225, .04);
  border: 1px solid var(--line);
}
.ava {
  width: 38px; height: 38px;
  display: grid; place-items: center;
  font-family: var(--disp); font-weight: 700; font-size: 19px;
  color: #0F1923; background: var(--ac);
}
.info { display: grid; gap: 3px; min-width: 0; }
.info b {
  font-family: var(--disp); font-weight: 700; font-size: 17px; letter-spacing: 1.8px; color: var(--cream);
}
.info span { font-family: var(--mono); font-size: 9.5px; letter-spacing: 1.1px; color: var(--muted); }

.scope { margin-bottom: 16px; }
.slab {
  margin: 0 0 8px;
  font-family: var(--mono); font-size: 9px; letter-spacing: 1.8px; color: var(--muted);
}
.scope ul { margin: 0; padding: 0; list-style: none; display: grid; gap: 6px; }
.scope li {
  display: flex; gap: 8px; align-items: flex-start;
  font-size: 12px; line-height: 1.5; color: #b9c3cc;
}
.scope li i { font-style: normal; color: #3ddc97; }

.tip {
  margin: 0 0 14px;
  font-size: 12.5px; line-height: 1.7; color: var(--muted);
}
.fld { display: grid; gap: 6px; margin-bottom: 12px; }
.fld span {
  font-family: var(--mono); font-size: 9.5px; letter-spacing: 1.8px; color: var(--muted);
}
.fld input {
  height: 44px; padding: 0 13px;
  background: rgba(10, 17, 25, .7);
  border: 1px solid var(--line);
  color: var(--cream);
  font-family: var(--mono); font-size: 13px; letter-spacing: 1px;
  outline: 0; transition: .2s;
}
.fld input:focus { border-color: var(--ac); box-shadow: 0 0 22px -12px var(--ac); }

.acts { display: grid; gap: 9px; }
.btn {
  width: 100%; height: 46px;
  border: 1px solid var(--ac); background: var(--ac); color: #0F1923;
  font-family: var(--disp); font-weight: 700; font-size: 14px; letter-spacing: 2.4px;
  cursor: pointer;
  clip-path: polygon(10px 0, 100% 0, calc(100% - 10px) 100%, 0 100%);
  transition: .2s;
}
.btn:hover:not(:disabled) { box-shadow: 0 0 26px -10px var(--ac); filter: brightness(1.07); }
.btn:disabled { opacity: .5; cursor: not-allowed; }
.ghost {
  width: 100%; height: 40px;
  border: 1px solid var(--line); background: transparent; color: var(--muted);
  font-family: var(--mono); font-size: 10.5px; letter-spacing: 1.6px;
  cursor: pointer; transition: .2s;
}
.ghost:hover { color: var(--cream); border-color: rgba(236, 232, 225, .4); }

.err {
  margin: 12px 0 0;
  padding: 9px 12px;
  font-size: 12px; color: #FF8B95;
  background: rgba(255, 70, 85, .1);
  border-left: 2px solid var(--red);
}
.err b { margin-right: 6px; }

.foot {
  margin: 14px 0 0;
  padding-top: 12px;
  border-top: 1px solid var(--line);
  font-family: var(--mono); font-size: 8.5px; line-height: 1.6;
  letter-spacing: .8px; color: var(--muted);
}
</style>
