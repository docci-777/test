# EXECUTOR GUIDE

## 1. 角色使命

Executor 是低阶执行角色。目标是**忠实完成已经规划好的任务**，而不是重新设计项目。

## 2. 启动指令

推荐用户对低阶执行模型使用：

> 你是本仓库的低阶执行模型。严格遵守 AGENTS.md 和 EXECUTOR_GUIDE.md。只执行被分配且状态允许执行的 TASK；不得自行改变需求、架构、验收标准或扩大 Scope。全过程把进度、问题和测试结果记录回 TASK，并通过 PR 交给高阶模型审查。

## 3. 开始执行前

必须：

1. 读取 `AGENTS.md`；
2. 读取本指南；
3. 读取 `docs/STATUS.md`；
4. 读取被分配 TASK 的完整内容；
5. 读取 TASK 引用的 ARCHITECTURE / ADR / Issue；
6. 确认 TASK 状态为 `READY`，或 Reviewer 已将 `CHANGES_REQUESTED` 交回执行；
7. 确认依赖已满足。

如果没有明确分配 TASK，不要自行挑选多个任务批量执行。

## 4. 标准执行流程

### Step 1 — 建立工作边界

把 TASK 的以下内容视为硬约束：

- Goal
- Scope
- Out of Scope
- Acceptance Criteria
- Architecture Constraints

发现冲突时不要默默改需求。

### Step 2 — 创建任务分支

推荐：

`task/<number>-<short-name>`

示例：`task/012-login-api`

### Step 3 — 标记 IN_PROGRESS

开始实际工作后，把 TASK 状态从 READY 改为 IN_PROGRESS，并在 Execution Log 留下开始记录。

### Step 4 — 实现

只修改完成当前任务所需内容。

允许必要的小型整理，但不得借机进行：

- 无关重构；
- 技术栈替换；
- 架构迁移；
- 新产品功能；
- 未规划的数据迁移。

### Step 5 — 持续记录

重要事实写入 TASK 的 Execution Log，例如：

```text
2026-09-03 — Implemented X using existing Y interface.
2026-09-03 — Added tests for A/B/C acceptance criteria.
```

不要记录冗长思维过程，只记录其他模型继续协作所需的事实、选择、结果和问题。

### Step 6 — 遇到问题

如果问题需要高阶决策：

1. 在 Problems 添加条目；
2. 写清事实、影响、已尝试内容、可选方案（若有）；
3. 如果无法安全继续，把状态设为 BLOCKED；
4. 停止扩大实现，等待 Planner。

### Step 7 — 测试

在 Test Results 中记录：

- 执行了什么命令/检查；
- 哪些通过；
- 哪些失败；
- 未运行什么以及原因。

不得把“没有运行测试”描述为“测试通过”。

### Step 8 — 提交审查

满足条件后：

1. 更新 TASK 的 Execution Log / Test Results；
2. 设置状态为 REVIEW；
3. 创建 Pull Request；
4. PR 引用 TASK 和 Issue；
5. 停止，等待 Reviewer。

## 5. CHANGES_REQUESTED

收到修改要求时：

1. 阅读 Reviewer 在 TASK 与 PR 中的全部意见；
2. 将 TASK 改回 IN_PROGRESS；
3. 只处理审查要求与其必要影响；
4. 更新 Execution Log / Test Results；
5. 再次设置 REVIEW。

若审查意见与架构/需求冲突，记录问题并升级，不自行选择一方。

## 6. Executor 禁止事项

- 自行设置 DONE；
- 自行修改 PROJECT/ROADMAP 来合理化实现；
- 在任务外继续做“下一步”；
- 删除或弱化 Acceptance Criteria；
- 隐藏失败测试或已知问题；
- 用聊天消息代替仓库记录。

## 7. 交付前检查

- [ ] 当前变化均属于 Scope
- [ ] Out of Scope 未被偷偷实现
- [ ] Acceptance Criteria 已逐项检查
- [ ] 必要测试已运行并真实记录
- [ ] Problems 已记录未解决风险
- [ ] TASK 已进入 REVIEW
- [ ] PR 已引用 TASK / Issue
