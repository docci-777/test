---
task_id: TASK-007
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-001, TASK-006]
related_issue: null
related_pr: null
---

# TASK-007 — LAN 房间、会话与权威 WebSocket 命令管线

## Status

DRAFT

## Goal

把完整纯领域引擎封装为可供 3–4 个局域网浏览器使用的房间服务，建立运行时校验、串行命令、revision、commandId 幂等和按玩家投影广播。

## Background

规则引擎必须在网络边界外保持纯净；服务层负责身份、顺序、重试和秘密投影。此任务提供可工作的大厅到游戏命令管线，但把跨重启快照与完整重连故障恢复留给 TASK-009。

## Scope

- 实现创建房间、公开大厅摘要、加入座位、准备/取消准备和开始游戏。
- 房间严格限制 3 或 4 人，昵称、颜色和房间配置由 schema 校验。
- 生成不可预测房间码、playerId 和初始 reconnectToken；令牌只在领取时返回。
- 实现 WebSocket 认证、心跳、连接 presence 和消息大小/频率限制。
- 定义 ClientCommand、Accepted、Rejected、Snapshot、Presence 消息及 protocolVersion。
- 每房间串行处理命令，校验 expectedRevision，并单调增加 revision。
- 相同 playerId + commandId 返回同一已记录结果。
- 使用 domain projection 为每个连接生成不同私密视图。
- 托管 client 构建产物的占位入口和可配置 host/port。
- 为 3/4 连接、并发、非法身份、秘密隔离和房间隔离写集成测试。

## Out of Scope

- React 完整游戏 UI。
- 服务重启恢复、快照文件迁移和长期幂等缓存恢复（TASK-009）。
- 公网 TLS、账号、房间列表、匹配、踢人或观战。
- 自动替断线玩家操作。

## Acceptance Criteria

- [ ] AC-1：可创建 seatCount=3/4 且 mapMode=fixed/random 的房间，其他人数/配置被稳定拒绝。
- [ ] AC-2：恰好所需玩家加入并全部准备后才可开始；开始后不能新占座或改变配置。
- [ ] AC-3：非房主不能开始，重复昵称按明确规则处理，房间码碰撞会重试。
- [ ] AC-4：所有 WebSocket 入站消息经 protocol schema 验证，未知版本/type/超限 payload 不进入 domain。
- [ ] AC-5：每房间命令严格串行；expectedRevision 过期返回 STALE_REVISION 和当前 revision。
- [ ] AC-6：同一 commandId 重试不重复应用，返回与首次一致的可见结果。
- [ ] AC-7：三个和四个独立连接可执行领域命令并获得一致公开 revision。
- [ ] AC-8：每个连接只收到自己的资源/发展卡明细；自动化测试扫描序列化响应确认不含他人秘密和令牌。
- [ ] AC-9：不同房间的身份、事件和命令完全隔离。
- [ ] AC-10：断开连接只改变 presence，不移除座位、跳过回合或改变资源。
- [ ] AC-11：服务可绑定配置的 0.0.0.0 和端口；启动日志显示可用 host/port 且不打印秘密。
- [ ] AC-12：普通非法动作返回稳定领域错误而非 500，未知异常不泄露堆栈给客户端。

## Architecture Constraints

- 遵守 ARCHITECTURE.md Command and Event Contract、Player View Projection。
- 相关 ADR：ADR-001、ADR-002。
- apps/server 不得直接修改 GameState；只能调用 domain 命令处理器。
- WebSocket 广播前必须按 playerId 单独投影，不得先序列化完整状态。
- 初始令牌只存摘要；具体重连恢复和持久化由 TASK-009 完成。

## Dependencies

- TASK-001、TASK-006 必须 DONE。

## Allowed / Expected Files

- apps/server/src/http/**
- apps/server/src/ws/**
- apps/server/src/rooms/**
- apps/server/src/session/**
- packages/protocol/**
- packages/domain/src/projection/**
- packages/test-support/**
- 对应集成测试
- docs/tasks/TASK-007.md 的 Executor 区域

## Planner Notes

- HTTP 加入响应包含 reconnectToken 时要设置 no-store，并禁止结构化日志自动记录 body。
- 房间服务应依赖 SnapshotStore 接口；本任务可用内存实现，TASK-009 替换为文件适配器。
- Presence 事件是否增加游戏 revision 必须在 protocol 固定；推荐独立 presenceSequence，避免连接抖动造成规则 revision 变化。

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
