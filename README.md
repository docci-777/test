# Hex Settlers

一个以六角格资源交易桌游为灵感的独立实现，用于验证“高阶模型规划/审查、执行模型按 Issue 编码”的协作流程。

> 当前状态：M0。工程脚手架 PR #11 已通过审查和 CI，等待合并；玩法实现尚未开始。实时状态以 [多模型协作控制中心](docs/TASK_DISPATCH.md) 为准。

## 多模型协作入口

所有任务派发、当前进度、依赖关系、审查门禁和文档更新统一从 [docs/TASK_DISPATCH.md](docs/TASK_DISPATCH.md) 开始。

派发给低阶执行模型：

> 阅读 `docs/TASK_DISPATCH.md` 的“执行模型协议”，按其中当前状态和 Issue #N 完成任务；如果 Issue 不是 `READY` 或 `IN_PROGRESS`，立即停止并报告。

派发给高阶审查模型：

> 阅读 `docs/TASK_DISPATCH.md` 的“高阶模型审查协议”，开始审查 PR #N；把结构化结论记录到 PR，不要自动合并。

## 首版目标

- 3–4 人标准基础玩法
- 可复现的纯 TypeScript 规则引擎
- 命令行完整对局模拟与状态回放
- React + Vite 的本地浏览器界面
- 规则测试、类型检查、Lint 与构建全部由 CI 验证

首版不包含扩展规则、联网对战、AI 玩家、账号系统或官方美术资源。

## 技术方向

- Runtime：Node.js 24 LTS
- Language：TypeScript（strict）
- UI：React + Vite
- Tests：Vitest
- Architecture：`Command -> validation -> state transition -> Event`

规则引擎不依赖 UI、网络、系统时钟或隐式随机数。所有随机行为必须通过可注入、可设 seed 的随机源完成。

## 文档索引

- 动态协作与进度：[docs/TASK_DISPATCH.md](docs/TASK_DISPATCH.md)
- 产品边界：[docs/PRODUCT.md](docs/PRODUCT.md)
- 规则契约：[docs/GAME_RULES.md](docs/GAME_RULES.md)
- 架构约束：[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 路线图：[docs/ROADMAP.md](docs/ROADMAP.md)
- 模型不可变规则：[AGENTS.md](AGENTS.md)
- 分支与贡献流程：[CONTRIBUTING.md](CONTRIBUTING.md)

## 知识产权说明

本项目是独立学习与工程实践项目，不隶属于、也不代表任何商业桌游品牌。
