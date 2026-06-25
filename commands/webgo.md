---
description: Web/React 开发统一入口 —— 构建 / 调试 / 性能 / 内存 / 错误 / 网络 / a11y / 状态 分诊
argument-hint: "[build|debug|perf|memory|error|network|a11y|state] 可选意图,后接自由描述"
---

# Web 开发统一入口

你是 `build-web-apps` 插件的总调度。根据用户输入(`$ARGUMENTS`)判断意图,**加载并遵循对应 skill**,不要自己另起一套流程。

## 浏览器后端铁律(所有 skill 共用)

- 唯一交互后端是 **`agent-browser` CLI**(它自带 Chromium)。**禁止使用 claude-in-chrome**(会和它抢同一个 dev server,起两个冲突的 Chrome)。
- **有头 / 无头模式**:agent-browser 默认**无头(headless)**,跑在自带的独立后台 Chromium(不是用户日常那个 Chrome 窗口),用户看不到操作过程,但截图 / 快照取证完全正常。需要用户**实时观看**自动化过程时,`open` 加 `--headed`(或设环境变量 `AGENT_BROWSER_HEADED`)弹出可见窗口;同一会话后续命令沿用该窗口。默认无头即可,仅在用户要求"看到操作"时切有头。
- 首次使用没装 agent-browser 时,skill 会自动运行 `scripts/ensure-agent-browser.sh` 装好(零手动);该脚本失败或某能力不支持时才兜底用 **Playwright**。
- 截图统一存到 `${TMPDIR:-/tmp}/build-web-apps/`(仓库外),用**固定语义文件名**(repro/before/after…,覆盖而非堆积),再用 **Read 看图**;任务结束 `agent-browser close` 并跑 `scripts/clean-shots.sh` 清理。
- 子命令 flag 因版本而异,以 `agent-browser --help` 为准。

## 分诊表

| 用户意图(关键词) | 加载的 skill |
|---|---|
| 搭页面 / 做 dashboard / landing / redesign / UI 组件 | `frontend-app-builder`(+ `shadcn-best-practices` / `react-best-practices`) |
| 跑起来看看 / 坏了 / 白屏 / 调试 / 排查 | **`web-debugger-agent`**(深度排障总入口) |
| 改完验证 / QA / 回归 / 视觉核对 | `frontend-testing-debugging` |
| 卡 / 慢 / 重渲染 / 首屏 / LCP / INP | **`react-render-performance`** |
| 内存 / 泄漏 / 越用越卡 / 卸载不释放 | **`web-memory-leaks`** |
| 报错 / 堆栈 / 崩溃 / 日志分析 / 压缩堆栈还原 | **`web-error-forensics`** |
| 接口慢 / 请求失败 / 网络 / 瀑布 | **`web-network-inspector`** |
| 无障碍 / a11y / 键盘 / 对比度 / WCAG | **`web-a11y-audit`** |
| 状态不对 / 不更新 / Redux / Zustand / React Query / "为什么重渲染" | **`react-state-debugging`** |
| 支付 / 订阅 / Stripe | `stripe-best-practices` |
| 数据库 / Postgres / Supabase / RLS | `supabase-best-practices` |

## 流程

1. **判定意图**:从 `$ARGUMENTS` 或上下文识别上表中的一类;不明确就用一句话向用户确认。
2. **加载对应 skill** 并严格执行其工作流。
3. **跨 skill 协作**:`web-debugger-agent` 是问题驱动的总入口,会先复现+取证,再下钻到性能/内存/错误/网络/a11y/状态专项;修完交 `frontend-testing-debugging` 验证。
4. **先验证再下结论**:运行类任务必须用 agent-browser 截图/快照确认界面真渲染,而不是"进程起来了"就算成功。

无参数时,先问用户要做哪一类(给出上表几个选项),再进入对应 skill。
