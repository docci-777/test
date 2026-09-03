# ADR-002 — TypeScript 单仓库技术栈与包边界

**Status:** ACCEPTED  
**Date:** 2026-09-03  
**Decision Owners:** 高阶 Planner  
**Related Tasks:** TASK-001, TASK-002, TASK-007, TASK-008, TASK-009, TASK-010, TASK-011  
**Supersedes:** None  
**Superseded By:** None

## Context

项目同时包含浏览器界面、Node 服务端、纯规则引擎、共享协议和多客户端测试。首版由多模型协作完成，需要减少语言切换，避免协议类型复制，并让 Executor 有明确文件边界。项目在普通个人电脑上运行，不希望依赖外部数据库、容器或云服务。

## Decision

采用严格 TypeScript 单仓库：

- 包管理与工作区：pnpm workspaces；
- 任务编排：优先使用 pnpm 原生递归脚本，只有出现可测构建瓶颈时才引入额外编排器；
- 客户端：React + Vite，以 SVG/HTML/CSS 绘制原创棋盘和控件；
- 服务端：Node.js LTS + Fastify，WebSocket 使用与其集成良好的轻量库；
- 运行时 schema：Zod 或同类单一 schema 库，由 packages/protocol 集中导出；
- 测试：Vitest（单元/集成）+ Playwright（多浏览器上下文 E2E）；
- 代码质量：TypeScript strict、ESLint、Prettier；
- 存储：文件系统版本化 JSON 快照，经 adapter 隔离；
- 生产构建：服务端托管客户端静态产物，一个进程面向 LAN 启动。

依赖的精确版本由 TASK-001 在当时稳定兼容范围内锁定并提交 lockfile；未经 Planner 审批不得替换以上主要框架。

## Rationale

- 前后端共享类型和 schema，降低协议漂移。
- 纯 TypeScript domain 可在 Node 测试，也能共享只读枚举与投影类型。
- React/Vite 适合交互式棋盘与快速本地开发；SVG 对六角拓扑、缩放和原创视觉友好。
- Fastify 提供结构化 HTTP 与插件边界，仍保持单机部署轻量。
- Vitest 与 Playwright 能覆盖纯规则和 3–4 个独立浏览器身份。
- 不立即引入数据库或容器，符合零外部服务的局域网目标。

## Alternatives Considered

### Option A — Next.js 全栈

- 优点：前后端集成和打包便利。
- 缺点：回合制 WebSocket 服务、纯领域边界和 LAN 单进程状态管理容易与页面框架耦合。
- 未选择原因：本项目不是内容站，独立服务端边界更清楚。

### Option B — Python 服务端 + TypeScript 客户端

- 优点：后端生态成熟。
- 缺点：协议模型需跨语言维护，多模型交接与规则类型复用成本更高。
- 未选择原因：首版优先单语言一致性。

### Option C — Canvas/WebGL 棋盘

- 优点：大量动画时性能更高。
- 缺点：可访问性、命中测试和自动化测试复杂。
- 未选择原因：19 六角棋盘无需该性能，SVG 更容易审查和测试。

### Option D — SQLite 首版持久化

- 优点：事务、查询和单文件部署成熟。
- 缺点：对少量房间快照增加 schema/迁移和 repository 复杂度。
- 未选择原因：先保留存储端口；需要房间历史或大量并发时再评估。

## Consequences

### Positive

- Executor 可按 apps/packages 边界并行工作。
- 协议 schema、类型和测试在一个语言生态内复用。
- 开发与生产都可用少量命令启动。
- 棋盘视觉可保持 DOM/SVG 可测试性。

### Negative / Trade-offs

- Node 单进程需正确处理房间隔离和文件 I/O。
- 类型安全不能替代运行时 schema 校验。
- SVG 交互和响应式布局仍需专门设计。
- pnpm/Node 版本必须在仓库中固定并文档化。

### Follow-up

- TASK-001 建立目录、脚本、严格配置、健康检查和 CI。
- TASK-008 建立 SVG 坐标映射与键盘/文本替代。
- TASK-011 产出单进程生产启动和 LAN 指南。

## Validation / Revisit Trigger

以下情况出现时重新评估：

- 性能测试证明 SVG 或单进程服务无法满足目标；
- 需要移动原生客户端；
- 快照查询、房间历史或数据量要求数据库；
- 主要框架进入不可维护状态或存在无法缓解的安全问题。
