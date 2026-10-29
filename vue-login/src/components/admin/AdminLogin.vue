<script setup>
/* ============================================================
   后台管理员登录页
   后台与前台是两个独立登录态（admin_token / agent_token），互不影响。
   登录资格：只有 agent_user.permission = 0（管理员权限）的账号能通过校验，
   默认权限（permission = 1）的账号后端会直接拒绝登录。
   登录成功 -> state.admin 有值 -> App.vue 自动切换到 AdminDashboard。
   数据来源：/api/admin/login（AdminController）
   ============================================================ */
import { reactive, ref } from 'vue'
import { switchView, useSession } from '../../store/session'
import { beep } from '../../composables/useSound'

const { adminLogin, showToast } = useSession()

const form = reactive({ username: '', pass: '' })
const busy = ref(false)

async function submit() {
  if (busy.value) return
  if (!form.username.trim() || !form.pass) {
    showToast('请输入账号与密码', false)
    return
  }
  busy.value = true
  const r = await adminLogin(form.username, form.pass)
  busy.value = false
  if (r.ok) {
    beep(660, 0.08)
    showToast(`已接入后台 · ${r.data?.displayName || form.username}`, true)
  } else {
    beep(240, 0.12)
    showToast(r.reason || '登录失败', false)
  }
}
</script>

<template>
  <div class="admin-login">
    <div class="al-box">
      <button class="back" type="button" @click="switchView('home')">← 返回首页</button>

      <div class="al-head">
        <div class="al-tag">ADMIN TERMINAL</div>
        <h1 class="al-title">后台管理系统</h1>
        <p class="al-sub">仅限管理员权限账号接入 · 默认权限账号无法登录</p>
      </div>

      <form class="al-form" @submit.prevent="submit">
        <label class="field">
          <span class="lab">代号 / 邮箱 / USERNAME</span>
          <input
            v-model="form.username"
            type="text"
            autocomplete="username"
            placeholder="你的特工代号或邮箱"
            spellcheck="false"
          />
        </label>

        <label class="field">
          <span class="lab">密码 / PASSWORD</span>
          <input
            v-model="form.pass"
            type="password"
            autocomplete="current-password"
            placeholder="••••••••"
          />
        </label>

        <button class="al-btn" type="submit" :disabled="busy">
          {{ busy ? '验证中 ...' : '接入后台' }}
        </button>
      </form>
    </div>
  </div>
</template>

<style scoped>
.admin-login {
  position: relative;
  z-index: 2;
  min-height: 100vh;
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 86px 20px 24px;
}

.al-box {
  width: 100%;
  max-width: 420px;
  background: rgba(17, 26, 36, .86);
  border: 1px solid var(--line);
  padding: 34px 34px 30px;
  clip-path: polygon(18px 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%, 0 18px);
  animation: up .4s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes up {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: none; }
}

.back {
  display: inline-flex;
  margin-bottom: 20px;
  padding: 8px 15px;
  background: rgba(17, 26, 36, .8);
  border: 1px solid var(--line);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.8px;
  cursor: pointer;
  clip-path: polygon(9px 0, 100% 0, calc(100% - 9px) 100%, 0 100%);
  transition: .2s;
}
.back:hover {
  color: var(--cream);
  border-color: var(--ac);
}

.al-tag {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 4px;
  color: var(--ac);
  margin-bottom: 8px;
}
.al-title {
  margin: 0 0 6px;
  font-family: var(--disp);
  font-size: 34px;
  letter-spacing: 2px;
  color: var(--cream);
  text-transform: uppercase;
}
.al-sub {
  margin: 0 0 26px;
  font-size: 12px;
  color: var(--muted);
}

.field { display: block; margin-bottom: 16px; }
.lab {
  display: block;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2.4px;
  color: var(--muted);
  margin-bottom: 7px;
}
.field input {
  width: 100%;
  padding: 12px 14px;
  background: var(--bg2);
  border: 1px solid var(--line);
  color: var(--cream);
  font-family: var(--mono);
  font-size: 13px;
  outline: none;
  transition: .2s;
}
.field input:focus {
  border-color: var(--ac);
  box-shadow: 0 0 18px -8px var(--ac);
}
.field input::placeholder { color: rgba(127, 142, 155, .5); }

.al-btn {
  width: 100%;
  margin-top: 8px;
  padding: 13px;
  background: var(--red);
  border: none;
  color: #fff;
  font-family: var(--disp);
  font-size: 18px;
  letter-spacing: 4px;
  cursor: pointer;
  clip-path: polygon(12px 0, 100% 0, calc(100% - 12px) 100%, 0 100%);
  transition: .2s;
}
.al-btn:hover { background: var(--red-d); }
.al-btn:disabled { opacity: .6; cursor: wait; }

@media (max-width: 640px) {
  .admin-login { padding: 78px 16px 18px; }
  .al-box { padding: 26px 22px 24px; }
}
</style>
