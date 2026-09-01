# Hex Settlers

一个以六角格资源交易桌游为灵感的独立实现，用于验证“高阶模型规划/审查、执行模型按 Issue 编码”的协作流程。

> 当前状态：M0（工程与协作基线）。尚未开始玩法实现。

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

- 产品边界：[docs/PRODUCT.md](docs/PRODUCT.md)
- 规则契约：[docs/GAME_RULES.md](docs/GAME_RULES.md)
- 架构约束：[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 路线图：[docs/ROADMAP.md](docs/ROADMAP.md)
- 模型工作规则：[AGENTS.md](AGENTS.md)
- 贡献流程：[CONTRIBUTING.md](CONTRIBUTING.md)

## 知识产权说明

本项目是独立学习与工程实践项目，不隶属于、也不代表任何商业桌游品牌。

