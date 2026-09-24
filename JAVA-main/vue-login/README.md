# AGENT ACCESS · Vue 3 重构版

原 `valorant-login.html`（单文件 HTML + 原生 JS）的 **Vue 3 + Vite + SFC** 重构版本。
视觉效果、交互行为与原版保持一致，仅替换实现方式。

## 快速开始

```bash
cd vue-login
npm install
npm run dev        # 开发服务器，默认 http://localhost:5173
npm run build      # 生产构建，输出到 dist/
npm run preview    # 本地预览构建产物
```

## 技术栈

| 项 | 说明 |
| --- | --- |
| 框架 | Vue 3（`<script setup>` 组合式 API） |
| 构建 | Vite 6 |
| 样式 | 原生 CSS，不引 UI 库；组件级 `<style scoped>` + 少量全局共享样式 |
| 运行时依赖 | 仅 `vue`，无第三方运行时依赖 |
| 开发依赖 | `vite` / `@vitejs/plugin-vue`；`jsdom` 仅用于离线交互测试 |

## 目录结构

```
vue-login/
├─ index.html                    # 入口 HTML
├─ vite.config.js                # base:'./'，产物可直接部署到子目录
├─ src/
│  ├─ main.js                    # 应用入口
│  ├─ App.vue                    # 布局骨架、开机页控制、闪光效果、主题色同步
│  ├─ data/
│  │  └─ agents.js               # 特工数据（纯数据，无副作用）
│  ├─ store/
│  │  └─ session.js              # 响应式状态仓库 + 派生计算（等级/加密强度/进度）
│  ├─ composables/
│  │  ├─ useSound.js             # WebAudio 合成音效
│  │  ├─ useParallax.js          # 鼠标视差 → CSS 变量
│  │  └─ useEffects.js           # provide/inject 传递全屏闪光等跨层效果
│  ├─ styles/
│  │  ├─ base.css                # CSS 变量、重置
│  │  └─ auth.css                # 表单/字段/按钮等跨组件复用样式
│  ├─ components/
│  │  ├─ FxBackground.vue        # 粒子画布 + 斜纹/网格/扫光背景
│  │  ├─ Crosshair.vue           # 自定义准星（跟随 + 悬停张开）
│  │  ├─ ClickEffects.vue        # 点击涟漪 + 音效
│  │  ├─ TopHud.vue              # 顶栏与音效开关
│  │  ├─ BootScreen.vue          # 开机进度页
│  │  ├─ AgentShowcase.vue       # 特工立绘 / 定位 / 四维属性
│  │  ├─ AgentStrip.vue          # 底部特工选择条
│  │  ├─ AuthPanel.vue           # 面板容器 + 登录/注册切换
│  │  ├─ FieldInput.vue          # 通用输入字段（聚焦态 / 错误态 / 密码显隐）
│  │  ├─ LoginForm.vue           # 登录表单
│  │  ├─ RegisterForm.vue        # 注册表单（含加密等级条）
│  │  └─ AppToast.vue            # 全局提示
│  ├─ ssr-entry.js               # 仅用于离线结构校验的 SSR 入口
│  └─ assets/                    # 预留静态资源目录
└─ scripts/
   ├─ verify-styles.mjs          # CSS 选择器等价性校验
   ├─ verify-dom.mjs             # SSR 结构等价性校验
   └─ smoke-test.mjs             # jsdom 交互冒烟测试
```

## 相比原版的主要改动

**架构层面**

- 700 行 `(function(){ ... })()` 命令式脚本 → 拆成 12 个单一职责组件 + 1 个状态仓库
- 所有 `document.getElementById(...)` 读写 → 响应式 `reactive` 状态 + `computed` 派生
- `classList.toggle` 手工维护 UI 状态 → 模板绑定（`:class` / `:style` / `v-model`）
- 特工等级、加密强度、经验进度等由「回调里各写一遍」→ 收敛为 store 中的 `computed`
- 移除全部 `id` 与编辑器注入的 `data-page-node-id` 属性（唯一被 CSS 使用的 `#fx` 保留）

**保留不变**

- 视觉样式逐条迁移，与原版一一对应（用脚本校验，见下）
- 所有交互行为：开机动画、准星跟随、粒子连线、音效、Toast、表单校验规则与提示文案
- 校验逻辑与原版完全一致（含原版中 `!(len>=3 && (邮箱 || 含# || len>=3))` 这类冗余但等价的写法）
- 表单仍为纯前端演示，未连接后端接口

## 等价性校验

重构最容易出的问题是「样式挂点或文案悄悄丢了一个」，以及「交互行为被改坏了」。
仓库内附三个自动校验脚本，**都不需要浏览器**：

```bash
npm run verify          # 一次跑完：构建 + 样式校验 + 结构校验 + 交互冒烟

npm run verify:styles   # ① 抽取原版 <style> 与构建产物的全部选择器做集合比对
npm run verify:dom      # ② 用 Vue SSR 渲染整个应用，与原版 DOM 比对 class / placeholder / 文案
npm run smoke           # ③ 在 jsdom 里求值生产产物，实测交互流程（66 项断言）
```

**① 样式等价性** —— 自动忽略两处无害差异：Vue scoped 注入的 `[data-v-*]` 属性、
以及压缩器把 `::after` 写成 `:after`。当前结果：**138/138 全部命中**。

**② 结构等价性** —— 比对 class(72) / placeholder(6) / 可见文案(45)，全部命中。
它同时验证了「每个组件的 `setup()` 都能正常执行」，相当于一次免浏览器的冒烟测试。
已知且已登记的差异仅 2 条，均为原版「静态占位文本被首屏 JS 立即覆盖」导致，
Vue 版直接渲染覆盖后的最终状态：

- `SELECTED AGENT` → 最终态为 `SELECTED · <特工名>`
- `↑ 从下方选择你的特工` → 初始化后被 `当前特工： <名称> · <定位>` 覆盖

**③ 交互冒烟（66 项断言）** —— 直接对 `dist/` 的生产产物做真实交互，覆盖：

| 分组 | 覆盖内容 |
| --- | --- |
| 首屏渲染 | 挂载、画布、准星、6 张卡片、默认特工 VECTOR、等级 01 |
| 开机页 | 进度条跑满 → 点击 → 淡出 → 移除 → 就绪提示 |
| 特工切换 | 名称/定位/简介/选中态/`--ac` 主色（立绘与 `:root`）/等级 07/属性条宽度动画 |
| 标签切换 | 标题、副标题、表单显隐、标签高亮 |
| 表单校验 | 空提交标红、错误文案、输入自动清除错误、密码长度拦截 |
| 注册流程 | 加密等级随密码强度 3 段「高」→ 4 段「极高」、条款勾选、等级升至 16、提交 loading、成功提示、全屏闪光、表单重置 |
| 登录流程 | loading、成功提示带当前特工名 |
| 其他 | 第三方按钮提示、密码显隐切换、无运行时错误 |

> 写这类测试要注意：Vue 的 DOM 更新是异步的，点击后必须等一次宏任务
> （`scripts/smoke-test.mjs` 里的 `await click()` 已封装）再断言，否则会读到旧 DOM。

## 部署

`vite.config.js` 已设 `base: './'`，构建产物使用相对路径引用资源：
`npm run build` 后把 `dist/` 目录内容推到 GitHub Pages 任意子路径即可。

## 注意

`dist-ssr/` 与 `dist/` 是构建产物，已加入 `.gitignore`。`src/ssr-entry.js`
不参与线上产物，只在 `verify:dom` 中被使用。
