<script setup>
/* ============================================================
   登录表单
   ============================================================ */
import { reactive, ref, watch } from 'vue'
import FieldInput from './FieldInput.vue'
import ForgotPasswordModal from './ForgotPasswordModal.vue'
import RiotAuthModal from './RiotAuthModal.vue'
import { state, EMAIL, authLogin, useSession } from '../store/session'
import { beep } from '../composables/useSound'
import { useEffects } from '../composables/useEffects'

const { showToast, switchMode } = useSession()
const { flash } = useEffects()

const form = state.login
const errors = reactive({ id: false, pass: false })
const loading = ref(false)

// 输入即清除该字段错误态（对应原 input 事件里的 classList.remove("bad")）
watch(() => form.id, () => { errors.id = false })
watch(() => form.pass, () => { errors.pass = false })

function mark(key, isBad) {
  errors[key] = !!isBad
  return !isBad
}

function success(msg) {
  flash()
  beep(660, 0.08)
  setTimeout(() => beep(880, 0.08), 90)
  setTimeout(() => beep(1180, 0.16), 180)
  showToast(msg, true)
}

/** 后端错误码 -> 界面反馈 */
const FAIL_HINTS = {
  notfound: '账号不存在 · 请检查代号 / 邮箱',
  wrongpass: '密码错误 · 请重新输入',
  'network-error': '无法连接服务器 · 请确认后端已启动',
  'http-500': '服务器开小差了 · 请稍后再试'
}

async function onSubmit() {
  const v = form.id.trim()
  // 校验：长度 ≥ 3 且（邮箱格式 / 含 # / 长度 ≥ 3）—— 与原实现保持一致
  const ok1 = mark('id', !(v.length >= 3 && (EMAIL.test(v) || v.indexOf('#') > -1 || v.length >= 3)))
  const ok2 = mark('pass', form.pass.length < 6)

  if (!ok1 || !ok2) {
    beep(160, 0.18, 'sawtooth')
    showToast('凭证校验失败，请检查输入', false)
    return
  }

  loading.value = true
  const r = await authLogin(v, form.pass, form.remember)
  loading.value = false

  if (!r.ok) {
    beep(160, 0.18, 'sawtooth')
    if (r.reason === 'notfound') errors.id = true
    if (r.reason === 'wrongpass') errors.pass = true
    showToast(FAIL_HINTS[r.reason] || `接入失败：${r.reason}`, false)
    return
  }

  form.pass = '' // 不在表单里残留密码
  success(`接入成功 · 欢迎回来，${r.data.name} 特工`)
}

/** 跳去注册页 */
function goRegister() {
  beep(640, 0.07)
  switchMode('register')
}

/* ---------- 弹窗：找回密码 / RIOT 授权 ---------- */
const showForgot = ref(false)
const showRiot = ref(false)

function openForgot() {
  beep(600, 0.06)
  showForgot.value = true
}

/** 重置完成后把邮箱带回登录框，省得再输一遍 */
function onForgotDone(mail) {
  showForgot.value = false
  if (mail) form.id = mail
  form.pass = ''
  showToast('密码已重置 · 请使用新密码登录', true)
}

function openRiot() {
  beep(600, 0.06)
  showRiot.value = true
}

/** Riot 授权成功：登录态已写入（applyLogin 自动跳转首页），这里只收掉弹窗 */
function onRiotDone(data) {
  showRiot.value = false
  if (data?.riotId) {
    showToast(`已通过 ${data.riotId} 接入`, true)
  }
}
</script>

<template>
  <form class="form" novalidate @submit.prevent="onSubmit">
    <FieldInput
      v-model="form.id"
      label="Riot ID / 邮箱"
      placeholder="agent#0000"
      autocomplete="username"
      :bad="errors.id"
      error-text="请输入 Riot ID 或有效邮箱"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <circle cx="12" cy="8" r="3.6" stroke="currentColor" stroke-width="1.7" />
          <path d="M5 19.5c1.3-3 4-4.5 7-4.5s5.7 1.5 7 4.5" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
        </svg>
      </template>
    </FieldInput>

    <FieldInput
      v-model="form.pass"
      label="密码"
      placeholder="••••••••"
      autocomplete="current-password"
      password
      :bad="errors.pass"
      error-text="密码至少 6 位"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <rect x="4" y="10" width="16" height="11" rx="2" stroke="currentColor" stroke-width="1.7" />
          <path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
        </svg>
      </template>
    </FieldInput>

    <div class="row">
      <label class="chk">
        <input v-model="form.remember" type="checkbox" />
        <span class="bx">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
            <path d="m5 13 4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
        </span>保持登录
      </label>
      <a class="lnk" href="#" @click.prevent="openForgot">忘记密码?</a>
    </div>

    <button class="btn" type="submit" :class="{ loading }" :disabled="loading">
      <span>进入战场</span>
      <span class="dots"><i></i><i></i><i></i></span>
    </button>

    <div class="alt">或</div>

    <div class="socials">
      <button class="soc" type="button" @click="goRegister">创建新特工</button>
      <button class="soc" type="button" @click="openRiot">RIOT 账号</button>
    </div>

    <!-- 找回密码 / RIOT 授权（Teleport 到 body，避免被父级层叠上下文裁切） -->
    <ForgotPasswordModal v-if="showForgot" @close="showForgot = false" @done="onForgotDone" />
    <RiotAuthModal v-if="showRiot" @close="showRiot = false" @done="onRiotDone" />
  </form>
</template>
