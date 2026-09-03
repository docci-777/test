---
task_id: TASK-XXX
status: DRAFT
priority: P1
owner_role: executor
depends_on: []
related_issue: null
related_pr: null
---

# TASK-XXX — <任务标题>

> 创建真实任务时复制本模板为 `docs/tasks/TASK-XXX.md`。TASK ID 一旦使用不要复用。

## Status

`DRAFT`

合法值：`DRAFT | READY | IN_PROGRESS | BLOCKED | REVIEW | CHANGES_REQUESTED | DONE`

> Front matter 与本节 Status 必须保持一致。

## Goal

用一到三句话描述本任务必须实现的结果。

## Background

为什么需要这个任务？关联什么需求、Issue、阶段或前置决策？

## Scope

允许并预期修改的范围：

- ...

## Out of Scope

明确本任务不做：

- ...

## Acceptance Criteria

- [ ] AC-1：...
- [ ] AC-2：...
- [ ] AC-3：...

验收标准应可观察、可验证。

## Architecture Constraints

- 必须遵守 `docs/ARCHITECTURE.md`。
- 相关 ADR：None / `ADR-XXX`。
- 任务特定约束：...

## Dependencies

- None / `TASK-XXX`（必须已满足到何种状态）

## Allowed / Expected Files

用于减少 Executor 搜索空间，但不是替代 Scope：

- `path/...`

## Planner Notes

高阶模型给 Executor 的实现提示、风险说明或已批准选择。不要写未经确认的猜测。

## Execution Log

> Executor 只记录跨模型协作需要的事实，不记录私有思维过程。

- YYYY-MM-DD — ...

## Problems

### P-001 — <问题标题>

**Status:** OPEN / RESOLVED  
**Found by:** Executor / Planner / Reviewer  
**Problem:** ...  
**Impact:** ...  
**Evidence:** ...  
**Options / Recommendation:** ...  
**Decision Required:** YES / NO  
**Decision:** 待高阶模型填写（如需要）

> 没有问题时保留：`None.`

## Test Results

### Automated

- Command: `...`
- Result: PASS / FAIL / NOT_RUN
- Notes: ...

### Manual / Other Verification

- ...

### Not Run

- ...（说明原因）

## Review

**Reviewer:**  
**Result:** PENDING / APPROVED / CHANGES_REQUESTED  
**Reviewed Commit/PR:**  

### Acceptance Review

- [ ] AC-1
- [ ] AC-2
- [ ] AC-3

### Review Notes

- ...

## Final Result

> 仅在 PR 已合并且 Reviewer/Planner 收尾时填写。

**Final Status:** PENDING / DONE / CANCELLED  
**Merged PR:**  
**Merge Commit:**  
**Completed At:**  
**Summary:** ...
