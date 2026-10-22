<script setup>
/* ============================================================
   档案卡片网格 —— 首页搜索结果的展示组件
   数据来源：后端 /api/home/search（agent_archive 表）
   字段：name / mono / role("中文 · EN") / tier / color / bio / img / stats[]
   img 为空的条目（装备、任务）回退为 mono 徽标
   点击卡片 → 抛出 open 事件（父组件拉 /api/home/detail 展示详情弹窗）
   ============================================================ */
import { STAT_LABELS, roleShort } from '../../data/agents'

defineProps({
  /** 档案列表 */
  agents: { type: Array, default: () => [] },
  /** 当前搜索词（空态提示用） */
  query: { type: String, default: '' },
  /** 是否加载中（骨架屏） */
  loading: { type: Boolean, default: false },
  /** 是否处于筛选/搜索状态（空态文案不同） */
  filtered: { type: Boolean, default: false }
})

const emit = defineEmits(['open'])

/** 能力/特性名称，卡片上做一句「能干什么」的速览 */
function abilityNames(a) {
  const list = Array.isArray(a && a.abilities) ? a.abilities : []
  return list.map((x) => x && x.name).filter(Boolean)
}
</script>

<template>
  <div class="grid">
    <!-- ---------- 骨架屏 ---------- -->
    <template v-if="loading">
      <div v-for="i in 6" :key="'sk' + i" class="card skel">
        <div class="media"></div>
        <div class="body">
          <span class="bl w60"></span>
          <span class="bl w40"></span>
          <span class="bl w90"></span>
          <span class="bl w80"></span>
        </div>
      </div>
    </template>

    <template v-else>
      <!-- 点击整张卡片 → 打开档案详情（介绍 + 人物故事） -->
      <article
        v-for="a in agents"
        :key="a.id"
        class="card"
        :style="{ '--c': a.color }"
        role="button"
        tabindex="0"
        :aria-label="`查看档案 ${a.name}`"
        @click="emit('open', a.code)"
        @keydown.enter.prevent="emit('open', a.code)"
        @keydown.space.prevent="emit('open', a.code)"
      >
        <div class="media">
          <span class="wm">{{ a.mono }}</span>

          <!-- 有立绘展示图，没有则回退为字母徽标 -->
          <img v-if="a.img" :src="a.img" :alt="a.name" loading="lazy" />
          <span v-else class="badge">{{ a.mono }}</span>

          <span class="role">{{ roleShort(a.role) }}</span>
          <span v-if="a.tier" class="tier">{{ a.tier }}</span>

          <!-- 悬停提示：可查看详情 -->
          <span class="hint">查看档案 <i>→</i></span>
        </div>

        <div class="body">
          <h3>{{ a.name }}<span v-if="a.nameCn" class="cn">{{ a.nameCn }}</span></h3>
          <p class="roleline">
            {{ a.role }}
            <span v-if="a.categoryName" class="cat">{{ a.categoryName }}</span>
          </p>
          <p class="bio">{{ a.bio }}</p>

          <!-- 能力速览：不看详情也能知道它有哪几招 -->
          <p v-if="abilityNames(a).length" class="abs">
            <span v-for="(n, i) in abilityNames(a)" :key="i">{{ n }}</span>
          </p>

          <ul class="stats">
            <li v-for="(v, i) in a.stats" :key="i">
              <span class="lab">{{ STAT_LABELS[i] }}</span>
              <span class="track"><i :style="{ width: v + '%' }"></i></span>
              <span class="val">{{ v }}</span>
            </li>
          </ul>
        </div>
      </article>
    </template>

    <!-- ---------- 空态 ---------- -->
    <div v-if="!loading && !agents.length" class="empty">
      <div class="ex">!</div>
      <h4>未检索到匹配档案</h4>
      <p v-if="filtered">
        <template v-if="query">关键词「{{ query }}」</template>
        <template v-else>当前筛选条件</template>
        没有命中任何档案，换个关键词或放宽分级试试。
      </p>
      <p v-else>档案库暂无数据。</p>
    </div>
  </div>
</template>

<style scoped>
.grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(264px, 1fr));
  gap: 20px;
}

/* ---------- 卡片 ---------- */
.card {
  position: relative;
  background: linear-gradient(170deg, rgba(22, 33, 44, .92), rgba(15, 25, 35, .95));
  border: 1px solid var(--line);
  clip-path: polygon(18px 0, 100% 0, 100% calc(100% - 18px), calc(100% - 18px) 100%, 0 100%, 0 18px);
  overflow: hidden;
  cursor: pointer;
  transition: transform .28s cubic-bezier(.2, 1, .3, 1), border-color .28s, box-shadow .28s;
  animation: rise .5s cubic-bezier(.2, 1, .3, 1) both;
}
.card:focus-visible {
  outline: 2px solid var(--c);
  outline-offset: 2px;
}
.card:active { transform: translateY(-2px) scale(.995); }
@keyframes rise {
  from { opacity: 0; transform: translateY(14px); }
  to { opacity: 1; transform: none; }
}
.card:hover {
  transform: translateY(-6px);
  border-color: var(--c);
  box-shadow: 0 30px 60px -34px #000, 0 0 34px -18px var(--c);
}
/* 顶部一道主色细线 */
.card::before {
  content: '';
  position: absolute;
  left: 0;
  right: 0;
  top: 0;
  height: 2px;
  background: var(--c);
  opacity: .55;
  transition: opacity .28s;
}
.card:hover::before { opacity: 1; }

/* ---------- 立绘 ---------- */
.media {
  position: relative;
  height: 236px;
  background:
    radial-gradient(120% 90% at 50% 108%, color-mix(in srgb, var(--c) 26%, transparent), transparent 62%),
    linear-gradient(180deg, rgba(10, 17, 25, .2), rgba(10, 17, 25, .9));
  overflow: hidden;
  display: grid;
  place-items: center;
}
.media img {
  max-width: 100%;
  max-height: 100%;
  object-fit: contain;
  filter: drop-shadow(0 18px 26px rgba(0, 0, 0, .65));
  transition: transform .38s cubic-bezier(.2, 1, .3, 1);
}
.card:hover .media img { transform: translateY(-6px) scale(1.05); }

.wm {
  position: absolute;
  left: 10px;
  bottom: -18px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 132px;
  line-height: 1;
  color: var(--c);
  opacity: .1;
  pointer-events: none;
  user-select: none;
}
.role {
  position: absolute;
  top: 12px;
  right: 12px;
  font-family: var(--mono);
  font-size: 9.5px;
  letter-spacing: 1.6px;
  padding: 4px 8px;
  color: var(--c);
  border: 1px solid color-mix(in srgb, var(--c) 55%, transparent);
  background: rgba(10, 17, 25, .72);
  backdrop-filter: blur(4px);
}

/* 分级角标 */
.tier {
  position: absolute;
  top: 12px;
  left: 12px;
  width: 26px;
  height: 26px;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 14px;
  color: #0b1017;
  background: var(--c);
  clip-path: polygon(0 0, 100% 0, 100% 68%, 68% 100%, 0 100%);
}

/* 悬停提示：可点开档案详情 */
.hint {
  position: absolute;
  left: 0;
  right: 0;
  bottom: 0;
  padding: 9px 12px;
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 6px;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: #0b1017;
  background: var(--c);
  transform: translateY(100%);
  transition: transform .28s cubic-bezier(.2, 1, .3, 1);
}
.hint i { font-style: normal; font-size: 12px; }
.card:hover .hint,
.card:focus-visible .hint { transform: none; }

/* 无立绘时的字母徽标 */
.badge {
  width: 96px;
  height: 96px;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 46px;
  color: var(--c);
  border: 2px solid color-mix(in srgb, var(--c) 60%, transparent);
  background: rgba(10, 17, 25, .55);
  clip-path: polygon(16px 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%, 0 16px);
  box-shadow: 0 0 40px -14px var(--c);
  transition: transform .38s cubic-bezier(.2, 1, .3, 1);
}
.card:hover .badge { transform: translateY(-6px) scale(1.06); }

/* ---------- 骨架屏 ---------- */
.skel { animation: none; pointer-events: none; }
.skel .media { background: rgba(236, 232, 225, .05); }
.skel .bl {
  display: block;
  height: 11px;
  margin-bottom: 9px;
  background: linear-gradient(90deg, rgba(236, 232, 225, .06), rgba(236, 232, 225, .13), rgba(236, 232, 225, .06));
  background-size: 220% 100%;
  animation: sweep 1.3s linear infinite;
}
.skel .w60 { width: 60%; }
.skel .w40 { width: 40%; }
.skel .w90 { width: 90%; }
.skel .w80 { width: 80%; }
@keyframes sweep {
  from { background-position: 120% 0; }
  to { background-position: -120% 0; }
}

/* ---------- 文本 ---------- */
.body { padding: 16px 18px 18px; }
.body h3 {
  margin: 0;
  display: flex;
  align-items: baseline;
  gap: 9px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 25px;
  letter-spacing: 2.5px;
  text-transform: uppercase;
  color: var(--cream);
}
/* 英文代号旁并排的中文名 */
.cn {
  font-family: var(--mono);
  font-size: 13px;
  letter-spacing: 1.4px;
  text-transform: none;
  color: var(--c);
}

/* 能力速览标签 */
.abs {
  display: flex;
  flex-wrap: wrap;
  gap: 6px;
  margin: 0 0 12px;
}
.abs span {
  padding: 3px 7px;
  font-size: 10.5px;
  letter-spacing: .6px;
  color: var(--cream);
  border: 1px solid color-mix(in srgb, var(--c) 45%, transparent);
  background: color-mix(in srgb, var(--c) 12%, transparent);
}
.roleline {
  display: flex;
  align-items: center;
  gap: 8px;
  margin: 3px 0 10px;
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.6px;
  color: var(--c);
}
.cat {
  padding: 2px 6px;
  border: 1px solid var(--line);
  color: var(--muted);
  font-size: 9px;
  letter-spacing: 1px;
}
.bio {
  margin: 0 0 14px;
  font-size: 12.5px;
  line-height: 1.65;
  color: var(--muted);
  display: -webkit-box;
  -webkit-line-clamp: 2;
  -webkit-box-orient: vertical;
  overflow: hidden;
}

/* ---------- 属性条 ---------- */
.stats { list-style: none; margin: 0; padding: 0; display: grid; gap: 7px; }
.stats li { display: grid; grid-template-columns: 34px 1fr 26px; align-items: center; gap: 9px; }
.lab { font-size: 11px; color: var(--muted); letter-spacing: .5px; }
.track {
  height: 4px;
  background: rgba(236, 232, 225, .09);
  overflow: hidden;
}
.track i {
  display: block;
  height: 100%;
  background: var(--c);
  box-shadow: 0 0 12px -2px var(--c);
  transition: width .6s cubic-bezier(.2, 1, .3, 1);
}
.val {
  font-family: var(--mono);
  font-size: 10.5px;
  color: var(--cream);
  text-align: right;
}

/* ---------- 空态 ---------- */
.empty {
  grid-column: 1 / -1;
  text-align: center;
  padding: 52px 20px;
  border: 1px dashed var(--line);
  background: rgba(17, 26, 36, .5);
}
.ex {
  width: 46px;
  height: 46px;
  margin: 0 auto 14px;
  display: grid;
  place-items: center;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 24px;
  color: var(--red);
  border: 1px solid var(--red);
  transform: skewX(-10deg);
  box-shadow: 0 0 26px -8px var(--red);
}
.empty h4 {
  margin: 0 0 6px;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 19px;
  letter-spacing: 2px;
}
.empty p { margin: 0; font-size: 12.5px; color: var(--muted); }

@media (max-width: 640px) {
  .grid { grid-template-columns: 1fr; }
  .media { height: 210px; }
}
</style>
