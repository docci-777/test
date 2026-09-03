---
task_id: TASK-008
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-006, TASK-007]
related_issue: null
related_pr: null
---

# TASK-008 — 原创大厅、棋盘与完整行动客户端

## Status

DRAFT

## Goal

实现供 3–4 位玩家实际操作完整基础游戏的浏览器 UI：大厅、SVG 棋盘、私密手牌、交易、建造、弃牌、强盗、发展卡、奖项和终局；所有裁决来自服务端投影与 allowedActions。

## Background

客户端是交互层而非规则裁判。它必须清楚展示当前 phase、待谁行动和失败原因，同时保护屏幕上的私密信息，避免重复提交。

## Scope

- 创建/加入房间、昵称、3/4 人、固定/随机地图选择和准备大厅。
- 使用原创 SVG/CSS 绘制六角地形、数字、顶点、边、港口、建筑和强盗。
- 展示回合、phase、骰子、玩家资源总数、本人资源明细、发展卡、奖项和得分。
- 实现初始放置、掷骰、弃牌、移动强盗、选择偷取目标。
- 实现银行/港口交易、玩家报价/回应、道路/聚落/城市/发展卡购买。
- 实现各发展卡子流程、结束回合和终局页。
- 只依据服务端 allowedActions/稳定错误决定可用操作，pending 时阻止同命令重复提交。
- 显示连接状态和可恢复错误；重连机制细节在 TASK-009。
- 键盘可达、文本提示、颜色外编码和基本响应式桌面布局。
- 仅使用 ADR-003 允许的原创占位视觉。

## Out of Scope

- 客户端本地裁决、离线模式或作弊调试面板。
- 官方 Logo、地形/卡牌图像、规则书图示或近似版式。
- 复杂动画、3D、音效、手机原生体验。
- 持久化/重连协议实现（TASK-009），但 UI 需保留连接状态接口。

## Acceptance Criteria

- [ ] AC-1：3/4 个浏览器可完成创建、加入、准备和开始流程，错误原因可理解。
- [ ] AC-2：固定和随机地图的 19 hex、数字、港口、道路/顶点命中区域与服务端稳定 ID 一致。
- [ ] AC-3：当前 phase、当前玩家、必须先完成的 pendingAction 和允许动作始终清晰。
- [ ] AC-4：初始放置、骰子/生产、弃牌/强盗、三类交易、三类建造、发展卡和结束回合均有完整交互。
- [ ] AC-5：本人能看到资源与发展卡明细；他人只显示数量；终局前不显示他人隐藏胜利点。
- [ ] AC-6：提交命令期间防重复，Rejected 后回滚本地 pending 并按最新 snapshot/revision 恢复。
- [ ] AC-7：客户端代码不重新实现成本、距离、最长道路或胜利判断；可用性来自 allowedActions，最终以拒绝响应为准。
- [ ] AC-8：棋盘缩放后仍可操作；键盘可到达关键按钮；玩家/资源不用颜色作为唯一标识。
- [ ] AC-9：所有视觉是原创 CSS、SVG 基元、文本或已登记许可资产，无官方素材。
- [ ] AC-10：组件/交互测试覆盖至少每类 pendingAction、交易接受竞态的 UI 反馈和终局。
- [ ] AC-11：敏感 token 不显示在页面、URL、错误提示或普通日志。
- [ ] AC-12：界面明确标注临时代号/非官方性质，不作授权暗示。

## Architecture Constraints

- 遵守 ARCHITECTURE.md client 边界和 ADR-003。
- 相关 ADR：ADR-001、ADR-002、ADR-003。
- apps/client 只能依赖 protocol 的公开类型/schema，不直接导入 domain engine。
- 视觉坐标映射可在 client；稳定实体 ID 必须来自 BoardView。
- 不引入大型 UI/状态库，除非 TASK Problems 证明必要并获 Planner 批准。

## Dependencies

- TASK-006、TASK-007 必须 DONE。

## Allowed / Expected Files

- apps/client/**
- packages/protocol 的客户端投影/allowedActions 修正
- assets/original/**
- 对应组件与交互测试
- docs/tasks/TASK-008.md 的 Executor 区域

## Planner Notes

- 地形可用原创几何纹理和中性符号；不需要绘制“像官方一样”的插画。
- 私密面板默认避免旁观者友好不是安全边界，但可提供点击遮挡作为后续增强，不阻塞 MVP。
- 错误文案应映射稳定 errorCode，不解析服务端自由文本。

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
