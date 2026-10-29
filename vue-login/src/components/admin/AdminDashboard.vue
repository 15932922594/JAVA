<script setup>
/* ============================================================
   后台管理台
   标签页：概览统计 / 档案 / 分类 / 动态(情报) / 任务简报 / 用户 / 日志
   数据来源：/api/admin/*（AdminController）
   列字段与后端表结构（sql/home.sql、sql/mission.sql）保持一致。
   ============================================================ */
import { computed, onMounted, reactive, ref } from 'vue'
import { state, switchView, useSession } from '../../store/session'
import * as api from '../../store/api'
import { beep } from '../../composables/useSound'

const { showToast, adminSignOut, adminSetPermission } = useSession()

const token = computed(() => state.adminToken || '')

/* ---------------- 标签页 ---------------- */
const TABS = [
  { code: 'stats', label: '概览', en: 'OVERVIEW' },
  { code: 'archive', label: '档案', en: 'ARCHIVE' },
  { code: 'category', label: '分类', en: 'CATEGORY' },
  { code: 'feed', label: '动态', en: 'FEED' },
  { code: 'mission', label: '任务', en: 'MISSION' },
  { code: 'user', label: '用户', en: 'USER' },
  { code: 'log', label: '日志', en: 'LOG' }
]
const tab = ref('stats')

/* ---------------- 通用请求 ---------------- */
async function call(fn, ...args) {
  const r = await fn(token.value, ...args)
  if (r.code !== 0) {
    showToast(r.msg || '请求失败', false)
    return null
  }
  return r.data
}

/* ---------------- 概览统计 ---------------- */
const stats = ref(null)

/* ---------------- 通用列表状态 ---------------- */
const list = reactive({ rows: [], total: 0, pages: 0, page: 1, loading: false, q: '' })
const PAGE_SIZE = 8

/* ---------------- 编辑弹窗 ---------------- */
const editing = ref(false)          // 弹窗开关
const editTab = ref('')             // 当前编辑的对象类型：archive|category|feed|mission
const form = reactive({})           // 编辑表单（字段随对象类型变化）

function openEdit(type, row) {
  editTab.value = type
  editing.value = true
  Object.keys(form).forEach((k) => delete form[k])
  Object.assign(form, row ? { ...row } : defaultOf(type))
}
function closeEdit() {
  editing.value = false
}

function defaultOf(type) {
  if (type === 'archive')
    return { id: null, category_code: 'AGENT', sub_code: '', tier: 'A', code: '', name: '', name_cn: '', mono: '', color: '#FF4655', bio: '', img: '', abilities: '', firepower: 5, mobility: 5, control: 5, defense: 5, heat: 0, featured: 0, sort: 0, status: 1, story: '' }
  if (type === 'category')
    return { id: null, parent_id: 0, code: '', name: '', name_en: '', sort: 0 }
  if (type === 'feed')
    return { id: null, kind: 'NEWS', title: '', summary: '', body: '', source: '', importance: 'LOW', category_code: '', tag: '', heat: 0, status: 1 }
  if (type === 'mission')
    return { id: null, mission_code: '', briefing: '', objectives: '', reward: 100, duration_min: 30, region: '', squad: '', status: 1 }
  return {}
}

/* 表单字段定义：驱动编辑弹窗渲染（key 与后端返回的行字段一致） */
const FORM_FIELDS = {
  archive: [
    { k: 'category_code', lab: '一级分类', type: 'select', options: ['AGENT', 'GEAR', 'MISSION'] },
    { k: 'sub_code', lab: '二级分类', type: 'text' },
    { k: 'tier', lab: '分级', type: 'select', options: ['S', 'A', 'B'] },
    { k: 'code', lab: '代号(英文唯一)', type: 'text', required: true },
    { k: 'name', lab: '名称(英文)', type: 'text', required: true },
    { k: 'name_cn', lab: '中文名', type: 'text' },
    { k: 'mono', lab: '单字缩写', type: 'text' },
    { k: 'color', lab: '主题色', type: 'text' },
    { k: 'bio', lab: '简介', type: 'area' },
    { k: 'img', lab: '立绘地址', type: 'text' },
    { k: 'firepower', lab: '火力', type: 'num' },
    { k: 'mobility', lab: '机动', type: 'num' },
    { k: 'control', lab: '控制', type: 'num' },
    { k: 'defense', lab: '防御', type: 'num' },
    { k: 'heat', lab: '热度', type: 'num' },
    { k: 'sort', lab: '排序', type: 'num' },
    { k: 'featured', lab: '首页精选', type: 'select', options: [1, 0] },
    { k: 'status', lab: '状态', type: 'select', options: [1, 0] },
    { k: 'abilities', lab: '能力JSON [{slot,name,desc}]', type: 'area' },
    { k: 'story', lab: '人物故事(空行分段)', type: 'area' }
  ],
  category: [
    { k: 'parent_id', lab: '父分类(0=一级)', type: 'select', options: [0, 1, 2, 3] },
    { k: 'code', lab: '分类编码', type: 'text', required: true },
    { k: 'name', lab: '中文名', type: 'text', required: true },
    { k: 'name_en', lab: '英文名', type: 'text' },
    { k: 'sort', lab: '排序', type: 'num' }
  ],
  feed: [
    { k: 'kind', lab: '类型', type: 'select', options: ['NEWS', 'PATCH', 'MISSION'] },
    { k: 'title', lab: '标题', type: 'text', required: true },
    { k: 'summary', lab: '摘要', type: 'area' },
    { k: 'body', lab: '正文', type: 'area' },
    { k: 'source', lab: '来源', type: 'text' },
    { k: 'importance', lab: '重要度(1低/2中/3高)', type: 'select', options: [1, 2, 3] },
    { k: 'category_code', lab: '关联分类', type: 'text' },
    { k: 'tag', lab: '角标文案', type: 'text' },
    { k: 'heat', lab: '热度', type: 'num' },
    { k: 'status', lab: '状态', type: 'select', options: [1, 0] }
  ],
  mission: [
    { k: 'mission_code', lab: '任务代号(关联档案code)', type: 'text', required: true },
    { k: 'briefing', lab: '简报', type: 'area' },
    { k: 'objectives', lab: '目标(每行一个)', type: 'area' },
    { k: 'reward', lab: '积分奖励', type: 'num' },
    { k: 'duration_min', lab: '时限(分钟)', type: 'num' },
    { k: 'region', lab: '区域', type: 'text' },
    { k: 'squad', lab: '小队要求', type: 'text' },
    { k: 'status', lab: '状态', type: 'select', options: [1, 0] }
  ]
}

/* ---------------- 各列表加载 ---------------- */
// 直接引用 api 函数（call 会自动注入 token 并解包 r.data）
const LIST_LOADERS = {
  archive: api.adminArchiveList,
  category: api.adminCategoryList,
  feed: api.adminFeedList,
  mission: api.adminMissionList,
  user: api.adminUserList,
  log: api.adminLogList
}

async function load(reset = true) {
  if (tab.value === 'stats') {
    stats.value = await call(api.adminStats)
    return
  }
  if (reset) list.page = 1
  const loader = LIST_LOADERS[tab.value]
  if (!loader) return
  list.loading = true
  // call() 自动注入 token 作为首参并解包为 r.data
  const data = await call(loader, { q: list.q.trim(), page: list.page, size: PAGE_SIZE })
  list.loading = false
  if (!data) return
  list.rows = data.list || data.rows || data || []
  if (!Array.isArray(list.rows)) list.rows = []
  list.total = data.total ?? list.rows.length
  list.pages = data.pages ?? 1
}

function search() { load(true) }
function goPage(p) {
  if (p < 1 || p > list.pages) return
  list.page = p
  load(false)
}

function switchTab(code) {
  tab.value = code
  beep(520, 0.04)
  load(true)
}

/* ---------------- 保存 / 删除 ---------------- */
const saving = ref(false)

async function saveEdit() {
  const f = FORM_FIELDS[editTab.value]
  for (const item of f) {
    if (item.required && !String(form[item.k] ?? '').trim()) {
      showToast(`请填写「${item.lab}」`, false)
      return
    }
  }
  saving.value = true
  const saveFns = {
    archive: api.adminArchiveSave,
    category: api.adminCategorySave,
    feed: api.adminFeedSave,
    mission: api.adminMissionSave
  }
  const data = await call(saveFns[editTab.value], { ...form })
  saving.value = false
  if (!data) return
  beep(660, 0.08)
  showToast(form.id ? '修改已保存' : '新增成功', true)
  closeEdit()
  load(tab.value !== 'stats')
}

async function removeRow(type, row) {
  if (!confirm(`确认删除「${row.name || row.title || row.code || row.id}」？此操作不可恢复。`)) return
  const delFns = {
    archive: api.adminArchiveDelete,
    category: api.adminCategoryDelete,
    feed: api.adminFeedDelete,
    mission: api.adminMissionDelete
  }
  const data = await call(delFns[type], row.id)
  if (data === null) return
  beep(300, 0.06)
  showToast('已删除', true)
  load()
}

/* ---------------- 用户权限（0 管理员 / 1 默认） ---------------- */
const permBusy = ref(null)

async function togglePermission(row) {
  if (permBusy.value !== null) return
  const next = row.permission === 0 ? 1 : 0
  const tip = next === 0 ? '设为管理员？该账号将可登录后台管理系统。' : '取消管理员权限？该账号将无法再登录后台。'
  if (!confirm(tip)) return
  permBusy.value = row.id
  const r = await adminSetPermission(row.id, next)
  permBusy.value = null
  if (!r.ok) {
    showToast(r.reason || '操作失败', false)
    return
  }
  beep(660, 0.08)
  showToast(next === 0 ? '已授予管理员权限' : '已恢复默认权限', true)
  load(false)
}

/* ---------------- 退出后台 ---------------- */
async function signOut() {
  await adminSignOut()
  showToast('已退出后台', true)
}

onMounted(load)
</script>

<template>
  <div class="admin">
    <!-- 顶栏 -->
    <header class="ad-top">
      <div class="ad-brand">
        <span class="dot"></span>
        <span class="t">ADMIN CONSOLE</span>
        <span class="who">{{ state.admin?.displayName || state.admin?.username || '' }}</span>
      </div>
      <div class="ad-actions">
        <button class="ghost" type="button" @click="switchView('home')">前台首页</button>
        <button class="ghost danger" type="button" @click="signOut">退出后台</button>
      </div>
    </header>

    <!-- 标签页 -->
    <nav class="ad-tabs">
      <button
        v-for="t in TABS"
        :key="t.code"
        class="tab"
        :class="{ on: tab === t.code }"
        type="button"
        @click="switchTab(t.code)"
      >
        {{ t.label }}<i>{{ t.en }}</i>
      </button>
    </nav>

    <!-- 概览 -->
    <section v-if="tab === 'stats'" class="ad-body">
      <div v-if="stats" class="stat-grid">
        <div v-for="(v, k) in stats" :key="k" class="stat-card">
          <div class="sv">{{ v }}</div>
          <div class="sk">{{ k }}</div>
        </div>
      </div>
      <div v-else class="empty">正在加载统计 ...</div>
    </section>

    <!-- 列表页 -->
    <section v-else class="ad-body">
      <div class="ad-toolbar">
        <input
          v-model="list.q"
          class="q"
          type="text"
          placeholder="关键词检索 ..."
          @keyup.enter="search"
        />
        <button class="ghost" type="button" @click="search">搜索</button>
        <button
          v-if="['archive', 'category', 'feed', 'mission'].includes(tab)"
          class="ghost primary"
          type="button"
          @click="openEdit(tab, null)"
        >+ 新增</button>
      </div>

      <div class="tbl-wrap">
        <table class="tbl">
          <thead>
            <tr>
              <th>ID</th>
              <th v-if="tab === 'archive'">名称 / 代号</th>
              <th v-else-if="tab === 'category'">分类</th>
              <th v-else-if="tab === 'feed'">动态</th>
              <th v-else-if="tab === 'mission'">任务</th>
              <th v-else-if="tab === 'user'">用户</th>
              <th v-else-if="tab === 'log'">操作</th>
              <th>操作</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="row in list.rows" :key="row.id">
              <td class="mono">{{ row.id }}</td>

              <template v-if="tab === 'archive'">
                <td>
                  <b>{{ row.name }}</b>
                  <span v-if="row.name_cn" class="sub">{{ row.name_cn }}</span>
                  <span class="mono sub">{{ row.code }}</span>
                  <span class="pill">{{ row.tier }}</span>
                  <span class="sub">{{ row.category_code }} / {{ row.sub_code || '-' }}</span>
                </td>
              </template>
              <template v-else-if="tab === 'category'">
                <td>
                  <b>{{ row.name }}</b>
                  <span class="mono sub">{{ row.code }}</span>
                  <span class="sub">{{ row.name_en }} · {{ row.parent_id === 0 || row.level === 1 ? '一级' : '二级' }}</span>
                </td>
              </template>
              <template v-else-if="tab === 'feed'">
                <td>
                  <span class="pill">{{ row.kind }}</span>
                  <b>{{ row.title }}</b>
                  <span class="sub">{{ row.summary }}</span>
                </td>
              </template>
              <template v-else-if="tab === 'mission'">
                <td>
                  <b>{{ row.name }}</b>
                  <span class="mono sub">{{ row.mission_code }}</span>
                  <span class="pill">{{ row.tier || '—' }}</span>
                  <span class="sub">奖励 {{ row.reward }} 分 · {{ row.duration_min || 0 }} 分钟 · {{ row.region || '未设区域' }}</span>
                </td>
              </template>
              <template v-else-if="tab === 'user'">
                <td>
                  <b>{{ row.name }}</b>
                  <span class="pill" :class="{ 'perm-admin': row.permission === 0 }">
                    {{ row.permission === 0 ? '管理员' : '默认权限' }}
                  </span>
                  <span class="mono sub">{{ row.email }}</span>
                  <span class="sub">密码 {{ row.password || '—' }} · 注册于 {{ row.create_time }}</span>
                </td>
              </template>
              <template v-else-if="tab === 'log'">
                <td>
                  <span class="pill">{{ row.action }}</span>
                  <b>{{ row.admin_name }}</b>
                  <span class="sub">{{ row.target }} · {{ row.detail }}</span>
                  <span class="sub">{{ row.create_time }}</span>
                </td>
              </template>

              <td class="ops">
                <template v-if="['archive', 'category', 'feed', 'mission'].includes(tab)">
                  <button class="op" type="button" @click="openEdit(tab, row)">编辑</button>
                  <button class="op danger" type="button" @click="removeRow(tab, row)">删除</button>
                </template>
                <template v-else-if="tab === 'user'">
                  <button
                    class="op"
                    :class="{ danger: row.permission === 0 }"
                    type="button"
                    :disabled="permBusy === row.id"
                    @click="togglePermission(row)"
                  >
                    {{ permBusy === row.id
                      ? '处理中…'
                      : (row.permission === 0 ? '取消管理员' : '设为管理员') }}
                  </button>
                </template>
                <span v-else class="sub">—</span>
              </td>
            </tr>
            <tr v-if="!list.rows.length && !list.loading">
              <td colspan="2" class="empty">暂无数据</td>
            </tr>
          </tbody>
        </table>
        <div v-if="list.loading" class="empty">加载中 ...</div>
      </div>

      <div v-if="list.pages > 1" class="pager">
        <button class="ghost" :disabled="list.page <= 1" @click="goPage(list.page - 1)">‹</button>
        <span class="mono">{{ list.page }} / {{ list.pages }}</span>
        <button class="ghost" :disabled="list.page >= list.pages" @click="goPage(list.page + 1)">›</button>
      </div>
    </section>

    <!-- 编辑弹窗 -->
    <div v-if="editing" class="modal-mask" @click.self="closeEdit">
      <div class="modal">
        <div class="m-head">
          <span class="m-title">{{ form.id ? '编辑' : '新增' }} · {{ TABS.find(t => t.code === editTab)?.en }}</span>
          <button class="op" type="button" @click="closeEdit">✕</button>
        </div>
        <div class="m-body">
          <label v-for="f in FORM_FIELDS[editTab]" :key="f.k" class="m-field" :class="{ full: f.type === 'area' }">
            <span class="lab">{{ f.lab }}<i v-if="f.required">*</i></span>
            <select v-if="f.type === 'select'" v-model="form[f.k]">
              <option v-for="o in f.options" :key="o" :value="o">{{ o }}</option>
            </select>
            <textarea
              v-else-if="f.type === 'area'"
              v-model="form[f.k]"
              rows="3"
              spellcheck="false"
            ></textarea>
            <input
              v-else-if="f.type === 'num'"
              v-model.number="form[f.k]"
              type="number"
            />
            <input v-else v-model="form[f.k]" type="text" spellcheck="false" />
          </label>
        </div>
        <div class="m-foot">
          <button class="ghost" type="button" @click="closeEdit">取消</button>
          <button class="primary-btn" type="button" :disabled="saving" @click="saveEdit">
            {{ saving ? '保存中 ...' : '保存' }}
          </button>
        </div>
      </div>
    </div>
  </div>
</template>

<style scoped>
.admin {
  position: relative;
  z-index: 2;
  min-height: 100vh;
  padding: 86px 26px 24px;
  max-width: 1280px;
  margin: 0 auto;
}

/* ---------- 顶栏 ---------- */
.ad-top {
  display: flex;
  align-items: center;
  justify-content: space-between;
  margin-bottom: 18px;
}
.ad-brand { display: flex; align-items: center; gap: 12px; }
.dot {
  width: 9px; height: 9px;
  background: var(--red);
  box-shadow: 0 0 12px var(--red);
}
.ad-brand .t {
  font-family: var(--disp);
  font-size: 24px;
  letter-spacing: 3px;
  color: var(--cream);
}
.who {
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.5px;
  color: var(--ac);
  border: 1px solid var(--line);
  padding: 3px 10px;
}
.ad-actions { display: flex; gap: 10px; }

/* ---------- 按钮 ---------- */
.ghost {
  padding: 8px 15px;
  background: rgba(17, 26, 36, .8);
  border: 1px solid var(--line);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  letter-spacing: 1.5px;
  cursor: pointer;
  transition: .2s;
}
.ghost:hover:not(:disabled) { color: var(--cream); border-color: var(--ac); }
.ghost:disabled { opacity: .4; cursor: default; }
.ghost.danger:hover { border-color: var(--red); color: var(--red); }
.ghost.primary { border-color: var(--ac); color: var(--ac); }
.primary-btn {
  padding: 10px 26px;
  background: var(--red);
  border: none;
  color: #fff;
  font-family: var(--disp);
  font-size: 15px;
  letter-spacing: 2px;
  cursor: pointer;
}
.primary-btn:hover { background: var(--red-d); }
.primary-btn:disabled { opacity: .6; cursor: wait; }

/* ---------- 标签页 ---------- */
.ad-tabs {
  display: flex;
  gap: 6px;
  flex-wrap: wrap;
  border-bottom: 1px solid var(--line);
  margin-bottom: 18px;
}
.tab {
  position: relative;
  padding: 10px 18px 12px;
  background: transparent;
  border: none;
  color: var(--muted);
  font-family: var(--sans);
  font-size: 14px;
  cursor: pointer;
  transition: .2s;
}
.tab i {
  display: block;
  font-family: var(--mono);
  font-style: normal;
  font-size: 9px;
  letter-spacing: 2px;
  opacity: .6;
}
.tab.on { color: var(--cream); }
.tab.on::after {
  content: '';
  position: absolute;
  left: 0; right: 0; bottom: -1px;
  height: 2px;
  background: var(--red);
}

/* ---------- 概览 ---------- */
.stat-grid {
  display: grid;
  grid-template-columns: repeat(auto-fill, minmax(170px, 1fr));
  gap: 14px;
}
.stat-card {
  background: rgba(17, 26, 36, .86);
  border: 1px solid var(--line);
  padding: 22px 20px;
  clip-path: polygon(12px 0, 100% 0, 100% calc(100% - 12px), calc(100% - 12px) 100%, 0 100%, 0 12px);
}
.sv {
  font-family: var(--disp);
  font-size: 42px;
  color: var(--ac);
  line-height: 1;
}
.sk {
  margin-top: 8px;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2.5px;
  color: var(--muted);
  text-transform: uppercase;
}

/* ---------- 工具栏 ---------- */
.ad-toolbar { display: flex; gap: 10px; margin-bottom: 14px; }
.q {
  flex: 1;
  max-width: 320px;
  padding: 9px 13px;
  background: var(--bg2);
  border: 1px solid var(--line);
  color: var(--cream);
  font-family: var(--mono);
  font-size: 12px;
  outline: none;
}
.q:focus { border-color: var(--ac); }

/* ---------- 表格 ---------- */
.tbl-wrap {
  background: rgba(17, 26, 36, .86);
  border: 1px solid var(--line);
  overflow-x: auto;
}
.tbl { width: 100%; border-collapse: collapse; }
.tbl th, .tbl td {
  text-align: left;
  padding: 12px 16px;
  border-bottom: 1px solid rgba(236, 232, 225, .07);
  font-size: 13px;
  vertical-align: top;
}
.tbl th {
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--muted);
  text-transform: uppercase;
}
.tbl tbody tr:hover { background: rgba(236, 232, 225, .03); }
.mono { font-family: var(--mono); }
.sub {
  display: block;
  color: var(--muted);
  font-size: 11px;
  margin-top: 2px;
}
.pill {
  display: inline-block;
  margin: 2px 6px 0 0;
  padding: 1px 8px;
  border: 1px solid var(--ac);
  color: var(--ac);
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 1px;
}
/* 注意：不要用 .admin 做修饰类，会和本组件根节点 .admin 的 scoped 样式撞车 */
.pill.perm-admin {
  background: var(--red);
  border-color: var(--red);
  color: #fff;
}
.ops { white-space: nowrap; }
.op {
  padding: 5px 12px;
  background: transparent;
  border: 1px solid var(--line);
  color: var(--muted);
  font-family: var(--mono);
  font-size: 11px;
  cursor: pointer;
  margin-right: 6px;
  transition: .2s;
}
.op:hover { color: var(--cream); border-color: var(--ac); }
.op.danger:hover { color: var(--red); border-color: var(--red); }
.empty {
  padding: 30px;
  text-align: center;
  color: var(--muted);
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 1.5px;
}

/* ---------- 分页 ---------- */
.pager {
  display: flex;
  align-items: center;
  justify-content: center;
  gap: 14px;
  margin-top: 16px;
  color: var(--muted);
  font-size: 12px;
}

/* ---------- 编辑弹窗 ---------- */
.modal-mask {
  position: fixed;
  inset: 0;
  z-index: 90;
  background: rgba(10, 17, 25, .8);
  display: flex;
  align-items: center;
  justify-content: center;
  padding: 20px;
}
.modal {
  width: 100%;
  max-width: 640px;
  max-height: 86vh;
  display: flex;
  flex-direction: column;
  background: var(--panel);
  border: 1px solid var(--line);
  clip-path: polygon(14px 0, 100% 0, 100% calc(100% - 14px), calc(100% - 14px) 100%, 0 100%, 0 14px);
}
.m-head {
  display: flex;
  align-items: center;
  justify-content: space-between;
  padding: 16px 20px;
  border-bottom: 1px solid var(--line);
}
.m-title {
  font-family: var(--mono);
  font-size: 12px;
  letter-spacing: 2.5px;
  color: var(--ac);
}
.m-body {
  flex: 1;
  overflow-y: auto;
  padding: 18px 20px;
  display: grid;
  grid-template-columns: 1fr 1fr;
  gap: 12px;
}
.m-field.full { grid-column: 1 / -1; }
.lab {
  display: block;
  font-family: var(--mono);
  font-size: 10px;
  letter-spacing: 2px;
  color: var(--muted);
  margin-bottom: 5px;
}
.lab i { color: var(--red); font-style: normal; }
.m-field input,
.m-field select,
.m-field textarea {
  width: 100%;
  padding: 9px 11px;
  background: var(--bg2);
  border: 1px solid var(--line);
  color: var(--cream);
  font-family: var(--mono);
  font-size: 12px;
  outline: none;
  resize: vertical;
}
.m-field input:focus,
.m-field select:focus,
.m-field textarea:focus { border-color: var(--ac); }
.m-foot {
  display: flex;
  justify-content: flex-end;
  gap: 10px;
  padding: 14px 20px;
  border-top: 1px solid var(--line);
}

@media (max-width: 640px) {
  .admin { padding: 78px 14px 18px; }
  .m-body { grid-template-columns: 1fr; }
  .ad-top { flex-direction: column; gap: 12px; align-items: flex-start; }
}
</style>
