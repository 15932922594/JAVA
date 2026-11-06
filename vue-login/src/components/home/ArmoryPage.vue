<script setup>
/* ============================================================
   军械商店页（ARMORY）—— 信用点购买武器
   - 顶栏余额 / 英雄等级 / 已拥有数
   - 武器卡：按后端目录顺序展示（标配免费 → 冥狙最贵）
   - 点击购买：扣信用点，余额实时刷新
   数据来源：/api/game/armory（ArmoryController）
   ============================================================ */
import { computed, onMounted, ref, watch } from 'vue'
import { state, currentAgent, switchView, useSession } from '../../store/session'
import { armory, armoryBuy } from '../../store/api'
import { WEAPONS, WEAPON_FALLBACK } from '../../data/weapons'
import { frameClassOf, frameOfTier, frameStyleOf, frameTierOf, nextFrameOf } from '../../data/frames'
import HomeNav from './HomeNav.vue'
import { beep } from '../../composables/useSound'
import { useEffects } from '../../composables/useEffects'

const { showToast } = useSession()
const { flash } = useEffects()

const token = computed(() => state.token || '')

const loading = ref(false)
const credits = ref(0)
const heroLevel = ref(1)
const weapons = ref([])

/** 已拥有武器数（标配免费直接计入） */
const ownedCount = computed(() => weapons.value.filter((w) => w.owned).length)

/** 当前头像框（佩戴中档位以后端为准）& 下一档 */
const myFrame = computed(() =>
  frameOfTier(Number.isFinite(state.user?.frameTier) && state.user.frameTier >= 1
    ? state.user.frameTier
    : frameTierOf(heroLevel.value || 1))
)
const myNextFrame = computed(() => nextFrameOf(heroLevel.value || 1))

/** 经验进度（来自登录态，升级后实时刷新；等级无上限，不会有满级状态） */
const expInfo = computed(() => {
  const u = state.user
  if (!u) return { inLevel: 0, need: 100, pct: 0 }
  const need = u.expForNext || 100
  const inLevel = Math.min(u.expInLevel || 0, need)
  return { inLevel, need, pct: need > 0 ? inLevel / need : 0 }
})

/** 余额是否够买（未拥有且余额不足的卡片置灰） */
function affordable(w) {
  return w.price === 0 || credits.value >= w.price
}

/** 等级是否达标（低于武器要求等级则锁定） */
function levelOk(w) {
  return heroLevel.value >= (w.reqLevel || 1)
}

/** 购买中的武器 code（按钮转圈防重复点击） */
const buying = ref('')

async function load() {
  if (!token.value) return
  loading.value = true
  const r = await armory(token.value)
  loading.value = false
  if (r.code !== 0) {
    showToast(`军械商店加载失败 · ${r.msg || '未知错误'}`, false)
    return
  }
  credits.value = r.data.credits ?? 0
  heroLevel.value = r.data.heroLevel ?? 1
  weapons.value = r.data.weapons || []
  // 同步账号余额（导航栏 / 首页可用）
  if (state.user) state.user.credits = credits.value
}

const BUY_HINTS = {
  'unknown-weapon': '武器不存在',
  'already-owned': '你已经拥有这把武器',
  'level-too-low': '英雄等级不足 · 打训练场升级后再来',
  'not-enough-credits': '信用点不足 · 去训练场赚一点'
}

async function buy(w) {
  if (buying.value || w.owned) return
  if (!levelOk(w)) {
    beep(160, 0.18, 'sawtooth')
    showToast(`需要英雄 LV.${w.reqLevel} 才能解锁 ${w.name}`, false)
    return
  }
  if (!affordable(w)) {
    beep(160, 0.18, 'sawtooth')
    showToast('信用点不足 · 去训练场赚一点', false)
    return
  }
  buying.value = w.code
  const r = await armoryBuy(token.value, w.code)
  buying.value = ''
  if (r.code !== 0) {
    beep(160, 0.18, 'sawtooth')
    showToast(BUY_HINTS[r.msg] || `购买失败：${r.msg}`, false)
    return
  }

  // 购买成功：刷新余额与拥有状态（本地标记，避免整页重拉）
  const name = WEAPONS[w.code]?.name || w.name
  credits.value = r.data.credits ?? credits.value
  if (state.user) state.user.credits = credits.value
  w.owned = true
  beep(660, 0.08)
  setTimeout(() => beep(1180, 0.16), 110)
  flash()
  showToast(`${name} 已购入 · 余额 ${credits.value} 信用点`, true)
}

function backHome() {
  beep(520, 0.06)
  switchView('home')
}

onMounted(load)
watch(token, (v) => v && load())
</script>

<template>
  <div class="page">
    <HomeNav />

    <main class="main">
      <!-- ========== 页头 ========== -->
      <header class="phead">
        <p class="crumbs">
          <button type="button" class="crumb" @click="backHome">首页</button>
          <span class="sep">/</span>
          <span class="cur">军械商店</span>
        </p>
        <div class="hrow">
          <h1>军械商店<i>ARMORY</i></h1>
          <p class="sub">
            当前英雄 <b>{{ currentAgent.name }}</b> · LV.{{ heroLevel }} ·
            训练场对战可赚取信用点
          </p>
        </div>
      </header>

      <!-- ========== 余额栏 ========== -->
      <section class="wallet">
        <div class="wcard credits">
          <span class="wk">CREDITS</span>
          <b>{{ credits }}</b>
          <span class="wl">信用点余额</span>
        </div>
        <div class="wcard">
          <span class="wk">HERO</span>
          <b>LV.{{ heroLevel }}</b>
          <span class="wl">
            {{ currentAgent.name }} · {{ expInfo.inLevel }}/{{ expInfo.need }} EXP
          </span>
          <span class="xpbar"><em :style="{ width: (expInfo.pct * 100).toFixed(1) + '%' }"></em></span>
          <span class="wframe">
            <em
              class="fdot"
              :class="frameClassOf(myFrame.tier)"
              :style="{ ...frameStyleOf(myFrame.tier), '--hc': currentAgent.color }"
            ></em>
            边框 {{ myFrame.name }}
            <i>· LV.{{ myNextFrame.level }} 解锁「{{ myNextFrame.name }}」</i>
          </span>
        </div>
        <div class="wcard">
          <span class="wk">OWNED</span>
          <b>{{ ownedCount }}<i>/{{ weapons.length }}</i></b>
          <span class="wl">已拥有武器</span>
        </div>
      </section>

      <!-- ========== 武器架 ========== -->
      <section class="grid" :class="{ dim: loading }">
        <article
          v-for="w in weapons"
          :key="w.code"
          class="wbox"
          :class="{ owned: w.owned, poor: !affordable(w) || !levelOk(w), locked: !w.owned && !levelOk(w) }"
          :style="{ '--wc': (WEAPONS[w.code] || WEAPON_FALLBACK).color }"
        >
          <!-- 武器代号水印 -->
          <span class="wmono">{{ (WEAPONS[w.code] || WEAPON_FALLBACK).mono }}</span>

          <!-- 等级门槛角标 -->
          <span v-if="!levelOk(w) && !w.owned" class="wlock">
            <svg width="10" height="10" viewBox="0 0 24 24" fill="none">
              <rect x="4" y="10" width="16" height="11" rx="2" stroke="currentColor" stroke-width="2" />
              <path d="M8 10V7a4 4 0 0 1 8 0v3" stroke="currentColor" stroke-width="2" stroke-linecap="round" />
            </svg>
            LV.{{ w.reqLevel }} 解锁
          </span>

          <div class="winfo">
            <span class="wcat">{{ w.category }}</span>
            <h3 class="wname">{{ WEAPONS[w.code]?.name || w.name }}</h3>
            <span class="wen">{{ (WEAPONS[w.code] || WEAPON_FALLBACK).en }}</span>
            <p class="wdesc">{{ (WEAPONS[w.code] || WEAPON_FALLBACK).desc }}</p>
          </div>

          <!-- 价格 / 已拥有 -->
          <div class="wfoot">
            <span class="price" :class="{ free: w.price === 0 }">
              <template v-if="w.price === 0">免费配发</template>
              <template v-else>{{ w.price }} <i>信用点</i></template>
            </span>

            <button
              class="buy"
              type="button"
              :disabled="w.owned || !!buying || !levelOk(w)"
              @click="buy(w)"
            >
              <template v-if="w.owned">
                <svg width="12" height="12" viewBox="0 0 24 24" fill="none">
                  <path d="m5 13 4 4L19 7" stroke="currentColor" stroke-width="3" stroke-linecap="round" stroke-linejoin="round" />
                </svg>
                已拥有
              </template>
              <template v-else-if="buying === w.code">购买中…</template>
              <template v-else-if="!levelOk(w)">需 LV.{{ w.reqLevel }}</template>
              <template v-else>{{ w.price === 0 ? '免费领取' : '购买' }}</template>
            </button>
          </div>
        </article>
      </section>

      <p v-if="!loading && !weapons.length" class="empty">军械库为空 · 稍后再来看看</p>
    </main>
  </div>
</template>

<style scoped>
.page { min-height: 100vh; display: flex; flex-direction: column; }

.main {
  flex: 1;
  width: 100%;
  max-width: 1280px;
  margin: 0 auto;
  padding: 104px 26px 54px;
}

/* ========== 页头 ========== */
.phead {
  padding-bottom: 18px;
  border-bottom: 1px solid var(--line);
  animation: up .45s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes up {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: none; }
}
.crumbs {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 10px;
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.8px;
  color: var(--muted);
}
.crumb {
  border: 0;
  background: transparent;
  padding: 0;
  color: var(--muted);
  cursor: pointer;
  font: inherit;
  letter-spacing: inherit;
  transition: .18s;
}
.crumb:hover { color: var(--ac); }
.sep { opacity: .5; }
.cur { color: var(--cream); }

.hrow { display: flex; align-items: flex-end; justify-content: space-between; gap: 18px; flex-wrap: wrap; }
.phead h1 {
  margin: 0;
  display: flex;
  align-items: baseline;
  gap: 12px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 46px;
  letter-spacing: 3.4px;
  text-transform: uppercase;
}
.phead h1 i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 11px;
  letter-spacing: 2.4px;
  color: var(--muted);
}
.sub {
  margin: 0 0 6px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.sub b { color: var(--ac); font-size: 13px; }

/* ========== 余额栏 ========== */
.wallet {
  display: grid;
  grid-template-columns: repeat(3, 1fr);
  gap: 14px;
  margin: 22px 0 26px;
}
.wcard {
  position: relative;
  padding: 16px 18px 14px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .92), rgba(15, 25, 35, .94));
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
  animation: up .45s .06s cubic-bezier(.2, 1, .3, 1) both;
}
.wcard.credits { border-color: color-mix(in srgb, var(--red) 55%, transparent); }
.wcard .wk {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 2px;
  color: var(--muted);
}
.wcard b {
  display: block;
  margin: 4px 0 2px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 30px;
  letter-spacing: 1px;
  color: var(--cream);
}
.wcard.credits b { color: var(--red); text-shadow: 0 0 22px rgba(255, 70, 85, .45); }
.wcard b i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 13px;
  color: var(--muted);
}
.wcard .wl {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1px;
  color: var(--muted);
}
.wcard .xpbar {
  display: block;
  margin-top: 8px;
  height: 3px;
  background: rgba(236, 232, 225, .14);
  overflow: hidden;
}
.wcard .xpbar em {
  display: block;
  height: 100%;
  background: var(--ac);
  box-shadow: 0 0 8px var(--ac);
  transition: width .45s cubic-bezier(.2, 1, .3, 1);
}

/* 头像框档位提示 */
.wframe {
  display: flex;
  align-items: center;
  gap: 6px;
  margin-top: 10px;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: .8px;
  color: var(--muted);
}
.wframe i { font-style: normal; opacity: .9; }
.wframe .fdot {
  width: 14px;
  height: 14px;
  background: rgba(9, 14, 20, .9);
  flex-shrink: 0;
}

/* ========== 武器架 ========== */
.grid {
  display: grid;
  grid-template-columns: repeat(4, 1fr);
  gap: 16px;
  transition: opacity .2s;
}
.grid.dim { opacity: .45; }

.wbox {
  position: relative;
  overflow: hidden;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 18px 18px 16px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .92), rgba(15, 25, 35, .94));
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
  transition: transform .22s, border-color .22s, box-shadow .22s;
  animation: up .45s .1s cubic-bezier(.2, 1, .3, 1) both;
}
.wbox:hover {
  transform: translateY(-5px);
  border-color: color-mix(in srgb, var(--wc) 65%, transparent);
  box-shadow: 0 24px 50px -30px var(--wc);
}

/* 武器代号大水印 */
.wmono {
  position: absolute;
  right: -4px;
  top: -18px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 84px;
  line-height: 1;
  color: transparent;
  -webkit-text-stroke: 1.5px color-mix(in srgb, var(--wc) 55%, transparent);
  opacity: .5;
  pointer-events: none;
  transition: .25s;
}
.wbox:hover .wmono { opacity: .95; transform: translateY(4px); }

.winfo { position: relative; z-index: 1; }
.wcat {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.6px;
  color: var(--wc);
}
.wname {
  margin: 5px 0 1px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 26px;
  letter-spacing: 2px;
  color: var(--cream);
  text-transform: uppercase;
}
.wen {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 2.4px;
  color: var(--muted);
}
.wdesc {
  margin: 10px 0 0;
  font-family: var(--mono);
  font-size: 10.5px;
  line-height: 1.7;
  letter-spacing: .4px;
  color: var(--muted);
}

/* ========== 底部：价格 + 购买 ========== */
.wfoot {
  margin-top: auto;
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 10px;
  position: relative;
  z-index: 1;
}
.price {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 17px;
  letter-spacing: 1px;
  color: var(--cream);
}
.price i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 9.5px;
  letter-spacing: 1px;
  color: var(--muted);
}
.price.free { color: var(--wc); }

.buy {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  padding: 9px 16px;
  background: var(--wc);
  color: #0a1119;
  border: 0;
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 1.6px;
  text-transform: uppercase;
  clip-path: polygon(7px 0, 100% 0, calc(100% - 7px) 100%, 0 100%);
  transition: .2s;
}
.buy:hover { filter: brightness(1.18); box-shadow: 0 0 20px -6px var(--wc); }

/* 已拥有 */
.wbox.owned { border-color: color-mix(in srgb, var(--wc) 70%, transparent); }
.wbox.owned::before {
  content: "";
  position: absolute;
  left: 0;
  bottom: 0;
  width: 100%;
  height: 3px;
  background: var(--wc);
}
.wbox.owned .buy {
  background: rgba(236, 232, 225, .08);
  color: var(--wc);
  cursor: default;
}

/* 等级未达标的武器：整体压暗 + 锁定角标 */
.wbox.locked { opacity: .55; filter: grayscale(.55); }
.wbox.locked:hover { transform: none; box-shadow: none; }
.wlock {
  position: absolute;
  right: 10px;
  top: 10px;
  z-index: 3;
  display: inline-flex;
  align-items: center;
  gap: 4px;
  padding: 3px 7px;
  background: rgba(9, 14, 20, .85);
  border: 1px solid var(--muted);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.2px;
  clip-path: polygon(4px 0, 100% 0, calc(100% - 4px) 100%, 0 100%);
}

/* 余额不足：卡片与按钮置灰 */
.wbox.poor .price { color: var(--muted); }
.wbox.poor .buy {
  background: rgba(236, 232, 225, .06);
  color: var(--muted);
}

.empty {
  margin: 40px 0;
  text-align: center;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 2px;
  color: var(--muted);
}

/* ========== 响应式 ========== */
@media (max-width: 1080px) {
  .grid { grid-template-columns: repeat(3, 1fr); }
}
@media (max-width: 860px) {
  .grid { grid-template-columns: repeat(2, 1fr); }
  .wallet { grid-template-columns: 1fr; gap: 10px; }
  .main { padding: 84px 16px 40px; }
  .phead h1 { font-size: 34px; }
}
@media (max-width: 560px) {
  .grid { grid-template-columns: 1fr; }
}
</style>
