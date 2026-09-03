---
task_id: TASK-005
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-004]
related_issue: null
related_pr: null
---

# TASK-005 — 玩家交易报价与原子结算

## Status

DRAFT

## Goal

实现只由当前玩家发起、其他玩家独立回应、接受时再次校验并原子结算的玩家间资源交易流程。

## Background

实时多人交易会跨多个连接和 revision。报价创建时合法并不代表接受时仍合法，任何“先扣一方再扣另一方”的实现都会产生双花或断线损坏。

## Scope

- 定义 TradeOffer、offerId、发起人、可回应对象、give/want、状态和创建 revision。
- 当前玩家创建、撤销报价；目标玩家接受或拒绝。
- 支持向一个指定玩家或全部对手公开报价；第一笔成功接受使报价关闭。
- 接受时用最新 GameState 校验双方资源和当前 phase。
- 在一次状态转换中交换双方资源。
- 回合结束、强盗/子流程开始、发起人断开后按明确规则关闭/保留报价；MVP 决定断线仅标记 presence，报价仍可由发起人重连后处理，但不可在错误 phase 接受。
- 公开交易内容和状态，但不暴露交易前后手牌明细。
- 对并发接受、重复接受、撤销竞态和过期 revision 写测试。

## Out of Scope

- 私密/秘密交易、聊天、赊账、赠送、未来服务和三角交易。
- 银行/港口交易（TASK-004）。
- WebSocket 并发队列本身（TASK-007）；本任务提供可串行调用的领域命令。
- UI 交易面板。

## Acceptance Criteria

- [ ] AC-1：只有当前玩家在 TURN_ACTIONS 可创建非空双向资源报价。
- [ ] AC-2：不得向自己报价，不得用同资源无意义交换，不得提交负数、零项或超过协议上限的 payload。
- [ ] AC-3：非目标玩家不能接受指定报价；公开报价只允许对手回应。
- [ ] AC-4：接受时重新校验双方资源；不足则拒绝且报价/资源保持一致。
- [ ] AC-5：成功接受在单个状态转换中完成，报价关闭，资源总量守恒。
- [ ] AC-6：同一 offer 的并发或重复接受最多成功一次，其余返回稳定错误。
- [ ] AC-7：回合结束或 phase 离开 TURN_ACTIONS 后所有开放报价失效，不能跨回合接受。
- [ ] AC-8：撤销、拒绝和失效不改变任何资源。
- [ ] AC-9：投影显示交易所需公开信息，但不泄露任一玩家其余手牌。
- [ ] AC-10：场景测试覆盖 3 人和 4 人、公开/定向报价、断线 presence 和过期 revision 语义。

## Architecture Constraints

- 遵守 ARCHITECTURE.md Trading。
- 相关 ADR：ADR-001、ADR-002。
- domain 不感知 Socket；并发通过顺序命令的状态/revision 前置条件模拟。
- 不允许“乐观先改客户端资源再等待补偿”成为事实源。

## Dependencies

- TASK-004 必须 DONE。

## Allowed / Expected Files

- packages/domain/src/rules/player-trade*
- packages/domain/src/model/trade*
- packages/domain/src/projection/**
- packages/protocol/src/trade*
- packages/test-support/**
- 对应测试
- docs/tasks/TASK-005.md 的 Executor 区域

## Planner Notes

- 报价具体资源公开符合线下桌游信息模型；仍不得广播双方完整手牌。
- 若 UX 需要反报价，后续可用“新报价”表达，MVP 不建嵌套协商状态机。

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
