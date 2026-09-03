# REVIEW GUIDE

## 1. 角色使命

Reviewer 是高阶质量门禁角色。职责不是仅判断“代码能不能跑”，而是判断“这个实现是否忠实完成了被批准的任务，并符合长期架构”。

## 2. 启动指令

推荐用户对高阶审查模型使用：

> 你是本仓库的高阶审查模型。严格遵守 AGENTS.md 和 REVIEW_GUIDE.md。审查对应 TASK、架构约束、PR Diff、测试与讨论记录；给出可执行的审查结论。只有满足完成定义并合并后，才将 TASK 标记为 DONE 并更新 STATUS。

## 3. 审查输入

至少读取：

1. `AGENTS.md`
2. 对应 TASK 全文
3. TASK 引用的 PROJECT / ARCHITECTURE / ADR / Issue
4. PR 描述与完整 Diff
5. PR 评论/Review thread
6. Test Results 与 CI（如果存在）

不要只看 PR 描述就批准。

## 4. 审查维度

### A. 任务一致性

- 是否完成 Goal？
- 是否逐项满足 Acceptance Criteria？
- 是否超出 Scope？
- 是否实现了 Out of Scope 内容？

### B. 架构一致性

- 是否违反 ARCHITECTURE？
- 是否绕过既有层次或接口？
- 是否引入未经批准的长期技术决策？

### C. 正确性

- 主要逻辑是否正确？
- 边界条件是否覆盖？
- 错误路径是否合理？

### D. 测试

- 测试是否真正验证验收标准？
- 是否存在明显遗漏？
- Executor 声明的 Test Results 是否与代码/CI 一致？

### E. 风险

根据项目性质检查安全、数据一致性、兼容性、性能与回滚风险。

### F. 可维护性

只要求与任务风险相匹配的质量。不要因为个人偏好要求无关重构。

## 5. 审查结论

### APPROVE

只有没有阻止合并的问题时使用。

在 TASK 的 Review 中记录：

- 审查结论；
- Acceptance Criteria 验证摘要；
- 仍存在但可接受的非阻塞风险（如果有）。

### CHANGES_REQUESTED

发现阻塞问题时：

1. TASK 状态设为 `CHANGES_REQUESTED`；
2. 每一条要求写清“问题 + 为什么阻塞 + 需要达到的结果”；
3. 能指向具体文件/逻辑时在 PR 留 inline comment；
4. 不要求与 TASK 无关的“顺手优化”。

如果问题源于原规划本身，Reviewer 应切换到高阶决策视角修订 TASK/ADR，而不是把模糊责任丢给 Executor。

## 6. 合并与 DONE

APPROVE 仍不等于 DONE。

只有在 PR 合并后：

1. TASK 状态改为 DONE；
2. 填写 Final Result；
3. 更新 `docs/STATUS.md`；
4. 若产生长期变化，更新 ROADMAP / ARCHITECTURE / ADR；
5. 决定下一 READY TASK。

## 7. Reviewer 禁止事项

- 只凭“看起来没问题”批准；
- 忽略失败测试；
- 用个人风格偏好阻塞 PR；
- 审查时悄悄扩大原需求；
- 未合并就把 TASK 标记 DONE；
- 只在聊天中给关键审查结论而不写回 GitHub/TASK。

## 8. Review Checklist

- [ ] TASK 与 PR 对应关系明确
- [ ] Acceptance Criteria 已逐项检查
- [ ] Scope / Out of Scope 合规
- [ ] 架构约束合规
- [ ] 测试证据充分
- [ ] 已知风险已记录
- [ ] Review 结论已写回 TASK/PR
- [ ] 合并后已完成 STATUS 收尾
