---
task_id: TASK-010
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-003, TASK-004, TASK-005, TASK-006, TASK-007, TASK-008, TASK-009]
related_issue: null
related_pr: null
---

# TASK-010 — 3/4 玩家端到端规则回归与故障验收

## Status

DRAFT

## Goal

建立可重复的多浏览器端到端验收和局域网真机检查，证明核心规则从大厅到终局可用，并在断线、重复、乱序和秘密隔离场景下保持一致。

## Background

单元测试不能证明 UI、协议、房间与恢复组合正确。本任务不新增产品功能，专注把 PROJECT Success Criteria 转化为自动化和手工证据。

## Scope

- 建立 Playwright 多 browser context 测试工具，每个 context 有独立身份存储。
- 覆盖 3 人固定地图完整关键路径和 4 人随机地图关键路径。
- 通过测试专用种子/场景入口缩短长局，但入口仅在测试环境可用且不能绕过生产命令校验。
- 覆盖初始放置、生产、7 点弃牌/强盗、三类交易、三类建造、五类发展卡、两大奖项和终局。
- 覆盖刷新、断网、响应丢失、重复 commandId、过期 revision、服务重启。
- 自动比较所有玩家公开视图 revision 和板面一致性。
- 扫描网络响应/日志，验证秘密和令牌不泄露。
- 编写两台以上真实设备的 LAN 手工验收表并执行记录。
- 汇总缺陷；阻断缺陷建立后续 TASK，不在本任务顺手扩大实现。

## Out of Scope

- 新规则、新 UI 主题或大规模重构。
- 互联网跨地域测试、性能压测或安全渗透测试。
- 伪造官方认证或与官方客户端对比截图。

## Acceptance Criteria

- [ ] AC-1：3 人固定地图场景从创建房间到 10 分终局全自动通过。
- [ ] AC-2：4 人带种子随机地图场景验证所有客户端地图一致并覆盖至少一个完整轮次和终局路径。
- [ ] AC-3：自动化覆盖资源生产/短缺、7 点、强盗、银行/港口/玩家交易、建造、全部发展卡、最长道路、最大骑士。
- [ ] AC-4：至少对非法越权、错误 phase、资源不足、非法位置、过期 revision 逐类断言状态不变。
- [ ] AC-5：刷新、Socket 中断、丢响应重试和服务重启后能继续，三个高价值动作无重复应用。
- [ ] AC-6：跨玩家响应扫描不发现他人资源明细、未用发展卡、牌堆顺序或 reconnectToken。
- [ ] AC-7：测试环境的场景加速入口在 production build 不存在或不可访问，并有断言。
- [ ] AC-8：真机验收至少包含主机 + 两台不同局域网设备，3 人加入和稳定操作通过。
- [ ] AC-9：测试失败保留无秘密的截图、trace 和日志，CI 可重复运行且无明显 flaky 重试依赖。
- [ ] AC-10：PROJECT Success Criteria 建立逐项证据链接；未满足项明确阻塞后续发布任务。
- [ ] AC-11：规则边界 fixture 与官方公开基础规则/FAQ 的事实性摘要无已知 P0/P1 偏差。
- [ ] AC-12：发现的 P0/P1 不在本任务掩盖或降低等级，必须 BLOCKED 并交 Planner 拆修复任务。

## Architecture Constraints

- 相关 ADR：ADR-001、ADR-002、ADR-003。
- 测试只能通过公开 UI/协议或明确 test adapter，禁止直接修改生产房间内存。
- 测试产物不得记录真实令牌/完整秘密；使用测试值也要脱敏。
- 规则参考只链接，不复制大段官方规则文字或图片。

## Dependencies

- TASK-003 至 TASK-009 必须 DONE。

## Allowed / Expected Files

- tests/e2e/**
- packages/test-support/**
- 测试配置与 CI 的必要调整
- docs/qa/**（若创建）
- docs/tasks/TASK-010.md 的 Executor 区域
- 仅限修正测试可观察性的最小生产改动；任何业务修复先记录问题并由 Planner 决定

## Planner Notes

- “完整关键路径”可用受控场景缩短，但至少保留一条正常大厅和开局流程。
- 真机测试需要记录主机系统、浏览器、网络拓扑和结果，不记录私人 IP 的可识别信息。
- 最长道路 fixture 必须含分叉、环和对手聚落切断。

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
