# ROADMAP

> 权威职责：说明“项目接下来往哪里走”。由高阶 Planner 维护阶段和里程碑，不记录每个实现细节。

## Current Stage

### Stage 0 — Collaboration Bootstrap

目标：建立可供多个模型稳定交接的 GitHub 文档协议。

状态：`IN_PROGRESS`

完成条件：

- [x] 定义角色与权限；
- [x] 定义 TASK 状态机；
- [x] 建立 Planner / Executor / Reviewer 指南；
- [x] 建立 TASK / ADR / Issue / PR 模板；
- [ ] 由用户提供或确认真实项目目标；
- [ ] 高阶 Planner 完成 PROJECT 与初版 ARCHITECTURE；
- [ ] 创建第一个真实 `TASK-001` 并完成一次完整协作闭环。

## Planned Stages

### Stage 1 — Project Definition

由高阶 Planner：

1. 明确 PROJECT；
2. 设计最小可行架构；
3. 定义首个里程碑；
4. 拆出一组有依赖顺序的 TASK。

### Stage 2 — First Execution Loop

用至少一个真实 TASK 验证：

`READY → IN_PROGRESS → REVIEW → DONE`

并记录实际协作摩擦点。

### Stage 3 — Protocol Hardening

根据真实执行反馈调整模板、权限和文档职责。

### Stage 4 — Optional Automation (V2)

只有协议稳定后再考虑 GitHub Actions，例如：

- TASK 状态合法性检查；
- PR 是否引用 TASK；
- 必填验收/测试字段检查；
- 防止不符合状态机的合并。

## Backlog / Future Ideas

- 自动化状态检查；
- 多 Executor 并行调度规则；
- 自动生成进度摘要；
- 任务依赖图；
- 更严格的机器可读 TASK front matter。
