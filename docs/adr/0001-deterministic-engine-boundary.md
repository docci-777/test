# ADR-0001: Deterministic Engine Boundary

- Status: Accepted
- Date: 2026-09-01

## Context

项目需要同时支持命令行模拟、浏览器界面、未来 AI 与可能的联网模式。如果规则散落在 UI 中，多模型并行开发会快速产生重复逻辑和规则漂移。

## Decision

采用与 UI 无关的纯 TypeScript 领域引擎。所有玩法变化通过 Command 进入，经校验与状态迁移后产生新状态和 Event。时间、随机数、存储及网络均通过边界接口提供。

## Consequences

- 同一状态和命令总能得到相同结果，便于测试和回放。
- UI、CLI 和未来 Bot 复用同一套规则。
- 必须显式建模阶段、错误、随机结果与公开/私密事件。
- 初期类型设计成本更高，但减少后期规则分叉。

