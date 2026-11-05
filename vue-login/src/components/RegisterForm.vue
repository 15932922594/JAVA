<script setup>
/* ============================================================
   注册表单：英雄选择 / 特工代号 / 邮箱 / 密码 + 加密等级 / 确认密码 / 条款
   ============================================================ */
import { reactive, ref, watch, computed } from 'vue'
import FieldInput from './FieldInput.vue'
import { AGENTS, roleShort } from '../data/agents'
import {
  state,
  EMAIL,
  SEC_COLORS,
  SEC_TEXTS,
  securityLevel,
  resetRegister,
  authRegister,
  selectAgent,
  useSession
} from '../store/session'
import { beep } from '../composables/useSound'
import { useEffects } from '../composables/useEffects'

const { showToast, switchMode } = useSession()
const { flash } = useEffects()

const form = state.register
const errors = reactive({ name: false, email: false, pass: false, pass2: false, terms: false })
const loading = ref(false)

/* ---------- 英雄选择 ---------- */
const hero = computed(() => AGENTS[state.agentIndex] || AGENTS[0])

/** 点击英雄卡片：选中并同步到全局 agentIndex（注册时会随表单一并提交） */
function pickHero(i) {
  if (i === state.agentIndex) {
    beep(520, 0.06)
    return
  }
  selectAgent(i)
  beep(760, 0.07)
}

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

/** 后端错误码 -> 字段标记 + 提示文案 */
const DUP_FIELDS = { 'duplicate-email': 'email', 'duplicate-name': 'name' }
const DUP_HINTS = {
  'duplicate-email': '该邮箱已被注册',
  'duplicate-name': '该代号已被占用',
  'network-error': '无法连接服务器 · 请确认后端已启动'
}

async function onSubmit() {
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
  const r = await authRegister(form.name, form.email, form.pass, state.agentIndex)
  loading.value = false

  if (!r.ok) {
    beep(160, 0.18, 'sawtooth')
    const field = DUP_FIELDS[r.reason]
    if (field) errors[field] = true
    showToast(DUP_HINTS[r.reason] || `创建失败：${r.reason}`, false)
    return
  }

  flash()
  beep(660, 0.08)
  setTimeout(() => beep(880, 0.08), 90)
  setTimeout(() => beep(1180, 0.16), 180)
  showToast(`特工已创建 · ${hero.value.name} 加入战场，用代号 ${form.name.trim()} 即可登录`, true)
  // 注册成功后带回代号，切到登录页直接可登录
  state.login.id = form.name.trim()
  resetRegister()
  switchMode('login')
}
</script>

<template>
  <form class="form" novalidate @submit.prevent="onSubmit">
    <!-- 英雄选择：6 张卡片，点击锁定你的角色 -->
    <div class="heropick">
      <div class="hp-head">
        <span class="hp-title">选择你的英雄</span>
        <span class="hp-cur" :style="{ color: hero.color }">
          {{ hero.name }} · {{ roleShort(hero.role) }}
        </span>
      </div>
      <div class="hp-grid">
        <button
          v-for="(a, i) in AGENTS"
          :key="a.id"
          type="button"
          class="hp-card"
          :class="{ sel: i === state.agentIndex }"
          :style="{ '--ac': a.color }"
          :title="a.bio"
          @click="pickHero(i)"
        >
          <img class="hp-img" :src="a.img" :alt="a.name" draggable="false" loading="lazy" />
          <span class="hp-mono">{{ a.mono }}</span>
          <span class="hp-name">{{ a.name }}</span>
          <span class="hp-role">{{ roleShort(a.role) }}</span>
          <span class="hp-lock">
            <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
              <path d="m5 13 4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
            </svg>
            LOCK IN
          </span>
        </button>
      </div>
      <p class="hp-bio">{{ hero.bio }}</p>
    </div>

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
      <span>创建特工 · {{ hero.name }}</span>
      <span class="dots"><i></i><i></i><i></i></span>
    </button>
  </form>
</template>

<style scoped>
/* ============================================================
   英雄选择：VALORANT 特工锁定风格的 6 卡选择组
   ============================================================ */
.heropick {
  display: flex;
  flex-direction: column;
  gap: 10px;
  padding: 14px;
  background: rgba(236, 232, 225, .04);
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
}

.hp-head {
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  gap: 10px;
}
.hp-title {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 2px;
  color: var(--muted);
  text-transform: uppercase;
}
.hp-cur {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 1.5px;
  text-transform: uppercase;
  text-shadow: 0 0 18px currentColor;
}

.hp-grid {
  display: grid;
  grid-template-columns: repeat(6, 1fr);
  gap: 8px;
}

.hp-card {
  position: relative;
  overflow: hidden;
  aspect-ratio: 3/4;
  min-height: 84px;
  padding: 0;
  border: 1px solid var(--line);
  background: linear-gradient(160deg, #0e1721, #0a1119);
  clip-path: polygon(0 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%);
  cursor: pointer;
  transition: transform .22s, border-color .22s, box-shadow .22s;
}
.hp-img {
  position: absolute;
  inset: 0;
  width: 100%;
  height: 100%;
  object-fit: cover;
  object-position: center 12%;
  opacity: .55;
  transition: opacity .25s, transform .25s;
  user-select: none;
  pointer-events: none;
}
.hp-card::before {
  content: "";
  position: absolute;
  inset: 0;
  z-index: 1;
  background: linear-gradient(to bottom, rgba(9, 14, 20, .2), transparent 45%, rgba(9, 14, 20, .92));
  pointer-events: none;
}
.hp-mono {
  position: absolute;
  right: -3px;
  bottom: -14px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 44px;
  color: transparent;
  -webkit-text-stroke: 1.2px color-mix(in srgb, var(--ac) 65%, #fff 10%);
  opacity: .6;
  transition: .25s;
}
.hp-name {
  position: absolute;
  left: 6px;
  bottom: 12px;
  z-index: 2;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 10.5px;
  letter-spacing: 1px;
  color: var(--cream);
  text-transform: uppercase;
}
.hp-role {
  position: absolute;
  left: 6px;
  top: 6px;
  z-index: 2;
  font-family: var(--mono);
  font-size: 7.5px;
  letter-spacing: .8px;
  color: var(--ac);
}

/* 悬停：立绘点亮 + 上浮 */
.hp-card:hover {
  transform: translateY(-5px);
  border-color: color-mix(in srgb, var(--ac) 70%, transparent);
}
.hp-card:hover .hp-img { opacity: .95; transform: scale(1.06); }
.hp-card:hover .hp-mono { opacity: 1; transform: translateY(-4px); }

/* 选中：描边发光 + LOCK IN 角标 */
.hp-card.sel {
  border-color: var(--ac);
  box-shadow: 0 0 22px -6px var(--ac);
  transform: translateY(-3px);
}
.hp-card.sel .hp-img { opacity: 1; }
.hp-card.sel .hp-mono { opacity: 1; }
.hp-card.sel::after {
  content: "";
  position: absolute;
  left: 0;
  bottom: 0;
  z-index: 2;
  width: 100%;
  height: 3px;
  background: var(--ac);
}
.hp-lock {
  position: absolute;
  right: 5px;
  bottom: 5px;
  z-index: 3;
  display: none;
  align-items: center;
  gap: 3px;
  padding: 3px 6px;
  background: var(--ac);
  color: #0a1119;
  font-family: var(--mono);
  font-size: 7.5px;
  font-weight: 700;
  letter-spacing: 1px;
  clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%);
}
.hp-card.sel .hp-lock { display: inline-flex; }

/* 当前英雄简介 */
.hp-bio {
  margin: 0;
  font-family: var(--mono);
  font-size: 10.5px;
  line-height: 1.6;
  letter-spacing: .5px;
  color: var(--muted);
}

@media (max-width: 640px) {
  .hp-grid { grid-template-columns: repeat(3, 1fr); }
  .hp-name { font-size: 12px; }
}
</style>
