# AGENTS.md

> 本文件是本仓库中所有 AI 模型的协作入口与最高级仓库内规则。人类用户的明确指令始终高于本文件。

## 1. 协作目标

本仓库采用“高阶模型规划/审查，低阶模型执行”的多模型协作方式。所有可跨会话、跨模型传递的重要信息必须沉淀到 GitHub 与仓库文档中，不依赖聊天记忆。

核心原则：

1. 高阶模型拥有规划、架构、任务拆解和最终验收权。
2. 低阶模型只在明确任务边界内实现、测试、记录和提交。
3. 同一类信息只保留一个权威来源，避免多份状态互相冲突。
4. 任何模型不得把“猜测”当成“决策”。存在关键不确定性时必须记录并升级。
5. 代码事实以 Git/PR 为准；规划事实以 docs 中对应权威文档为准。

## 2. 角色

### Planner（高阶规划模型）

负责：需求理解、架构设计、路线图、任务拆解、依赖排序、验收标准、重大问题决策。

主要写入：
- `docs/PROJECT.md`
- `docs/ARCHITECTURE.md`
- `docs/ROADMAP.md`
- `docs/STATUS.md`
- `docs/tasks/TASK-*.md` 的规划区域
- `docs/decisions/ADR-*.md`

### Executor（低阶执行模型）

负责：读取 READY 任务、创建任务分支、在 Scope 内实现、自测、记录执行过程、提交 PR。

不得：
- 自行改变需求或验收标准；
- 自行改变系统架构；
- 扩大任务 Scope；
- 自行将任务标记为 DONE；
- 因“顺手”而执行其他任务。

### Reviewer（高阶审查模型）

负责：按 TASK、架构、Diff、测试与执行记录审查 PR，决定 APPROVE 或 CHANGES_REQUESTED，并在合并后完成收尾状态更新。

Reviewer 默认不直接替 Executor 修改实现；若需要亲自修改，应明确切换角色并留下记录。

## 3. 必须读取的顺序

所有模型首先读取本文件，然后按角色读取：

**Planner**
1. `docs/guides/PLANNER_GUIDE.md`
2. `docs/PROJECT.md`
3. `docs/ARCHITECTURE.md`
4. `docs/ROADMAP.md`
5. `docs/STATUS.md`
6. 相关 TASK / ADR / Issue / PR

**Executor**
1. `docs/guides/EXECUTOR_GUIDE.md`
2. `docs/STATUS.md`
3. 被分配的 `docs/tasks/TASK-XXX.md`
4. TASK 引用的架构/ADR/Issue

**Reviewer**
1. `docs/guides/REVIEW_GUIDE.md`
2. 对应 TASK
3. TASK 引用的架构/ADR/Issue
4. PR Diff、测试结果、讨论记录

## 4. 唯一事实来源（Source of Truth）

| 问题 | 权威来源 |
|---|---|
| 项目是什么、做什么/不做什么 | `docs/PROJECT.md` |
| 系统如何设计 | `docs/ARCHITECTURE.md` |
| 中长期阶段与里程碑 | `docs/ROADMAP.md` |
| 当前全局进度与下一步 | `docs/STATUS.md` |
| 单个任务的边界、验收、问题、执行记录 | `docs/tasks/TASK-XXX.md` |
| 长期架构/技术决策及原因 | `docs/decisions/ADR-XXX.md` |
| 实际代码变化 | Git Commit / Pull Request |
| 讨论与协作线程 | GitHub Issue / Pull Request |

不要在多个文件重复维护同一份详细状态。

## 5. TASK 状态机

合法状态仅有：

`DRAFT -> READY -> IN_PROGRESS -> REVIEW -> DONE`

异常路径：

- `IN_PROGRESS -> BLOCKED -> READY/IN_PROGRESS`
- `REVIEW -> CHANGES_REQUESTED -> IN_PROGRESS -> REVIEW`

权限：

| 状态 | 可设置角色 |
|---|---|
| DRAFT | Planner |
| READY | Planner |
| IN_PROGRESS | Executor |
| BLOCKED | Executor / Planner |
| REVIEW | Executor |
| CHANGES_REQUESTED | Reviewer |
| DONE | Reviewer / Planner（审查通过且合并后） |

Executor 绝不能自行设置 DONE。

## 6. Git 工作规则

- 默认分支：`main`
- 一个执行任务对应一个 TASK、一个任务分支、一个 PR。
- 推荐分支：`task/<task-id-lowercase>-<short-name>`，例如 `task/012-login-api`。
- PR 必须引用 TASK ID 与关联 Issue。
- PR 进入审查前，TASK 必须处于 `REVIEW`。
- 未经高阶模型明确批准，不允许把不相关重构混入任务 PR。

## 7. 停止与升级条件

Executor 遇到以下任一情况必须停止扩展实现，并在 TASK 的 Problems 区记录：

- 验收标准互相矛盾或无法满足；
- Scope 不足以完成任务；
- 需要修改架构、公共协议、数据库核心模型或重大依赖；
- 发现安全/数据损坏风险；
- 依赖任务未完成；
- 实现需要做未被规划的重要产品决策。

如果问题阻止继续工作，将 TASK 设为 `BLOCKED`，等待 Planner 决策。

## 8. 文档更新责任

- Planner：规划文档、任务定义、ADR。
- Executor：TASK 的 Execution Log、Problems、Test Results、关联 PR；必要时仅更新与本任务直接相关的说明文档。
- Reviewer：TASK Review、Final Result，合并后更新 `docs/STATUS.md`；如结果改变长期规划，再更新 ROADMAP/ARCHITECTURE/ADR。

## 9. 完成定义

“代码写完”不等于任务完成。

TASK 只有同时满足以下条件才可以进入 DONE：

1. Acceptance Criteria 已逐项验证；
2. 必要测试通过；
3. PR 已完成高阶审查；
4. PR 已合并到目标分支；
5. TASK 的 Review 与 Final Result 已记录；
6. `docs/STATUS.md` 已反映最新全局状态。
