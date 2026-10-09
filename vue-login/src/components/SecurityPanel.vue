<script setup>
/* ============================================================
   安全设置：修改密码
   ============================================================ */
import { reactive, ref, watch } from 'vue'
import FieldInput from './FieldInput.vue'
import { authChangePass, useSession } from '../store/session'
import { beep } from '../composables/useSound'
import { useEffects } from '../composables/useEffects'

const { showToast } = useSession()
const { flash } = useEffects()

const form = reactive({ oldPass: '', newPass: '', newPass2: '' })
const errors = reactive({ oldPass: false, newPass: false, newPass2: false })
const loading = ref(false)

watch(() => form.oldPass, () => { errors.oldPass = false })
watch(() => form.newPass, () => { errors.newPass = false })
watch(() => form.newPass2, () => { errors.newPass2 = false })

function mark(key, isBad) {
  errors[key] = !!isBad
  return !isBad
}

async function onSubmit() {
  const o1 = mark('oldPass', form.oldPass.length < 6)
  const o2 = mark('newPass', form.newPass.length < 6)
  const o3 = mark('newPass2', form.newPass2 === '' || form.newPass2 !== form.newPass)

  if (!(o1 && o2 && o3)) {
    beep(160, 0.18, 'sawtooth')
    showToast('修改失败：请检查输入', false)
    return
  }
  if (form.newPass === form.oldPass) {
    mark('newPass', true)
    beep(160, 0.18, 'sawtooth')
    showToast('新密码不能与旧密码相同', false)
    return
  }

  loading.value = true
  const r = await authChangePass(form.oldPass, form.newPass)
  loading.value = false

  if (!r.ok) {
    beep(160, 0.18, 'sawtooth')
    if (r.reason === 'wrongpass') errors.oldPass = true
    const hints = {
      wrongpass: '旧密码错误 · 请重新输入',
      'network-error': '无法连接服务器 · 请确认后端已启动'
    }
    showToast(hints[r.reason] || `修改失败：${r.reason}`, false)
    return
  }

  flash()
  beep(660, 0.08)
  setTimeout(() => beep(880, 0.08), 90)
  showToast('密码已更新 · 请牢记你的新凭证', true)
  form.oldPass = ''
  form.newPass = ''
  form.newPass2 = ''
}

function reset() {
  form.oldPass = ''
  form.newPass = ''
  form.newPass2 = ''
  errors.oldPass = false
  errors.newPass = false
  errors.newPass2 = false
}
</script>

<template>
  <form class="form on" novalidate @submit.prevent="onSubmit">
    <FieldInput
      v-model="form.oldPass"
      label="当前密码"
      placeholder="输入旧密码"
      autocomplete="current-password"
      password
      :bad="errors.oldPass"
      error-text="旧密码至少 6 位"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <rect x="4" y="10" width="16" height="11" rx="2" stroke="currentColor" stroke-width="1.7" />
          <path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" />
        </svg>
      </template>
    </FieldInput>

    <FieldInput
      v-model="form.newPass"
      label="新密码"
      placeholder="至少 6 位"
      autocomplete="new-password"
      password
      :bad="errors.newPass"
      error-text="新密码至少 6 位"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <path d="M12 3 4.5 6.5v5c0 4.4 3.1 8.4 7.5 9.5 4.4-1.1 7.5-5.1 7.5-9.5v-5L12 3Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" />
          <path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </template>
    </FieldInput>

    <FieldInput
      v-model="form.newPass2"
      label="确认新密码"
      placeholder="再输一次"
      autocomplete="new-password"
      password
      :bad="errors.newPass2"
      error-text="两次密码不一致"
    >
      <template #icon>
        <svg class="ic" width="17" height="17" viewBox="0 0 24 24" fill="none">
          <path d="M12 2 3 7v10l9 5 9-5V7l-9-5Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" />
          <path d="m9 12 2 2 4-4" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" stroke-linejoin="round" />
        </svg>
      </template>
    </FieldInput>

    <div class="ops">
      <button class="btn sub" type="button" @click="reset">清空</button>
      <button class="btn main" type="submit" :class="{ loading }" :disabled="loading">
        <span>更新密码</span>
        <span class="dots"><i></i><i></i><i></i></span>
      </button>
    </div>

    <div class="note">修改密码后其他设备的登录态不受影响，如需强制下线请到「会话」页踢出。</div>
  </form>
</template>

<style scoped>
.ops {
  display: grid;
  grid-template-columns: 1fr 2fr;
  gap: 10px;
  margin-top: 4px;
}
.btn.sub {
  color: var(--muted);
  border-color: var(--line);
}
.btn.sub::before { background: rgba(236, 232, 225, .15); }
.btn.sub:hover { color: var(--cream); box-shadow: none; }

.note {
  margin-top: 14px;
  font-family: var(--mono);
  font-size: 10px;
  color: var(--muted);
  letter-spacing: 1px;
  text-align: center;
  line-height: 1.8;
}
</style>
