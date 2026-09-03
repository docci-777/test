---
task_id: TASK-003
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-002]
related_issue: null
related_pr: null
---

# TASK-003 — 初始放置、回合、资源生产与强盗流程

## Status

DRAFT

## Goal

实现纯领域 GameState 与命令状态机，覆盖 3/4 人开局、蛇形初始放置、回合推进、服务端骰子、资源生产、7 点弃牌、强盗移动和随机偷取。

## Background

这是规则引擎的主干。后续建造、交易和发展卡必须接入同一 phase/pendingAction 机制，不能另建隐式流程。

## Scope

- 定义 GameState、PlayerState、Bank、TurnState、phase、pendingAction 和稳定领域错误。
- 建立 3/4 人开局及服务端决定首位玩家/座次的接口。
- 实现 SETUP_FORWARD/SETUP_REVERSE 聚落与相邻道路命令。
- 第二聚落结算起始资源。
- 实现开始回合、掷两个骰子、非 7 生产与银行短缺。
- 实现多玩家私密弃牌提交、全部完成屏障、强盗移动、目标选择与随机偷取。
- 实现结束回合和下位玩家推进。
- 输出去秘密的领域事件，并建立玩家视图投影基础。
- 为所有状态跳转、非法命令与随机路径编写场景测试。

## Out of Scope

- 常规建造、银行/港口交易、玩家交易。
- 发展卡、最长道路、最大骑士和终局。
- WebSocket、快照文件、React UI。
- 超时自动弃牌、自动托管或踢人。

## Acceptance Criteria

- [ ] AC-1：3 人和 4 人的初始放置顺序分别严格执行正序/反序，轮到者和合法下一动作可观察。
- [ ] AC-2：初始聚落遵守距离规则，初始道路必须连接刚放聚落；第二聚落按相邻地形发起始资源。
- [ ] AC-3：只有当前玩家在正确 phase 可掷骰且每回合至多一次，两个骰值由注入 RNG 产生。
- [ ] AC-4：聚落/城市生产倍率、强盗阻断和每资源独立银行短缺规则有边界测试。
- [ ] AC-5：掷 7 后所有手牌大于 7 的玩家精确弃 floor(n/2)，未完成前其他动作均被拒绝。
- [ ] AC-6：强盗不能留在原 hex；目标必须邻接且有资源；偷取种类由服务端 RNG 决定。
- [ ] AC-7：无合法偷取目标时流程可继续，且掷 7 处理完后回到当前玩家行动阶段。
- [ ] AC-8：非当前玩家、错误 phase、资源声明不实或非法位置命令返回稳定错误且状态/revision 不变。
- [ ] AC-9：公开事件/他人投影不泄露弃牌种类、被偷具体资源或完整手牌；本人投影正确。
- [ ] AC-10：给定状态、命令与 RNG 序列可完全重放到相同状态和事件。

## Architecture Constraints

- 遵守 ARCHITECTURE.md Core Rule Invariants。
- 相关 ADR：ADR-001、ADR-002。
- 状态转换必须纯且原子；禁止在 domain 读取系统时间、Socket 或文件。
- 错误返回不得包含部分修改后的状态。

## Dependencies

- TASK-002 必须 DONE。

## Allowed / Expected Files

- packages/domain/src/game/**
- packages/domain/src/rules/setup*
- packages/domain/src/rules/turn*
- packages/domain/src/rules/production*
- packages/domain/src/rules/robber*
- packages/domain/src/projection/**
- packages/protocol/src/game*
- packages/test-support/**
- 对应测试
- docs/tasks/TASK-003.md 的 Executor 区域

## Planner Notes

- pendingAction 应能表达“哪些玩家仍需弃牌”以及只有本人能看到的所需数量。
- revision 的网络语义在 TASK-007；domain 可先返回新状态与事件，不直接管理连接。
- 建造库存可先建模，但常规扣费与动作留给 TASK-004。

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

### Review Notes

- pending

## Final Result

**Final Status:** PENDING  
**Merged PR:**  
**Merge Commit:**  
**Completed At:**  
**Summary:** pending
