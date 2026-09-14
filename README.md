# JAVA
学习java记录过程

---

## 🌐 在线预览 Online Preview

由 **GitHub Pages** 部署，直接点开即可访问（源文件位于 `main` 分支根目录）：

| 页面 | 在线访问 | 源码 |
| --- | --- | --- |
| 🎯 无畏契约风格 · 特工登录页 | **[点击访问](https://15932922594.github.io/JAVA/valorant-login.html)** | [valorant-login.html](https://github.com/15932922594/JAVA/blob/main/valorant-login.html) |
| 🎮 游戏风格 · 登录/注册页 | [点击访问](https://15932922594.github.io/JAVA/auth-game.html) | [auth-game.html](https://github.com/15932922594/JAVA/blob/main/auth-game.html) |
| 🏠 站点首页 | [点击访问](https://15932922594.github.io/JAVA/) | [index.html](https://github.com/15932922594/JAVA/blob/main/index.html) |

> 首页 `index.html` 会自动跳转到特工登录页。

## 📁 页面说明

- **`valorant-login.html`** — 无畏契约（VALORANT）风格的战术科幻登录/注册页。含开机动画、鼠标视差、canvas 粒子、自定义准星、特工选择、表单校验、音效等交互效果。
- **`auth-game.html`** — 赛博霓虹游戏 HUD 风格的登录/注册页。含星空穿越背景、玩家卡片（等级/HP/MP/EXP）、职业选择、密码安全等级条。
- **`index.html`** — 站点首页，自动跳转。

## 🛠 技术说明

纯前端单文件实现：**HTML + CSS + 原生 JavaScript**，无任何第三方依赖，双击即可在浏览器打开。
表单目前仅为前端校验与演示，未连接后端接口。

## 🚀 本地运行

```bash
git clone https://github.com/15932922594/JAVA.git
cd JAVA
# 直接用浏览器打开 index.html 即可，或起一个本地服务：
python -m http.server 8000
# 然后访问 http://localhost:8000
```
