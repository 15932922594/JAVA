<script setup>
/* ============================================================
   作战任务简报弹窗（可交互）
   - 目标清单：点击勾选 / 取消，实时写库（/api/mission/objective）
   - 接取任务：/api/mission/accept
   - 放弃任务：/api/mission/abandon
   - 提交结算：/api/mission/claim（目标全部完成后可用）
   动作成功后 emit('changed')，父组件重新拉列表刷新统计
   ============================================================ */
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { missionAccept, missionAbandon, missionClaim, missionToggle } from '../../store/api'
import { state } from '../../store/session'
import { beep } from '../../composables/useSound'

const props = defineProps({
  mission: { type: Object, required: true },
  token: { type: String, default: '' }
})

const emit = defineEmits(['close', 'changed'])

/** 本地副本：接口返回后立即刷新界面，不等父组件重新拉取 */
const m = ref({ ...props.mission })
const busy = ref('')          // 正在进行的动作：accept / toggle / abandon / claim
const errorMsg = ref('')
const justClaimed = ref(0)    // 本次结算获得的积分（>0 时展示成功条）

const STATUS_TEXT = { IDLE: '待接取', ACTIVE: '执行中', READY: '待结算', DONE: '已完成' }
const status = computed(() => m.value.status || 'IDLE')
const statusText = computed(() => STATUS_TEXT[status.value] || '待接取')

/* ---------- 倒计时 ---------- */
const now = ref(Date.now())
let ticker = null

const remain = computed(() => {
  if (!m.value.deadline) return (m.value.duration || 0) * 60
  const t = new Date(String(m.value.deadline).replace(' ', 'T')).getTime()
  if (Number.isNaN(t)) return 0
  return Math.round((t - now.value) / 1000)
})
const remainText = computed(() => {
  const s = remain.value
  const abs = Math.abs(s)
  const h = Math.floor(abs / 3600)
  const mm = String(Math.floor((abs % 3600) / 60)).padStart(2, '0')
  const ss = String(abs % 60).padStart(2, '0')
  const txt = h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`
  return s < 0 ? `+${txt} 超时` : txt
})
const overdue = computed(() => status.value === 'ACTIVE' && remain.value <= 0)

/* ---------- 动作 ---------- */
function apply(data) {
  if (data && data.code) {
    m.value = { ...data }
    emit('changed', m.value)
  }
}

async function accept() {
  if (busy.value) return
  busy.value = 'accept'
  errorMsg.value = ''
  const r = await missionAccept(props.token, m.value.code)
  busy.value = ''
  if (r.code !== 0) {
    errorMsg.value = r.msg || '接取失败'
    return
  }
  beep(660, 0.07)
  apply(r.data)
}

async function toggle(index) {
  if (busy.value || status.value === 'IDLE' || status.value === 'DONE') return
  busy.value = 'toggle'
  errorMsg.value = ''
  const r = await missionToggle(props.token, m.value.code, index)
  busy.value = ''
  if (r.code !== 0) {
    errorMsg.value = r.msg || '目标更新失败'
    return
  }
  beep(r.data?.status === 'READY' ? 880 : 520, 0.05)
  apply(r.data)
}

async function abandon() {
  if (busy.value) return
  busy.value = 'abandon'
  errorMsg.value = ''
  const r = await missionAbandon(props.token, m.value.code)
  busy.value = ''
  if (r.code !== 0) {
    errorMsg.value = r.msg || '放弃失败'
    return
  }
  beep(420, 0.09)
  apply(r.data)
}

async function claim() {
  if (busy.value || status.value !== 'READY') return
  busy.value = 'claim'
  errorMsg.value = ''
  const r = await missionClaim(props.token, m.value.code)
  busy.value = ''
  if (r.code !== 0) {
    errorMsg.value = r.msg || '结算失败'
    return
  }
  beep(980, 0.12)
  justClaimed.value = r.data?.reward || 0
  apply(r.data?.mission)
  emit('changed', m.value)
}

/* ---------- 打开 / 关闭 ---------- */
function onKey(e) {
  if (e.key === 'Escape') emit('close')
}

let savedOverflow = ''
onMounted(() => {
  window.addEventListener('keydown', onKey)
  savedOverflow = document.body.style.overflow
  document.body.style.overflow = 'hidden'
  ticker = setInterval(() => {
    now.value = Date.now()
  }, 1000)
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey)
  document.body.style.overflow = savedOverflow
  clearInterval(ticker)
})

/** 人物/地图背景故事分段 */
const storyParas = computed(() =>
  String(m.value.story || '')
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean)
)


</script>

<template>
  <div class="mask" @click.self="emit('close')">
    <div class="panel" :style="{ '--c': m.color || '#FF4655' }">
      <button class="x" type="button" title="关闭（ESC）" @click="emit('close')">×</button>

      <!-- 顶部：代号 / 名称 / 状态 -->
      <header class="head">
        <span class="mono">{{ m.mono }}</span>
        <div class="ht">
          <p class="eyebrow">
            {{ m.subName }}<i v-if="m.region"> · {{ m.region }}</i>
            <span class="dot"></span>
            <span>NO.{{ m.code }}</span>
          </p>
          <h2>{{ m.name }}</h2>
        </div>
        <div class="hright">
          <span class="tier" :data-t="m.tier">{{ m.tier }}</span>
          <span class="badge" :class="'s-' + status.toLowerCase()">{{ statusText }}</span>
        </div>
      </header>

      <!-- 结算成功提示 -->
      <div v-if="justClaimed" class="okbar">
        <b>+{{ justClaimed }}</b> 积分已入账 · 任务归档完成
      </div>

      <p v-if="errorMsg" class="errbar"><b>!</b> {{ errorMsg }}</p>

      <div class="body">
        <!-- 左栏：简报 + 目标 -->
        <section class="left">
          <div class="block">
            <div class="bh"><span class="bar"></span><h3>任务简报</h3><em>BRIEFING</em></div>
            <p class="brief">{{ m.briefing }}</p>
          </div>

          <div class="block">
            <div class="bh">
              <span class="bar"></span><h3>战术目标</h3><em>OBJECTIVES</em>
              <span class="cnt">{{ m.doneCount }}/{{ m.objectiveCount }}</span>
            </div>

            <p v-if="status === 'IDLE'" class="tip">接取任务后可勾选目标，进度会实时保存。</p>

            <ul class="objs">
              <li
                v-for="o in m.objectives"
                :key="o.index"
                :class="{ done: o.done, locked: status === 'IDLE' || status === 'DONE', busy: busy === 'toggle' }"
              >
                <button
                  type="button"
                  class="obj"
                  :disabled="status === 'IDLE' || status === 'DONE' || busy === 'toggle'"
                  @click="toggle(o.index)"
                >
                  <span class="box">
                    <svg v-if="o.done" width="11" height="11" viewBox="0 0 24 24" fill="none">
                      <path d="M4 12.5 9.5 18 20 6.5" stroke="currentColor" stroke-width="3.4"
                        stroke-linecap="round" stroke-linejoin="round" />
                    </svg>
                  </span>
                  <span class="otx">{{ o.text }}</span>
                  <span class="oidx">{{ String(o.index + 1).padStart(2, '0') }}</span>
                </button>
              </li>
            </ul>
          </div>

          <div v-if="storyParas.length" class="block">
            <div class="bh"><span class="bar"></span><h3>战术情报</h3><em>INTEL</em></div>
            <p v-for="(p, i) in storyParas" :key="i" class="story">{{ p }}</p>
          </div>
        </section>

        <!-- 右栏：时限 / 奖励 / 操作 -->
        <aside class="right">
          <div class="stat">
            <span class="slab">任务时限</span>
            <b class="big">{{ m.duration }}<i>MIN</i></b>
          </div>

          <div class="stat">
            <span class="slab">剩余时间</span>
            <b class="clock" :class="{ hot: overdue || (status === 'ACTIVE' && remain <= 300) }">
              {{ status === 'IDLE' ? '未接取' : status === 'DONE' ? '已结束' : remainText }}
            </b>
          </div>

          <div class="stat">
            <span class="slab">结算积分</span>
            <b class="big reward">+{{ m.reward }}</b>
          </div>

          <div class="stat">
            <span class="slab">当前进度</span>
            <div class="ptrack"><i :style="{ width: m.progress + '%' }"></i></div>
            <span class="pval">{{ m.progress }}%</span>
          </div>

          <div class="stat">
            <span class="slab">编队</span>
            <b class="small">{{ m.squad || '5V5' }}</b>
          </div>

          <!-- 操作区 -->
          <div class="actions">
            <button
              v-if="status === 'IDLE'"
              class="btn primary"
              type="button"
              :disabled="busy === 'accept'"
              @click="accept"
            >
              {{ busy === 'accept' ? '接取中…' : '接取任务' }}
            </button>

            <template v-if="status === 'ACTIVE' || status === 'READY'">
              <button
                class="btn primary"
                type="button"
                :disabled="status !== 'READY' || busy === 'claim'"
                :title="status !== 'READY' ? '目标全部完成后才能结算' : ''"
                @click="claim"
              >
                {{ busy === 'claim' ? '结算中…' : status === 'READY' ? '提交结算' : '尚未完成目标' }}
              </button>
              <button class="btn ghost" type="button" :disabled="busy === 'abandon'" @click="abandon">
                {{ busy === 'abandon' ? '处理中…' : '放弃任务' }}
              </button>
            </template>

            <div v-if="status === 'DONE'" class="donebox">
              <span>任务已完成</span>
              <em v-if="m.finishedAt">{{ m.finishedAt }}</em>
            </div>
          </div>

          <p class="hintline">
            操作会实时写入 mission_progress，刷新页面进度不丢失。
          </p>
        </aside>
      </div>

      <footer class="foot">
        <span>特工 {{ state.user?.name || '—' }}</span>
        <span v-if="m.startedAt">接取时间 {{ m.startedAt }}</span>
      </footer>
    </div>
  </div>
</template>

<style scoped>
/* ---------- 遮罩 ---------- */
.mask {
  position: fixed;
  inset: 0;
  z-index: 200;
  display: grid;
  place-items: center;
  padding: 24px;
  background: rgba(6, 11, 17, .84);
  backdrop-filter: blur(6px);
  animation: fade .2s ease both;
}
@keyframes fade { from { opacity: 0; } to { opacity: 1; } }

.panel {
  position: relative;
  width: min(980px, 100%);
  max-height: 90vh;
  overflow: auto;
  padding: 22px 24px 16px;
  background: linear-gradient(168deg, rgba(20, 30, 41, .99), rgba(12, 20, 29, .99));
  border: 1px solid var(--line);
  clip-path: polygon(22px 0, 100% 0, 100% calc(100% - 22px), calc(100% - 22px) 100%, 0 100%, 0 22px);
  box-shadow: 0 40px 90px -30px #000, 0 0 60px -34px var(--c);
  animation: pop .3s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes pop {
  from { opacity: 0; transform: translateY(16px) scale(.985); }
  to { opacity: 1; transform: none; }
}
.panel::before {
  content: '';
  position: absolute;
  left: 0; right: 0; top: 0;
  height: 2px;
  background: var(--c);
  box-shadow: 0 0 20px var(--c);
}

.x {
  position: absolute;
  top: 10px; right: 12px;
  z-index: 3;
  width: 32px; height: 32px;
  display: grid; place-items: center;
  font-size: 22px; line-height: 1;
  color: var(--muted);
  background: rgba(10, 17, 25, .7);
  border: 1px solid var(--line);
  cursor: pointer;
  transition: .2s;
}
.x:hover { color: #fff; background: var(--c); border-color: var(--c); }

/* ---------- 头部 ---------- */
.head {
  display: flex;
  align-items: center;
  gap: 14px;
  padding-bottom: 16px;
  border-bottom: 1px solid var(--line);
}
.mono {
  width: 46px; height: 46px;
  display: grid; place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 19px;
  color: var(--c);
  border: 1px solid var(--c);
  background: rgba(0, 0, 0, .3);
  clip-path: polygon(9px 0, 100% 0, 100% calc(100% - 9px), calc(100% - 9px) 100%, 0 100%, 0 9px);
}
.ht { flex: 1; min-width: 0; }
.eyebrow {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 0 0 4px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.7px;
  color: var(--muted);
  text-transform: uppercase;
}
.eyebrow i { font-style: normal; }
.dot { width: 3px; height: 3px; background: var(--c); border-radius: 50%; }
.ht h2 {
  margin: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 32px;
  letter-spacing: 2.6px;
  text-transform: uppercase;
  color: var(--cream);
}
.hright { display: flex; flex-direction: column; align-items: flex-end; gap: 6px; }
.tier {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  padding: 2px 10px;
  color: #0F1923;
  background: var(--cream);
}
.tier[data-t="S"] { background: #FFB443; }
.tier[data-t="B"] { background: #7f8e9b; }
.badge {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.4px;
  padding: 3px 9px;
  border: 1px solid var(--line);
  color: var(--muted);
}
.badge.s-active { color: var(--c); border-color: var(--c); }
.badge.s-ready { color: #FFB443; border-color: #FFB443; }
.badge.s-done { color: #3ddc97; border-color: rgba(61, 220, 151, .7); }

/* ---------- 提示条 ---------- */
.okbar {
  margin-top: 14px;
  padding: 10px 14px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.2px;
  color: #3ddc97;
  background: rgba(61, 220, 151, .1);
  border-left: 2px solid #3ddc97;
  animation: slidein .3s ease both;
}
.okbar b { font-size: 15px; }
@keyframes slidein { from { opacity: 0; transform: translateX(-8px); } to { opacity: 1; transform: none; } }
.errbar {
  margin: 14px 0 0;
  padding: 9px 13px;
  font-size: 12px;
  color: #FF8B95;
  background: rgba(255, 70, 85, .1);
  border-left: 2px solid var(--red);
}
.errbar b { margin-right: 6px; }

/* ---------- 主体 ---------- */
.body {
  display: grid;
  grid-template-columns: 1fr 250px;
  gap: 26px;
  padding: 20px 0 6px;
}
.block { margin-bottom: 20px; }
.bh {
  display: flex;
  align-items: center;
  gap: 9px;
  margin-bottom: 10px;
}
.bh .bar { width: 3px; height: 13px; background: var(--c); }
.bh h3 {
  margin: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 2px;
  color: var(--cream);
}
.bh em {
  font-family: var(--mono);
  font-style: normal;
  font-size: 9px;
  letter-spacing: 1.8px;
  color: var(--muted);
}
.bh .cnt {
  margin-left: auto;
  font-family: var(--mono);
  font-size: 11px;
  color: var(--c);
}
.brief {
  margin: 0;
  font-size: 13px;
  line-height: 1.75;
  color: #b9c3cc;
}
.tip {
  margin: 0 0 9px;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: .8px;
  color: var(--muted);
}

/* 目标清单 */
.objs { margin: 0; padding: 0; list-style: none; display: grid; gap: 6px; }
.obj {
  width: 100%;
  display: flex;
  align-items: center;
  gap: 11px;
  padding: 10px 12px;
  background: rgba(236, 232, 225, .03);
  border: 1px solid var(--line);
  color: var(--cream);
  font-family: inherit;
  font-size: 13px;
  text-align: left;
  cursor: pointer;
  transition: .18s;
}
.obj:hover:not(:disabled) {
  background: rgba(236, 232, 225, .07);
  border-color: rgba(236, 232, 225, .34);
  transform: translateX(2px);
}
.obj:disabled { cursor: default; opacity: .75; }
li.done .obj { opacity: .62; }
.box {
  flex-shrink: 0;
  width: 17px; height: 17px;
  display: grid; place-items: center;
  border: 1px solid var(--line);
  color: #0F1923;
  transition: .2s;
}
li.done .box { background: #3ddc97; border-color: #3ddc97; }
.otx { flex: 1; line-height: 1.4; }
li.done .otx { text-decoration: line-through; color: var(--muted); }
.oidx {
  font-family: var(--mono);
  font-size: 9.5px;
  color: var(--muted);
  letter-spacing: 1px;
}
.story {
  margin: 0 0 8px;
  font-size: 12.5px;
  line-height: 1.7;
  color: var(--muted);
}

/* 右栏 */
.right {
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 14px;
  background: rgba(10, 17, 25, .6);
  border: 1px solid var(--line);
  clip-path: polygon(0 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%);
  align-self: start;
}
.stat { display: grid; gap: 4px; }
.slab {
  font-family: var(--mono);
  font-size: 9px;
  letter-spacing: 1.6px;
  color: var(--muted);
}
.big {
  font-family: var(--disp);
  font-weight: 700;
  font-size: 24px;
  letter-spacing: 1px;
  color: var(--cream);
}
.big i { font-style: normal; font-size: 10px; letter-spacing: 1.6px; color: var(--muted); margin-left: 4px; }
.big.reward { color: #FFB443; }
.small {
  font-family: var(--mono);
  font-size: 12px;
  color: var(--cream);
}
.clock {
  font-family: var(--mono);
  font-size: 16px;
  letter-spacing: 1px;
  color: var(--cream);
}
.clock.hot { color: #FFB443; animation: pulse 1s steps(2) infinite; }
@keyframes pulse { 50% { opacity: .5; } }

.ptrack {
  height: 4px;
  background: rgba(236, 232, 225, .1);
  overflow: hidden;
}
.ptrack i {
  display: block;
  height: 100%;
  background: var(--c);
  transition: width .45s cubic-bezier(.2, 1, .3, 1);
}
.pval { font-family: var(--mono); font-size: 10px; color: var(--muted); }

.actions {
  display: grid;
  gap: 8px;
  margin-top: 4px;
  padding-top: 12px;
  border-top: 1px solid var(--line);
}
.btn {
  width: 100%;
  padding: 11px 14px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--cream);
  font-family: var(--disp);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 2.2px;
  cursor: pointer;
  clip-path: polygon(9px 0, 100% 0, calc(100% - 9px) 100%, 0 100%);
  transition: .2s;
}
.btn.primary { background: var(--c); border-color: var(--c); color: #0F1923; }
.btn.primary:hover:not(:disabled) { box-shadow: 0 0 24px -8px var(--c); filter: brightness(1.08); }
.btn.primary:disabled {
  background: rgba(236, 232, 225, .07);
  border-color: var(--line);
  color: var(--muted);
  cursor: not-allowed;
}
.btn.ghost:hover { color: var(--red); border-color: var(--red); }
.btn:disabled { cursor: not-allowed; }

.donebox {
  display: grid;
  gap: 3px;
  padding: 11px 14px;
  border: 1px solid rgba(61, 220, 151, .45);
  background: rgba(61, 220, 151, .08);
  color: #3ddc97;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.4px;
}
.donebox em { font-style: normal; font-size: 9px; color: var(--muted); letter-spacing: 1px; }

.hintline {
  margin: 2px 0 0;
  font-family: var(--mono);
  font-size: 9px;
  line-height: 1.6;
  letter-spacing: .6px;
  color: var(--muted);
}

.foot {
  display: flex;
  justify-content: space-between;
  gap: 12px;
  padding-top: 12px;
  border-top: 1px solid var(--line);
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.3px;
  color: var(--muted);
}

@media (max-width: 780px) {
  .body { grid-template-columns: 1fr; gap: 14px; }
  .ht h2 { font-size: 24px; }
  .panel { padding: 18px 16px 12px; }
}
</style>
