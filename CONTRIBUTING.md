# Contribution Workflow

实时任务状态以 `docs/STATUS.md` 为准；低阶执行协议见 `docs/EXECUTOR_GUIDE.md`，高阶审查协议见 `docs/REVIEW_GUIDE.md`。本文件只定义稳定的分支与 PR 通用流程。

## 开始条件

只有 `docs/STATUS.md` 中标记为 `READY` 的 Issue 才能首次派发。`IN_PROGRESS` 或 `CHANGES_REQUESTED` 的任务只能由原负责人继续。

## 分支命名

- `feat/issue-<number>-<slug>`
- `fix/issue-<number>-<slug>`
- `test/issue-<number>-<slug>`
- `docs/issue-<number>-<slug>`
- `chore/issue-<number>-<slug>`

禁止从旧任务分支、历史 `trae/*` 分支或其他未合并分支开始新任务。

## 标准流程

1. 高阶模型确认 Issue 契约完整、依赖已合并，并在 `docs/STATUS.md` 标记 `READY`。
2. 指定唯一执行模型；执行模型从最新 `main` 创建独立分支。
3. 执行模型严格按 Issue 允许范围实现、测试并运行质量命令。
4. 创建关联 `Closes #N` 的 Pull Request，完整填写 PR 模板。
5. 等待 CI 与高阶模型按 `docs/REVIEW_GUIDE.md` 结构化审查。
6. 若需修改，仅原负责人在原分支和原 PR 修复明确意见。
7. 当前 head 通过审查且 CI 成功后，由高阶模型更新 `docs/STATUS.md` 为 `APPROVED`。
8. 通过后由仓库所有者或其明确授权者 squash merge，并删除任务分支。
9. 合并后高阶模型将任务标记为 `DONE`，并重新计算下游任务是否可变为 `READY`。

## Issue 就绪条件

只有同时具备以下内容的 Issue 才能标记为 `READY`：

- 单一、明确的目标
- 输入输出或接口定义
- 允许修改与禁止修改的范围
- 可客观验证的验收标准
- 正常、非法和边界场景
- 依赖关系、阻塞项及必要的高阶决策

## Pull Request 大小

优先保持在约 400 行有效改动以内。超过时应先判断能否拆分；生成文件、锁文件和测试数据不计入该建议值。

## 文档更新

- Issue 保存单任务契约；不要把逐任务细节复制到 README 或 ROADMAP。
- `docs/STATUS.md` 保存当前状态和依赖；由高阶模型在 GitHub 状态变化后更新。
- README 只提供入口；ROADMAP 只维护里程碑方向。
- 规则变化更新 `docs/GAME_RULES.md`；架构变化通过 ADR 并同步 `docs/ARCHITECTURE.md`。
- 协作文档职责和冲突处理按 `docs/DOC_MAINTENANCE.md` 执行。
- 低阶执行模型不得在未授权时修改动态状态或协作规则。
