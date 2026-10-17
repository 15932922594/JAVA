<script setup>
/* ============================================================
   情报详情弹窗（可交互）
   - 打开即自动标记已读（后端 /api/intel/detail 负责）
   - 点赞 / 收藏 / 标记未读，操作后 emit('changed') 让列表刷新统计
   - 关联档案：按 categoryCode 跳到特工档案 / 武器库 / 作战任务
   ============================================================ */
import { computed, onBeforeUnmount, onMounted, ref, watch } from 'vue'
import { intelDetail, intelLike, intelRead, intelStar } from '../../store/api'
import { beep } from '../../composables/useSound'

const props = defineProps({
  /** 情报 id（0 表示不请求） */
  id: { type: Number, default: 0 },
  token: { type: String, default: '' }
})

const emit = defineEmits(['close', 'changed', 'goto'])

const item = ref(null)
const loading = ref(false)
const error = ref('')
const busy = ref('')

const KIND_NAMES = { NEWS: '情报', PATCH: '版本', MISSION: '任务' }

async function load() {
  if (!props.id || !props.token) return
  loading.value = true
  error.value = ''
  item.value = null
  const r = await intelDetail(props.token, props.id)
  loading.value = false
  if (r.code === 0) {
    item.value = r.data
    emit('changed')
  } else {
    error.value = r.code === 404 ? '情报不存在或已下线' : `情报解密失败 · ${r.msg || '未知错误'}`
  }
}

async function like() {
  if (busy.value) return
  busy.value = 'like'
  const r = await intelLike(props.token, props.id)
  busy.value = ''
  if (r.code !== 0) return
  item.value = { ...item.value, liked: r.data.liked, likes: r.data.likes }
  beep(r.data.liked ? 760 : 420, 0.06)
  emit('changed')
}

async function star() {
  if (busy.value) return
  busy.value = 'star'
  const r = await intelStar(props.token, props.id)
  busy.value = ''
  if (r.code !== 0) return
  item.value = { ...item.value, starred: r.data.starred }
  beep(r.data.starred ? 820 : 380, 0.06)
  emit('changed')
}

async function unread() {
  if (busy.value) return
  busy.value = 'unread'
  const r = await intelRead(props.token, props.id, false)
  busy.value = ''
  if (r.code !== 0) return
  item.value = { ...item.value, read: false }
  beep(340, 0.07)
  emit('changed')
}

/** 关联档案的目标视图 */
const VIEW_BY_CATEGORY = { AGENT: 'agents', GEAR: 'arsenal', MISSION: 'missions' }
const gotoView = computed(() => VIEW_BY_CATEGORY[item.value?.categoryCode] || '')

const paras = computed(() =>
  String(item.value?.body || '')
    .split('\n')
    .map((s) => s.trim())
    .filter(Boolean)
)

const kindName = computed(() => KIND_NAMES[item.value?.kind] || item.value?.kind || '')

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

watch(() => props.id, load)
</script>

<template>
  <div class="mask" @click.self="emit('close')">
    <div class="panel">
      <button class="x" type="button" title="关闭（ESC）" @click="emit('close')">×</button>

      <div v-if="loading" class="state"><div class="spin"></div><p>正在解密情报 …</p></div>

      <div v-else-if="error" class="state">
        <div class="ex">!</div>
        <p>{{ error }}</p>
        <button class="retry" type="button" @click="load">重新解密</button>
      </div>

      <template v-else-if="item">
        <header class="head">
          <div class="tags">
            <span class="kind" :data-kind="item.kind">{{ kindName }}</span>
            <span v-if="item.tag" class="tag">{{ item.tag }}</span>
            <span class="imp" :data-i="item.importance">{{ item.importanceName }}</span>
          </div>
          <h2>{{ item.title }}</h2>
          <p class="meta">
            <span v-if="item.source">来源 · {{ item.source }}</span>
            <span class="dot"></span>
            <span>{{ item.publishedAt }}</span>
            <span class="dot"></span>
            <span>热度 {{ item.heat }}</span>
          </p>
        </header>

        <div class="body">
          <p v-if="item.summary" class="lead">{{ item.summary }}</p>
          <p v-for="(p, i) in paras" :key="i" class="para">{{ p }}</p>
          <p v-if="!paras.length" class="para muted">该情报暂无正文内容。</p>
        </div>

        <footer class="foot">
          <div class="acts">
            <button
              class="act like"
              :class="{ on: item.liked }"
              type="button"
              :disabled="busy === 'like'"
              @click="like"
            >
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
                <path d="M12 20s-7-4.35-7-9a4 4 0 0 1 7-2.6A4 4 0 0 1 19 11c0 4.65-7 9-7 9z"
                  :fill="item.liked ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" />
              </svg>
              认可 <b>{{ item.likes }}</b>
            </button>

            <button
              class="act star"
              :class="{ on: item.starred }"
              type="button"
              :disabled="busy === 'star'"
              @click="star"
            >
              <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
                <path d="M12 3.5l2.7 5.6 6.1.9-4.4 4.3 1 6.1-5.4-2.9-5.4 2.9 1-6.1L3.2 10l6.1-.9z"
                  :fill="item.starred ? 'currentColor' : 'none'" stroke="currentColor" stroke-width="1.8" />
              </svg>
              {{ item.starred ? '已收藏' : '收藏' }}
            </button>

            <button class="act" type="button" :disabled="busy === 'unread' || !item.read" @click="unread">
              标记未读
            </button>
          </div>

          <button
            v-if="gotoView"
            class="goto"
            type="button"
            @click="emit('goto', gotoView)"
          >
            查看{{ item.categoryName || '相关' }}档案 <i>→</i>
          </button>
        </footer>
      </template>
    </div>
  </div>
</template>

<style scoped>
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
  width: min(760px, 100%);
  max-height: 88vh;
  overflow: auto;
  padding: 24px 26px 18px;
  background: linear-gradient(168deg, rgba(20, 30, 41, .99), rgba(12, 20, 29, .99));
  border: 1px solid var(--line);
  clip-path: polygon(20px 0, 100% 0, 100% calc(100% - 20px), calc(100% - 20px) 100%, 0 100%, 0 20px);
  box-shadow: 0 40px 90px -30px #000, 0 0 60px -36px var(--red);
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
  background: var(--ac);
  box-shadow: 0 0 20px var(--ac);
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
.x:hover { color: #fff; background: var(--red); border-color: var(--red); }

/* 加载 / 错误 */
.state { display: grid; place-items: center; gap: 12px; padding: 54px 20px; text-align: center; }
.state p { margin: 0; font-family: var(--mono); font-size: 11px; letter-spacing: 1.4px; color: var(--muted); }
.spin {
  width: 26px; height: 26px;
  border: 2px solid rgba(236, 232, 225, .18);
  border-top-color: var(--ac);
  border-radius: 50%;
  animation: spin .8s linear infinite;
}
@keyframes spin { to { transform: rotate(360deg); } }
.ex {
  width: 38px; height: 38px;
  display: grid; place-items: center;
  border: 1px solid var(--red);
  color: var(--red);
  font-family: var(--disp);
  font-size: 20px;
}
.retry {
  padding: 8px 18px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--cream);
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.4px;
  cursor: pointer;
  transition: .2s;
}
.retry:hover { border-color: var(--ac); color: #fff; }

/* 头部 */
.tags { display: flex; gap: 7px; align-items: center; margin-bottom: 11px; }
.kind, .tag, .imp {
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.6px;
  padding: 3px 9px;
  border: 1px solid var(--line);
  color: var(--muted);
}
.kind[data-kind="PATCH"] { color: #00E0C6; border-color: rgba(0, 224, 198, .5); }
.kind[data-kind="MISSION"] { color: #FFB443; border-color: rgba(255, 180, 67, .5); }
.kind[data-kind="NEWS"] { color: var(--ac); border-color: rgba(255, 70, 85, .5); }
.tag { color: var(--cream); }
.imp[data-i="3"] { color: #fff; background: var(--red); border-color: var(--red); animation: blink 1.1s steps(2) infinite; }
.imp[data-i="2"] { color: #FFB443; border-color: rgba(255, 180, 67, .55); }
@keyframes blink { 50% { opacity: .5; } }

h2 {
  margin: 0 0 10px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 30px;
  line-height: 1.2;
  letter-spacing: 2.2px;
  color: var(--cream);
}
.meta {
  display: flex;
  align-items: center;
  gap: 9px;
  margin: 0 0 16px;
  padding-bottom: 14px;
  border-bottom: 1px solid var(--line);
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.3px;
  color: var(--muted);
}
.dot { width: 3px; height: 3px; border-radius: 50%; background: var(--ac); }

/* 正文 */
.lead {
  margin: 0 0 12px;
  padding-left: 12px;
  border-left: 2px solid var(--ac);
  font-size: 13.5px;
  line-height: 1.7;
  color: #cfd8e0;
}
.para {
  margin: 0 0 10px;
  font-size: 13px;
  line-height: 1.85;
  color: #a9b6c2;
}
.para.muted { color: var(--muted); }

/* 底部操作 */
.foot {
  display: flex;
  align-items: center;
  justify-content: space-between;
  gap: 14px;
  flex-wrap: wrap;
  margin-top: 18px;
  padding-top: 14px;
  border-top: 1px solid var(--line);
}
.acts { display: flex; gap: 8px; flex-wrap: wrap; }
.act {
  display: inline-flex;
  align-items: center;
  gap: 6px;
  padding: 8px 13px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.3px;
  cursor: pointer;
  transition: .2s;
}
.act b { font-weight: 700; color: inherit; }
.act:hover { color: var(--cream); border-color: rgba(236, 232, 225, .4); }
.act:disabled { opacity: .45; cursor: not-allowed; }
.act.like.on { color: var(--red); border-color: var(--red); background: rgba(255, 70, 85, .1); }
.act.star.on { color: #FFB443; border-color: #FFB443; background: rgba(255, 180, 67, .1); }

.goto {
  padding: 9px 16px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--cream);
  font-family: var(--disp);
  font-weight: 700;
  font-size: 13px;
  letter-spacing: 2px;
  cursor: pointer;
  clip-path: polygon(9px 0, 100% 0, calc(100% - 9px) 100%, 0 100%);
  transition: .2s;
}
.goto:hover { color: #fff; background: var(--ac); border-color: var(--ac); box-shadow: 0 0 24px -10px var(--ac); }
.goto i { font-style: normal; }

@media (max-width: 620px) {
  h2 { font-size: 23px; }
  .panel { padding: 18px 16px 14px; }
}
</style>
