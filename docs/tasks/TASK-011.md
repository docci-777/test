---
task_id: TASK-011
status: DRAFT
priority: P1
owner_role: executor
depends_on: [TASK-009, TASK-010]
related_issue: null
related_pr: null
---

# TASK-011 — 单进程打包、LAN 启动与房主运行手册

## Status

DRAFT

## Goal

把客户端和服务端打包为普通电脑可启动的单进程应用，并提供房主可照做的安装、局域网访问、备份恢复和故障排查文档。

## Background

代码能开发运行不等于朋友能使用。房主需要知道如何发现可分享地址、处理防火墙、保存 data 目录和在断线/重启时恢复，同时不能误把服务暴露到公网。

## Scope

- 生产构建由服务端托管客户端静态文件。
- 提供明确的安装、构建、启动和开发命令。
- 启动时显示监听地址、端口、localhost 和可用 LAN 地址提示。
- 配置 host、port、data 目录和日志级别，提供安全默认值/警告。
- README 增加 3/4 人创建加入流程、固定/随机地图说明和非官方声明。
- 编写防火墙、同网段、地址不可达、端口占用、浏览器存储清除、快照损坏的排查。
- 编写 data 目录备份/恢复、升级前备份和版本不兼容处理。
- 记录支持平台/浏览器和已知限制。
- 验证干净环境从 clone 到 LAN 加入。

## Out of Scope

- Docker、安装器、自动更新、云部署、域名和公网 TLS。
- 路由器端口转发指导。
- 新规则、UI 重设计或外部品牌素材。

## Acceptance Criteria

- [ ] AC-1：production build 生成客户端静态产物并由一个 Node 服务进程提供 HTTP + WebSocket。
- [ ] AC-2：干净环境按 README 可安装、构建和启动，无需数据库或外部服务。
- [ ] AC-3：启动输出明确区分本机地址与局域网地址，不在无法确定时伪造可访问 URL。
- [ ] AC-4：host、port、data 目录可配置，非法配置快速失败并给可操作错误。
- [ ] AC-5：至少一台其他设备按文档使用 LAN 地址加入成功。
- [ ] AC-6：文档明确可信局域网假设、不要直接公网暴露、基础防火墙注意事项。
- [ ] AC-7：备份并恢复 data 目录后，未结束房间可继续且秘密不出现在命令输出。
- [ ] AC-8：README 清楚说明 3–4 人、基础规则、固定/随机地图、断线恢复和 MVP 不支持项。
- [ ] AC-9：关于/README 使用原创名称并包含准确的非官方、无授权隶属说明。
- [ ] AC-10：故障排查覆盖端口占用、不同网段、防火墙、令牌丢失、快照不兼容。
- [ ] AC-11：生产依赖审计无未解释的高危问题；任何例外由 Reviewer 记录。
- [ ] AC-12：构建包不包含测试入口、源秘密、运行快照或未登记素材。

## Architecture Constraints

- 相关 ADR：ADR-001、ADR-002、ADR-003。
- 不新增云服务、数据库或容器作为必需运行条件。
- 配置文档不建议把服务直接暴露公网。
- 正式版本号、protocolVersion、rulesetVersion 和 snapshot schema 可被 /health 查看。

## Dependencies

- TASK-009、TASK-010 必须 DONE。

## Allowed / Expected Files

- apps/server 的静态托管/启动配置
- package scripts 与构建配置
- README.md
- docs/guides/** 或 docs/runbook/**
- 示例环境配置（不得含秘密）
- 对应打包/冒烟测试
- docs/tasks/TASK-011.md 的 Executor 区域

## Planner Notes

- “一条启动命令”可以是先安装/构建后的一条 run 命令，不要求制作原生安装包。
- LAN 地址枚举在不同系统会变化，输出应作为候选并允许用户手动指定。
- 所有文档截图如非必要不使用；若使用必须原创并更新 NOTICE。

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
