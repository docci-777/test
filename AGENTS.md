# 模型协作入口
用户明确指令优先于仓库约定。
## 职责
- Planner：高阶模型。按 docs/PLANNING.md 规划、明确规则、拆任务及处理阻塞；不代替实施者编写业务代码。
- Reviewer：独立高阶模型。按 docs/REVIEW.md 审查具体提交及证据；不得自审自己编写的实现，不自行改写需求。
- Executor：低阶模型。只按 docs/IMPLEMENTATION.md 指派的 READY 任务实施、自测、记录。代码和任务指定资料可以读取，但其他规划、聊天或审查意见不能直接变成新增实施任务。
模型等级由调用方选定；这些 Markdown 不会自动启动、切换或调度模型。
## 交接
DRAFT → READY（Planner）→ IN_PROGRESS（Executor）→ REVIEW（Executor）→ APPROVED（Reviewer）→ DONE（审查通过、已合并且 Planner 更新记录）。
返工：REVIEW → CHANGES_REQUESTED（Reviewer）→ Planner 把要求写回实施任务 → READY。
阻塞：Executor 记录问题并置 BLOCKED；Planner 决策并修订任务后才恢复 READY。
实施者不得改任务目标、验收标准、公共协议和架构，不得自行宣布 DONE。
## 同步与提交
一个任务一个分支一个 PR；代码、执行记录、测试证据、状态更新须同次提交。
每次开始、交接、阻塞、返工、审查和合并都更新对应任务及 STATUS；重要问题写 ISSUES，决策由 Planner 写 DECISIONS 并同步到实施任务。
任务明细是状态权威来源；STATUS 只汇总并链接。保留历史，不覆盖失败记录。
审查针对明确 commit SHA；后续代码变化使原批准失效，需重新审查。
不要自动合并；合并按用户授权及仓库权限执行。未配置分支保护、自动检查或模型调度时不得声称已强制执行。
