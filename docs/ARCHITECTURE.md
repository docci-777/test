# ARCHITECTURE

> 权威职责：说明“系统应该如何设计”。由高阶 Planner 维护；重大长期改变应同时建立 ADR。

## Current Architecture Status

`NOT_DEFINED`

当前尚未录入具体业务系统，因此这里不预设技术栈或架构。

## Architecture Goals

待定义。

## System Context

待定义。

## Components

待定义。建议按模块说明：

| Component | Responsibility | Allowed Dependencies | Notes |
|---|---|---|---|
| TBD | TBD | TBD | TBD |

## Data Flow

待定义。

## Data Model

待定义。

## Interfaces / Contracts

待定义。

## Dependency Rules

待定义。应明确哪些层可以依赖哪些层，避免 Executor 自行形成新架构。

## Cross-Cutting Concerns

待定义，例如：

- Authentication / Authorization
- Logging / Observability
- Error handling
- Security
- Configuration
- Testing strategy

## Architecture Constraints for Executors

在本文件完成定义前，Executor 不得自行选择会形成长期绑定的框架、数据库、协议或基础设施。

一旦定义后：

1. TASK 中的 Architecture Constraints 必须与本文件一致；
2. 如果实现需要违反本文件，Executor 必须记录问题并停止扩大实现；
3. 高阶模型应通过更新本文件和/或 ADR 作出正式决策。

## Related ADRs

暂无。
