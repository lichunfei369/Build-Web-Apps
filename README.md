<!-- Language: 简体中文 | English -->

**简体中文** | [English](#english)

---

# Build Web Apps · React 全栈开发与诊断插件

一个 Claude Code 插件,提供一整套**诊断套件**,统一以 [`agent-browser`](https://agent-browser.dev) CLI 作为**唯一浏览器后端**,专注 **React** 应用的构建、调试、性能、内存、错误、网络、可访问性与状态问题。

> 姊妹项目:[Build-iOS-Apps](https://github.com/lichunfei369/Build-iOS-Apps) —— 同样的打包模式,iOS 版。

## 一、项目介绍

### 它能做什么
- **构建**:搭页面、做 dashboard / landing、组合 shadcn/ui、接 Stripe 支付、设计 Supabase/Postgres 数据。
- **深度诊断**(本插件新增的重点):
  - 🐞 深度调试(起 dev server → 复现 → 抓 console/network → 下钻专项)
  - ⚡ 渲染性能(re-render 录制、fiber 树、Core Web Vitals)
  - 🧠 内存泄漏(heap 快照、detached DOM、增长 diff)
  - 🔴 错误取证(console/未捕获异常/网络错误 + **source map 还原压缩堆栈** + 聚类根因)
  - 🌐 网络面板(慢/失败请求、瀑布、payload)
  - ♿ 可访问性(快照 + 注入 axe-core)
  - 🔀 状态调试(Redux / Zustand / React Query 读取与溯源)

### 为什么只用一个浏览器后端
`agent-browser` 会**自启一个 Chromium**,并把 agent 需要的一切以**紧凑、带引用 ID 的文本**(`@e1`/`@e2`,约 200–400 token,而非数千 token 的原始 DOM)暴露出来:accessibility 快照、点击/表单、截图、网络、React DevTools、profiler、Core Web Vitals。
本插件**刻意不使用 claude-in-chrome** —— 否则会对同一个 dev server 起两个互相冲突的 Chrome。某版本不支持的能力,**兜底走 Playwright**。

### 组件一览
| 类别 | 内容 |
|---|---|
| 🔬 诊断 skill ×7 | web-debugger-agent · react-render-performance · web-memory-leaks · web-error-forensics · web-network-inspector · web-a11y-audit · react-state-debugging |
| 🏗 建造 skill ×6 | frontend-app-builder · react/shadcn/stripe/supabase-best-practices · frontend-testing-debugging(浏览器路由已重写为 agent-browser) |
| ⌨️ 命令 | `/webgo` 中文统一分诊入口 |
| 🪝 Hook | dev-server gut-check(尽力而为) |
| 📜 脚本 | inject-axe.js(a11y)· read-store.js(状态读取) |
| ⚙️ 配置 | 不含 `.mcp.json`(agent-browser 是 CLI,不是 MCP) |

## 二、安装教程

### 前置 1:Node.js(两平台都需要)
- 需要 Node.js ≥ 18(自带 npm)。检查:`node -v` 与 `npm -v`。
- 没装的话到 https://nodejs.org 装 LTS 版。

### 前置 2:agent-browser 浏览器后端(**通常无需手动装**)

**插件会在首次使用浏览器功能时自动安装 agent-browser**:各 skill 的就绪检测会调用 `scripts/ensure-agent-browser.sh`(幂等),没装就自动装好 CLI 并预热 Chromium。所以**换设备装上插件后,第一次跑 `/webgo` 等浏览器任务会自动就绪,你不用敲任何命令**(首次下载 Chrome 会花几分钟)。一进会话若检测到没装,SessionStart 也会提示一句。

需要的话也可**手动预装**(可选):
- **macOS**:`npm i -g agent-browser`(或 `brew install agent-browser`)
- **Windows**(PowerShell):`npm i -g agent-browser`
- 临时用、不全局装:`npx agent-browser <命令>`
- 一键预装脚本:`bash scripts/ensure-agent-browser.sh`
- 验证:`agent-browser --version`

> 仍需 Node.js ≥ 18(前置 1)。自动安装失败(没 Node/npm、或 npm 权限)会给出提示,届时按提示手动装即可。

### 安装本插件(两平台命令一致)
```bash
claude plugin marketplace add lichunfei369/Build-Web-Apps
claude plugin install build-web-apps@build-web-apps-local
```
安装后**重启 Claude Code** 或执行 `/reload-plugins` 使其生效。

### 验证
```bash
claude plugin details build-web-apps   # 应显示 14 个 skill、1 个 hook、0 个 MCP
```
> ⚠️ 若你之前把 frontend-app-builder、react/shadcn/stripe/supabase-best-practices、frontend-testing-debugging **散装**放在 `~/.claude/skills/`,装本插件前请先移除它们,否则会**重复加载同名 skill**。

## 三、使用教程

### 浏览器后端铁律(所有 skill 共用)
- 唯一交互后端是 **agent-browser**(禁用 claude-in-chrome)。
- 缺能力时兜底 **Playwright**。
- 用 **agent-browser 截图**(`agent-browser screenshot`)存到仓库外,再用 **Read 打开 PNG 查看**——因为 agent-browser 跑的是它自己的 Chromium,我看不到那个窗口,只能读取保存下来的截图文件。
- **有头 / 无头模式**:agent-browser **默认无头(headless)**,在自带的独立后台 Chromium 里跑(不是你日常那个 Chrome 窗口),所以你**看不到操作过程**——但截图/快照取证一切正常,这也是上一条要靠 PNG 文件核对的原因。需要**实时观看**自动化时,`open` 加 `--headed`(或设环境变量 `AGENT_BROWSER_HEADED`)弹出可见窗口,同一会话后续命令沿用该窗口;默认无头即可,仅在你想"看到操作"时切有头。
- 子命令 flag 因版本而异,以 `agent-browser --help` 为准。

### 截图与临时文件(不会堆积)
- 所有截图/临时图写到 **`$TMPDIR/build-web-apps/`** —— 在系统临时目录,**不在你的项目里、不进 git**。
- 用**固定语义文件名**(`repro.png` / `before.png` / `after.png` / `profile.png`…)并**覆盖而非新增** → 文件数**恒定**,不随截图次数增长。
- 任务结束时诊断 skill 会 `agent-browser close` 并清理本次截图;你也可随时一键清:`bash scripts/clean-shots.sh`。
- macOS 还会定期回收 `$TMPDIR`,即便忘了清也不会长期堆积。

### 用法一:直接说需求(最省心)
在某个 React 项目里直接描述,插件会自动触发对应 skill:
```
把这个项目跑起来,打开首页给我截图
列表滑动很卡,帮我看看重渲染
详情页返回后内存不释放
线上这个压缩堆栈帮我还原定位
```

### 用法二:`/webgo` 统一入口(分诊更精准)
```
/webgo debug 启动后白屏,排查一下
/webgo perf  首屏 LCP 太慢
/webgo memory 反复进出详情页内存涨
/webgo error 控制台一堆报错,归类分析
/webgo network 搜索接口很慢
/webgo a11y  跑一遍可访问性审计
/webgo state 改了状态界面不更新
/webgo build 做一个定价页
```
不带参数 `/webgo` 会先问你要做哪一类。

### `/webgo` 分诊表
| 你说的话 | 路由到 |
|---|---|
| 搭页面 / dashboard / landing / UI 组件 | frontend-app-builder(+ shadcn / react-best-practices) |
| 跑起来 / 坏了 / 白屏 / 调试 | **web-debugger-agent** |
| 改完验证 / QA / 回归 | frontend-testing-debugging |
| 卡 / 慢 / 重渲染 / LCP·INP | **react-render-performance** |
| 内存 / 泄漏 / 越用越卡 | **web-memory-leaks** |
| 报错 / 堆栈 / 日志分析 | **web-error-forensics** |
| 接口慢 / 请求失败 / 瀑布 | **web-network-inspector** |
| 无障碍 / a11y / 键盘 / 对比度 | **web-a11y-audit** |
| 状态不对 / Redux / "为什么重渲染" | **react-state-debugging** |
| 支付 / 订阅 | stripe-best-practices |
| 数据库 / Postgres / RLS | supabase-best-practices |

### 典型工作流
1. `cd` 到你的 React 工程(或告诉我路径)。
2. 说"跑起来" → 发现/拉起 dev server → `agent-browser open` → 截图确认界面真渲染。
3. 报问题 → `web-debugger-agent` 复现取证 → 下钻到性能/内存/错误专项。
4. 修完 → `frontend-testing-debugging` 跑 QA 验证并出 pass/fail 报告。

### 已知风险(实际跑起来时验证)
- **console 抓取** 与 **深度 heap 快照** 依赖 agent-browser 具体版本的 CDP 能力,扛不住走 Playwright 兜底。
- **a11y** 与 **状态调试** 依赖注入脚本(`scripts/inject-axe.js` / `scripts/read-store.js`),属尽力而为。

---

<a name="english"></a>
[简体中文](#build-web-apps--react-全栈开发与诊断插件) | **English**

# Build Web Apps · React build & diagnosis plugin

A Claude Code plugin providing a full **diagnosis suite**, driven by a single browser backend — the [`agent-browser`](https://agent-browser.dev) CLI. Focused on building, debugging, profiling, and hardening **React** apps.

> Sibling of [Build-iOS-Apps](https://github.com/lichunfei369/Build-iOS-Apps) — same packaging model, web edition.

## 1. Overview

### What it does
- **Build**: pages, dashboards, landings, shadcn/ui composition, Stripe payments, Supabase/Postgres data.
- **Deep diagnosis** (the new focus):
  - 🐞 Deep debugging (start dev server → reproduce → capture console/network → drill down)
  - ⚡ Render performance (re-render recording, fiber tree, Core Web Vitals)
  - 🧠 Memory leaks (heap snapshots, detached DOM, growth diffing)
  - 🔴 Error forensics (console/uncaught/network errors + **source-map stack reconstruction** + clustering/root cause)
  - 🌐 Network inspection (slow/failed requests, waterfall, payloads)
  - ♿ Accessibility (snapshot + injected axe-core)
  - 🔀 State debugging (read Redux / Zustand / React Query, trace causes)

### Why one browser backend
`agent-browser` launches **its own Chromium** and exposes everything as compact, ref-addressed text (`@e1`, `@e2`, ~200–400 tokens vs thousands for a raw DOM): a11y snapshots, clicks/forms, screenshots, network, React DevTools, profiler, Core Web Vitals. We deliberately **do not** use claude-in-chrome — a second Chrome on the same dev server means two conflicting sessions. Fallback for missing capabilities is **Playwright**.

### Components
| Type | Items |
|---|---|
| 🔬 Diagnosis skills ×7 | web-debugger-agent · react-render-performance · web-memory-leaks · web-error-forensics · web-network-inspector · web-a11y-audit · react-state-debugging |
| 🏗 Build skills ×6 | frontend-app-builder · react/shadcn/stripe/supabase-best-practices · frontend-testing-debugging (browser routing rewritten to agent-browser) |
| ⌨️ Command | `/webgo` unified dispatcher |
| 🪝 Hook | dev-server gut-check (best-effort) |
| 📜 Scripts | inject-axe.js (a11y) · read-store.js (state) |
| ⚙️ Config | **no `.mcp.json`** (agent-browser is a CLI, not an MCP) |

## 2. Installation

### Prerequisite 1: Node.js (both platforms)
Node.js ≥ 18 (ships npm). Check with `node -v` / `npm -v`; install the LTS from https://nodejs.org if missing.

### Prerequisite 2: the agent-browser backend (**usually no manual install**)

**The plugin auto-installs agent-browser on first browser use** — every skill's readiness step calls `scripts/ensure-agent-browser.sh` (idempotent), which installs the CLI and warms up Chromium if missing. So on a fresh machine you just install the plugin and the first `/webgo` (or any browser task) sets it up with **zero manual steps** (the one-time Chrome download takes a few minutes). A SessionStart hook also nudges once if it's not yet installed.

Optionally pre-install it yourself:
- **macOS**: `npm i -g agent-browser` (or `brew install agent-browser`)
- **Windows** (PowerShell): `npm i -g agent-browser`
- Ad-hoc, no global install: `npx agent-browser <command>`
- One-shot pre-install script: `bash scripts/ensure-agent-browser.sh`
- Verify: `agent-browser --version`

> Still needs Node.js ≥ 18 (Prerequisite 1). If auto-install fails (no Node/npm, or npm permissions) it surfaces the error so you can install manually.

### Install the plugin (same on both platforms)
```bash
claude plugin marketplace add lichunfei369/Build-Web-Apps
claude plugin install build-web-apps@build-web-apps-local
```
Restart Claude Code or run `/reload-plugins` to activate.

### Verify
```bash
claude plugin details build-web-apps   # 14 skills, 1 hook, 0 MCP
```
> ⚠️ If you already have frontend-app-builder, react/shadcn/stripe/supabase-best-practices, or frontend-testing-debugging loose in `~/.claude/skills/`, remove them first to avoid duplicate-loading the same skill names.

## 3. Usage

### Browser-backend rule (every skill)
- **agent-browser** is the only interaction backend (claude-in-chrome is disabled here).
- **Playwright** is the fallback for missing capabilities.
- Take screenshots **with agent-browser** (`agent-browser screenshot`) to a path outside the repo, then **Read the PNG** to inspect it — agent-browser runs its own Chromium that the agent can't see, so it reads the saved file instead.
- Flags vary by version — confirm with `agent-browser --help`.

### Screenshots & temp files (no pile-up)
- All screenshots/temp images go to **`$TMPDIR/build-web-apps/`** — the system temp dir, **never your project, never git**.
- Use **fixed semantic names** (`repro.png` / `before.png` / `after.png` / `profile.png`…) and **overwrite** instead of adding files → the count stays constant no matter how many shots you take.
- On finish, diagnosis skills `agent-browser close` and clean their screenshots; you can also clear them anytime: `bash scripts/clean-shots.sh`.
- macOS reclaims `$TMPDIR` periodically too, so even un-cleaned shots don't accumulate long-term.

### Way 1: just describe the task
```
run this project and screenshot the home page
this list scrolls janky, check re-renders
memory isn't released after leaving the detail page
decode this minified production stack trace
```

### Way 2: the `/webgo` dispatcher
```
/webgo debug  white screen after start
/webgo perf   slow LCP on first paint
/webgo memory heap grows when navigating in/out of detail
/webgo error  console is flooded — cluster and analyze
/webgo network the search API is slow
/webgo a11y   run an accessibility audit
/webgo state  UI doesn't update after a state change
/webgo build  make a pricing page
```
`/webgo` with no args asks which category first.

### Dispatch table
| You say | Routes to |
|---|---|
| build page / dashboard / landing / UI | frontend-app-builder (+ shadcn / react-best-practices) |
| run it / broken / white screen / debug | **web-debugger-agent** |
| verify a change / QA / regression | frontend-testing-debugging |
| janky / slow / re-renders / LCP·INP | **react-render-performance** |
| memory / leak / slows over time | **web-memory-leaks** |
| errors / stack / log analysis | **web-error-forensics** |
| slow/failed API / waterfall | **web-network-inspector** |
| a11y / keyboard / contrast | **web-a11y-audit** |
| wrong state / Redux / "why re-render" | **react-state-debugging** |
| payments / subscriptions | stripe-best-practices |
| database / Postgres / RLS | supabase-best-practices |

### Typical loop
1. `cd` into your React project (or give the path).
2. Say "run it" → discover/start dev server → `agent-browser open` → screenshot to confirm a real render.
3. Report a problem → `web-debugger-agent` reproduces & captures → drills into the perf/memory/error specialist.
4. After a fix → `frontend-testing-debugging` runs the QA loop and returns a pass/fail report.

### Known risks (verify at runtime)
- **Console capture** and **deep heap diffing** depend on the installed agent-browser version's CDP surface — fall back to Playwright.
- **a11y** and **state debugging** rely on injected scripts (`scripts/inject-axe.js` / `scripts/read-store.js`) — best-effort.

## License
MIT.
