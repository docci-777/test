# Contribution Workflow

动态任务选择、状态、依赖和下一步统一以 `docs/CHECKLIST.md` 为准。本文件只定义稳定的分支与 PR 通用流程。

## 开始条件

执行模型先根据 `docs/CHECKLIST.md` 自动选择任务，不需要用户提供 Issue 编号。

- `READY`：可以首次开始。
- `IN_PROGRESS`：仅原负责人继续。
- `CHANGES_REQUESTED`：仅原负责人在原分支、原 PR 修订。
- 其他状态不得开始编码。

## 分支命名

- `feat/issue-<number>-<slug>`
- `fix/issue-<number>-<slug>`
- `test/issue-<number>-<slug>`
- `docs/issue-<number>-<slug>`
- `chore/issue-<number>-<slug>`

具体分支优先使用 `docs/CHECKLIST.md` 中目标任务记录的建议分支。禁止从旧任务分支、历史 `trae/*` 分支或其他未合并分支开始新任务。

## 标准流程

1. 高阶模型依据 GitHub 实际状态确认依赖和 Issue 契约，并在 `docs/CHECKLIST.md` 将任务置为 `READY`。
2. 低阶模型收到“根据清单执行”后自动选取最高优先级可执行项，从最新 `main` 创建独立分支；若为 `CHANGES_REQUESTED` 则继续原分支。
3. 严格按 Issue 允许范围实现、测试并运行质量命令。
4. 创建关联目标 Issue 的唯一 Pull Request，完整填写 PR 模板。
5. 高阶模型收到同样的“根据清单执行”指令后，自动选择最高优先级待审 PR 并结构化审查。
6. 若需修改，仅原负责人在原分支和原 PR 修复明确意见。
7. 当前 head 通过审查且 CI 成功后，高阶模型在清单中置为 `APPROVED`。
8. 通过后由仓库所有者或其明确授权者 squash merge，并删除任务分支。
9. 合并后高阶模型按 GitHub 事实将任务标记为 `DONE`，重算依赖并自动解锁下一任务。

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

- `docs/CHECKLIST.md` 保存当前状态、执行顺序、依赖和完成清单；由高阶模型根据 GitHub 实际变化维护。
- Issue 保存单任务契约；不要把逐任务细节复制到 README 或 ROADMAP。
- README 只提供统一协作入口；ROADMAP 只维护里程碑方向。
- 规则变化更新 `docs/GAME_RULES.md`；架构变化通过 ADR 并同步 `docs/ARCHITECTURE.md`。
- 协作文档职责和冲突处理按 `docs/DOC_MAINTENANCE.md` 执行。
- 低阶执行模型不得在未授权时修改动态清单或协作规则。
