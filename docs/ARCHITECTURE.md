# Architecture

## 技术基线

- Node.js 24 LTS
- TypeScript strict mode
- React + Vite 浏览器界面
- Vitest 单元与集成测试
- npm 与提交到仓库的 lockfile

依赖的准确版本将在工程脚手架 Issue 中锁定，并通过自动更新 PR 单独维护。

## 核心原则

规则引擎必须是纯函数、确定性、可序列化、与展示层无关的模块。

```text
UI / CLI / Bot
      |
    Command
      v
Application service
      |
Domain validation -> State transition -> Event[]
      |
  New GameState
```

## 计划目录

```text
src/
├── domain/          # 值对象、状态、命令、事件与纯规则
├── application/     # 命令调度、回放、用例编排
├── infrastructure/  # seed RNG、存储适配与日志
├── ui/              # React 组件和交互适配
└── main.tsx
tests/
├── domain/
├── application/
└── fixtures/
```

依赖方向：`ui -> application -> domain`；`infrastructure` 通过接口注入。`domain` 不得导入其他层。

## 领域接口草案

```ts
type DispatchResult =
  | { ok: true; state: GameState; events: DomainEvent[] }
  | { ok: false; error: RuleViolation };

function dispatch(state: GameState, command: GameCommand): DispatchResult;
```

失败结果不返回部分更新状态。正式类型需在对应 Issue 中审查确认。

## 随机性

- 不允许领域代码直接调用 `Math.random()`。
- 随机源作为端口注入并支持 seed。
- 产生随机结果的事件应记录足够信息用于回放。
- 回放消费已记录结果，不重新抽取随机数。

## 状态与事件

- `GameState` 是当前事实快照。
- `Command` 表示玩家或系统意图。
- `DomainEvent` 表示已发生且可展示、记录的结果。
- 事件需要区分公开信息和私密信息，避免资源手牌泄露。

## 变更规则

以下修改必须先新增 ADR：

- 改变层级或依赖方向
- 改变核心状态或命令处理模型
- 引入服务端、数据库或实时通信
- 替换包管理器、UI 框架或测试框架
- 引入会影响大量模块的第三方状态管理库

