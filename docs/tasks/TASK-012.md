---
task_id: TASK-012
status: DRAFT
priority: P1
owner_role: executor
depends_on: [TASK-008, TASK-010, TASK-011]
related_issue: null
related_pr: null
---

# TASK-012 — 原创视觉、可访问性与许可发布审查

## Status

DRAFT

## Goal

在 MVP 发布前完成一次独立审查，确认产品视觉/文案原创、第三方资产许可可追溯、交互不只依赖颜色，且仓库没有官方品牌素材或大段规则文本复制。

## Background

ADR-003 将视觉与知识产权边界设为发布阻断条件。本任务是审查和必要的小范围替换，不是重新设计品牌；重大问题须拆任务处理。

## Scope

- 扫描代码、assets、README、文档和构建产物中的图片、字体、音频、Logo、名称和来源 URL。
- 建立/核对 assets/original/NOTICE.md，记录每项第三方资产的来源、作者、许可、用途和修改。
- 对所有未登记或来源不清资产删除/替换为原创 CSS/SVG/文字占位。
- 审查应用名、关于页和 README 的非官方说明，不暗示授权/隶属。
- 审查是否复制官方规则书大段文字、图示或版式；保留事实性摘要和链接。
- 检查玩家/资源/可行动状态是否有颜色之外的文本或形状编码。
- 检查键盘操作、焦点、对比度、错误提示和缩放可用性。
- 记录发布审查清单与证据。

## Out of Scope

- 法律意见或官方授权申请。
- 全新商业品牌设计、复杂插画和音效制作。
- 规则、网络、持久化功能开发。
- 用“粉丝项目”声明替代实际素材许可。

## Acceptance Criteria

- [ ] AC-1：仓库和生产构建中不存在官方 Logo、棋盘/卡牌插画、截图、音效、规则图示或近似复制素材。
- [ ] AC-2：每项非自制资产都在 NOTICE 中有可验证来源和允许当前分发方式的许可；来源不明项为 0。
- [ ] AC-3：应用名、Logo 文案、资源/地形图形和界面布局符合 ADR-003 原创边界。
- [ ] AC-4：README/关于页明确这是非官方原创实现，且不以官方商标作为产品主名称。
- [ ] AC-5：规则说明使用原创概括，不包含大段官方文字；参考链接指向公开合法来源。
- [ ] AC-6：四位玩家和五类资源均有颜色之外的文本/形状区分。
- [ ] AC-7：键盘可完成创建/加入、核心回合按钮、交易、弃牌和强盗目标选择。
- [ ] AC-8：焦点可见、错误与连接状态有文本、关键文字对比度达到团队采用的 WCAG AA 检查标准。
- [ ] AC-9：200% 浏览器缩放下无阻断操作的内容丢失或不可达。
- [ ] AC-10：发布清单记录审查日期、范围、工具/人工结果和所有例外；P0/P1 例外为 0。
- [ ] AC-11：构建产物扫描与源仓库扫描结果一致，不从依赖或生成步骤意外带入品牌素材。
- [ ] AC-12：Reviewer 对 ADR-003 逐条签核后才能将任务设为 DONE。

## Architecture Constraints

- 相关 ADR：ADR-003（主要）、ADR-002。
- 仅允许小范围替换和修正；需要新品牌方向或大规模 UI 改动时设为 BLOCKED 并拆任务。
- 不在文档中给出法律保证；发布前商业用途需另行专业审查。

## Dependencies

- TASK-008、TASK-010、TASK-011 必须 DONE。

## Allowed / Expected Files

- assets/original/**
- apps/client 的视觉、文案与可访问性修正
- README.md、关于页
- docs/qa/** 或 docs/release/**
- 资产扫描/许可检查脚本与测试
- docs/tasks/TASK-012.md 的 Executor 区域

## Planner Notes

- 几何 SVG 若由项目自行创建，在 NOTICE 标明“project-authored”，保留源文件。
- npm 依赖自身包含图标不等于可以直接展示其品牌资产，审查实际构建输出。
- 若正式名称仍未确认，可用中性临时代号发布技术预览，但不能假装已有商标许可。

## Execution Log

- None.

## Problems

None.

## Test Results

### Automated

- Command: pending
- Result: NOT_RUN
- Notes: Executor 填写。

### Manual / Other Verification

- pending

### Not Run

- pending

## Review

**Reviewer:**  
**Result:** PENDING  
**Reviewed Commit/PR:**  

### Acceptance Review

- [ ] AC-1
- [ ] AC-2
- [ ] AC-3
- [ ] AC-4
- [ ] AC-5
- [ ] AC-6
- [ ] AC-7
- [ ] AC-8
- [ ] AC-9
- [ ] AC-10
- [ ] AC-11
- [ ] AC-12

### Review Notes

- pending

## Final Result

**Final Status:** PENDING  
**Merged PR:**  
**Merge Commit:**  
**Completed At:**  
**Summary:** pending
