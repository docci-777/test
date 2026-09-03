# ROADMAP

> 权威职责：说明“项目接下来往哪里走”。由高阶 Planner 维护阶段和里程碑，不记录每个实现细节。

## Current Stage

### Stage 1 — Foundation and Rule Contract

状态：PLANNED  
当前里程碑：M1 可运行技术骨架与可测试规则边界

目标：建立不会迫使后续 Executor 重新做架构决策的单仓库骨架、协议基础和规则场景体系。

完成条件：

- [ ] TASK-001 完成：工程骨架、质量门禁、空应用与测试入口可运行；
- [ ] TASK-002 完成：棋盘拓扑、固定/随机地图与确定性测试；
- [ ] 协议版本、规则版本和错误码有唯一位置；
- [ ] 后续规则任务无需自行选择框架、状态模型或随机策略。

## Stage 0 — Collaboration Bootstrap and Project Definition

状态：COMPLETE

完成结果：

- [x] 定义 Planner / Executor / Reviewer 角色与权限；
- [x] 建立 TASK 状态机、指南和模板；
- [x] 明确真实项目目标、范围、成功标准和原创资产边界；
- [x] 接受初版架构与关键 ADR；
- [x] 建立首批真实 TASK 及依赖顺序。

## Planned Stages

### Stage 2 — Pure Authoritative Rules Engine

目标：在没有网络和 UI 的条件下完成可重放的 3–4 人基础规则闭环。

任务：

- TASK-003：初始放置、回合、骰子、生产、7 点与强盗；
- TASK-004：成本、道路/聚落/城市建造和银行/港口交易；
- TASK-005：玩家报价、接受/拒绝与原子交易；
- TASK-006：发展卡、最长道路、最大骑士、计分与终局。

退出标准：

- 所有核心规则由纯命令处理器裁决；
- 正常与非法路径都有场景测试；
- 固定 RNG 可稳定复现骰子、偷取、牌堆和地图；
- 任何命令失败均不产生部分状态变化。

### Stage 3 — LAN Server and Multiplayer Client

目标：把完整规则安全地提供给 3–4 个局域网浏览器。

任务：

- TASK-007：房间、会话、权威 WebSocket 命令管线与玩家投影；
- TASK-008：原创大厅、棋盘、私密手牌及核心行动 UI；
- TASK-009：断线重连、修订追平、幂等和版本化本地快照。

退出标准：

- 3/4 人可创建、加入、准备并进行完整回合；
- 客户端无法绕过服务端规则；
- 每个玩家只收到允许查看的秘密；
- 刷新、短时断网和重复发送不会破坏状态。

### Stage 4 — End-to-End Hardening and LAN Release

目标：形成朋友可实际启动和完成整局的可交付版本。

任务：

- TASK-010：3/4 玩家多上下文 E2E、规则回归与故障注入；
- TASK-011：局域网启动、打包、恢复与房主运行手册；
- TASK-012：原创视觉、可访问性、许可清单与发布审查。

退出标准：

- PROJECT.md 的全部 Success Criteria 有证据；
- Reviewer 完成规则、秘密隔离、重连和视觉合规审查；
- 干净设备按 README 可启动，其他设备可通过 LAN 地址加入；
- 无 P0/P1 缺陷，已知限制写入发布说明。

## Dependency Graph

    TASK-001 -> TASK-002 -> TASK-003 -> TASK-004 -> TASK-005 -> TASK-006
                                                                  |
                                                                  v
                                                               TASK-007
                                                                  |
                                                                  v
                                                               TASK-008
                                                                  |
                                                                  v
                                                               TASK-009
                                                                  |
                                                                  v
                                                               TASK-010
                                                                /     \
                                                       TASK-011       |
                                                           \          |
                                                            v         v
                                                              TASK-012

补充依赖：

- TASK-006 同时依赖 TASK-004 与 TASK-005。
- TASK-007 同时依赖 TASK-001 与 TASK-006。
- TASK-008 同时依赖 TASK-006 与 TASK-007。
- TASK-010 以 TASK-003 至 TASK-009 全部 DONE 为门槛。
- TASK-011 依赖 TASK-009 与 TASK-010；TASK-012 依赖 TASK-008、TASK-010 与 TASK-011。

并发规则：

- 默认按依赖图串行释放 P0 任务，以减少多个 Executor 同时修改 domain/protocol 的冲突。
- Planner 可将独立的测试数据、文档或视觉探索拆成新任务并行，但不得改变现有 TASK Scope。
- TASK-008 不复制业务规则，只消费 protocol 的投影和 allowedActions。
- TASK-010 前，TASK-003 至 TASK-009 必须全部 DONE。

## Milestones

| Milestone | Outcome | Tasks | Status |
|---|---|---|---|
| M1 Foundation | 可运行骨架、确定性棋盘 | 001–002 | NEXT |
| M2 Rules Complete | 纯领域层可完整裁决基础游戏 | 003–006 | PLANNED |
| M3 Multiplayer Playable | LAN 多人 UI、权威协议与恢复 | 007–009 | PLANNED |
| M4 MVP Release | 3/4 人验收、运行手册、原创审查 | 010–012 | PLANNED |

## Deferred Backlog

MVP 完成后才评估：

- 房间重赛和历史回放；
- 可选友好强盗等家规；
- 机器人、观战、聊天；
- 5–6 人与扩展玩法；
- 公网部署、账号、TLS 自动化；
- 协作协议自动检查与任务依赖图生成。

这些条目不得被 Executor 当作现有 TASK 的隐含 Scope。
