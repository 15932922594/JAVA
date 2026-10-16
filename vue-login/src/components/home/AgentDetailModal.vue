<script setup>
/* ============================================================
   档案详情弹窗 —— 点击卡片后展开
   数据来源：后端 /api/home/detail（agent_archive 单条，含 story）
   左侧立绘 / 右侧：代号、定位、分级、简介、四维属性、人物故事
   ============================================================ */
import { onMounted, onBeforeUnmount, ref, watch } from 'vue'
import { homeDetail } from '../../store/api'
import { STAT_LABELS, roleShort } from '../../data/agents'

const props = defineProps({
  /** 档案代号（空则不请求） */
  code: { type: String, default: '' },
  /** 登录 token */
  token: { type: String, default: '' }
})

const emit = defineEmits(['close'])

const data = ref(null)
const loading = ref(false)
const error = ref('')

/** 拉取详情 */
async function load() {
  if (!props.code || !props.token) return
  loading.value = true
  error.value = ''
  data.value = null
  const r = await homeDetail(props.token, props.code)
  loading.value = false
  if (r.code === 0) {
    data.value = r.data
  } else {
    error.value = r.code === 404 ? '档案不存在或已下线' : `档案解密失败 · ${r.msg || '未知错误'}`
  }
}

/** 人物故事按空行分段 */
function paragraphs(text) {
  if (!text) return []
  return String(text).split('\n').map((s) => s.trim()).filter(Boolean)
}

function onKey(e) {
  if (e.key === 'Escape') emit('close')
}

let savedOverflow = ''
onMounted(() => {
  load()
  window.addEventListener('keydown', onKey)
  savedOverflow = document.body.style.overflow
  document.body.style.overflow = 'hidden'
})

onBeforeUnmount(() => {
  window.removeEventListener('keydown', onKey)
  document.body.style.overflow = savedOverflow
})

watch(() => props.code, load)
</script>

<template>
  <div class="mask" @click.self="emit('close')">
    <div class="panel" :style="{ '--c': data?.color || '#4DA6FF' }">
      <!-- 关闭 -->
      <button class="x" type="button" title="关闭（ESC）" @click="emit('close')">×</button>

      <!-- ---------- 加载中 ---------- -->
      <div v-if="loading" class="state">
        <div class="spin"></div>
        <p>正在解密档案 …</p>
      </div>

      <!-- ---------- 出错 ---------- -->
      <div v-else-if="error" class="state">
        <div class="ex">!</div>
        <p>{{ error }}</p>
        <button class="retry" type="button" @click="load">重新解密</button>
      </div>

      <!-- ---------- 详情 ---------- -->
      <div v-else-if="data" class="wrap">
        <!-- 左：立绘 -->
        <aside class="left">
          <span class="wm">{{ data.mono }}</span>
          <img v-if="data.img" :src="data.img" :alt="data.name" />
          <span v-else class="badge">{{ data.mono }}</span>
          <span class="tier">{{ data.tier }}</span>
        </aside>

        <!-- 右：信息 -->
        <section class="right">
          <p class="eyebrow">
            {{ data.categoryName }} · {{ data.subCode }}
            <span class="dot"></span>
            <span class="cid">NO.{{ data.code }}</span>
          </p>
          <h2>{{ data.name }}</h2>
          <p class="roleline">{{ data.role }}</p>

          <p class="bio">{{ data.bio }}</p>

          <!-- 四维属性 -->
          <ul class="stats">
            <li v-for="(v, i) in data.stats" :key="i">
              <span class="lab">{{ STAT_LABELS[i] }}</span>
              <span class="track"><i :style="{ width: v + '%' }"></i></span>
              <span class="val">{{ v }}</span>
            </li>
          </ul>

          <!-- 人物故事 -->
          <div class="storybox">
            <div class="shead">
              <span class="bar"></span>
              <h3>人物故事</h3>
              <span class="sen">DOSSIER</span>
            </div>
            <template v-if="paragraphs(data.story).length">
              <p v-for="(p, i) in paragraphs(data.story)" :key="i">{{ p }}</p>
            </template>
            <p v-else class="nostory">该档案的人物故事尚未解密。</p>
          </div>

          <p class="foot">
            角色定位 {{ roleShort(data.role) }} · 档案分级 {{ data.tier }} · 热度 {{ data.heat }}
          </p>
        </section>
      </div>
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
  padding: 26px;
  background: rgba(6, 11, 17, .82);
  backdrop-filter: blur(6px);
  animation: fade .2s ease both;
}
@keyframes fade {
  from { opacity: 0; }
  to { opacity: 1; }
}

/* ---------- 弹窗主体 ---------- */
.panel {
  position: relative;
  width: min(940px, 100%);
  max-height: 88vh;
  overflow: auto;
  background: linear-gradient(168deg, rgba(20, 30, 41, .98), rgba(12, 20, 29, .99));
  border: 1px solid var(--line);
  clip-path: polygon(22px 0, 100% 0, 100% calc(100% - 22px), calc(100% - 22px) 100%, 0 100%, 0 22px);
  box-shadow: 0 40px 90px -30px #000, 0 0 60px -30px var(--c);
  animation: pop .3s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes pop {
  from { opacity: 0; transform: translateY(18px) scale(.98); }
  to { opacity: 1; transform: none; }
}
/* 顶部主色线 */
.panel::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  height: 2px;
  background: var(--c);
  box-shadow: 0 0 18px var(--c);
}

.x {
  position: absolute;
  top: 10px;
  right: 12px;
  z-index: 3;
  width: 32px;
  height: 32px;
  display: grid;
  place-items: center;
  font-size: 22px;
  line-height: 1;
  color: var(--muted);
  background: rgba(10, 17, 25, .7);
  border: 1px solid var(--line);
  cursor: pointer;
  transition: .2s;
}
.x:hover { color: #fff; border-color: var(--c); background: var(--c); }

/* ---------- 两栏布局 ---------- */
.wrap {
  display: grid;
  grid-template-columns: 330px 1fr;
  gap: 0;
}

/* ---------- 左：立绘 ---------- */
.left {
  position: relative;
  min-height: 430px;
  display: grid;
  place-items: center;
  border-right: 1px solid var(--line);
  background:
    radial-gradient(120% 80% at 50% 108%, color-mix(in srgb, var(--c) 30%, transparent), transparent 64%),
    linear-gradient(180deg, rgba(10, 17, 25, .25), rgba(10, 17, 25, .92));
  overflow: hidden;
}
.left img {
  max-width: 100%;
  max-height: 430px;
  object-fit: contain;
  filter: drop-shadow(0 22px 32px rgba(0, 0, 0, .7));
  animation: rise .45s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes rise {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: none; }
}
.wm {
  position: absolute;
  left: 8px;
  bottom: -26px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 168px;
  line-height: 1;
  color: var(--c);
  opacity: .1;
  user-select: none;
  pointer-events: none;
}
.badge {
  width: 116px;
  height: 116px;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 54px;
  color: var(--c);
  border: 2px solid color-mix(in srgb, var(--c) 60%, transparent);
  background: rgba(10, 17, 25, .55);
  clip-path: polygon(18px 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%, 0 18px);
  box-shadow: 0 0 46px -16px var(--c);
}
.tier {
  position: absolute;
  top: 16px;
  left: 16px;
  width: 30px;
  height: 30px;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 16px;
  color: #0b1017;
  background: var(--c);
  clip-path: polygon(0 0, 100% 0, 100% 68%, 68% 100%, 0 100%);
}

/* ---------- 右：信息 ---------- */
.right { padding: 24px 26px 20px; }
.eyebrow {
  display: flex;
  align-items: center;
  gap: 9px;
  margin: 0 0 8px;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1.8px;
  color: var(--c);
}
.eyebrow .dot { width: 4px; height: 4px; background: var(--line); }
.eyebrow .cid { color: var(--muted); }
.right h2 {
  margin: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 40px;
  line-height: 1;
  letter-spacing: 3.4px;
  text-transform: uppercase;
  color: var(--cream);
}
.roleline {
  margin: 6px 0 14px;
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.8px;
  color: var(--muted);
}
.bio {
  margin: 0 0 16px;
  padding-left: 12px;
  border-left: 2px solid var(--c);
  font-size: 13.5px;
  line-height: 1.75;
  color: var(--cream);
  opacity: .92;
}

/* 属性条 */
.stats { list-style: none; margin: 0 0 18px; padding: 0; display: grid; gap: 8px; }
.stats li { display: grid; grid-template-columns: 40px 1fr 30px; align-items: center; gap: 10px; }
.lab { font-size: 11.5px; color: var(--muted); }
.track { height: 5px; background: rgba(236, 232, 225, .09); overflow: hidden; }
.track i {
  display: block;
  height: 100%;
  background: var(--c);
  box-shadow: 0 0 14px -2px var(--c);
  animation: grow .7s cubic-bezier(.2, 1, .3, 1) both;
}
@keyframes grow {
  from { width: 0 !important; }
}
.val { font-family: var(--mono); font-size: 11px; color: var(--cream); text-align: right; }

/* 人物故事 */
.storybox {
  padding: 14px 16px;
  background: rgba(10, 17, 25, .55);
  border: 1px solid var(--line);
  max-height: 250px;
  overflow: auto;
}
.shead { display: flex; align-items: center; gap: 9px; margin-bottom: 10px; }
.shead .bar { width: 3px; height: 14px; background: var(--c); }
.shead h3 {
  margin: 0;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 2px;
  color: var(--cream);
}
.shead .sen {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 2px;
  color: var(--muted);
}
.storybox p {
  margin: 0 0 11px;
  font-size: 13px;
  line-height: 1.9;
  color: var(--muted);
  text-align: justify;
}
.storybox p:last-child { margin-bottom: 0; }
.storybox p:first-of-type { color: color-mix(in srgb, var(--cream) 88%, transparent); }
.nostory { font-style: italic; opacity: .7; }

.foot {
  margin: 14px 0 0;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.6px;
  color: var(--muted);
}

/* ---------- 加载 / 出错 ---------- */
.state { padding: 74px 20px; text-align: center; }
.state p { margin: 14px 0 0; font-size: 12.5px; color: var(--muted); }
.spin {
  width: 34px;
  height: 34px;
  margin: 0 auto;
  border: 2px solid rgba(236, 232, 225, .14);
  border-top-color: var(--c);
  border-radius: 50%;
  animation: rot .8s linear infinite;
}
@keyframes rot { to { transform: rotate(360deg); } }
.ex {
  width: 44px;
  height: 44px;
  margin: 0 auto;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 22px;
  color: var(--red);
  border: 1px solid var(--red);
  transform: skewX(-10deg);
}
.retry {
  margin-top: 16px;
  padding: 9px 22px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--cream);
  font-family: var(--disp);
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  transition: .2s;
}
.retry:hover { background: var(--c); border-color: var(--c); color: #0b1017; }

/* ---------- 响应式 ---------- */
@media (max-width: 760px) {
  .mask { padding: 12px; }
  .wrap { grid-template-columns: 1fr; }
  .left { min-height: 260px; border-right: none; border-bottom: 1px solid var(--line); }
  .left img { max-height: 260px; }
  .wm { font-size: 120px; bottom: -18px; }
  .right { padding: 18px; }
  .right h2 { font-size: 30px; letter-spacing: 2.4px; }
  .panel { max-height: 92vh; }
}
</style>
