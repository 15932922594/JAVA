<script setup>
/* ============================================================
   首页搜索栏（关键词 + 分级分类筛选）
   数据来源：后端 /api/home/search（HomePage.vue 负责请求）
   分级分类：一级分类 category → 二级分类 subCategory → 分级 tier
   ============================================================ */
import { computed, onBeforeUnmount, onMounted, ref } from 'vue'
import { beep } from '../../composables/useSound'

/** 分级档位（与后端 agent_archive.tier 一致） */
const TIERS = ['S', 'A', 'B']

const props = defineProps({
  /** 搜索关键词 */
  modelValue: { type: String, default: '' },
  /** 命中条数 */
  result: { type: Number, default: 0 },
  /** 总条数 */
  total: { type: Number, default: 0 },
  /** 热门关键词 */
  hot: { type: Array, default: () => [] },
  /** 分级分类目录（两级树，来自 /api/home/categories） */
  categories: { type: Array, default: () => [] },
  /** 当前一级分类编码 */
  category: { type: String, default: '' },
  /** 当前二级分类编码 */
  subCategory: { type: String, default: '' },
  /** 当前分级 S / A / B */
  tier: { type: String, default: '' },
  /** 是否请求中 */
  loading: { type: Boolean, default: false }
})

const emit = defineEmits([
  'update:modelValue',
  'update:category',
  'update:subCategory',
  'update:tier',
  'submit'
])

/** 当前一级分类下的二级分类（未选一级时展示全部二级） */
const subs = computed(() => {
  if (!props.category) {
    return props.categories.flatMap((c) => c.children || [])
  }
  return props.categories.find((c) => c.code === props.category)?.children || []
})

/** 当前已启用的筛选项数量（用于「清除筛选」） */
const filterCount = computed(
  () => (props.category ? 1 : 0) + (props.subCategory ? 1 : 0) + (props.tier ? 1 : 0)
)

function setCategory(code) {
  if (props.category === code) return
  emit('update:category', code)
  emit('update:subCategory', '') // 换大类时清空二级，避免出现无效组合
  beep(520, 0.05)
}

function setSub(code) {
  if (props.subCategory === code) return
  emit('update:subCategory', code)
  beep(560, 0.05)
}

function setTier(t) {
  if (props.tier === t) return
  emit('update:tier', t)
  beep(600, 0.05)
}

function resetFilters() {
  emit('update:category', '')
  emit('update:subCategory', '')
  emit('update:tier', '')
  beep(420, 0.05)
}

const inputEl = ref(null)
const focused = ref(false)
const hasText = computed(() => props.modelValue.trim().length > 0)

function onInput(e) {
  emit('update:modelValue', e.target.value)
}

function clear() {
  emit('update:modelValue', '')
  beep(420, 0.05)
  inputEl.value?.focus()
}

function submit() {
  beep(680, 0.06)
  emit('submit', props.modelValue.trim())
}

function pick(k) {
  emit('update:modelValue', k)
  beep(600, 0.05)
  inputEl.value?.focus()
}

/* ---------- 快捷键：/ 聚焦，Esc 清空 ---------- */
function onKey(e) {
  const tag = (e.target?.tagName || '').toLowerCase()
  const typing = tag === 'input' || tag === 'textarea'
  if (e.key === '/' && !typing) {
    e.preventDefault()
    inputEl.value?.focus()
    return
  }
  if (e.key === 'Escape' && document.activeElement === inputEl.value) {
    if (hasText.value) emit('update:modelValue', '')
    inputEl.value?.blur()
  }
}
onMounted(() => document.addEventListener('keydown', onKey))
onBeforeUnmount(() => document.removeEventListener('keydown', onKey))

defineExpose({ focus: () => inputEl.value?.focus() })
</script>

<template>
  <div class="search">
    <div class="bar" :class="{ focus: focused, filled: hasText }">
      <span class="prompt">//</span>

      <svg class="ic" width="18" height="18" viewBox="0 0 24 24" fill="none">
        <circle cx="11" cy="11" r="6.4" stroke="currentColor" stroke-width="1.8" />
        <path d="m16 16 4.4 4.4" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" />
      </svg>

      <input
        ref="inputEl"
        class="ipt"
        type="text"
        :value="modelValue"
        placeholder="搜索特工代号 / 定位 / 关键词…"
        autocomplete="off"
        spellcheck="false"
        aria-label="站内搜索"
        @input="onInput"
        @focus="focused = true"
        @blur="focused = false"
        @keyup.enter="submit"
      />

      <button v-if="hasText" class="clear" type="button" title="清空" aria-label="清空搜索" @click="clear">
        <svg width="13" height="13" viewBox="0 0 24 24" fill="none">
          <path d="M6 6l12 12M18 6 6 18" stroke="currentColor" stroke-width="2.6" stroke-linecap="round" />
        </svg>
      </button>

      <button class="go" type="button" @click="submit">检索</button>
    </div>

    <!-- ---------- 分级分类筛选 ---------- -->
    <div class="filters">
      <div class="frow">
        <span class="flab">类别</span>
        <button class="f" :class="{ on: !category }" type="button" @click="setCategory('')">全部</button>
        <button
          v-for="c in categories"
          :key="c.code"
          class="f"
          :class="{ on: category === c.code }"
          type="button"
          @click="setCategory(c.code)"
        >
          {{ c.name }}<i>{{ c.count }}</i>
        </button>
      </div>

      <div class="frow" v-if="subs.length">
        <span class="flab">细分</span>
        <button class="f" :class="{ on: !subCategory }" type="button" @click="setSub('')">全部</button>
        <button
          v-for="s in subs"
          :key="s.code"
          class="f"
          :class="{ on: subCategory === s.code }"
          type="button"
          @click="setSub(s.code)"
        >
          {{ s.name }}<i>{{ s.count }}</i>
        </button>
      </div>

      <div class="frow">
        <span class="flab">分级</span>
        <button class="f" :class="{ on: !tier }" type="button" @click="setTier('')">全部</button>
        <button
          v-for="t in TIERS"
          :key="t"
          class="f tier"
          :class="{ on: tier === t }"
          type="button"
          @click="setTier(t)"
        >
          {{ t }}
        </button>

        <button v-if="filterCount" class="clearf" type="button" @click="resetFilters">
          清除筛选 ×{{ filterCount }}
        </button>
      </div>
    </div>

    <div class="meta">
      <div class="hot" v-if="hot.length">
        <span class="hotlab">热门</span>
        <button v-for="k in hot" :key="k" class="k" type="button" @click="pick(k)">{{ k }}</button>
      </div>
      <span class="sp"></span>
      <span class="count">
        <template v-if="loading">
          检索中<span class="dots">…</span>
        </template>
        <template v-else-if="hasText || filterCount">
          命中 <b>{{ result }}</b> / {{ total }} 条档案
        </template>
        <template v-else>
          共 <b>{{ total }}</b> 条档案 · 按 <kbd>/</kbd> 聚焦搜索
        </template>
      </span>
    </div>
  </div>
</template>

<style scoped>
.search { width: 100%; }

.bar {
  position: relative;
  display: flex;
  align-items: center;
  gap: 12px;
  height: 62px;
  padding: 0 8px 0 18px;
  background: linear-gradient(160deg, rgba(22, 33, 44, .94), rgba(15, 25, 35, .96));
  border: 1px solid var(--line);
  backdrop-filter: blur(8px);
  clip-path: polygon(16px 0, 100% 0, 100% calc(100% - 16px), calc(100% - 16px) 100%, 0 100%, 0 16px);
  transition: border-color .22s, box-shadow .22s;
}
.bar:hover { border-color: rgba(236, 232, 225, .3); }
.bar.focus {
  border-color: var(--ac);
  box-shadow: 0 0 40px -14px var(--ac), inset 0 0 40px -30px var(--ac);
}

.prompt {
  font-family: var(--mono);
  font-size: 13px;
  letter-spacing: 1px;
  color: var(--ac);
  flex-shrink: 0;
  user-select: none;
}
.ic { color: var(--muted); flex-shrink: 0; transition: .2s; }
.bar.focus .ic { color: var(--ac); }

.ipt {
  flex: 1;
  min-width: 0;
  height: 100%;
  border: 0;
  outline: 0;
  background: transparent;
  color: var(--cream);
  font-family: var(--sans);
  font-size: 15.5px;
  letter-spacing: .4px;
}
.ipt::placeholder { color: var(--muted); }

.clear {
  width: 30px;
  height: 30px;
  flex-shrink: 0;
  display: grid;
  place-items: center;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--muted);
  cursor: pointer;
  transition: .18s;
}
.clear:hover { color: var(--red); border-color: var(--red); }

.go {
  flex-shrink: 0;
  height: 44px;
  padding: 0 26px;
  border: 0;
  background: var(--ac);
  color: #fff;
  font-family: var(--disp);
  font-weight: 700;
  font-size: 15px;
  letter-spacing: 3px;
  cursor: pointer;
  clip-path: polygon(11px 0, 100% 0, calc(100% - 11px) 100%, 0 100%);
  box-shadow: 0 0 26px -10px var(--ac);
  transition: .2s;
}
.go:hover { background: var(--red); box-shadow: 0 0 30px -8px var(--red); }

/* ---------- 分级分类筛选 ---------- */
.filters {
  margin-top: 14px;
  display: grid;
  gap: 9px;
}
.frow {
  display: flex;
  align-items: center;
  gap: 7px;
  flex-wrap: wrap;
}
.flab {
  flex-shrink: 0;
  width: 34px;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--muted);
}
.f {
  display: inline-flex;
  align-items: center;
  gap: 5px;
  border: 1px solid var(--line);
  background: transparent;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1px;
  padding: 5px 10px;
  cursor: pointer;
  transition: .18s;
}
.f i {
  font-style: normal;
  font-size: 9px;
  opacity: .6;
}
.f:hover { color: var(--cream); border-color: rgba(236, 232, 225, .38); }
.f.on {
  color: #fff;
  background: var(--ac);
  border-color: var(--ac);
  box-shadow: 0 0 18px -8px var(--ac);
}
.f.on i { opacity: .85; }
.f.tier { min-width: 38px; justify-content: center; }

.clearf {
  margin-left: 4px;
  border: 1px dashed var(--line);
  background: transparent;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1px;
  padding: 5px 10px;
  cursor: pointer;
  transition: .18s;
}
.clearf:hover { color: var(--red); border-color: var(--red); }

.dots { animation: blink 1s steps(3) infinite; }
@keyframes blink { 50% { opacity: .2; } }

/* ---------- 底部元信息 ---------- */
.meta {
  display: flex;
  align-items: center;
  gap: 10px;
  margin-top: 12px;
  flex-wrap: wrap;
}
.hot { display: flex; align-items: center; gap: 7px; flex-wrap: wrap; }
.hotlab {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--muted);
}
.k {
  border: 1px solid var(--line);
  background: transparent;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1px;
  padding: 4px 9px;
  cursor: pointer;
  transition: .18s;
}
.k:hover { color: var(--cream); border-color: var(--ac); box-shadow: 0 0 16px -8px var(--ac); }
.sp { flex: 1; }
.count {
  font-family: var(--mono);
  font-size: 10.5px;
  letter-spacing: 1.4px;
  color: var(--muted);
}
.count b { color: var(--ac); }
kbd {
  font-family: var(--mono);
  font-size: 10px;
  border: 1px solid var(--line);
  padding: 1px 5px;
  color: var(--cream);
}

/* ---------- 响应式 ---------- */
@media (max-width: 720px) {
  .bar { height: 56px; padding-left: 14px; gap: 9px; }
  .go { padding: 0 16px; height: 40px; font-size: 14px; letter-spacing: 2px; }
  .ipt { font-size: 14.5px; }
  .count { width: 100%; }
}
</style>
