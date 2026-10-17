<script setup>
/* ============================================================
   找回密码弹窗（三步交互）
   1 输入邮箱 → 2 验证码（演示环境直接生成并显示，含倒计时/重发）
             → 3 设置新密码 → 4 完成
   数据真实写库：agent_reset_code + agent_user（换盐重算摘要 + 踢掉旧会话）
   ============================================================ */
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { authResetConfirm, authResetRequest } from '../store/session'
import { beep } from '../composables/useSound'

const emit = defineEmits(['close', 'done'])

const EMAIL = /^[^\s@]+@[^\s@]+\.[^\s@]{2,}$/

/** 当前步骤：email | code | pass | done */
const step = ref('email')
const loading = ref(false)
const error = ref('')

const email = ref('')
const code = ref('')
const shownCode = ref('')
const left = ref(0)
const pass = ref('')
const pass2 = ref('')

let ticker = null

const stepIndex = computed(() => ['email', 'code', 'pass', 'done'].indexOf(step.value))
const passOk = computed(() => pass.value.length >= 6)
const pass2Ok = computed(() => pass2.value !== '' && pass2.value === pass.value)

/** 请求验证码 */
async function request() {
  if (loading.value) return
  if (!EMAIL.test(email.value.trim())) {
    error.value = '邮箱格式不正确'
    beep(160, 0.18, 'sawtooth')
    return
  }
  loading.value = true
  error.value = ''
  const r = await authResetRequest(email.value)
  loading.value = false
  if (!r.ok) {
    error.value = r.reason
    beep(160, 0.18, 'sawtooth')
    return
  }
  shownCode.value = r.data.code
  code.value = r.data.code // 演示环境直接带上，真实环境应由用户查收邮件后输入
  left.value = r.data.expiresIn || 600
  startTick()
  step.value = 'code'
  beep(680, 0.07)
}

function startTick() {
  clearInterval(ticker)
  ticker = setInterval(() => {
    left.value -= 1
    if (left.value <= 0) clearInterval(ticker)
  }, 1000)
}

const timeText = computed(() => {
  const m = String(Math.floor(left.value / 60)).padStart(2, '0')
  const s = String(left.value % 60).padStart(2, '0')
  return `${m}:${s}`
})

/** 校验验证码（顺带进入下一步） */
async function verifyCode() {
  if (code.value.trim().length < 6) {
    error.value = '请输入 6 位验证码'
    beep(160, 0.18, 'sawtooth')
    return
  }
  if (left.value <= 0) {
    error.value = '验证码已过期，请重新获取'
    beep(160, 0.18, 'sawtooth')
    return
  }
  error.value = ''
  step.value = 'pass'
  beep(620, 0.06)
}

/** 提交新密码 */
async function submit() {
  if (loading.value) return
  if (!passOk.value) {
    error.value = '新密码至少 6 位'
    beep(160, 0.18, 'sawtooth')
    return
  }
  if (!pass2Ok.value) {
    error.value = '两次输入的密码不一致'
    beep(160, 0.18, 'sawtooth')
    return
  }
  loading.value = true
  error.value = ''
  const r = await authResetConfirm(email.value, code.value, pass.value)
  loading.value = false
  if (!r.ok) {
    error.value = r.reason
    beep(160, 0.18, 'sawtooth')
    return
  }
  clearInterval(ticker)
  step.value = 'done'
  beep(880, 0.12)
}

function backToLogin() {
  clearInterval(ticker)
  beep(520, 0.06)
  emit('done', email.value.trim())
}

function onKey(e) {
  if (e.key === 'Escape') backToLogin()
}

let savedOverflow = ''
onMounted(() => {
  window.addEventListener('keydown', onKey)
  savedOverflow = document.body.style.overflow
  document.body.style.overflow = 'hidden'
})

onBeforeUnmount(() => {
  clearInterval(ticker)
  window.removeEventListener('keydown', onKey)
  document.body.style.overflow = savedOverflow
})
</script>

<template>
  <Teleport to="body">
    <div class="mask" @click.self="backToLogin">
      <div class="panel">
        <button class="x" type="button" title="关闭（ESC）" @click="backToLogin">×</button>

        <!-- 步骤条 -->
        <ol class="steps">
          <li :class="{ on: stepIndex >= 0, cur: step === 'email' }"><b>01</b>验证邮箱</li>
          <li :class="{ on: stepIndex >= 1, cur: step === 'code' }"><b>02</b>输入验证码</li>
          <li :class="{ on: stepIndex >= 2, cur: step === 'pass' }"><b>03</b>设置新密码</li>
        </ol>

        <h2>找回密码</h2>
        <p class="sub">PASSWORD RECOVERY</p>

        <!-- ---------- 步骤 1：邮箱 ---------- -->
        <template v-if="step === 'email'">
          <p class="tip">输入注册时使用的邮箱，我们会生成一个 6 位验证码用于验证身份。</p>
          <label class="fld">
            <span>注册邮箱</span>
            <input
              v-model="email"
              type="email"
              placeholder="agent@example.com"
              autocomplete="email"
              spellcheck="false"
              @keydown.enter.prevent="request"
            />
          </label>
          <button class="btn" type="button" :disabled="loading" @click="request">
            {{ loading ? '生成中…' : '获取验证码' }}
          </button>
        </template>

        <!-- ---------- 步骤 2：验证码 ---------- -->
        <template v-else-if="step === 'code'">
          <p class="tip">
            验证码已生成，有效期 <b>{{ timeText }}</b>。演示环境未接入邮件服务，验证码直接显示如下：
          </p>
          <div class="codebox">
            <span v-for="(c, i) in String(shownCode)" :key="i">{{ c }}</span>
          </div>
          <label class="fld">
            <span>验证码</span>
            <input
              v-model="code"
              type="text"
              maxlength="6"
              placeholder="6 位数字"
              spellcheck="false"
              @keydown.enter.prevent="verifyCode"
            />
          </label>
          <div class="acts">
            <button class="btn" type="button" @click="verifyCode">下一步</button>
            <button
              class="lnk"
              type="button"
              :disabled="loading || left > 540"
              @click="request"
            >
              重新获取验证码
            </button>
          </div>
        </template>

        <!-- ---------- 步骤 3：新密码 ---------- -->
        <template v-else-if="step === 'pass'">
          <p class="tip">为特工 <b>{{ email }}</b> 设置新密码，重置后所有设备需要重新登录。</p>
          <label class="fld">
            <span>新密码</span>
            <input
              v-model="pass"
              type="password"
              placeholder="至少 6 位"
              autocomplete="new-password"
              @keydown.enter.prevent="submit"
            />
          </label>
          <label class="fld">
            <span>确认新密码</span>
            <input
              v-model="pass2"
              type="password"
              placeholder="再输入一次"
              autocomplete="new-password"
              @keydown.enter.prevent="submit"
            />
          </label>
          <div class="chkline">
            <span :class="{ ok: passOk }">· 长度 ≥ 6 位</span>
            <span :class="{ ok: pass2Ok }">· 两次输入一致</span>
          </div>
          <button class="btn" type="button" :disabled="loading" @click="submit">
            {{ loading ? '重置中…' : '确认重置' }}
          </button>
        </template>

        <!-- ---------- 步骤 4：完成 ---------- -->
        <template v-else>
          <div class="ok">
            <svg width="34" height="34" viewBox="0 0 24 24" fill="none">
              <path d="M4 12.5 9.5 18 20 6.5" stroke="currentColor" stroke-width="2.6"
                stroke-linecap="round" stroke-linejoin="round" />
            </svg>
          </div>
          <p class="tip">密码已重置，请使用新密码登录。</p>
          <button class="btn" type="button" @click="backToLogin">返回登录</button>
        </template>

        <p v-if="error" class="err"><b>!</b> {{ error }}</p>

        <p class="foot">验证码存储于 agent_reset_code，10 分钟有效且仅可使用一次。</p>
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
  width: min(440px, 100%);
  max-height: 90vh;
  overflow: auto;
  padding: 26px 26px 18px;
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

.steps { display: flex; gap: 14px; margin: 0 0 14px; padding: 0; list-style: none; }
.steps li {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.2px;
  color: var(--muted);
  opacity: .55;
  transition: .25s;
}
.steps li b { display: block; font-size: 12px; letter-spacing: 1.6px; }
.steps li.on { opacity: 1; color: var(--cream); }
.steps li.cur { color: var(--ac); }

h2 {
  margin: 0;
  font-family: var(--disp); font-weight: 700;
  font-size: 27px; letter-spacing: 2.4px; text-transform: uppercase;
}
.sub {
  margin: 3px 0 14px;
  font-family: var(--mono); font-size: 9px; letter-spacing: 2.2px; color: var(--muted);
}
.tip {
  margin: 0 0 14px;
  font-size: 12.5px; line-height: 1.7; color: var(--muted);
}
.tip b { color: var(--ac); font-family: var(--mono); }

.fld { display: grid; gap: 6px; margin-bottom: 12px; }
.fld span {
  font-family: var(--mono); font-size: 9.5px; letter-spacing: 1.8px; color: var(--muted);
}
.fld input {
  height: 44px;
  padding: 0 13px;
  background: rgba(10, 17, 25, .7);
  border: 1px solid var(--line);
  color: var(--cream);
  font-family: var(--mono);
  font-size: 13px;
  letter-spacing: 1px;
  outline: 0;
  transition: .2s;
}
.fld input:focus { border-color: var(--ac); box-shadow: 0 0 22px -12px var(--ac); }
.fld input::placeholder { color: rgba(127, 142, 155, .7); letter-spacing: 0; }

.codebox { display: flex; gap: 8px; margin-bottom: 14px; }
.codebox span {
  flex: 1;
  height: 50px;
  display: grid; place-items: center;
  font-family: var(--disp); font-weight: 700; font-size: 26px;
  color: var(--ac);
  background: rgba(255, 70, 85, .08);
  border: 1px solid rgba(255, 70, 85, .45);
  animation: flip .4s backwards;
}
.codebox span:nth-child(2) { animation-delay: .05s; }
.codebox span:nth-child(3) { animation-delay: .1s; }
.codebox span:nth-child(4) { animation-delay: .15s; }
.codebox span:nth-child(5) { animation-delay: .2s; }
.codebox span:nth-child(6) { animation-delay: .25s; }
@keyframes flip {
  from { opacity: 0; transform: rotateX(-70deg); }
  to { opacity: 1; transform: none; }
}

.btn {
  width: 100%;
  height: 46px;
  border: 1px solid var(--ac);
  background: var(--ac);
  color: #0F1923;
  font-family: var(--disp); font-weight: 700;
  font-size: 14px; letter-spacing: 2.4px;
  cursor: pointer;
  clip-path: polygon(10px 0, 100% 0, calc(100% - 10px) 100%, 0 100%);
  transition: .2s;
}
.btn:hover:not(:disabled) { box-shadow: 0 0 26px -10px var(--ac); filter: brightness(1.07); }
.btn:disabled { opacity: .55; cursor: not-allowed; }

.acts { display: grid; gap: 10px; }
.lnk {
  background: transparent; border: 0;
  color: var(--muted);
  font-family: var(--mono); font-size: 10px; letter-spacing: 1.4px;
  cursor: pointer; transition: .2s;
}
.lnk:hover:not(:disabled) { color: var(--ac); }
.lnk:disabled { opacity: .4; cursor: not-allowed; }

.chkline { display: flex; gap: 14px; margin-bottom: 12px; }
.chkline span {
  font-family: var(--mono); font-size: 9.5px; letter-spacing: 1.2px; color: var(--muted);
  transition: .2s;
}
.chkline span.ok { color: #3ddc97; }

.ok {
  display: grid; place-items: center;
  margin: 6px 0 14px;
  color: #3ddc97;
  animation: popin .4s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes popin {
  from { opacity: 0; transform: scale(.7); }
  to { opacity: 1; transform: none; }
}

.err {
  margin: 12px 0 0;
  padding: 9px 12px;
  font-size: 12px;
  color: #FF8B95;
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
