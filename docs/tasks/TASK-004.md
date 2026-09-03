---
task_id: TASK-004
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-003]
related_issue: null
related_pr: null
---

# TASK-004 — 建造、库存与银行/港口交易

## Status

DRAFT

## Goal

在 TURN_ACTIONS 中实现道路、聚落、城市、发展卡购买的成本与库存事务，以及 4:1、3:1、2:1 银行/港口交易。

## Background

建造会同时改变资源、棋子库存、地图和计分，是最容易发生部分提交的领域。港口交易还依赖建筑占据的港口顶点，必须由服务端从棋盘状态推导比例。

## Scope

- 定义构建成本和玩家棋子库存。
- 实现付费道路、聚落、城市升级和购买发展卡入口。
- 实现道路连接、对手建筑阻断、聚落距离/连通和城市升级合法性。
- 原子扣除资源、放置/升级棋子并更新库存。
- 实现银行 4:1、通用港 3:1、对应专港 2:1 的最优合法比例。
- 允许行动阶段在交易与建造之间自由交错。
- 牌堆抽取接口由服务端 RNG/预洗牌顺序控制；卡牌效果留给 TASK-006。
- 为资源不足、库存耗尽、占位冲突和港口边界写测试。

## Out of Scope

- 玩家间报价/接受流程。
- 发展卡使用、最长道路、最大骑士和最终胜利。
- UI、房间、网络和快照。
- 严格分开的“先交易后建造”旧式变体。

## Acceptance Criteria

- [ ] AC-1：道路、聚落、城市、发展卡成本与 ARCHITECTURE.md 一致且只有一个定义来源。
- [ ] AC-2：道路只能连接自己的网络且不能穿过对手建筑继续；重复占用被拒绝。
- [ ] AC-3：常规聚落必须连接自己的道路并满足相邻顶点空置的距离规则。
- [ ] AC-4：城市只能升级自己的聚落，升级后聚落棋子归还、城市库存减少。
- [ ] AC-5：玩家不能超过 15 道路、5 聚落、4 城市，库存耗尽返回稳定错误。
- [ ] AC-6：银行交易从当前建筑推导最优比例，仅在支付和银行库存都足够时原子完成。
- [ ] AC-7：港口在建成聚落/城市后立即可用于后续交易；强盗不禁用港口。
- [ ] AC-8：发展牌堆空或资源不足时购买不改变资源；成功购买的卡仅进入本人秘密状态。
- [ ] AC-9：任一失败动作对资源、银行、地图、库存、牌堆和 revision 均无部分影响。
- [ ] AC-10：测试覆盖分叉网络、被对手建筑阻断后的扩路、海岸无港口和多港口取优。

## Architecture Constraints

- 遵守 ARCHITECTURE.md Building、Trading、Development Cards。
- 相关 ADR：ADR-001、ADR-002。
- 成本、库存和合法性属于 domain；客户端 allowedActions 只作提示。
- 不在本任务实现奖项缓存；每次相关动作预留统一重算钩子供 TASK-006 使用。

## Dependencies

- TASK-003 必须 DONE。

## Allowed / Expected Files

- packages/domain/src/rules/build*
- packages/domain/src/rules/maritime-trade*
- packages/domain/src/model/inventory*
- packages/domain/src/model/development*
- packages/domain/src/projection/**
- packages/protocol/src/commands*
- packages/test-support/**
- 对应测试
- docs/tasks/TASK-004.md 的 Executor 区域

## Planner Notes

- 购买发展卡时需记录 acquiredTurn，供 TASK-006 阻止当回合使用。
- 银行资源是有限实体，交易和购买必须同时更新双方库存。
- 不要为了最长道路提前实现近似算法。

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
