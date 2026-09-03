---
task_id: TASK-002
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-001]
related_issue: null
related_pr: null
---

# TASK-002 — 棋盘拓扑、固定地图与确定性随机地图

## Status

DRAFT

> TASK-001 进入 DONE 后由 Planner 提升为 READY。

## Goal

在纯 domain 包中建立规范化六角棋盘拓扑、原创固定地图数据和带种子的随机地图生成器，为全部建造、强盗、港口和最长道路规则提供唯一坐标事实。

## Background

地图和稳定 vertex/edge ID 是规则、协议、UI 的共同基础。若各层独立推导，容易出现点击位置与服务端位置不一致。随机地图还必须可重放并满足高概率数字不相邻等约束。

## Scope

- 定义 Hex、Vertex、Edge、Port 的稳定 ID、邻接与序列化模型。
- 生成 19 陆地六角的规范化拓扑。
- 实现一份仓库内原创数据表示的固定平衡地图。
- 实现带 algorithmVersion 和 seed 的随机资源、数字、沙漠和港口布局。
- 维持规定组件数量；沙漠无数字；6/8 不相邻。
- 强盗初始位置由沙漠派生。
- 提供地图验证器和确定性测试。
- 提供 domain 到 protocol 可公开 BoardView 的最小映射，不做 UI 绘制。
- 建立场景构造器，后续测试可按稳定 ID 指定位置。

## Out of Scope

- 玩家、回合、资源发放、建造动作和最长道路计算。
- 房间、网络、React 棋盘或动画。
- 复制官方固定地图截图、坐标或美术。
- 任意扩展地图、5–6 人地图或自定义编辑器。

## Acceptance Criteria

- [ ] AC-1：生成的棋盘恰有 19 个陆地 hex，地形计数符合 ARCHITECTURE.md。
- [ ] AC-2：数字与港口计数正确，沙漠无数字，强盗位于沙漠。
- [ ] AC-3：每条 edge 恰连接两个 vertex；邻接关系双向一致；所有 ID 在序列化后稳定。
- [ ] AC-4：固定地图在多次运行和序列化往返后完全相同。
- [ ] AC-5：同 rulesetVersion、algorithmVersion、seed 始终生成同一地图；不同种子集合能产生不同合法布局。
- [ ] AC-6：至少 100 个固定测试种子均通过组件数量、唯一性、连通性和 6/8 不相邻验证。
- [ ] AC-7：非法/不可能布局由地图验证器返回稳定错误，不进入游戏状态。
- [ ] AC-8：BoardView 不包含 RNG 内部状态或未来秘密。
- [ ] AC-9：所有地图资产为数据、SVG 基元或原创占位，不含官方图像。

## Architecture Constraints

- 遵守 docs/ARCHITECTURE.md 的 Board and Map Invariants。
- 相关 ADR：ADR-001、ADR-002、ADR-003。
- RNG 必须注入；禁止直接在规则函数内调用 Math.random。
- algorithmVersion 是持久化兼容性的一部分，改变生成结果需 Planner 审批。

## Dependencies

- TASK-001 必须 DONE。

## Allowed / Expected Files

- packages/domain/src/board/**
- packages/domain/src/map/**
- packages/protocol/src/board*
- packages/test-support/**
- 对应测试文件
- docs/tasks/TASK-002.md 的 Executor 区域

## Planner Notes

- UI 屏幕坐标不属于 domain；domain 只保存拓扑坐标和稳定 ID。
- 固定地图可使用人工编写的原创排列，但必须由同一个验证器检查。
- 不追求“绝对公平”的随机地图优化；MVP 只执行已写明约束。

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

### Review Notes

- pending

## Final Result

**Final Status:** PENDING  
**Merged PR:**  
**Merge Commit:**  
**Completed At:**  
**Summary:** pending
