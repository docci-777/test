# test — 多模型 GitHub 协作框架 V1

本仓库当前首先用于建立一套可持续的多模型协作协议：

- **高阶模型（Planner / Reviewer）**：负责规划、架构、拆任务、决策与审查。
- **低阶模型（Executor）**：按明确任务边界实现、测试、记录并提交 PR。
- **GitHub + 仓库文档**：作为跨模型、跨会话的持久协作上下文。

## 快速入口

任何模型进入仓库后第一步都应阅读：

**`AGENTS.md`**

然后根据角色继续：

- 高阶规划：`docs/guides/PLANNER_GUIDE.md`
- 低阶执行：`docs/guides/EXECUTOR_GUIDE.md`
- 高阶审查：`docs/guides/REVIEW_GUIDE.md`

## 文档地图

```text
/
├── AGENTS.md                         # 所有模型的最高级仓库协作规则
├── README.md
├── docs/
│   ├── PROJECT.md                    # 项目目标、范围、约束
│   ├── ARCHITECTURE.md               # 系统架构与边界
│   ├── ROADMAP.md                    # 阶段与里程碑
│   ├── STATUS.md                     # 当前全局状态
│   ├── guides/
│   │   ├── PLANNER_GUIDE.md          # 高阶规划流程
│   │   ├── EXECUTOR_GUIDE.md         # 低阶执行流程
│   │   └── REVIEW_GUIDE.md           # 高阶审查流程
│   ├── tasks/
│   │   └── TASK_TEMPLATE.md          # 单任务标准模板
│   └── decisions/
│       └── ADR_TEMPLATE.md           # 长期决策记录模板
└── .github/
    ├── ISSUE_TEMPLATE/task.yml       # GitHub 任务 Issue 模板
    └── pull_request_template.md       # PR 模板
```

## 标准闭环

```text
需求/目标
   ↓
Planner
   ↓
PROJECT / ARCHITECTURE / ROADMAP
   ↓
TASK = READY
   ↓
Executor
   ↓
IN_PROGRESS → 实现/测试/记录
   ↓
TASK = REVIEW + Pull Request
   ↓
Reviewer
   ├─ CHANGES_REQUESTED → Executor
   └─ APPROVE → Merge
                    ↓
                 TASK = DONE
                    ↓
                STATUS 更新
```

## 推荐使用方式

### 启动高阶规划模型

告诉模型：

> 你是本仓库的高阶规划模型。严格遵守 AGENTS.md 和 PLANNER_GUIDE.md，读取仓库当前事实后进行规划。不要直接执行未拆解的业务实现。

### 启动低阶执行模型

告诉模型：

> 你是本仓库的低阶执行模型。严格遵守 AGENTS.md 和 EXECUTOR_GUIDE.md，只执行被分配且状态允许执行的 TASK，不自行改变规划或扩大范围。

### 启动高阶审查模型

告诉模型：

> 你是本仓库的高阶审查模型。严格遵守 AGENTS.md 和 REVIEW_GUIDE.md，根据 TASK 验收标准、架构约束、PR Diff 和测试结果完成审查与收尾。

## V1 的边界

当前版本有意保持简单：

- 不自动调度模型；
- 不自动 Merge；
- 不依赖聊天记忆；
- 暂不加入复杂 GitHub Actions 状态校验；
- 先通过真实任务验证文档协议，再决定 V2 自动化。
