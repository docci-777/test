# Hex Settlers

一个以六角格资源交易桌游为灵感的独立实现，用于验证“高阶模型规划/审查、低阶模型按任务契约执行”的协作流程。

> **统一协作入口：[docs/CHECKLIST.md](docs/CHECKLIST.md)**

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

## 协作方式

以后无论给高阶模型还是低阶模型，都只需发送同一句：

> **根据 `docs/CHECKLIST.md` 执行。**

模型必须自行核对 GitHub 当前状态、识别自己的角色、从清单中选择最靠前且可执行的工作项，并自动确定对应 Issue、PR 和分支；不再要求用户手工指定 Issue 或 PR 编号。

其他文件均是清单按需引用的稳定资料：

- 产品边界：[docs/PRODUCT.md](docs/PRODUCT.md)
- 规则契约：[docs/GAME_RULES.md](docs/GAME_RULES.md)
- 架构约束：[docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
- 路线图：[docs/ROADMAP.md](docs/ROADMAP.md)
- 模型底线：[AGENTS.md](AGENTS.md)
- 贡献流程：[CONTRIBUTING.md](CONTRIBUTING.md)

## 知识产权说明

本项目是独立学习与工程实践项目，不隶属于、也不代表任何商业桌游品牌。
