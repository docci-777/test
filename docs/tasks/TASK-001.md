---
task_id: TASK-001
status: READY
priority: P0
owner_role: executor
depends_on: []
related_issue: null
related_pr: null
---

# TASK-001 — TypeScript 单仓库骨架与质量门禁

## Status

READY

## Goal

建立 ADR-002 定义的可运行单仓库骨架，使客户端、服务端、领域、协议和测试包都能独立构建、检查和测试。只提供最小占位入口，不实现任何桌游业务规则。

## Background

所有后续任务依赖一致的 TypeScript 配置、包边界、脚本和测试工具。先固定工程约束可避免多个 Executor 分别选择框架或复制协议类型。

## Scope

- 初始化 pnpm workspace 与 apps/client、apps/server、packages/domain、packages/protocol、packages/test-support、tests/e2e。
- 固定 Node/pnpm 版本范围并提交 lockfile。
- 配置 TypeScript strict、ESLint、Prettier、Vitest 和 Playwright 基础。
- 创建最小 React/Vite 占位页。
- 创建最小 Fastify 服务，提供 GET /health，返回服务名、协议版本、规则版本和状态。
- 为每个包建立明确 exports、构建和测试脚本。
- 配置 gitignore，排除 data/、环境文件、构建物与测试输出。
- 增加 CI：安装、格式检查、lint、typecheck、unit test、build；E2E 可先只跑占位健康测试。
- README 增加开发命令，但不得声称游戏已可玩。

## Out of Scope

- 棋盘、房间、WebSocket、玩家、资源、交易、建造或任何业务规则。
- 生产打包、服务重启恢复和 LAN 真机指南。
- 正式视觉、Logo、官方或第三方未登记素材。
- 更换 ADR-002 已选技术栈。

## Acceptance Criteria

- [ ] AC-1：干净环境按 README 的单一安装命令可恢复依赖，lockfile 无漂移。
- [ ] AC-2：根级 format-check、lint、typecheck、test、build 脚本均成功并覆盖所有 workspace。
- [ ] AC-3：apps/client 显示明确“功能尚未实现”的原创占位页，不含官方品牌或素材。
- [ ] AC-4：apps/server 的 GET /health 返回 200 及稳定 JSON schema，且有自动化测试。
- [ ] AC-5：domain、protocol、test-support 均有最小导出和测试，可证明包解析正常。
- [ ] AC-6：client 不直接依赖 domain，依赖关系符合 ARCHITECTURE.md。
- [ ] AC-7：data、dist、coverage、Playwright 输出和本地秘密不会被 Git 跟踪。
- [ ] AC-8：CI 配置在 pull_request 和 main push 上执行全部基础门禁。
- [ ] AC-9：仓库中没有游戏业务实现或未经批准的新基础设施。

## Architecture Constraints

- 遵守 docs/ARCHITECTURE.md。
- 相关 ADR：ADR-002、ADR-003。
- Node/pnpm 版本需使用仓库可执行的声明文件固定。
- 只允许选择运行时 schema 库的一个实现；若 ADR-002 的候选无法正常工作，记录 BLOCKED，不自行换架构。
- 不加入数据库、ORM、Docker、状态管理大框架或 UI 组件库。

## Dependencies

None.

## Allowed / Expected Files

- package.json、pnpm-workspace.yaml、pnpm-lock.yaml
- tsconfig*.json、eslint/prettier 配置
- apps/**
- packages/**
- tests/e2e/**
- .github/workflows/**
- .gitignore
- README.md
- docs/tasks/TASK-001.md 的 Executor 区域

## Planner Notes

- 业务占位类型应最少，避免 TASK-002 需要删除臆造模型。
- 依赖使用兼容的稳定版本并锁定；PR 中记录选定版本和理由。
- CI 若无法在插件环境验证，仍需本地执行等价脚本并记录证据。

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
