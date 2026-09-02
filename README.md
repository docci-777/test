# Hex Settlers

一个以六角格资源交易桌游为灵感的独立实现，用于验证“高阶模型规划/审查、执行模型按 Issue 编码”的协作流程。

> 当前阶段与实时任务状态请查看 [docs/STATUS.md](docs/STATUS.md)。

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

## 协作入口

- 总入口：[docs/TASK_DISPATCH.md](docs/TASK_DISPATCH.md)
- 当前状态：[docs/STATUS.md](docs/STATUS.md)
- 低阶模型执行：[docs/EXECUTOR_GUIDE.md](docs/EXECUTOR_GUIDE.md)
- 高阶模型审查：[docs/REVIEW_GUIDE.md](docs/REVIEW_GUIDE.md)
- 文档维护：[docs/DOC_MAINTENANCE.md](docs/DOC_MAINTENANCE.md)
- 产品边界：[docs/PRODUCT.md](docs/PRODUCT.md)
- 规则契约：[docs/GAME_RULES.md](docs/GAME_RULES.md)
- 架构约束：[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 路线图：[docs/ROADMAP.md](docs/ROADMAP.md)
- 模型底线：[AGENTS.md](AGENTS.md)
- 贡献流程：[CONTRIBUTING.md](CONTRIBUTING.md)

以后派发低阶模型，只需说：`阅读 docs/EXECUTOR_GUIDE.md，执行 Issue #N。`

以后让高阶模型审查，只需说：`阅读 docs/REVIEW_GUIDE.md，开始审查 PR #N。`

## 知识产权说明

本项目是独立学习与工程实践项目，不隶属于、也不代表任何商业桌游品牌。
