<script setup>
/* ============================================================
   登录表单
   ============================================================ */
import { reactive, ref, watch } from 'vue'
import FieldInput from './FieldInput.vue'
import { state, currentAgent, EMAIL, useSession } from '../store/session'
import { beep } from '../composables/useSound'
import { useEffects } from '../composables/useEffects'

const { showToast } = useSession()
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

function onSubmit() {
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
  setTimeout(() => {
    loading.value = false
    success(`接入成功 · 欢迎回来，${currentAgent.value.name} 特工`)
  }, 1000)
}

/** 第三方快捷登录（原页面仅作演示反馈） */
function connect(provider) {
  beep(600, 0.07)
  showToast(`正在连接 ${provider} 授权网关...`, false)
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
      <a class="lnk" href="#" @click.prevent>忘记密码?</a>
    </div>

    <button class="btn" type="submit" :class="{ loading }" :disabled="loading">
      <span>进入战场</span>
      <span class="dots"><i></i><i></i><i></i></span>
    </button>

    <div class="alt">或</div>

    <div class="socials">
      <button class="soc" type="button" @click="connect('Riot')">RIOT 账号</button>
      <button class="soc" type="button" @click="connect('Steam')">STEAM</button>
    </div>
  </form>
</template>
