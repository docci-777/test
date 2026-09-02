# 多模型协作入口

> 本文件只负责“把不同角色路由到正确文档”。实时状态、执行规则、审查规则和文档维护已拆分，避免单文件持续膨胀。

## 给低阶执行模型

只需发送：

> 阅读 `docs/EXECUTOR_GUIDE.md`，执行 Issue #N。

执行指南会要求模型继续读取 `docs/STATUS.md`、目标 Issue、`AGENTS.md`、`CONTRIBUTING.md` 以及相关规则/架构文档。

## 给高阶审查模型

只需发送：

> 阅读 `docs/REVIEW_GUIDE.md`，开始审查 PR #N。

审查指南会要求模型核对当前 head、完整 diff、Issue、CI、reviews、线程和相关领域文档，并把结构化结论记录到 PR。

## 给高阶规划 / 状态维护模型

只需发送：

> 阅读 `docs/STATUS.md` 和 `docs/DOC_MAINTENANCE.md`，根据 GitHub 当前事实更新项目状态并规划下一批可派发任务。

## 文档地图

| 文件 | 唯一职责 |
| --- | --- |
| `docs/STATUS.md` | 当前 Issue / PR 状态、依赖、下一步动作 |
| `docs/EXECUTOR_GUIDE.md` | 低阶执行模型工作协议 |
| `docs/REVIEW_GUIDE.md` | 高阶审查模型工作协议 |
| `docs/DOC_MAINTENANCE.md` | 文档职责、状态更新和冲突处理 |
| GitHub Issue | 单任务契约 |
| `AGENTS.md` | 全部代理必须遵守的稳定底线 |
| `CONTRIBUTING.md` | 分支与 PR 通用流程 |
| `docs/PRODUCT.md` | 产品范围 |
| `docs/GAME_RULES.md` | 游戏规则事实 |
| `docs/ARCHITECTURE.md` + ADR | 架构和依赖方向 |
| `docs/ROADMAP.md` | 里程碑级长期方向 |

## 兼容说明

旧提示词“阅读 `docs/TASK_DISPATCH.md` 的执行模型协议 / 高阶模型审查协议”仍会到达本文件，但从现在起应使用上面的新短句。实时状态不再维护在本文件中。
