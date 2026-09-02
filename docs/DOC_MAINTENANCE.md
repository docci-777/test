# Collaboration Document Maintenance

> 本文件定义协作文档如何更新、谁维护以及同一事实放在哪里。统一动态入口为 `docs/CHECKLIST.md`。

## 单一事实来源

| 信息 | 唯一维护位置 |
| --- | --- |
| 当前任务状态、Issue / PR 对应关系、依赖、执行顺序、下一步、完成清单 | `docs/CHECKLIST.md` |
| 低阶执行细则 | `docs/EXECUTOR_GUIDE.md` |
| 高阶审查细则 | `docs/REVIEW_GUIDE.md` |
| 文档职责与更新规则 | `docs/DOC_MAINTENANCE.md` |
| 单任务目标、允许/禁止范围、验收标准 | GitHub Issue |
| 项目产品边界 | `docs/PRODUCT.md` |
| 游戏规则事实 | `docs/GAME_RULES.md` |
| 架构与依赖方向 | `docs/ARCHITECTURE.md` + ADR |
| 里程碑级长期方向 | `docs/ROADMAP.md` |
| 稳定代理底线 | `AGENTS.md` |
| 分支、PR 通用流程 | `CONTRIBUTING.md` |
| PR 交付证据格式 | `.github/pull_request_template.md` |

`docs/STATUS.md` 与 `docs/TASK_DISPATCH.md` 仅保留兼容跳转，不再保存动态事实。

## README 的职责

README 只提供项目简介和统一口令：**根据 `docs/CHECKLIST.md` 执行。** 不保存逐任务实时状态，也不要求用户指定 Issue/PR。

## CHECKLIST 更新触发器

以下事件发生后，高阶模型或仓库所有者必须重新核对 GitHub 并更新 `docs/CHECKLIST.md`：

- Issue 被创建、关闭、重新打开或契约发生关键变化。
- 任务依赖满足、进入 `READY`，或被正式开始。
- PR 创建、关闭、重新打开、head 变化、冲突变化或合并。
- CI 结果变化。
- 高阶审查结论变化。
- 审查线程从未解决变为已解决，或出现新的阻塞线程。
- 任务暂缓、取消或重新启用。
- ROADMAP 工作被拆成新 Issue。

每次更新必须同时修改“最后核对”日期，并同步对应 checkbox、状态和“当前执行队列”。

## 状态变更原则

- `READY` 只能在依赖已满足、Issue 契约完整后设置。
- PR 创建后一般进入 `IN_REVIEW`。
- 有需要修复的阻塞/重要 finding 或合并冲突时进入 `CHANGES_REQUESTED`。
- `APPROVED` 必须同时满足：当前 head 的 CI 成功、当前 head 有高阶结构化“通过”结论、无未解决阻塞/重要线程。
- head 变化后旧审查失效；状态应回到 `IN_REVIEW`，直到新 head 复审完成。
- `DONE` 只能在 PR 实际合并后设置。
- `DEFERRED` 不计为完成。

## 文档修改权限

- 低阶执行模型默认不得修改 `docs/CHECKLIST.md`、`docs/REVIEW_GUIDE.md` 或本文件，除非目标 Issue 明确授权。
- 低阶模型通过分支、提交和 PR 留下事实证据；发现清单错误时报告，不擅自改动态状态。
- 高阶模型可以根据 GitHub 事实更新 `docs/CHECKLIST.md`，并在必要时修订协作规则；规则变化必须保持各入口统一指向清单。

## 冲突处理

发现两个文档对同一事实给出不同说法时：

1. 停止依赖该事实的关键决策。
2. 根据上表确定唯一事实来源。
3. 以 GitHub 实际状态或已批准 ADR / Issue 契约核实事实。
4. 修正错误副本；尽量删除重复内容，改为链接唯一来源。

若 `docs/CHECKLIST.md` 与 GitHub 实际状态冲突，GitHub 事实优先，高阶模型应先修清单再继续。

## 新增文档前检查

只有当现有文件无法承担一个明确且独立的稳定职责时才新增文档。新增前必须回答：这个文件保存什么唯一事实、谁维护、何时读取、是否复制现有内容。若会复制动态协作状态，禁止新增，统一写入 `docs/CHECKLIST.md`。
