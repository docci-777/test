---
task_id: TASK-009
status: DRAFT
priority: P0
owner_role: executor
depends_on: [TASK-007, TASK-008]
related_issue: null
related_pr: null
---

# TASK-009 — 断线重连、幂等追平与版本化本地快照

## Status

DRAFT

## Goal

让页面刷新、短时网络中断、Socket 重连和服务进程重启都能恢复同一玩家座位与一致游戏状态，且任何重试不会重复应用动作。

## Background

局域网无线连接常有瞬断。恢复设计必须同时处理身份、私密投影、revision、客户端未确认命令和服务器落盘顺序；只“自动重连 Socket”不足以保证正确。

## Scope

- 客户端安全保存 roomCode、playerId、reconnectToken；提供清除/失效处理。
- WebSocket 断开后的退避重连、认证和完整 Snapshot 追平。
- 新连接成功后替换同一玩家旧连接，旧连接不再可发命令。
- 未确认命令以同 commandId 有界重试；服务端幂等缓存可随快照恢复。
- 实现带 schemaVersion/rulesetVersion/protocolVersion 的文件 SnapshotStore。
- 每个成功规则状态变化按 ADR-001 明确 durability 顺序原子写入。
- 服务启动恢复未结束房间，校验 snapshot；损坏/不兼容文件隔离并给出日志。
- 数据目录、权限、秘密日志脱敏和清理接口。
- 故障注入测试覆盖断开时提交、响应丢失、重复认证、写盘失败和重启。

## Out of Scope

- 多主机高可用、云同步、跨设备转移令牌。
- 忘记令牌后的人工找回或管理员改座。
- 自动行动、回合超时、机器人接管。
- 长期赛事历史、完整回放和数据库迁移。

## Acceptance Criteria

- [ ] AC-1：同一浏览器刷新后自动恢复原 playerId、座位、私密手牌、phase 和最新 revision。
- [ ] AC-2：断网后 UI 显示离线且禁止新动作；恢复后先应用 Snapshot 再重新启用 allowedActions。
- [ ] AC-3：同身份新连接替换旧连接，旧 Socket 的后续命令被拒绝。
- [ ] AC-4：响应丢失后重发相同 commandId 至多应用一次，并返回与首次一致结果。
- [ ] AC-5：STALE_REVISION 触发有界追平，不进入无限重试或覆盖服务端状态。
- [ ] AC-6：服务进程重启后能恢复未结束房间、全部秘密、幂等记录和当前回合；玩家原令牌仍可重连。
- [ ] AC-7：快照写入使用临时文件 + 原子替换；写入失败时命令按文档化策略不广播未持久状态。
- [ ] AC-8：损坏或版本不兼容快照不会使整个服务崩溃，不会被静默当作新房间覆盖。
- [ ] AC-9：data/ 不被 Git 跟踪，令牌原文不进入快照、URL、普通日志或测试快照。
- [ ] AC-10：3/4 玩家中任意一人掉线不会自动结束、跳过或改变其他玩家游戏数据。
- [ ] AC-11：集成测试覆盖掷骰、交易接受和建造三个动作在响应丢失下的幂等性。
- [ ] AC-12：并发文件写入按房间隔离，两个房间互不阻塞到产生可观察错误。

## Architecture Constraints

- 遵守 ARCHITECTURE.md Reconnection and Persistence。
- 相关 ADR：ADR-001、ADR-002。
- 快照存储是 server adapter，不进入 domain。
- 令牌用安全随机生成、仅存摘要；浏览器存储风险在 README 明确。
- schema 迁移若超出“当前版本读取”需新 ADR，不得静默丢字段。

## Dependencies

- TASK-007、TASK-008 必须 DONE。

## Allowed / Expected Files

- apps/server/src/session/**
- apps/server/src/snapshot/**
- apps/server/src/rooms/**
- apps/client/src/connection/**
- packages/protocol/**
- packages/test-support/**
- data/.gitkeep（仅当确有必要；不得提交运行快照）
- 对应集成/组件测试
- docs/tasks/TASK-009.md 的 Executor 区域

## Planner Notes

- 推荐持久后广播，性能对回合制游戏足够；若实测不可接受，记录数据再提 ADR。
- 浏览器 localStorage 可作为 LAN MVP 能力令牌存储，但必须避免 XSS 风险并禁止第三方脚本。
- 自动重连要有最大退避和手动重试，不要高频打满主机。

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
