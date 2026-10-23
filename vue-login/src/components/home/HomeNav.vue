<script setup>
/* ============================================================
   首页导航栏
   沿用登录页的 HUD 语言：斜切色块、多边形裁角、红辉光、等宽小标签。
   ============================================================ */
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { state, agentLevel, accent, switchView, enterAdmin, useSession } from '../../store/session'
import { beep, toggleSound } from '../../composables/useSound'

const { showToast, authLogout } = useSession()

/**
 * 导航项（全部已实现，数据来自后端 /api/home/*）
 *  key 对应 state.view：home 首页 / agents 特工档案 / arsenal 武器库
 *  / missions 作战任务 / intel 情报中心
 */
const NAVS = [
  { key: 'home', label: '首页' },
  { key: 'agents', label: '特工档案' },
  { key: 'arsenal', label: '武器库' },
  { key: 'missions', label: '作战任务' },
  { key: 'intel', label: '情报中心' }
]

const active = computed(() => state.view)

/* ---------- 用户菜单 ---------- */
const menuOpen = ref(false)
const menuEl = ref(null)

function toggleMenu() {
  menuOpen.value = !menuOpen.value
  beep(menuOpen.value ? 720 : 520, 0.05)
}

function closeMenu() {
  menuOpen.value = false
}

function onDocClick(e) {
  if (menuOpen.value && menuEl.value && !menuEl.value.contains(e.target)) closeMenu()
}
onMounted(() => document.addEventListener('click', onDocClick))
onBeforeUnmount(() => document.removeEventListener('click', onDocClick))

/* ---------- 导航点击 ---------- */
function onNav(n) {
  if (state.view === n.key) return
  beep(640, 0.07)
  switchView(n.key)
}

/* ---------- 后台管理系统（独立登录） ---------- */
function goAdmin() {
  beep(680, 0.07)
  enterAdmin()
}

/* ---------- 作战终端 ---------- */
function goDash() {
  closeMenu()
  beep(660, 0.07)
  switchView('dash')
}

/* ---------- 退出登录 ---------- */
const loggingOut = ref(false)
async function onLogout() {
  if (loggingOut.value) return
  closeMenu()
  loggingOut.value = true
  beep(240, 0.12, 'sawtooth')
  await authLogout()
  showToast('已断开连接 · 会话已注销', false)
  loggingOut.value = false
}

/** 头像里的特工字母 */
const mono = computed(() => (state.user?.name || '?').trim().charAt(0).toUpperCase())
</script>

<template>
  <header class="nav">
    <div class="inner">
      <!-- 品牌 -->
      <a class="brand" href="#" @click.prevent="onNav(NAVS[0])">
        <span class="slash"></span>
        AGENT <b>ACCESS</b>
      </a>

      <!-- 导航项 -->
      <nav class="links">
        <button
          v-for="n in NAVS"
          :key="n.key"
          class="link"
          :class="{ on: active === n.key || (n.key === 'home' && (active === 'home' || active === 'dash')) }"
          type="button"
          @click="onNav(n)"
        >
          {{ n.label }}
        </button>
      </nav>

      <span class="sp"></span>

      <!-- 后台管理入口 -->
      <button class="admin-btn" type="button" title="进入后台管理系统" @click="goAdmin">
        <svg width="15" height="15" viewBox="0 0 24 24" fill="none">
          <path d="M12 15.5a3.5 3.5 0 1 0 0-7 3.5 3.5 0 0 0 0 7Z" stroke="currentColor" stroke-width="1.7" />
          <path
            d="M19.4 13a7.7 7.7 0 0 0 0-2l2-1.5-2-3.4-2.4 1a7.6 7.6 0 0 0-1.7-1l-.4-2.6h-4l-.4 2.6a7.6 7.6 0 0 0-1.7 1l-2.4-1-2 3.4L6.6 11a7.7 7.7 0 0 0 0 2l-2 1.5 2 3.4 2.4-1a7.6 7.6 0 0 0 1.7 1l.4 2.6h4l.4-2.6a7.6 7.6 0 0 0 1.7-1l2.4 1 2-3.4-2-1.5Z"
            stroke="currentColor"
            stroke-width="1.6"
            stroke-linejoin="round"
          />
        </svg>
        后台管理
      </button>

      <!-- 右侧：音效 + 用户 -->
      <button class="icon-btn" :class="{ muted: !state.soundOn }" title="音效" aria-label="音效开关" @click.stop="toggleSound">
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none">
          <path d="M4 9v6h4l5 4V5L8 9H4Z" stroke="currentColor" stroke-width="1.7" stroke-linejoin="round" />
          <path d="M16.5 8.5a5 5 0 0 1 0 7" stroke="currentColor" stroke-width="1.7" stroke-linecap="round" :opacity="state.soundOn ? '1' : '.25'" />
        </svg>
      </button>

      <div ref="menuEl" class="user">
        <button class="chip" type="button" :class="{ open: menuOpen }" @click.stop="toggleMenu">
          <span class="ava">{{ mono }}</span>
          <span class="meta">
            <b>{{ state.user?.name || '未接入' }}</b>
            <i>LV.{{ agentLevel }}</i>
          </span>
          <svg class="caret" width="11" height="11" viewBox="0 0 24 24" fill="none">
            <path d="m6 9 6 6 6-6" stroke="currentColor" stroke-width="2.4" stroke-linecap="round" stroke-linejoin="round" />
          </svg>
        </button>

        <div v-if="menuOpen" class="menu">
          <button class="mi" type="button" @click="goDash">作战终端</button>
          <button class="mi danger" type="button" :disabled="loggingOut" @click="onLogout">
            {{ loggingOut ? '正在断开…' : '退出登录' }}
          </button>
        </div>
      </div>
    </div>
  </header>
</template>

<style scoped>
.nav {
  position: fixed;
  top: 0;
  left: 0;
  right: 0;
  z-index: 40;
  background: linear-gradient(180deg, rgba(10, 17, 25, .96), rgba(10, 17, 25, .78));
  border-bottom: 1px solid var(--line);
  backdrop-filter: blur(10px);
}
.nav::after {
  /* 底部一道细的强调渐变线，呼应登录页的分割条 */
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  bottom: -1px;
  height: 1px;
  background: linear-gradient(90deg, var(--ac), transparent 42%);
  opacity: .8;
}

.inner {
  max-width: 1280px;
  margin: 0 auto;
  height: 74px;
  padding: 0 26px;
  display: flex;
  align-items: center;
  gap: 22px;
}

/* ---------- 品牌 ---------- */
.brand {
  display: flex;
  align-items: center;
  gap: 10px;
  font-family: var(--disp);
  font-weight: 700;
  letter-spacing: 3px;
  font-size: 19px;
  text-transform: uppercase;
  color: var(--cream);
  text-decoration: none;
  flex-shrink: 0;
}
.brand .slash {
  width: 20px;
  height: 20px;
  background: var(--red);
  transform: skewX(-14deg);
  box-shadow: 0 0 18px -2px var(--red);
}
.brand b { color: var(--red); }

/* ---------- 导航 ---------- */
.links { display: flex; align-items: center; gap: 4px; }
.link {
  position: relative;
  border: 0;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 2.2px;
  padding: 9px 15px;
  transition: .22s;
  clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
  display: flex;
  align-items: center;
  gap: 6px;
}
.link:hover { color: var(--cream); background: rgba(236, 232, 225, .05); }
.link.on {
  color: #fff;
  background: var(--ac);
  box-shadow: 0 0 26px -8px var(--ac);
}
.sp { flex: 1; }

/* ---------- 后台管理按钮 ---------- */
.admin-btn {
  display: flex;
  align-items: center;
  gap: 6px;
  height: 38px;
  flex-shrink: 0;
  padding: 0 14px;
  background: rgba(17, 26, 36, .7);
  border: 1px solid var(--line);
  color: var(--cream);
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  letter-spacing: 2px;
  clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
  transition: .2s;
}
.admin-btn:hover {
  color: #fff;
  border-color: var(--red);
  background: rgba(255, 70, 85, .14);
  box-shadow: 0 0 20px -6px var(--red);
}

/* ---------- 图标按钮 ---------- */
.icon-btn {
  width: 38px;
  height: 38px;
  flex-shrink: 0;
  display: grid;
  place-items: center;
  background: rgba(17, 26, 36, .7);
  border: 1px solid var(--line);
  color: var(--cream);
  cursor: pointer;
  clip-path: polygon(8px 0, 100% 0, 100% calc(100% - 8px), calc(100% - 8px) 100%, 0 100%, 0 8px);
  transition: .2s;
}
.icon-btn:hover { border-color: var(--red); color: var(--red); box-shadow: 0 0 18px -6px var(--red); }
.icon-btn.muted { color: var(--muted); }

/* ---------- 用户芯片 ---------- */
.user { position: relative; flex-shrink: 0; }
.chip {
  display: flex;
  align-items: center;
  gap: 10px;
  height: 42px;
  padding: 0 12px;
  background: rgba(17, 26, 36, .8);
  border: 1px solid var(--line);
  color: var(--cream);
  cursor: pointer;
  clip-path: polygon(9px 0, 100% 0, 100% calc(100% - 9px), calc(100% - 9px) 100%, 0 100%, 0 9px);
  transition: .2s;
}
.chip:hover, .chip.open { border-color: var(--ac); box-shadow: 0 0 20px -8px var(--ac); }
.ava {
  width: 26px;
  height: 26px;
  display: grid;
  place-items: center;
  background: var(--ac);
  color: #fff;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  transform: skewX(-10deg);
}
.ava > * { transform: skewX(10deg); }
.meta { display: flex; flex-direction: column; align-items: flex-start; line-height: 1.15; }
.meta b { font-size: 12.5px; letter-spacing: .5px; }
.meta i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 9.5px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.caret { color: var(--muted); transition: .2s; }
.chip.open .caret { transform: rotate(180deg); color: var(--ac); }

/* ---------- 下拉菜单 ---------- */
.menu {
  position: absolute;
  right: 0;
  top: calc(100% + 10px);
  min-width: 158px;
  background: rgba(17, 26, 36, .97);
  border: 1px solid var(--line);
  backdrop-filter: blur(8px);
  padding: 6px;
  clip-path: polygon(10px 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%, 0 10px);
  box-shadow: 0 26px 60px -30px #000;
  animation: drop .18s ease-out both;
}
@keyframes drop {
  from { opacity: 0; transform: translateY(-6px); }
  to { opacity: 1; transform: none; }
}
.mi {
  display: block;
  width: 100%;
  border: 0;
  background: transparent;
  color: var(--cream);
  text-align: left;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  letter-spacing: 2px;
  padding: 10px 12px;
  cursor: pointer;
  transition: .18s;
}
.mi:hover { background: rgba(236, 232, 225, .07); color: #fff; }
.mi.danger { color: var(--red); }
.mi.danger:hover { background: var(--red); color: #fff; }
.mi:disabled { opacity: .5; cursor: default; }

/* ---------- 响应式 ---------- */
@media (max-width: 1080px) {
  .links { gap: 0; }
  .link { padding: 9px 10px; font-size: 14px; letter-spacing: 1.4px; }
  .soon { display: none; }
}
@media (max-width: 860px) {
  .inner { gap: 14px; padding: 0 16px; height: 66px; }
  .links { display: none; }
}
@media (max-width: 560px) {
  .brand { font-size: 15px; letter-spacing: 2px; }
  .meta { display: none; }
}
</style>
