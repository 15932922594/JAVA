<script setup>
/* ============================================================
   作战任务卡片
   状态：IDLE 待接取 / ACTIVE 执行中 / READY 待结算 / DONE 已完成
   卡片本身只做展示，接取与结算由父组件调接口（避免每个卡片各自持有请求状态）
   now 由父组件每秒推进，用于倒计时刷新
   ============================================================ */
import { computed } from 'vue'

const props = defineProps({
  mission: { type: Object, required: true },
  /** 当前时间戳（毫秒），父组件每秒更新 */
  now: { type: Number, default: () => Date.now() }
})

const emit = defineEmits(['open', 'accept'])

const STATUS_TEXT = { IDLE: '待接取', ACTIVE: '执行中', READY: '待结算', DONE: '已完成' }

const status = computed(() => props.mission.status || 'IDLE')
const statusText = computed(() => STATUS_TEXT[status.value] || '待接取')

/** 剩余秒数：有截止时间按截止时间算，未接取按任务时限展示 */
const remain = computed(() => {
  const m = props.mission
  if (!m.deadline) return (m.duration || 0) * 60
  const t = new Date(String(m.deadline).replace(' ', 'T')).getTime()
  if (Number.isNaN(t)) return 0
  return Math.round((t - props.now) / 1000)
})

const remainText = computed(() => {
  const s = remain.value
  if (s <= 0) return '已超时'
  const h = Math.floor(s / 3600)
  const mm = String(Math.floor((s % 3600) / 60)).padStart(2, '0')
  const ss = String(s % 60).padStart(2, '0')
  return h > 0 ? `${h}:${mm}:${ss}` : `${mm}:${ss}`
})

const urgent = computed(() => status.value === 'ACTIVE' && remain.value <= 300 && remain.value > 0)
const overdue = computed(() => status.value === 'ACTIVE' && remain.value <= 0)

/** 进度条颜色：完成后转为绿色系提示 */
const barColor = computed(() =>
  status.value === 'DONE' ? '#3ddc97' : status.value === 'READY' ? '#FFB443' : 'var(--c)'
)
</script>

<template>
  <article
    class="mcard"
    :class="['s-' + status.toLowerCase(), { urgent, overdue }]"
    :style="{ '--c': mission.color || '#FF4655' }"
    role="button"
    tabindex="0"
    :aria-label="`${mission.name} · ${statusText}`"
    @click="emit('open', mission.code)"
    @keydown.enter.prevent="emit('open', mission.code)"
  >
    <!-- 左侧状态色条 -->
    <span class="edge"></span>

    <header class="head">
      <span class="mono">{{ mission.mono }}</span>
      <div class="ttl">
        <h3>{{ mission.name }}</h3>
        <p>{{ mission.subName }}<i v-if="mission.region"> · {{ mission.region }}</i></p>
      </div>
      <span class="tier" :data-t="mission.tier">{{ mission.tier }}</span>
    </header>

    <p class="brief">{{ mission.briefing }}</p>

    <!-- 目标进度 -->
    <div class="prog">
      <div class="plab">
        <span>目标进度</span>
        <b>{{ mission.doneCount }}/{{ mission.objectiveCount }}</b>
      </div>
      <div class="track">
        <i :style="{ width: mission.progress + '%', background: barColor }"></i>
      </div>
    </div>

    <!-- 参数 -->
    <ul class="meta">
      <li><span>时限</span>{{ mission.duration }} MIN</li>
      <li><span>编队</span>{{ mission.squad || '5V5' }}</li>
      <li><span>积分</span>+{{ mission.reward }}</li>
    </ul>

    <footer class="foot">
      <span class="badge">{{ statusText }}</span>
      <span v-if="status === 'ACTIVE'" class="clock" :class="{ hot: urgent || overdue }">
        {{ remainText }}
      </span>
      <span v-else-if="status === 'DONE'" class="clock ok">已结算</span>
      <span v-else class="clock">{{ mission.duration }} MIN 内完成</span>

      <button
        v-if="status === 'IDLE'"
        class="act primary"
        type="button"
        @click.stop="emit('accept', mission.code)"
      >
        接取
      </button>
      <button
        v-else
        class="act"
        type="button"
        @click.stop="emit('open', mission.code)"
      >
        {{ status === 'READY' ? '去结算' : '简报' }}
      </button>
    </footer>
  </article>
</template>

<style scoped>
.mcard {
  position: relative;
  display: flex;
  flex-direction: column;
  gap: 12px;
  padding: 18px 18px 14px 22px;
  background: linear-gradient(168deg, rgba(22, 33, 44, .94), rgba(14, 23, 33, .97));
  border: 1px solid var(--line);
  clip-path: polygon(16px 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%, 0 16px);
  cursor: pointer;
  transition: transform .26s cubic-bezier(.2, 1, .3, 1), border-color .26s, box-shadow .26s;
  animation: rise .45s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes rise {
  from { opacity: 0; transform: translateY(12px); }
  to { opacity: 1; transform: none; }
}
.mcard:hover {
  transform: translateY(-5px);
  border-color: var(--c);
  box-shadow: 0 26px 54px -32px #000, 0 0 30px -18px var(--c);
}
.mcard:focus-visible { outline: 2px solid var(--c); outline-offset: 3px; }

.edge {
  position: absolute;
  left: 0;
  top: 0;
  bottom: 0;
  width: 3px;
  background: var(--c);
  opacity: .65;
}
.s-active .edge { opacity: 1; box-shadow: 0 0 16px var(--c); }
.s-ready .edge { background: #FFB443; opacity: 1; box-shadow: 0 0 16px #FFB443; }
.s-done .edge { background: #3ddc97; opacity: .8; }

/* 状态态卡片整体压暗，突出未完成的任务 */
.s-done { opacity: .62; }
.s-done:hover { opacity: .9; }

.head { display: flex; align-items: flex-start; gap: 11px; }
.mono {
  flex-shrink: 0;
  width: 34px;
  height: 34px;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  color: var(--c);
  border: 1px solid var(--c);
  background: rgba(0, 0, 0, .3);
  clip-path: polygon(7px 0, 100% 0, 100% calc(100% - 7px), calc(100% - 7px) 100%, 0 100%, 0 7px);
}
.ttl { flex: 1; min-width: 0; }
.ttl h3 {
  margin: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 21px;
  letter-spacing: 1.6px;
  text-transform: uppercase;
  color: var(--cream);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.ttl p {
  margin: 3px 0 0;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.2px;
  color: var(--muted);
  white-space: nowrap;
  overflow: hidden;
  text-overflow: ellipsis;
}
.tier {
  flex-shrink: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 1px;
  padding: 2px 8px;
  color: #0F1923;
  background: var(--cream);
}
.tier[data-t="S"] { background: #FFB443; }
.tier[data-t="A"] { background: var(--cream); }
.tier[data-t="B"] { background: #7f8e9b; }

.brief {
  margin: 0;
  min-height: 36px;
  font-size: 12.5px;
  line-height: 1.55;
  color: var(--muted);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* 进度 */
.prog { display: grid; gap: 5px; }
.plab {
  display: flex;
  justify-content: space-between;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.plab b { color: var(--cream); font-weight: 400; }
.track {
  height: 4px;
  background: rgba(236, 232, 225, .1);
  overflow: hidden;
}
.track i {
  display: block;
  height: 100%;
  transition: width .5s cubic-bezier(.2, 1, .3, 1);
  box-shadow: 0 0 12px -2px currentColor;
}

.meta {
  display: flex;
  gap: 14px;
  margin: 0;
  padding: 0;
  list-style: none;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: .8px;
  color: var(--cream);
}
.meta li { display: flex; gap: 5px; align-items: baseline; }
.meta span { color: var(--muted); font-size: 9px; letter-spacing: 1.2px; }

.foot {
  display: flex;
  align-items: center;
  gap: 9px;
  padding-top: 11px;
  border-top: 1px solid rgba(236, 232, 225, .1);
}
.badge {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.4px;
  padding: 3px 8px;
  border: 1px solid var(--line);
  color: var(--muted);
}
.s-active .badge { color: var(--c); border-color: var(--c); background: rgba(255, 70, 85, .1); }
.s-ready .badge { color: #FFB443; border-color: #FFB443; background: rgba(255, 180, 67, .12); }
.s-done .badge { color: #3ddc97; border-color: rgba(61, 220, 151, .6); background: rgba(61, 220, 151, .1); }

.clock {
  flex: 1;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1px;
  color: var(--muted);
}
.clock.hot { color: #FFB443; animation: pulse 1s steps(2) infinite; }
.clock.ok { color: #3ddc97; }
@keyframes pulse { 50% { opacity: .45; } }

.act {
  flex-shrink: 0;
  padding: 6px 13px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--cream);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.4px;
  cursor: pointer;
  transition: .2s;
}
.act:hover { border-color: var(--c); color: #fff; background: rgba(255, 255, 255, .04); }
.act.primary {
  background: var(--c);
  border-color: var(--c);
  color: #0F1923;
  font-weight: 700;
}
.act.primary:hover { box-shadow: 0 0 20px -6px var(--c); color: #0F1923; }

/* 超时提示 */
.overdue { border-color: rgba(255, 70, 85, .45); }
</style>
