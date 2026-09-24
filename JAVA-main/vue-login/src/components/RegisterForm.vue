<script setup>
/* ============================================================
   注册表单：特工代号 / 邮箱 / 密码 + 加密等级 / 确认密码 / 条款
   ============================================================ */
import { reactive, ref, watch, computed } from 'vue'
import FieldInput from './FieldInput.vue'
import {
  state,
  currentAgent,
  EMAIL,
  SEC_COLORS,
  SEC_TEXTS,
  securityLevel,
  resetRegister,
  useSession
} from '../store/session'
import { beep } from '../composables/useSound'
import { useEffects } from '../composables/useEffects'

const { showToast } = useSession()
const { flash } = useEffects()

const form = state.register
const errors = reactive({ name: false, email: false, pass: false, pass2: false, terms: false })
const loading = ref(false)

// 输入即清除对应字段的错误态
watch(() => form.name, () => { errors.name = false })
watch(() => form.email, () => { errors.email = false })
watch(() => form.pass, () => { errors.pass = false })
watch(() => form.pass2, () => { errors.pass2 = false })
watch(() => form.terms, () => { errors.terms = false })

/* ---------- 加密等级显示 ---------- */
const secFill = computed(() => SEC_COLORS[securityLevel.value - 1] || SEC_COLORS[0])
const secText = computed(() => SEC_TEXTS[securityLevel.value - 1] || '低')
const secTextColor = computed(() => SEC_COLORS[securityLevel.value - 1] || '#7f8e9b')

/** 第 n 段（从 1 开始）是否点亮 */
function segStyle(n) {
  const on = n <= securityLevel.value
  return {
    background: on ? secFill.value : 'rgba(236,232,225,.1)',
    boxShadow: on ? `0 0 10px ${secFill.value}` : 'none'
  }
}

function mark(key, isBad) {
  errors[key] = !!isBad
  return !isBad
}

function onTermsChange(e) {
  form.terms = e.target.checked
}

function onSubmit() {
  const o1 = mark('name', form.name.trim().length < 2)
  const o2 = mark('email', !EMAIL.test(form.email.trim()))
  const o3 = mark('pass', form.pass.length < 6)
  const o4 = mark('pass2', form.pass2 === '' || form.pass2 !== form.pass)
  const o5 = mark('terms', !form.terms)

  if (!(o1 && o2 && o3 && o4 && o5)) {
    beep(160, 0.18, 'sawtooth')
    showToast('创建失败：信息不完整', false)
    return
  }

  loading.value = true
  setTimeout(() => {
    loading.value = false
    flash()
    beep(660, 0.08)
    setTimeout(() => beep(880, 0.08), 90)
    setTimeout(() => beep(1180, 0.16), 180)
    showToast(`特工已创建 · ${currentAgent.value.name} 已加入你的档案`, true)
    resetRegister()
  }, 1000)
}
</script>

<template>
  <form class="form" novalidate @submit.prevent="onSubmit">
    <FieldInput
      v-model="form.name"
      label="特工代号"
      placeholder="CODENAME"
      autocomplete="username"
      :maxlength="14"
      :bad="errors.name"
      error-text="代号至少 2 个字符"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <path d="M12 2 3 7v10l9 5 9-5V7l-9-5Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" />
        </svg>
      </template>
    </FieldInput>

    <FieldInput
      v-model="form.email"
      label="邮箱"
      type="email"
      placeholder="agent@nexus.net"
      autocomplete="email"
      :bad="errors.email"
      error-text="邮箱格式不正确"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <rect x="3" y="5" width="18" height="14" rx="2" stroke="currentColor" stroke-width="1.7" />
          <path d="m4 7 8 6 8-6" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </template>
    </FieldInput>

    <FieldInput
      v-model="form.pass"
      label="密码"
      placeholder="至少 6 位"
      autocomplete="new-password"
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

      <!-- 加密等级 -->
      <div class="secu" :class="{ on: securityLevel > 0 }">
        <div class="lb">
          <span>SECURITY 加密等级</span>
          <span :style="{ color: secTextColor }">{{ secText }}</span>
        </div>
        <div class="segs">
          <i v-for="n in 4" :key="n" :style="segStyle(n)"></i>
        </div>
      </div>
    </FieldInput>

    <FieldInput
      v-model="form.pass2"
      label="确认密码"
      placeholder="再输一次"
      autocomplete="new-password"
      password
      :bad="errors.pass2"
      error-text="两次密码不一致"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <path d="M12 3 4.5 6.5v5c0 4.4 3.1 8.4 7.5 9.5 4.4-1.1 7.5-5.1 7.5-9.5v-5L12 3Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" />
          <path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </template>
    </FieldInput>

    <div class="field" :class="{ bad: errors.terms }">
      <label class="chk" style="text-transform: none; font-size: 12px">
        <input type="checkbox" :checked="form.terms" @change="onTermsChange" />
        <span class="bx">
          <svg width="11" height="11" viewBox="0 0 24 24" fill="none">
            <path d="m5 13 4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
        </span>
        我已阅读并同意
        <a class="lnk" href="#" @click.prevent>服务条款</a>
        与
        <a class="lnk" href="#" @click.prevent>隐私政策</a>
      </label>
      <span class="emsg">请先同意服务条款</span>
    </div>

    <button class="btn" type="submit" :class="{ loading }" :disabled="loading">
      <span>创建特工</span>
      <span class="dots"><i></i><i></i><i></i></span>
    </button>
  </form>
</template>
