<script setup>
/* ============================================================
   竞技场（ARENA）—— 好友 / 排行榜 / 装备 / 战绩
   ------------------------------------------------------------
   · 好友：按代号搜索 → 发申请（对方同意才成为好友）→ 切磋 / 删除
   · 战力：英雄四项属性 × 等级成长 + 主武器加成（后端 HeroStats 统一算）
   · 排行榜：全服按战力排序，高亮自己 + 我的名次
   · 装备：已购武器里挑一把当主武器（影响战力）
   · 切磋：自动结算，胜者得信用点与经验；同一对手每天 3 场
   数据来源：/api/social/*（SocialController）、/api/game/armory（ArmoryController）
   ============================================================ */
import { computed, onMounted, ref, watch } from 'vue'
import {
  state,
  currentAgent,
  heroExp,
  switchView,
  useSession
} from '../../store/session'
import {
  armory,
  armoryEquip,
  socialFriends,
  socialSearch,
  socialRequest,
  socialAccept,
  socialReject,
  socialRemove,
  socialRank,
  socialPk,
  socialFrame,
  socialLogs
} from '../../store/api'
import { AGENTS, STAT_LABELS } from '../../data/agents'
import {
  FIXED_FRAMES,
  frameOfTier,
  frameClassOf,
  frameStyleOf,
  frameTierOf,
  nextFrameOf
} from '../../data/frames'
import { WEAPONS, WEAPON_FALLBACK } from '../../data/weapons'
import HomeNav from './HomeNav.vue'
import { beep } from '../../composables/useSound'
import { useEffects } from '../../composables/useEffects'

const { showToast, refreshAccount } = useSession()
const { flash } = useEffects()

const token = computed(() => state.token || '')

/* ---------- 标签页 ---------- */
const TABS = [
  { key: 'friends', label: '好友', en: 'NETWORK' },
  { key: 'rank', label: '排行榜', en: 'RANKING' },
  { key: 'loadout', label: '装备', en: 'LOADOUT' },
  { key: 'frames', label: '边框', en: 'FRAMES' },
  { key: 'history', label: '战绩', en: 'RECORDS' }
]
const tab = ref('friends')

/* ---------- 状态 ---------- */
const loading = ref(false)
const panel = ref({ friends: [], incoming: [], outgoing: [], me: null })
const rankData = ref(null)
const logs = ref([])
const loadout = ref({ weapons: [], equipped: 'classic' })
const busying = ref('')

/** 我的资料卡：优先用后端返回（含战力/胜负），未加载时用登录态兜底 */
const me = computed(() => {
  const p = panel.value.me
  if (p) return p
  return {
    name: state.user?.name || '未接入',
    level: state.user?.heroLevel || 1,
    power: state.user?.power || 0,
    win: state.user?.pkWin || 0,
    lose: state.user?.pkLose || 0,
    weapon: '标配',
    weaponCode: 'classic'
  }
})

/** 等级成长系数（与后端 HeroStats.GROWTH 一致：每级 +2%） */
const grow = computed(() => 1 + 0.02 * ((me.value.level || 1) - 1))

/** 主武器 */
const equippedWeapon = computed(
  () => loadout.value.weapons.find((w) => w.code === loadout.value.equipped) || null
)
const equippedName = computed(
  () => equippedWeapon.value?.name || WEAPONS[loadout.value.equipped]?.name || '标配'
)
const equippedBonus = computed(() => equippedWeapon.value?.power ?? 0)
const weaponColor = computed(() => (WEAPONS[loadout.value.equipped] || WEAPON_FALLBACK).color)

/** 胜率 */
const winRate = computed(() => {
  const w = me.value.win || 0
  const l = me.value.lose || 0
  return w + l === 0 ? 0 : Math.round((w / (w + l)) * 100)
})

/* ---------- 头像框（固定 11 档 + 星穹系列无限延伸，可自选佩戴） ---------- */
/** 佩戴中的档位以后端为准（equipped_frame），未拿到时按等级推导 */
const wornTier = computed(() => {
  const t = state.user?.frameTier
  return Number.isFinite(t) && t >= 1 ? t : frameTierOf(me.value.level || 1)
})
const myFrame = computed(() => frameOfTier(wornTier.value))
const myNextFrame = computed(() => nextFrameOf(me.value.level || 1))
const myMaxTier = computed(() => frameTierOf(me.value.level || 1))
/** 是否跟随最新解锁（equipped_frame=0 或正好戴到最高档） */
const frameIsAuto = computed(() => {
  const u = state.user
  if (!u || u.frameAuto === undefined) return wornTier.value === myMaxTier.value
  return !!u.frameAuto
})

/** 图鉴列表：固定 11 档 + 星穹系列（展示到当前档 + 下一档预览） */
const frameLadder = computed(() => {
  const max = Math.max(FIXED_FRAMES.length, myMaxTier.value + 1)
  const out = []
  for (let t = 1; t <= max; t++) out.push(frameOfTier(t))
  return out
})

const frameTip = computed(() =>
  `头像框：${myFrame.value.name} · LV.${myNextFrame.value.level} 解锁「${myNextFrame.value.name}」`
)

/** 佩戴某档边框（tier=0 表示恢复跟随最新解锁） */
async function equipFrame(tier) {
  if (busying.value) return
  if (tier !== 0 && tier > myMaxTier.value) {
    beep(200, 0.12, 'sawtooth')
    showToast(`该边框需要 LV.${frameOfTier(tier).level} 解锁`, false)
    return
  }
  busying.value = `fr-${tier}`
  const r = await socialFrame(token.value, tier)
  busying.value = ''
  if (r.code !== 0) {
    beep(200, 0.12, 'sawtooth')
    showToast(r.msg === 'frame-locked' ? '该边框还未解锁' : `佩戴失败：${r.msg}`, false)
    return
  }
  beep(720, 0.07)
  setTimeout(() => beep(1080, 0.1), 90)
  showToast(
    r.data.auto
      ? '已恢复跟随等级 · 佩戴最新解锁的边框'
      : `已佩戴边框「${r.data.name}」`,
    true
  )
  await refreshAccount()
}

/** 已拥有武器（装备页只列这些 + 未解锁提示） */
const ownedWeapons = computed(() => loadout.value.weapons)

/* ============================================================
   数据加载
   ============================================================ */
async function loadFriends() {
  if (!token.value) return
  const r = await socialFriends(token.value)
  if (r.code === 0) panel.value = r.data
}

async function loadRank() {
  if (!token.value) return
  const r = await socialRank(token.value)
  if (r.code === 0) rankData.value = r.data
}

async function loadLogs() {
  if (!token.value) return
  const r = await socialLogs(token.value, 20)
  if (r.code === 0) logs.value = r.data || []
}

async function loadArmory() {
  if (!token.value) return
  const r = await armory(token.value)
  if (r.code === 0) {
    loadout.value = {
      weapons: r.data.weapons || [],
      equipped: r.data.equipped || 'classic'
    }
  }
}

async function loadAll() {
  if (!token.value) return
  loading.value = true
  await Promise.all([loadFriends(), loadRank(), loadLogs(), loadArmory()])
  loading.value = false
}

/* ============================================================
   好友：搜索 / 申请 / 同意 / 拒绝 / 删除
   ============================================================ */
const keyword = ref('')
const searching = ref(false)
const results = ref([])
const searched = ref(false)

async function doSearch() {
  const q = keyword.value.trim()
  if (!q) {
    results.value = []
    searched.value = false
    return
  }
  searching.value = true
  const r = await socialSearch(token.value, q)
  searching.value = false
  searched.value = true
  if (r.code !== 0) {
    showToast(`搜索失败 · ${r.msg || '未知错误'}`, false)
    return
  }
  results.value = r.data || []
  if (!results.value.length) beep(240, 0.1)
}

const REQUEST_HINTS = {
  self: '不能加自己为好友',
  notfound: '该玩家不存在',
  'already-friend': '你们已经是好友了',
  'already-sent': '申请已发出 · 等待对方确认',
  'already-received': '对方已向你发过申请 · 去「收到的申请」里处理'
}

async function addFriend(u) {
  if (busying.value) return
  busying.value = `add-${u.id}`
  const r = await socialRequest(token.value, u.id)
  busying.value = ''
  if (r.code !== 0) {
    beep(200, 0.12, 'sawtooth')
    showToast(REQUEST_HINTS[r.msg] || `申请失败：${r.msg}`, false)
    return
  }
  beep(700, 0.07)
  setTimeout(() => beep(1040, 0.1), 90)
  showToast(`已向 ${u.name} 发送好友申请`, true)
  u.relation = 'out'
  await loadFriends()
}

async function accept(row) {
  if (busying.value) return
  busying.value = `accept-${row.rowId}`
  const r = await socialAccept(token.value, row.rowId)
  busying.value = ''
  if (r.code !== 0) {
    showToast(`同意失败：${r.msg}`, false)
    return
  }
  beep(720, 0.07)
  showToast(`已与 ${row.name} 结为好友`, true)
  flash()
  await Promise.all([loadFriends(), loadRank()])
}

async function reject(row) {
  if (busying.value) return
  busying.value = `reject-${row.rowId}`
  const r = await socialReject(token.value, row.rowId)
  busying.value = ''
  if (r.code !== 0) {
    showToast(`操作失败：${r.msg}`, false)
    return
  }
  beep(300, 0.08)
  showToast('已拒绝该申请', false)
  await loadFriends()
}

async function removeFriend(u) {
  if (busying.value) return
  busying.value = `rm-${u.id}`
  const r = await socialRemove(token.value, u.id)
  busying.value = ''
  if (r.code !== 0) {
    showToast(`删除失败：${r.msg}`, false)
    return
  }
  beep(280, 0.1)
  showToast(`已与 ${u.name} 解除好友关系`, false)
  await Promise.all([loadFriends(), loadRank()])
}

/* ============================================================
   PK（自动结算）
   ============================================================ */
const fighting = ref('')
const pk = ref(null)

const PK_HINTS = {
  self: '不能和自己切磋',
  notfound: '对方不存在',
  'daily-limit': '今日与 TA 的切磋次数已用完（每天 3 场）'
}

async function doPk(u) {
  if (fighting.value || pk.value) return
  beep(520, 0.06)
  fighting.value = u.name
  const r = await socialPk(token.value, u.id)
  fighting.value = ''
  if (r.code !== 0) {
    beep(190, 0.14, 'sawtooth')
    showToast(PK_HINTS[r.msg] || `切磋失败：${r.msg}`, false)
    return
  }
  pk.value = r.data
  if (r.data.win) {
    flash()
    beep(660, 0.08)
    setTimeout(() => beep(880, 0.1), 100)
    setTimeout(() => beep(1240, 0.18), 210)
  } else {
    beep(300, 0.12, 'sawtooth')
    setTimeout(() => beep(200, 0.2, 'sawtooth'), 130)
  }
  // 战力/信用点/经验都以服务端为准
  await refreshAccount()
  await Promise.all([loadFriends(), loadRank(), loadLogs()])
}

function closePk() {
  beep(480, 0.05)
  pk.value = null
}

/* ============================================================
   装备主武器
   ============================================================ */
async function equipWeapon(w) {
  if (busying.value || !w.owned || w.equipped) return
  if ((me.value.level || 1) < (w.reqLevel || 1)) {
    beep(180, 0.14, 'sawtooth')
    showToast(`需要英雄 LV.${w.reqLevel} 才能装备 ${w.name}`, false)
    return
  }
  busying.value = `eq-${w.code}`
  const r = await armoryEquip(token.value, w.code)
  busying.value = ''
  if (r.code !== 0) {
    beep(180, 0.14, 'sawtooth')
    const hints = {
      'unknown-weapon': '武器不存在',
      'not-owned': '你还没有这把武器 · 先去军械商店购买',
      'level-too-low': '英雄等级不足'
    }
    showToast(hints[r.msg] || `装备失败：${r.msg}`, false)
    return
  }
  loadout.value.weapons.forEach((x) => {
    x.equipped = x.code === w.code
  })
  loadout.value.equipped = w.code
  beep(660, 0.07)
  setTimeout(() => beep(1120, 0.12), 90)
  showToast(`${w.name} 已装备 · 当前战力 ${r.data.power}`, true)
  await Promise.all([refreshAccount(), loadFriends(), loadRank()])
}

/* ---------- 跳转 ---------- */
function backHome() {
  beep(520, 0.06)
  switchView('home')
}
function goShop() {
  beep(640, 0.07)
  switchView('armory')
}

/* ---------- 工具 ---------- */
function agentColor(index) {
  return (AGENTS[index] || AGENTS[0]).color
}
function agentMono(index) {
  return (AGENTS[index] || AGENTS[0]).mono
}
function weaponColorOf(code) {
  return (WEAPONS[code] || WEAPON_FALLBACK).color
}

onMounted(loadAll)
watch(token, (v) => v && loadAll())
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
          <span class="cur">竞技场</span>
        </p>
        <div class="hrow">
          <h1>竞技场<i>ARENA</i></h1>
          <p class="sub">
            {{ currentAgent.name }} · LV.{{ me.level }} ·
            战力 <b>{{ me.power }}</b> · 好友切磋每日同对手 3 场
          </p>
        </div>
      </header>

      <div class="layout" :class="{ dim: loading }">
        <!-- ================= 我的档案 ================= -->
        <aside class="profile" :style="{ '--hc': currentAgent.color }">
          <div
            class="pava"
            :class="frameClassOf(myFrame.tier)"
            :style="frameStyleOf(myFrame.tier)"
            :title="frameTip"
          >
            <div class="pava-in">
              <span class="pmono">{{ currentAgent.mono }}</span>
            </div>
            <span class="plv">LV.{{ me.level }}</span>
          </div>

          <h2 class="pname">{{ state.user?.name || '未接入' }}</h2>
          <p class="prole">{{ currentAgent.name }} · {{ currentAgent.role }}</p>

          <!-- 头像框档位 + 下一档进度 -->
          <p class="pframe">
            <b>{{ myFrame.name }}</b><em>{{ myFrame.en }}</em>
            <i v-if="frameIsAuto" class="auto">跟随</i>
            <span>LV.{{ myNextFrame.level }} 解锁「{{ myNextFrame.name }}」</span>
          </p>

          <div class="pw">
            <div class="pwnum">
              <b>{{ me.power }}</b>
              <span>战力 POWER</span>
            </div>
            <i v-if="rankData" class="prank">
              #{{ rankData.myRank }}<em>/ {{ rankData.total }}</em>
            </i>
          </div>

          <!-- 经验 -->
          <div class="xp">
            <span class="xk">EXP</span>
            <span class="xv">{{ heroExp.inLevel }} / {{ heroExp.need }}</span>
            <span class="xbar">
              <em :style="{ width: (heroExp.pct * 100).toFixed(1) + '%' }"></em>
            </span>
          </div>

          <!-- 四项属性 -->
          <ul class="stats">
            <li v-for="(s, i) in currentAgent.stats" :key="i">
              <span class="sk">{{ STAT_LABELS[i] }}</span>
              <span class="sbar"><em :style="{ width: s + '%' }"></em></span>
              <b>{{ s }}</b>
            </li>
          </ul>
          <p class="grow">等级成长 ×{{ grow.toFixed(2) }} · 主武器另计加成</p>

          <!-- 主武器 -->
          <div class="weap" :style="{ '--wc': weaponColor }">
            <span class="wk">主武器</span>
            <b>{{ equippedName }}</b>
            <span class="wp">战力 +{{ equippedBonus }}</span>
          </div>

          <!-- 胜负 -->
          <div class="wl">
            <span>胜 <b class="w">{{ me.win }}</b></span>
            <span>负 <b class="l">{{ me.lose }}</b></span>
            <span>胜率 <b>{{ winRate }}%</b></span>
          </div>

          <button class="go-shop" type="button" @click="goShop">前往军械商店 →</button>
        </aside>

        <!-- ================= 右侧面板 ================= -->
        <section class="panel">
          <nav class="tabs">
            <button
              v-for="t in TABS"
              :key="t.key"
              type="button"
              class="tab"
              :class="{ on: tab === t.key }"
              @click="tab = t.key"
            >
              {{ t.label }}<i>{{ t.en }}</i>
              <em v-if="t.key === 'friends' && panel.incoming.length" class="badge">
                {{ panel.incoming.length }}
              </em>
            </button>
          </nav>

          <!-- ---------------- 好友 ---------------- -->
          <div v-show="tab === 'friends'" class="pane">
            <!-- 搜索 -->
            <div class="searchrow">
              <span class="slabel">FIND AGENT</span>
              <input
                v-model="keyword"
                class="sinput"
                type="text"
                placeholder="输入对方代号，如 gay"
                @keyup.enter="doSearch"
              />
              <button class="sbtn" type="button" :disabled="searching" @click="doSearch">
                {{ searching ? '搜索中…' : '搜索' }}
              </button>
            </div>

            <!-- 搜索结果 -->
            <div v-if="results.length" class="found">
              <p class="sechead">搜索结果 · {{ results.length }}</p>
              <div class="rows">
                <div v-for="u in results" :key="'s' + u.id" class="row">
                  <span
                    class="ravatar"
                    :class="`frame-${u.frameTier || 1}`"
                    :style="{ '--hc': agentColor(u.agentIndex) }"
                  >
                    {{ agentMono(u.agentIndex) }}
                  </span>
                  <div class="rmeta">
                    <b>{{ u.name }}</b>
                    <i>{{ u.agentName }} · {{ u.agentRole }}</i>
                  </div>
                  <span class="rstat">LV.{{ u.level }}</span>
                  <span class="rpower">{{ u.power }}<em>战力</em></span>
                  <button
                    class="mini ghost"
                    type="button"
                    title="直接切磋，无需好友"
                    @click="doPk(u)"
                  >
                    切磋
                  </button>
                  <button
                    v-if="u.relation === 'none'"
                    class="mini red"
                    type="button"
                    :disabled="busying === `add-${u.id}`"
                    @click="addFriend(u)"
                  >
                    {{ busying === `add-${u.id}` ? '发送中…' : '加好友' }}
                  </button>
                  <button v-else class="mini ghost" type="button" disabled>
                    {{
                      u.relation === 'friend'
                        ? '已是好友'
                        : u.relation === 'out'
                          ? '等待确认'
                          : '待你处理'
                    }}
                  </button>
                </div>
              </div>
            </div>
            <p v-else-if="searched && !searching" class="empty">没有找到该代号的特工</p>

            <!-- 收到的申请 -->
            <div v-if="panel.incoming.length" class="sec">
              <p class="sechead accent">
                收到的申请 · {{ panel.incoming.length }}
                <span class="hint">同意后即可切磋</span>
              </p>
              <div class="rows">
                <div v-for="r in panel.incoming" :key="'in' + r.rowId" class="row ask">
                  <span class="ravatar plain">?</span>
                  <div class="rmeta">
                    <b>{{ r.name }}</b>
                    <i>{{ r.time }} 发来好友申请</i>
                  </div>
                  <span class="sp"></span>
                  <button
                    class="mini red"
                    type="button"
                    :disabled="busying === `accept-${r.rowId}`"
                    @click="accept(r)"
                  >
                    同意
                  </button>
                  <button
                    class="mini ghost"
                    type="button"
                    :disabled="busying === `reject-${r.rowId}`"
                    @click="reject(r)"
                  >
                    拒绝
                  </button>
                </div>
              </div>
            </div>

            <!-- 好友列表 -->
            <div class="sec">
              <p class="sechead">
                我的好友 · {{ panel.friends.length }}
                <span class="hint">切磋：自动比拼战力，胜者得信用点与经验</span>
              </p>

              <div v-if="panel.friends.length" class="fgrid">
                <article
                  v-for="f in panel.friends"
                  :key="'f' + f.id"
                  class="fcard"
                  :style="{ '--hc': agentColor(f.agentIndex) }"
                >
                  <span class="fmono">{{ agentMono(f.agentIndex) }}</span>
                  <header>
                    <b>{{ f.name }}</b>
                    <i>{{ f.agentName }}</i>
                  </header>
                  <div class="fmeta">
                    <span class="flv">LV.{{ f.level }}</span>
                    <span class="fpow">{{ f.power }}<em>战力</em></span>
                  </div>
                  <div class="fweap" :style="{ '--wc': weaponColorOf(f.weaponCode) }">
                    {{ f.weapon }}
                  </div>
                  <div class="fwl">
                    <span class="w">{{ f.win }}W</span>
                    <span class="l">{{ f.lose }}L</span>
                  </div>
                  <div class="facts">
                    <button class="mini red" type="button" @click="doPk(f)">切磋</button>
                    <button
                      class="mini ghost"
                      type="button"
                      :disabled="busying === `rm-${f.id}`"
                      @click="removeFriend(f)"
                    >
                      移除
                    </button>
                  </div>
                </article>
              </div>
              <p v-else class="empty">
                还没有好友 · 用上方搜索框输入对方代号，发个申请试试
              </p>
            </div>

            <!-- 我发出的申请 -->
            <div v-if="panel.outgoing.length" class="sec">
              <p class="sechead">我发出的申请 · {{ panel.outgoing.length }}</p>
              <div class="rows">
                <div v-for="r in panel.outgoing" :key="'out' + r.rowId" class="row">
                  <span class="ravatar plain">…</span>
                  <div class="rmeta">
                    <b>{{ r.name }}</b>
                    <i>{{ r.time }} 已发送 · 等待对方确认</i>
                  </div>
                  <span class="sp"></span>
                  <span class="tag pending">PENDING</span>
                </div>
              </div>
            </div>
          </div>

          <!-- ---------------- 排行榜 ---------------- -->
          <div v-show="tab === 'rank'" class="pane">
            <div class="sechead">
              全服战力排行 · 共 {{ rankData?.total || 0 }} 名特工
              <span class="hint">任何人都可以直接切磋，无需好友 · 每天同一对手 3 场</span>
            </div>
            <div class="rankhead">
              <span>#</span><span>特工</span><span>英雄</span><span>LV</span>
              <span>战力</span><span>战绩</span><span>操作</span>
            </div>
            <div class="ranks">
              <div
                v-for="row in rankData?.list || []"
                :key="'rk' + row.id"
                class="rrow"
                :class="{ self: row.id === state.user?.id, top: row.rank <= 3 }"
              >
                <span class="rk" :data-rank="row.rank">{{ row.rank }}</span>
                <span class="rname">
                  {{ row.name }}
                  <em v-if="row.id === state.user?.id">YOU</em>
                </span>
                <span class="ragent" :style="{ '--hc': agentColor(row.agentIndex) }">
                  {{ row.agentName }}
                </span>
                <span class="rlv">{{ row.level }}</span>
                <span class="rpw">{{ row.power }}</span>
                <span class="rwl">{{ row.win }}W / {{ row.lose }}L</span>
                <span class="ract">
                  <button
                    v-if="row.id !== state.user?.id"
                    class="mini red small"
                    type="button"
                    @click="doPk(row)"
                  >
                    切磋
                  </button>
                  <em v-else class="me-tag">—</em>
                </span>
              </div>
            </div>
            <p v-if="!(rankData?.list || []).length" class="empty">暂无排行数据</p>
          </div>

          <!-- ---------------- 装备 ---------------- -->
          <div v-show="tab === 'loadout'" class="pane">
            <div class="sechead">
              选择主武器 · 只影响战力，不改变英雄属性
              <span class="hint">未拥有的武器请先去军械商店购买</span>
            </div>

            <div class="wgrid">
              <article
                v-for="w in ownedWeapons"
                :key="'w' + w.code"
                class="wcell"
                :class="{
                  on: w.equipped,
                  locked: !w.owned || (me.level || 1) < (w.reqLevel || 1),
                  poor: !w.owned
                }"
                :style="{ '--wc': weaponColorOf(w.code) }"
                @click="equipWeapon(w)"
              >
                <span class="wmono">{{ (WEAPONS[w.code] || WEAPON_FALLBACK).mono }}</span>
                <div class="winfo">
                  <span class="wcat">{{ w.category }}</span>
                  <h3>{{ w.name }}</h3>
                  <span class="wen">{{ (WEAPONS[w.code] || WEAPON_FALLBACK).en }}</span>
                </div>
                <div class="wfoot">
                  <span class="wpow">战力 +{{ w.power }}</span>
                  <span class="wstate">
                    <template v-if="w.equipped">已装备</template>
                    <template v-else-if="!w.owned">未拥有</template>
                    <template v-else-if="(me.level || 1) < (w.reqLevel || 1)">
                      LV.{{ w.reqLevel }} 解锁
                    </template>
                    <template v-else>装备</template>
                  </span>
                </div>
              </article>
            </div>

            <p v-if="!ownedWeapons.length" class="empty">军械库为空 · 先去军械商店看看</p>
          </div>

          <!-- ---------------- 边框图鉴 ---------------- -->
          <div v-show="tab === 'frames'" class="pane">
            <div class="sechead">
              头像框图鉴 · 已解锁 {{ myMaxTier }} 档
              <span class="hint">点击已解锁的边框即可佩戴 · Lv.50 后每 10 级解锁一枚「星穹」</span>
            </div>

            <div class="framehint">
              <span>每升 1 级：<b>{{ 100 + 50 * me.level }}</b> 信用点</span>
              <span>解锁新边框：额外 <b>+300</b> 信用点</span>
              <span>下一档 LV.{{ myNextFrame.level }}「{{ myNextFrame.name }}」</span>
            </div>

            <div class="fgrid-frame">
              <!-- 跟随最新解锁 -->
              <article
                class="fcell auto"
                :class="{ on: frameIsAuto }"
                title="恢复跟随等级：始终佩戴最新解锁的边框"
                @click="equipFrame(0)"
              >
                <span
                  class="fprev"
                  :class="frameClassOf(myMaxTier)"
                  :style="frameStyleOf(myMaxTier)"
                >
                  <i>新</i>
                </span>
                <div class="fmeta">
                  <b>跟随等级</b>
                  <em>AUTO</em>
                </div>
                <span class="freq">自动</span>
                <span class="fstate">{{ frameIsAuto ? '跟随中' : '恢复跟随' }}</span>
              </article>

              <!-- 固定 11 档 + 星穹系列 -->
              <article
                v-for="f in frameLadder"
                :key="'fr' + f.tier"
                class="fcell"
                :class="{ on: !frameIsAuto && f.tier === myFrame.tier, locked: f.tier > myMaxTier }"
                @click="equipFrame(f.tier)"
              >
                <span
                  class="fprev"
                  :class="frameClassOf(f.tier)"
                  :style="f.proc ? frameStyleOf(f.tier) : { '--hc': currentAgent.color }"
                >
                  <i>{{ currentAgent.mono }}</i>
                </span>
                <div class="fmeta">
                  <b>{{ f.name }}</b>
                  <em>{{ f.en }}</em>
                </div>
                <span class="freq">LV.{{ f.level }}</span>
                <span class="fstate">
                  {{
                    !frameIsAuto && f.tier === myFrame.tier
                      ? '佩戴中'
                      : f.tier <= myMaxTier
                        ? '点击佩戴'
                        : '未解锁'
                  }}
                </span>
              </article>
            </div>

            <p class="fnote">
              固定 11 档（Lv.1~50）之后进入「星穹」系列：每 10 级一枚，颜色随档位变化，永无止境 ·
              等级无上限，升级奖励照常发放
            </p>
          </div>

          <!-- ---------------- 战绩 ---------------- -->
          <div v-show="tab === 'history'" class="pane">
            <div class="sechead">
              我的切磋记录 · 最近 {{ logs.length }} 场
              <span class="hint">数据实时写入 agent_pk</span>
            </div>
            <div v-if="logs.length" class="logs">
              <div v-for="l in logs" :key="'lg' + l.id" class="lrow" :class="{ win: l.win, lose: !l.win }">
                <span class="lflag">{{ l.win ? 'WIN' : 'LOSE' }}</span>
                <span class="lrival">VS {{ l.rival }}</span>
                <span class="lscore">{{ l.myPower }} <em>:</em> {{ l.foePower }}</span>
                <span class="ltime">{{ l.time }}</span>
              </div>
            </div>
            <p v-else class="empty">还没有切磋记录 · 找个好友打一场</p>
          </div>
        </section>
      </div>
    </main>

    <!-- ========== 交战中 ========== -->
    <div v-if="fighting" class="overlay">
      <div class="fightbox">
        <div class="vsmark">VS</div>
        <p>正在与 <b>{{ fighting }}</b> 交战…</p>
        <span class="loading-bar"><em></em></span>
      </div>
    </div>

    <!-- ========== 切磋结算 ========== -->
    <div v-if="pk" class="overlay" @click.self="closePk">
      <div class="pkbox" :class="pk.win ? 'win' : 'lose'">
        <p class="pktop">COMBAT RESULT · 切磋结算</p>

        <div class="vsrow">
          <div class="side">
            <span class="sava" :style="{ '--hc': agentColor(pk.me.agentIndex) }">
              {{ agentMono(pk.me.agentIndex) }}
            </span>
            <b>{{ pk.me.name }}</b>
            <i>{{ pk.me.agentName }} · LV.{{ pk.me.level }}</i>
            <em class="sroll">{{ pk.myRoll }}</em>
            <span class="slabel">掷出战力</span>
          </div>

          <div class="vsmid">
            <span>VS</span>
            <em>{{ pk.myPower }} / {{ pk.foePower }}</em>
          </div>

          <div class="side foe">
            <span class="sava" :style="{ '--hc': agentColor(pk.foe.agentIndex) }">
              {{ agentMono(pk.foe.agentIndex) }}
            </span>
            <b>{{ pk.foe.name }}</b>
            <i>{{ pk.foe.agentName }} · LV.{{ pk.foe.level }}</i>
            <em class="sroll">{{ pk.foeRoll }}</em>
            <span class="slabel">掷出战力</span>
          </div>
        </div>

        <div class="banner">{{ pk.win ? 'VICTORY' : 'DEFEAT' }}</div>

        <div class="rewards">
          <span class="rchip">+{{ pk.creditsGained }} 信用点</span>
          <span class="rchip">+{{ pk.level.expGained }} EXP</span>
          <span v-if="pk.level.levelUp" class="rchip up">
            LEVEL UP · LV.{{ pk.level.level }}
          </span>
          <span v-if="pk.level.frameUnlocked" class="rchip frame">
            解锁边框 {{ (pk.level.unlockedFrames || []).join('、') }}
          </span>
        </div>

        <p class="remain">今日与该对手剩余 {{ pk.remainToday }} 场</p>

        <button class="pkclose" type="button" @click="closePk">确认</button>
      </div>
    </div>
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

/* ========== 布局 ========== */
.layout {
  display: grid;
  grid-template-columns: 306px 1fr;
  gap: 20px;
  margin-top: 22px;
  align-items: start;
  transition: opacity .2s;
}
.layout.dim { opacity: .55; }

/* ========== 我的档案 ========== */
.profile {
  position: relative;
  padding: 20px 20px 18px;
  background: linear-gradient(165deg, rgba(22, 33, 44, .94), rgba(14, 23, 32, .96));
  border: 1px solid var(--line);
  clip-path: polygon(16px 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%, 0 16px);
  animation: up .45s .06s cubic-bezier(.2, 1, .3, 1) both;
}
.profile::after {
  content: '';
  position: absolute;
  left: 0;
  top: 0;
  width: 3px;
  height: 100%;
  background: linear-gradient(180deg, var(--hc), transparent 68%);
}

.pava {
  position: relative;
  width: 74px;
  height: 74px;
  transition: box-shadow .3s;
}
/* 内层方形保留切角；头像框光环画在外层，避免被 clip-path 裁掉 */
.pava-in {
  width: 100%;
  height: 100%;
  display: grid;
  place-items: center;
  background: color-mix(in srgb, var(--hc) 16%, rgba(10, 17, 25, .9));
  border: 1px solid color-mix(in srgb, var(--hc) 55%, transparent);
  clip-path: polygon(12px 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%, 0 12px);
}
.pmono {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 34px;
  letter-spacing: 1px;
  color: var(--hc);
}
.plv {
  position: absolute;
  left: 6px;
  bottom: 6px;
  padding: 1px 5px;
  background: rgba(9, 14, 20, .88);
  border: 1px solid color-mix(in srgb, var(--hc) 50%, transparent);
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1px;
  color: var(--cream);
}

.pname {
  margin: 14px 0 2px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 25px;
  letter-spacing: 1.6px;
  color: var(--cream);
}
.prole {
  margin: 0;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.4px;
  color: var(--muted);
}

/* 头像框档位 + 下一档进度 */
.pframe {
  display: flex;
  align-items: center;
  gap: 6px;
  flex-wrap: wrap;
  margin: 9px 0 0;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: .8px;
  color: var(--muted);
}
.pframe b {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 12px;
  letter-spacing: 1.4px;
  color: var(--cream);
}
.pframe em {
  font-style: normal;
  font-size: 8px;
  letter-spacing: 1.4px;
  padding: 1px 4px;
  border: 1px solid var(--line);
  color: var(--hc);
}
.pframe span { margin-left: auto; opacity: .9; }
.pframe .auto {
  font-style: normal;
  padding: 1px 5px;
  background: var(--ac);
  color: #0a1119;
  font-weight: 700;
}

/* 战力 */
.pw {
  display: flex;
  align-items: flex-end;
  justify-content: space-between;
  gap: 10px;
  margin: 16px 0 4px;
  padding: 12px 0 10px;
  border-top: 1px solid var(--line);
  border-bottom: 1px solid var(--line);
}
.pwnum b {
  display: block;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 38px;
  line-height: 1;
  letter-spacing: 1px;
  color: var(--hc);
  text-shadow: 0 0 24px color-mix(in srgb, var(--hc) 45%, transparent);
}
.pwnum span {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.8px;
  color: var(--muted);
}
.prank {
  font-family: var(--disp);
  font-style: normal;
  font-weight: 700;
  font-size: 20px;
  color: var(--cream);
}
.prank em {
  font-family: var(--mono);
  font-style: normal;
  font-size: 10px;
  color: var(--muted);
}

/* 经验 */
.xp {
  display: grid;
  grid-template-columns: auto 1fr;
  gap: 2px 8px;
  margin: 12px 0 14px;
}
.xk {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.xv {
  justify-self: end;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: .8px;
  color: var(--cream);
}
.xbar {
  grid-column: 1 / -1;
  height: 3px;
  background: rgba(236, 232, 225, .14);
  overflow: hidden;
}
.xbar em {
  display: block;
  height: 100%;
  background: var(--ac);
  box-shadow: 0 0 8px var(--ac);
  transition: width .45s cubic-bezier(.2, 1, .3, 1);
}

/* 属性 */
.stats { list-style: none; margin: 0 0 4px; padding: 0; display: grid; gap: 7px; }
.stats li {
  display: grid;
  grid-template-columns: 30px 1fr 24px;
  align-items: center;
  gap: 8px;
}
.sk { font-family: var(--mono); font-size: 9.5px; letter-spacing: 1px; color: var(--muted); }
.sbar { height: 4px; background: rgba(236, 232, 225, .12); overflow: hidden; }
.sbar em {
  display: block;
  height: 100%;
  background: linear-gradient(90deg, color-mix(in srgb, var(--hc) 60%, transparent), var(--hc));
  transition: width .5s cubic-bezier(.2, 1, .3, 1);
}
.stats b {
  font-family: var(--mono);
  font-size: 10.5px;
  color: var(--cream);
  text-align: right;
}
.grow {
  margin: 0 0 14px;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1px;
  color: var(--muted);
  opacity: .8;
}

/* 主武器 */
.weap {
  display: flex;
  align-items: center;
  gap: 8px;
  padding: 9px 11px;
  background: color-mix(in srgb, var(--wc) 10%, rgba(10, 17, 25, .7));
  border-left: 2px solid var(--wc);
}
.weap .wk {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.weap b {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 1px;
  color: var(--cream);
}
.weap .wp {
  margin-left: auto;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1px;
  color: var(--wc);
}

.wl {
  display: flex;
  gap: 14px;
  margin: 12px 0 14px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.2px;
  color: var(--muted);
}
.wl b { font-size: 13px; color: var(--cream); }
.wl b.w { color: #3ddc97; }
.wl b.l { color: var(--red); }

.go-shop {
  width: 100%;
  padding: 10px;
  background: rgba(236, 232, 225, .05);
  border: 1px solid var(--line);
  color: var(--muted);
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 1.8px;
  clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
  transition: .2s;
}
.go-shop:hover {
  color: #fff;
  border-color: var(--ac);
  background: color-mix(in srgb, var(--ac) 16%, transparent);
  box-shadow: 0 0 22px -8px var(--ac);
}

/* ========== 右侧面板 ========== */
.panel {
  background: linear-gradient(165deg, rgba(20, 30, 41, .92), rgba(13, 22, 31, .95));
  border: 1px solid var(--line);
  clip-path: polygon(16px 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%, 0 16px);
  animation: up .45s .12s cubic-bezier(.2, 1, .3, 1) both;
  min-height: 560px;
}

.tabs {
  display: flex;
  gap: 2px;
  padding: 12px 14px 0;
  border-bottom: 1px solid var(--line);
}
.tab {
  position: relative;
  display: flex;
  align-items: baseline;
  gap: 6px;
  padding: 9px 14px 11px;
  border: 0;
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 1.8px;
  transition: .2s;
}
.tab i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 8.5px;
  letter-spacing: 1.2px;
  opacity: .75;
}
.tab:hover { color: var(--cream); }
.tab.on { color: #fff; }
.tab.on::after {
  content: '';
  position: absolute;
  left: 8px;
  right: 8px;
  bottom: -1px;
  height: 2px;
  background: var(--ac);
  box-shadow: 0 0 12px var(--ac);
}
.badge {
  font-family: var(--mono);
  font-style: normal;
  font-size: 9px;
  padding: 1px 5px;
  margin-left: 2px;
  background: var(--red);
  color: #fff;
  border-radius: 999px;
}

.pane { padding: 18px 18px 22px; }

.sechead {
  display: flex;
  align-items: center;
  gap: 10px;
  flex-wrap: wrap;
  margin: 0 0 12px;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.8px;
  color: var(--cream);
  text-transform: uppercase;
}
.sechead.accent { color: var(--red); }
.sechead .hint {
  font-size: 9px;
  letter-spacing: .8px;
  color: var(--muted);
  text-transform: none;
}
.sec { margin-top: 22px; }

/* ---------- 搜索 ---------- */
.searchrow {
  display: grid;
  grid-template-columns: auto 1fr auto;
  align-items: center;
  gap: 10px;
  padding: 12px;
  background: rgba(9, 14, 20, .5);
  border: 1px solid var(--line);
}
.slabel {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.sinput {
  height: 34px;
  padding: 0 11px;
  background: rgba(236, 232, 225, .04);
  border: 1px solid var(--line);
  color: var(--cream);
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: .6px;
  outline: none;
  transition: .2s;
}
.sinput::placeholder { color: var(--muted); opacity: .7; }
.sinput:focus { border-color: var(--ac); box-shadow: 0 0 18px -10px var(--ac); }
.sbtn {
  height: 34px;
  padding: 0 18px;
  background: var(--ac);
  border: 0;
  color: #0a1119;
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 1.6px;
  clip-path: polygon(7px 0, 100% 0, calc(100% - 7px) 100%, 0 100%);
  transition: .2s;
}
.sbtn:hover { filter: brightness(1.15); }
.sbtn:disabled { opacity: .6; cursor: default; }

/* ---------- 行列表 ---------- */
.rows { display: grid; gap: 8px; }
.found { margin-top: 14px; }

.row {
  display: flex;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  background: rgba(236, 232, 225, .03);
  border: 1px solid var(--line);
  transition: .2s;
}
.row:hover { border-color: color-mix(in srgb, var(--ac) 45%, transparent); background: rgba(236, 232, 225, .05); }
.row.ask { border-left: 2px solid var(--red); }
.sp { flex: 1; }

.ravatar {
  width: 30px;
  height: 30px;
  flex-shrink: 0;
  display: grid;
  place-items: center;
  background: color-mix(in srgb, var(--hc) 18%, rgba(9, 14, 20, .9));
  border: 1px solid color-mix(in srgb, var(--hc) 50%, transparent);
  color: var(--hc);
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  --hc: var(--muted);
}
.ravatar.plain { color: var(--muted); border-color: var(--line); background: rgba(9, 14, 20, .8); }

.rmeta { display: flex; flex-direction: column; line-height: 1.25; min-width: 0; }
.rmeta b { font-size: 13px; letter-spacing: .4px; color: var(--cream); }
.rmeta i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 9px;
  letter-spacing: 1px;
  color: var(--muted);
}
.rstat {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1px;
  color: var(--cream);
  padding: 2px 6px;
  border: 1px solid var(--line);
}
.rpower {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  color: var(--ac);
  min-width: 58px;
  text-align: right;
}
.rpower em {
  display: block;
  font-family: var(--mono);
  font-style: normal;
  font-weight: 400;
  font-size: 8.5px;
  letter-spacing: 1px;
  color: var(--muted);
  text-align: right;
}

.mini {
  padding: 6px 12px;
  border: 1px solid transparent;
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 12px;
  letter-spacing: 1.2px;
  clip-path: polygon(6px 0, 100% 0, calc(100% - 6px) 100%, 0 100%);
  transition: .18s;
  white-space: nowrap;
}
.mini.red { background: var(--ac); color: #0a1119; }
.mini.red:hover { filter: brightness(1.16); box-shadow: 0 0 18px -6px var(--ac); }
.mini.ghost {
  background: rgba(236, 232, 225, .05);
  border-color: var(--line);
  color: var(--muted);
}
.mini.ghost:hover { color: var(--cream); border-color: var(--muted); }
.mini:disabled { opacity: .55; cursor: default; box-shadow: none; }

.tag.pending {
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 1.4px;
  padding: 3px 7px;
  border: 1px dashed var(--line);
  color: var(--muted);
}

/* ---------- 好友卡片 ---------- */
.fgrid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(196px, 1fr));
  gap: 12px;
}
.fcard {
  position: relative;
  overflow: hidden;
  padding: 13px 13px 12px;
  background: linear-gradient(160deg, rgba(24, 35, 46, .9), rgba(13, 22, 31, .94));
  border: 1px solid var(--line);
  clip-path: polygon(12px 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%, 0 12px);
  transition: transform .2s, border-color .2s, box-shadow .2s;
}
.fcard:hover {
  transform: translateY(-4px);
  border-color: color-mix(in srgb, var(--hc) 60%, transparent);
  box-shadow: 0 22px 44px -30px var(--hc);
}
.fmono {
  position: absolute;
  right: -2px;
  top: -14px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 64px;
  line-height: 1;
  color: transparent;
  -webkit-text-stroke: 1.4px color-mix(in srgb, var(--hc) 50%, transparent);
  opacity: .45;
  pointer-events: none;
}
.fcard header { position: relative; z-index: 1; display: flex; flex-direction: column; }
.fcard header b {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 18px;
  letter-spacing: 1px;
  color: var(--cream);
}
.fcard header i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 9px;
  letter-spacing: 1.2px;
  color: var(--hc);
}
.fmeta {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: baseline;
  justify-content: space-between;
  margin: 10px 0 6px;
}
.flv {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1px;
  color: var(--muted);
}
.fpow {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 19px;
  color: var(--cream);
}
.fpow em {
  font-family: var(--mono);
  font-style: normal;
  font-weight: 400;
  font-size: 8.5px;
  letter-spacing: 1px;
  color: var(--muted);
  margin-left: 3px;
}
.fweap {
  position: relative;
  z-index: 1;
  display: inline-block;
  padding: 2px 7px;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1px;
  color: var(--wc);
  border-left: 2px solid var(--wc);
  background: color-mix(in srgb, var(--wc) 10%, transparent);
}
.fwl {
  position: relative;
  z-index: 1;
  display: flex;
  gap: 10px;
  margin: 8px 0 10px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: .8px;
}
.fwl .w { color: #3ddc97; }
.fwl .l { color: var(--red); }
.facts { position: relative; z-index: 1; display: flex; gap: 6px; }
.facts .mini { flex: 1; text-align: center; }

/* ---------- 排行榜 ---------- */
.rankhead,
.rrow {
  display: grid;
  grid-template-columns: 42px 1fr 104px 40px 64px 84px 66px;
  align-items: center;
  gap: 8px;
}
.rankhead {
  padding: 0 12px 8px;
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 1.6px;
  color: var(--muted);
  border-bottom: 1px solid var(--line);
}
.ranks { display: grid; }
.rrow {
  padding: 9px 12px;
  border-bottom: 1px solid rgba(236, 232, 225, .06);
  transition: .18s;
}
.rrow:hover { background: rgba(236, 232, 225, .04); }
.rrow.self {
  background: color-mix(in srgb, var(--ac) 12%, transparent);
  border-left: 2px solid var(--ac);
}
.rk {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  color: var(--muted);
}
.rrow.top .rk { color: #FFC24B; }
.rrow.top .rk[data-rank='1'] { color: #FFC24B; text-shadow: 0 0 16px rgba(255, 194, 75, .55); }
.rname {
  font-size: 13px;
  letter-spacing: .4px;
  color: var(--cream);
  display: flex;
  align-items: center;
  gap: 6px;
  min-width: 0;
  overflow: hidden;
  text-overflow: ellipsis;
  white-space: nowrap;
}
.rname em {
  font-family: var(--mono);
  font-style: normal;
  font-size: 8px;
  letter-spacing: 1px;
  padding: 1px 4px;
  background: var(--ac);
  color: #0a1119;
  font-weight: 700;
}
.ragent {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.2px;
  color: var(--hc);
  --hc: var(--muted);
}
.rlv {
  font-family: var(--mono);
  font-size: 10px;
  color: var(--cream);
}
.rpw {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 16px;
  color: var(--ac);
  text-align: right;
  padding-right: 8px;
}
.rwl {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: .5px;
  color: var(--muted);
  text-align: right;
}
.ract { display: flex; justify-content: flex-end; }
.ract .mini { padding: 4px 10px; font-size: 11px; }
.me-tag { font-family: var(--mono); font-style: normal; font-size: 10px; color: var(--muted); }

/* ---------- 装备 ---------- */
.wgrid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(178px, 1fr));
  gap: 12px;
}
.wcell {
  position: relative;
  overflow: hidden;
  padding: 14px 14px 12px;
  background: linear-gradient(160deg, rgba(24, 35, 46, .9), rgba(13, 22, 31, .94));
  border: 1px solid var(--line);
  cursor: pointer;
  clip-path: polygon(12px 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%, 0 12px);
  transition: transform .2s, border-color .2s, box-shadow .2s;
}
.wcell:hover {
  transform: translateY(-4px);
  border-color: color-mix(in srgb, var(--wc) 60%, transparent);
  box-shadow: 0 22px 44px -30px var(--wc);
}
.wcell.on {
  border-color: var(--wc);
  box-shadow: inset 0 -3px 0 var(--wc);
}
.wcell.locked { opacity: .5; filter: grayscale(.5); cursor: not-allowed; }
.wcell.locked:hover { transform: none; box-shadow: none; }
.wmono {
  position: absolute;
  right: -2px;
  top: -16px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 66px;
  line-height: 1;
  color: transparent;
  -webkit-text-stroke: 1.4px color-mix(in srgb, var(--wc) 50%, transparent);
  opacity: .45;
  pointer-events: none;
}
.winfo { position: relative; z-index: 1; }
.wcat {
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 1.4px;
  color: var(--wc);
}
.winfo h3 {
  margin: 4px 0 1px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 21px;
  letter-spacing: 1.4px;
  color: var(--cream);
}
.wen {
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 2px;
  color: var(--muted);
}
.wfoot {
  position: relative;
  z-index: 1;
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-top: 10px;
  padding-top: 8px;
  border-top: 1px solid rgba(236, 232, 225, .08);
}
.wpow {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: .8px;
  color: var(--wc);
}
.wstate {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1px;
  color: var(--muted);
}
.wcell.on .wstate { color: var(--wc); font-weight: 700; }

/* ---------- 边框图鉴 ---------- */
.framehint {
  display: flex;
  flex-wrap: wrap;
  gap: 6px 16px;
  margin: 0 0 14px;
  padding: 10px 12px;
  border: 1px solid var(--line);
  background: rgba(236, 232, 225, .03);
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: .6px;
  color: var(--muted);
}
.framehint b { color: var(--ac); font-size: 11px; }

.fgrid-frame {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(158px, 1fr));
  gap: 12px;
}
.fcell {
  position: relative;
  display: grid;
  grid-template-columns: 46px 1fr;
  grid-template-areas:
    "prev meta"
    "prev state";
  align-items: center;
  gap: 3px 10px;
  padding: 13px 12px;
  background: linear-gradient(160deg, rgba(24, 35, 46, .9), rgba(13, 22, 31, .94));
  border: 1px solid var(--line);
  clip-path: polygon(12px 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%, 0 12px);
  transition: border-color .2s, box-shadow .2s, opacity .2s;
}
.fcell.on { border-color: var(--ac); box-shadow: inset 0 -2px 0 var(--ac); }
.fcell.locked { opacity: .4; filter: grayscale(.65); }

.fprev {
  grid-area: prev;
  width: 46px;
  height: 46px;
  display: grid;
  place-items: center;
  background: rgba(9, 14, 20, .9);
}
.fprev i {
  font-family: var(--disp);
  font-style: normal;
  font-weight: 700;
  font-size: 20px;
  color: var(--hc, var(--muted));
}

.fmeta { grid-area: meta; }
.fmeta b {
  display: block;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 16px;
  letter-spacing: 1.2px;
  color: var(--cream);
}
.fmeta em {
  font-family: var(--mono);
  font-style: normal;
  font-size: 8px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.freq {
  position: absolute;
  right: 10px;
  top: 10px;
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 1px;
  color: var(--muted);
}
.fstate {
  grid-area: state;
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 1.2px;
  color: var(--muted);
}
.fcell.on .fstate { color: var(--ac); }
.fcell:not(.locked):not(.on) .fstate { color: #3ddc97; }

.fnote {
  margin: 16px 0 0;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: .8px;
  line-height: 1.8;
  color: var(--muted);
  opacity: .85;
}

/* ---------- 战绩 ---------- */
.logs { display: grid; gap: 6px; }
.lrow {
  display: grid;
  grid-template-columns: 66px 1fr auto 96px;
  align-items: center;
  gap: 12px;
  padding: 10px 12px;
  background: rgba(236, 232, 225, .03);
  border: 1px solid var(--line);
  border-left-width: 2px;
}
.lrow.win { border-left-color: #3ddc97; }
.lrow.lose { border-left-color: var(--red); }
.lflag {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.8px;
  font-weight: 700;
}
.lrow.win .lflag { color: #3ddc97; }
.lrow.lose .lflag { color: var(--red); }
.lrival { font-size: 12.5px; letter-spacing: .4px; color: var(--cream); }
.lscore {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  color: var(--cream);
}
.lscore em { font-style: normal; color: var(--muted); margin: 0 3px; }
.ltime {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: .8px;
  color: var(--muted);
  text-align: right;
}

.empty {
  margin: 26px 0;
  text-align: center;
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.6px;
  color: var(--muted);
  line-height: 1.9;
}

/* ========== 遮罩 / 结算 ========== */
.overlay {
  position: fixed;
  inset: 0;
  z-index: 60;
  display: grid;
  place-items: center;
  padding: 20px;
  background: rgba(4, 8, 12, .78);
  backdrop-filter: blur(6px);
  animation: fade .2s ease-out both;
}
@keyframes fade {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* 交战中 */
.fightbox {
  position: relative;
  width: min(360px, 92vw);
  padding: 30px 24px 26px;
  text-align: center;
  background: linear-gradient(165deg, rgba(22, 33, 44, .98), rgba(12, 20, 28, .99));
  border: 1px solid color-mix(in srgb, var(--ac) 55%, transparent);
  clip-path: polygon(16px 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%, 0 16px);
}
.vsmark {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 46px;
  letter-spacing: 4px;
  color: var(--ac);
  text-shadow: 0 0 30px color-mix(in srgb, var(--ac) 60%, transparent);
  animation: vsPulse 1s ease-in-out infinite;
}
@keyframes vsPulse {
  0%, 100% { opacity: .55; transform: scale(.96); }
  50% { opacity: 1; transform: scale(1.04); }
}
.fightbox p {
  margin: 8px 0 14px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.fightbox p b { color: var(--cream); }
.loading-bar {
  display: block;
  height: 2px;
  background: rgba(236, 232, 225, .12);
  overflow: hidden;
}
.loading-bar em {
  display: block;
  width: 40%;
  height: 100%;
  background: var(--ac);
  box-shadow: 0 0 10px var(--ac);
  animation: slide 1.1s ease-in-out infinite;
}
@keyframes slide {
  0% { transform: translateX(-100%); }
  100% { transform: translateX(320%); }
}

/* 结算卡 */
.pkbox {
  position: relative;
  width: min(560px, 94vw);
  padding: 20px 22px 22px;
  background: linear-gradient(165deg, rgba(22, 33, 44, .99), rgba(11, 19, 26, .99));
  border: 1px solid var(--line);
  clip-path: polygon(18px 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%, 0 18px);
  animation: pop .32s cubic-bezier(.2, 1.3, .4, 1) both;
}
@keyframes pop {
  from { opacity: 0; transform: scale(.94) translateY(10px); }
  to { opacity: 1; transform: none; }
}
.pkbox.win { border-color: #3ddc97; box-shadow: 0 0 60px -24px #3ddc97; }
.pkbox.lose { border-color: var(--red); box-shadow: 0 0 60px -24px var(--red); }

.pktop {
  margin: 0 0 16px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 2.4px;
  color: var(--muted);
  text-align: center;
}

.vsrow {
  display: grid;
  grid-template-columns: 1fr auto 1fr;
  gap: 10px;
  align-items: center;
}
.side { display: flex; flex-direction: column; align-items: center; gap: 3px; }
.sava {
  width: 52px;
  height: 52px;
  display: grid;
  place-items: center;
  margin-bottom: 4px;
  background: color-mix(in srgb, var(--hc) 16%, rgba(9, 14, 20, .9));
  border: 1px solid color-mix(in srgb, var(--hc) 55%, transparent);
  color: var(--hc);
  font-family: var(--disp);
  font-weight: 700;
  font-size: 24px;
  clip-path: polygon(10px 0, 100% 0, 100% calc(100% - 10px), calc(100% - 10px) 100%, 0 100%, 0 10px);
}
.side b { font-family: var(--disp); font-weight: 700; font-size: 16px; letter-spacing: 1px; color: var(--cream); }
.side i {
  font-family: var(--mono);
  font-style: normal;
  font-size: 9px;
  letter-spacing: 1px;
  color: var(--muted);
}
.sroll {
  margin-top: 6px;
  font-family: var(--disp);
  font-weight: 700;
  font-style: normal;
  font-size: 28px;
  line-height: 1;
  color: var(--cream);
}
.slabel {
  font-family: var(--mono);
  font-size: 8.5px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.vsmid { display: flex; flex-direction: column; align-items: center; gap: 2px; }
.vsmid span {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 18px;
  letter-spacing: 2px;
  color: var(--muted);
}
.vsmid em {
  font-family: var(--mono);
  font-style: normal;
  font-size: 8.5px;
  letter-spacing: 1px;
  color: var(--muted);
  opacity: .8;
}

.banner {
  margin: 18px 0 12px;
  text-align: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 40px;
  letter-spacing: 8px;
  text-transform: uppercase;
}
.pkbox.win .banner { color: #3ddc97; text-shadow: 0 0 34px rgba(61, 220, 151, .5); }
.pkbox.lose .banner { color: var(--red); text-shadow: 0 0 34px rgba(255, 70, 85, .5); }

.rewards {
  display: flex;
  justify-content: center;
  gap: 8px;
  flex-wrap: wrap;
}
.rchip {
  padding: 4px 10px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.2px;
  color: var(--cream);
  border: 1px solid var(--line);
  background: rgba(236, 232, 225, .05);
}
.rchip.up {
  border-color: #FFC24B;
  color: #FFC24B;
  background: rgba(255, 194, 75, .1);
  animation: vsPulse 1.6s ease-in-out infinite;
}
.rchip.frame {
  border-color: #A66CFF;
  color: #CBB5FF;
  background: rgba(166, 108, 255, .12);
}

.remain {
  margin: 12px 0 16px;
  text-align: center;
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.2px;
  color: var(--muted);
}
.pkclose {
  display: block;
  width: 100%;
  padding: 11px;
  background: var(--ac);
  border: 0;
  color: #0a1119;
  cursor: pointer;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  letter-spacing: 2.4px;
  clip-path: polygon(8px 0, 100% 0, calc(100% - 8px) 100%, 0 100%);
  transition: .2s;
}
.pkclose:hover { filter: brightness(1.16); }

/* ========== 响应式 ========== */
@media (max-width: 1080px) {
  .layout { grid-template-columns: 262px 1fr; }
  .rankhead, .rrow { grid-template-columns: 34px 1fr 92px 36px 60px 76px 60px; }
}
@media (max-width: 900px) {
  .layout { grid-template-columns: 1fr; }
  .panel { min-height: 0; }
  .main { padding: 84px 16px 40px; }
  .phead h1 { font-size: 34px; }
  .stats { max-width: 320px; }
}
@media (max-width: 640px) {
  .rankhead { display: none; }
  .rrow { grid-template-columns: 26px 1fr 48px 60px 56px; }
  .ragent, .rwl { display: none; }
  .tabs { overflow-x: auto; }
  .tab { padding: 9px 10px 11px; font-size: 14px; }
  .vsrow { grid-template-columns: 1fr auto 1fr; }
  .banner { font-size: 30px; letter-spacing: 5px; }
  .lrow { grid-template-columns: 54px 1fr auto; }
  .ltime { display: none; }
}
</style>
