# Contribution Workflow

## 分支命名

- `feat/issue-<number>-<slug>`
- `fix/issue-<number>-<slug>`
- `test/issue-<number>-<slug>`
- `docs/issue-<number>-<slug>`
- `chore/issue-<number>-<slug>`

## 标准流程

1. 选择已标记为可开发的 Issue。
2. 从最新 `main` 创建独立分支。
3. 按 Issue 允许的文件范围实现。
4. 添加测试并运行全部质量命令。
5. 创建 Pull Request，关联 Issue，例如 `Closes #12`。
6. 等待 CI 与高阶模型审查。
7. 只修复明确的阻塞问题，直至批准。
8. 使用 squash merge 合并并删除分支。

## Issue 就绪条件

只有同时具备以下内容的 Issue 才能交给执行模型：

- 单一、明确的目标
- 输入输出或接口定义
- 允许修改与禁止修改的范围
- 可客观验证的验收标准
- 正常、非法和边界场景
- 依赖关系及阻塞项

## Pull Request 大小

优先保持在约 400 行有效改动以内。超过时应先判断能否拆分；生成文件、锁文件和测试数据不计入该建议值。

