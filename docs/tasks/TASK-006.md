---
task_id: TASK-006
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-004, TASK-005]
related_issue: null
related_pr: null
---

# TASK-006 — 发展卡、最长道路、最大骑士与终局

## Status

DRAFT

## Goal

完成发展卡全部效果、最长道路与最大骑士奖项、公开/真实胜利分和 10 分终局，使纯领域引擎可以裁决完整基础游戏。

## Background

发展卡引入跨步骤 pendingAction 和私密信息；最长道路需要正确处理环、分叉、边不可复用、对手建筑阻断与并列；胜利判断还必须包含隐藏胜利点但只在本人回合结束游戏。

## Scope

- 建立 25 张发展牌堆的确定组成、洗牌接口和秘密投影。
- 实现骑士、道路建设、丰收、垄断及隐藏胜利点规则。
- 限制每回合 1 张非胜利点发展卡，新购卡当回合不可用；允许掷骰前或行动阶段合法使用。
- 实现自由道路和丰收的显式子流程及提前结束边界。
- 实现最长道路精确算法和奖项转移/并列规则。
- 实现最大骑士计算。
- 实现公开分与真实分，当前玩家在自己的回合达到至少 10 分时立即 FINISHED。
- 终局投影公开胜者和必要得分构成。
- 建立高覆盖场景与性质测试。

## Out of Scope

- 房间、网络、UI、重连或快照。
- 任何扩展或家规发展卡。
- 回放播放器与锦标赛计分。

## Acceptance Criteria

- [ ] AC-1：牌堆恰含 14 骑士、5 胜利点、2 道路建设、2 丰收、2 垄断，并通过注入 RNG 确定洗牌。
- [ ] AC-2：除胜利宣告外每回合最多使用一张发展卡；新购卡当回合不可使用。
- [ ] AC-3：骑士可在掷骰前或行动阶段移动强盗，不触发弃牌，并计入已打出骑士。
- [ ] AC-4：道路建设、丰收、垄断按银行/库存/合法位置正确结算，无可选动作时不会卡死。
- [ ] AC-5：他人投影只看见未使用发展卡数量，不看内容；胜利点在终局前保持私密。
- [ ] AC-6：最长道路对直线、分叉、环、边不可重复、对手建筑阻断和自己建筑不阻断均有测试。
- [ ] AC-7：最长道路至少 5 才授予；同长时现持有人保留；现持有人失格且多人并列最高时无人持有。
- [ ] AC-8：最大骑士至少 3 张已打出才授予，只有严格超过现持有人时转移。
- [ ] AC-9：真实分包含隐藏胜利点；仅轮到该玩家时达到 10 分才结束，结束后任何游戏动作被拒绝。
- [ ] AC-10：聚落、城市、两个奖项和胜利点卡的计分构成无重复且在相关动作后重算。
- [ ] AC-11：纯领域测试可跑完一条从 LOBBY 到 FINISHED 的确定性缩短场景。
- [ ] AC-12：失败的发展卡子流程不丢卡、不部分移动强盗、不部分发资源。

## Architecture Constraints

- 遵守 ARCHITECTURE.md Development Cards、Awards and Victory。
- 相关 ADR：ADR-001、ADR-002。
- 最长道路不得用简单连通边数量替代；算法需有清晰注释和专门 fixture。
- 投影是秘密隔离唯一出口，测试必须比较不同 playerId 的结果。

## Dependencies

- TASK-004、TASK-005 必须 DONE。

## Allowed / Expected Files

- packages/domain/src/rules/development*
- packages/domain/src/rules/awards*
- packages/domain/src/rules/scoring*
- packages/domain/src/rules/victory*
- packages/domain/src/projection/**
- packages/protocol/src/game*
- packages/test-support/**
- 对应测试
- docs/tasks/TASK-006.md 的 Executor 区域

## Planner Notes

- 胜利点卡不受“每回合一张非胜利点卡”限制；服务端可在达到 10 分时直接确认真实分。
- Road Building 最多放两条，棋子不足或没有合法位置时允许安全结束。
- 最长道路算法建议使用边 DFS/回溯；19 hex 规模足够，无需复杂缓存。

## Execution Log

- None.

## Problems

None.

## Test Results

### Automated

- Command: pending
- Result: NOT_RUN
- Notes: Executor 填写。

### Manual / Other Verification

- pending

### Not Run

- pending

## Review

**Reviewer:**  
**Result:** PENDING  
**Reviewed Commit/PR:**  

### Acceptance Review

- [ ] AC-1
- [ ] AC-2
- [ ] AC-3
- [ ] AC-4
- [ ] AC-5
- [ ] AC-6
- [ ] AC-7
- [ ] AC-8
- [ ] AC-9
- [ ] AC-10
- [ ] AC-11
- [ ] AC-12

### Review Notes

- pending

## Final Result

**Final Status:** PENDING  
**Merged PR:**  
**Merge Commit:**  
**Completed At:**  
**Summary:** pending
