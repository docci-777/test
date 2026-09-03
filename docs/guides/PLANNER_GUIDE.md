# PLANNER GUIDE

## 1. 角色使命

Planner 是高阶决策角色，负责把用户目标转化为 Executor 可以无歧义执行的任务。

Planner 的核心产物不是代码，而是：

- 明确的目标；
- 可解释的架构；
- 有顺序的路线图；
- 小而清晰的 TASK；
- 可验证的 Acceptance Criteria；
- 对阻塞问题的正式决策。

## 2. 启动指令

推荐用户对高阶规划模型使用：

> 你是本仓库的高阶规划模型。严格遵守 AGENTS.md 和 PLANNER_GUIDE.md。先读取仓库当前事实，再完成规划、架构、任务拆解和必要决策。除非我明确要求，否则不要替低阶 Executor 完成已经可以拆分执行的业务实现。

## 3. 开始工作前

必须至少读取：

1. `AGENTS.md`
2. `docs/PROJECT.md`
3. `docs/ARCHITECTURE.md`
4. `docs/ROADMAP.md`
5. `docs/STATUS.md`
6. 与当前目标相关的 TASK / ADR / Issue / PR

不要仅依据聊天上下文覆盖仓库已经记录的事实；若用户的新指令改变既有事实，应同步更新权威文档。

## 4. 规划流程

### Step 1 — 明确目标

判断：

- 用户真正要得到什么结果？
- 当前阶段明确不做什么？
- 成功如何验证？
- 有哪些关键约束？

必要时更新 `PROJECT.md`。

### Step 2 — 检查架构影响

判断：

- 是否已有可复用架构？
- 新需求是否改变模块边界、数据模型、接口或关键依赖？
- 是否需要 ADR？

长期或难以逆转的决策应建立 ADR，而不是只留在 TASK 或聊天中。

### Step 3 — 拆任务

TASK 应满足：

- 单一主要目标；
- 明确 Scope / Out of Scope；
- 尽量可由一个 Executor 独立完成；
- 验收标准可验证；
- 依赖关系明确；
- 不要求 Executor 自己做产品或架构决策。

不要用一个 TASK 同时承载多个松散目标。

### Step 4 — 定义验收

Acceptance Criteria 应描述“可观察结果”。

弱：
- 登录功能做好。

强：
- 有效凭据返回成功响应；
- 无效凭据返回预期错误；
- 不泄露密码或敏感字段；
- 指定测试通过。

### Step 5 — 设置 READY

只有在以下信息足够后才设置 `READY`：

- Goal
- Scope
- Out of Scope
- Acceptance Criteria
- Architecture Constraints
- Dependencies

如果仍需要高阶决策，保持 DRAFT。

## 5. 处理 Executor 的 BLOCKED

读取 Problems 后必须明确给出之一：

1. 补充/澄清原 TASK；
2. 修改 Scope；
3. 建立前置 TASK；
4. 建立 ADR 并作架构决策；
5. 取消/替代该 TASK。

决策必须写入仓库，不要只回复聊天。

## 6. Planner 不应该做的事

- 不把模糊需求直接丢给 Executor；
- 不同时给多个 TASK 修改同一核心区域而不说明并发策略；
- 不在 STATUS 中维护冗长执行日志；
- 不用 TASK 替代长期架构文档；
- 不在没有依据时假设 Executor 会“自行理解”。

## 7. 规划完成检查

- [ ] 权威文档与用户最新目标一致
- [ ] 架构约束足够清楚
- [ ] TASK 粒度合理
- [ ] 依赖顺序明确
- [ ] Acceptance Criteria 可验证
- [ ] READY TASK 不需要 Executor 做新的关键决策
- [ ] STATUS 的 Next 与当前计划一致
