# 开发进度追踪 (PROGRESS)

> 本文件是开发进度的唯一权威记录。每次 AI 会话开始时阅读当前状态，结束时更新。
> **未在本文件登记的功能视为未完成。** 状态变更必须真实反映测试结果。

---

## 0. 状态图例

| 标记 | 含义 |
|------|------|
| ⬜ | 未开始 |
| 🔄 | 进行中 |
| ✅ | 已完成（测试通过 + 文档同步） |
| ⛔ | 阻塞（须在"阻塞说明"列说明） |
| ⏭️ | 跳过/延后（须经所有者确认） |

## 1. 阶段总览

| 阶段 | 名称 | 状态 | 依赖 |
|------|------|------|------|
| P0 | 项目脚手架与工具链 | ✅ | — |
| P1 | 核心层数据模型 | ✅ | P0 |
| P2 | 棋盘拓扑与生成 | ✅ | P1 |
| P3 | 规则引擎：动作系统 | ✅ | P2 |
| P4 | 规则引擎：基础建造与产出 | ✅ | P3 |
| P5 | 规则引擎：交易 | ✅ | P4 |
| P6 | 规则引擎：发展卡 | ✅ | P4 |
| P7 | 规则引擎：强盗与成就 | ✅ | P4 |
| P8 | 应用层：回合状态机 | ✅ | P3-P7 |
| P9 | 表现层：本地渲染（热座可玩） | ✅ | P8 |
| P10 | 海洋扩展：船只与场景 | ⬜ | P9 |
| P11 | 网络层：联机对战 | ⬜ | P9 |
| P12 | AI 对手 | ⬜ | P11 |
| P13 | 打磨：存档/UX/平衡 | ⬜ | P12 |

> **顺序约束**：P1-P8 是规则引擎与应用层，必须先于 P9 完成。P9 是"本地可玩"里程碑。P10/P11 可并行，但 P11 依赖 P9 的表现层抽象稳定。

## 2. 阶段详细任务

### P0 — 项目脚手架与工具链
**目标**：可运行、可测试的空工程骨架。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P0-1 | 初始化 Godot 4.x 工程 | ✅ | — | Godot 4.3 stable，project.godot 配置完成 |
| P0-2 | 集成 GUT 测试框架 | ✅ | example_test.gd (4/4) | GUT 9.4.0（见 ADR-006） |
| P0-3 | 建立目录结构（见 ARCHITECTURE §2） | ✅ | — | src/{core,app,net,ui,autoload} + data + tests |
| P0-4 | 配置 Git 与 .gitignore | ✅ | — | 仓库已 init |
| P0-5 | 编写 CI 脚本（headless 跑 GUT） | ✅ | CI 跑通 | scripts/run_tests.sh，21 测试全绿 |
| P0-6 | 数据加载器骨架 + paths.gd | ✅ | data_loader_test.gd (10/10) | 含 Result 最小骨架（P1-1 扩展） |

**出口标准**：`godot --headless` 跑 GUT 返回 0；21 测试 / 40 断言全绿。✅ 达成

---

### P1 — 核心层数据模型
**目标**：纯逻辑层表达玩家、资源、状态，无 Node 依赖。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P1-1 | Result 类 | ✅ | result_test.gd (12/12) | 扩展至 22 个错误码 + 分类查询 + 名称查询 |
| P1-2 | 资源类型枚举与数据 | ✅ | resource_test.gd (23/23) | ResType + ResourceSet（避开 Godot 内置 ResourceType） |
| P1-3 | PlayerState 类 | ✅ | player_state_test.gd (30/30) | 手牌/建筑/发展卡/胜利点/成就/弃半/clone |
| P1-4 | GameState 类 | ✅ | game_state_test.gd (30/30) | 玩家/回合/银行/牌堆/强盗/胜利判定/clone |
| P1-5 | 数据文件：terrains/buildings/dev_cards/ports | ✅ | data_objects_test.gd (16/16) | 4 个 JSON + 4 个数据对象类 |
| P1-6 | DataLoader 加载与校验 | ✅ | data_loader_extended_test.gd (12/12) | 4 个强类型加载方法 + 结构校验 |

**出口标准**：核心数据模型单元测试全绿；可在无场景下实例化。✅ 达成（137 测试 / 303 断言）

---

### P2 — 棋盘拓扑与生成
**目标**：六边形/顶点/边拓扑 + 随机生成。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P2-1 | Hex 坐标系与几何 | ✅ | hex_coord_test.gd (8/8) | axial 坐标 + 距离 + 像素转换 |
| P2-2 | Board 拓扑（顶点/边邻接） | ✅ | board_test.gd (16/16) | 顶点/边归一化键 |
| P2-3 | 基础版布局生成器 | ✅ | board_test.gd | 19 格分布 |
| P2-4 | 数字牌分布（含平衡约束） | ✅ | board_test.gd | 6/8 不相邻 |
| P2-5 | 港口分布 | ✅ | board_test.gd | 9 个港口 |
| P2-6 | 随机种子可复现 | ✅ | board_test.gd | 种子复现 |

**出口标准**：给定种子可生成确定性棋盘；拓扑查询全部正确。✅ 达成

---

### P3 — 规则引擎：动作系统
**目标**：Action 命令模式 + validate/apply 框架。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P3-1 | Action 基类与子类骨架 | ✅ | action_test.gd (12/12) | 7 种 Action 类型 |
| P3-2 | RulesEngine.validate 框架 | ✅ | rules_engine_test.gd | 通用校验 + 分发 |
| P3-3 | RulesEngine.apply + 事件产出 | ✅ | rules_engine_test.gd | 不可变状态变更 |
| P3-4 | Event 类型定义 | ✅ | event_test.gd (14/14) | 13 种事件 |

**出口标准**：空动作可走完 validate→apply→event 链路。✅ 达成

---

### P4 — 规则引擎：基础建造与产出
**目标**：道路/定居点/城市/发展卡购买 + 掷骰产出。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P4-1 | 建造成本校验 | ✅ | rules_engine_test.gd | 数据驱动 |
| P4-2 | 道路建造校验（连接性） | ✅ | rules_engine_test.gd | |
| P4-3 | 定居点建造校验（距离规则） | ✅ | rules_engine_test.gd | |
| P4-4 | 城市升级校验 | ✅ | rules_engine_test.gd | |
| P4-5 | 掷骰产出逻辑 | ✅ | rules_engine_test.gd | 含强盗压制 |
| P4-6 | 初始放置阶段逻辑 | ✅ | rules_engine_test.gd | 双轮 + 初始资源 |

**出口标准**：基础版建造与产出规则测试全绿（对照 GAME_RULES §4-7）。✅ 达成

---

### P5 — 规则引擎：交易
**目标**：玩家间/银行/港口交易。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P5-1 | 银行 4:1 交易 | ✅ | rules_engine_test.gd | |
| P5-2 | 港口 3:1 / 2:1 交易 | ✅ | rules_engine_test.gd | 归属校验 |
| P5-3 | 玩家间交易协议 | ✅ | rules_engine_test.gd | 双方确认 |
| P5-4 | 资源耗尽处理 | ✅ | rules_engine_test.gd | |

---

### P6 — 规则引擎：发展卡
**目标**：5 种发展卡效果。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P6-1 | 发展卡购买与抽牌堆 | ✅ | rules_engine_test.gd | |
| P6-2 | 当回合不可用规则 | ✅ | rules_engine_test.gd | dev_cards_bought_this_turn |
| P6-3 | 骑士卡 | ✅ | rules_engine_test.gd | 触发强盗 |
| P6-4 | 胜利点卡（隐藏） | ✅ | rules_engine_test.gd | |
| P6-5 | 道路建设卡 | ✅ | rules_engine_test.gd | |
| P6-6 | 发明卡 | ✅ | rules_engine_test.gd | year_of_plenty |
| P6-7 | 垄断卡 | ✅ | rules_engine_test.gd | monopoly |

---

### P7 — 规则引擎：强盗与成就
**目标**：强盗机制 + 最长道路/最大军队。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P7-1 | 7 点强盗触发 | ✅ | rules_engine_test.gd | |
| P7-2 | 手牌弃半 | ✅ | rules_engine_test.gd | 奇数向下 |
| P7-3 | 强盗移动与偷取 | ✅ | rules_engine_test.gd | |
| P7-4 | 最长道路计算（含断链） | ✅ | rules_engine_test.gd | DFS + 对手定居点断链 |
| P7-5 | 最大军队计算 | ✅ | rules_engine_test.gd | |
| P7-6 | 胜利条件判定 | ✅ | rules_engine_test.gd | 10 点 + 隐藏 |

**出口标准**：基础版规则引擎完整，可模拟整局（无 UI）。✅ 达成

---

### P8 — 应用层：回合状态机
**目标**：TurnFSM + GameSession + EventBus。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P8-1 | TurnFSM 状态转移 | ✅ | turn_fsm_test.gd (15/15) | 8 个状态 + 允许动作 |
| P8-2 | GameSession 动作提交 | ✅ | game_session_test.gd (14/14) | 持有 GameState + 历史记录 |
| P8-3 | EventBus 订阅分发 | ✅ | event_bus_test.gd (10/10) | 订阅/全局/取消/计数 |
| P8-4 | 完整对局模拟（无 UI） | ✅ | e2e_simulated_game_test.gd (1/1) | 端到端 AI 对局 |

**出口标准**：可在无渲染下跑完一局模拟对局并判定胜利。✅ 达成

---

### P9 — 表现层：本地渲染（热座可玩）
**目标**：几何色块 UI，本地热座可玩通一局。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P9-1 | BoardView 渲染 | ✅ | ui_smoke_test.gd | 六边形/地形/数字牌/港口/建筑/强盗 |
| P9-2 | 建筑放置交互 | ✅ | ui_smoke_test.gd | 顶点/边点击 + 高亮合法位置 |
| P9-3 | 资源卡/HUD | ✅ | ui_smoke_test.gd | 资源/VP/建筑库存/回合信息 |
| P9-4 | 交易对话框 | ✅ | ui_smoke_test.gd | 银行 4:1 / 港口 / 玩家间 |
| P9-5 | 发展卡手牌 UI | ✅ | ui_smoke_test.gd | 手牌分组显示 + 使用按钮 |
| P9-6 | 骰子动画 | ✅ | ui_smoke_test.gd | 骰子点数显示 |
| P9-7 | 胜利结算界面 | ✅ | ui_smoke_test.gd | 获胜者 + 排名 + 得分明细 |
| P9-8 | 热座玩家切换 | ✅ | ui_smoke_test.gd | 全屏遮罩 + 玩家确认 |

**出口标准**：4 人本地热座可玩通完整基础版对局。✅ 达成（283 测试 / 685 断言全绿）**（里程碑 M1：本地可玩）**

---

### P10 — 海洋扩展：船只与场景
**目标**：船只机制 + 2 个海洋场景。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P10-1 | 海洋地形数据 | ⬜ | terrain_data_test | |
| P10-2 | 船只建造校验 | ⬜ | ship_build_test | |
| P10-3 | 船只移动逻辑 | ⬜ | ship_move_test | |
| P10-4 | 黄金地形产出 | ⬜ | gold_terrain_test | |
| P10-5 | 场景数据格式 + 加载 | ⬜ | scenario_load_test | |
| P10-6 | 场景 A: The New World | ⬜ | scenario_a_test | |
| P10-7 | 场景 B: Into the Desert | ⬜ | scenario_b_test | |
| P10-8 | 最长道路含船只 | ⬜ | longest_road_ship_test | |

**出口标准**：海洋扩展 2 场景可玩通。

---

### P11 — 网络层：联机对战
**目标**：服务器权威联机，3-4 人房间。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P11-1 | 协议定义与序列化 | ⬜ | protocol_test | 版本化 |
| P11-2 | Server 权威循环 | ⬜ | server_test | mock transport |
| P11-3 | Client 动作提交 + 事件接收 | ⬜ | client_test | |
| P11-4 | 房间创建/加入 | ⬜ | room_test | |
| P11-5 | 状态快照广播 | ⬜ | snapshot_test | |
| P11-6 | 断线重连 | ⬜ | reconnect_test | |
| P11-7 | 乐观预测与对账 | ⬜ | reconciliation_test | |
| P11-8 | 多客户端集成对局 | ⬜ | e2e_net_game_test | |

**出口标准**：3-4 客户端联机玩通一局。**（里程碑 M2：联机可玩）**

---

### P12 — AI 对手
**目标**：中等难度 AI 策略。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P12-1 | IPlayerController 接口 | ⬜ | controller_test | |
| P12-2 | AIPlayer 适配器 | ⬜ | ai_player_test | |
| P12-3 | IAIStrategy 接口 + Registry | ⬜ | strategy_registry_test | |
| P12-4 | 启发式策略 v1（建点/建路/换牌） | ⬜ | strategy_v1_test | |
| P12-5 | AI 决策时间上限 | ⬜ | ai_timeout_test | ≤2s |
| P12-6 | AI 接入联机房间 | ⬜ | ai_in_room_test | |

**出口标准**：1 人类 + 3 AI 可玩通一局。

---

### P13 — 打磨
**目标**：存档、UX、平衡微调。

| ID | 任务 | 状态 | 测试 | 备注 |
|----|------|------|------|------|
| P13-1 | 存档/读档 | ⬜ | save_load_test | |
| P13-2 | 设置（音效/规则开关） | ⬜ | — | |
| P13-3 | 规则开关（平衡约束等） | ⬜ | config_test | |
| P13-4 | 错误提示本地化框架 | ⬜ | — | i18n 扩展点 |
| P13-5 | 性能与体积优化 | ⬜ | — | |

---

## 3. 里程碑

| 里程碑 | 含义 | 对应阶段 |
|--------|------|----------|
| M0 | 工程可测试 | P0 |
| M1 | 本地热座可玩（基础版） | P9 |
| M2 | 联机可玩（基础版） | P11 |
| M3 | 海洋扩展可玩 | P10 |
| M4 | AI 对手可玩 | P12 |
| M5 | 打磨完成，正式自用版 | P13 |

## 4. 变更日志

记录规则/架构/范围变更。格式：`YYYY-MM-DD | 类型 | 描述 | 影响范围`

| 日期 | 类型 | 描述 | 影响 |
|------|------|------|------|
| 2026-06-24 | init | 初始规格建立 | 全部 |
| 2026-06-24 | feat | P0 完成：工程脚手架、GUT 9.4.0、DataLoader、Result 骨架 | P0 |
| 2026-06-24 | adr | ADR-006：GUT 锁定 9.4.0（9.5.0+ 引入 class_name 循环依赖，Godot 4.3 不支持） | 测试框架 |
| 2026-06-24 | refactor | 文件按游戏开发标准模式分门别类（assets/scenes/data/scripts 细分） | 目录结构 |
| 2026-06-24 | feat | P1 完成：核心数据模型（Result/ResType/ResourceSet/PlayerState/GameState + 4 数据对象 + 4 JSON） | P1 |
| 2026-06-24 | adr | ADR-007：资源类型类命名为 ResType 而非 ResourceType，避免与 Godot 内置枚举冲突 | 命名 |
| 2026-06-25 | feat | P2-P7 完成：棋盘拓扑/生成 + 规则引擎（动作/建造/交易/发展卡/强盗/成就） | P2-P7 |
| 2026-06-25 | feat | P8 完成：应用层（TurnFSM/GameSession/EventBus + 端到端模拟对局） | P8 |
| 2026-06-25 | feat | P9 完成：表现层（BoardView/HUD/TradeDialog/VictoryScreen/PlayerSwitch/GameController + 主场景 + 冒烟测试） | P9 |

## 5. 阻塞与风险登记

| ID | 描述 | 影响 | 缓解 | 状态 |
|----|------|------|------|------|
| R1 | Godot 4.x 高级多人 API 在 NAT 穿透需中继 | 联机体验 | P11 评估 WebSocket + 信令服务 | 开放 |
| R2 | 海洋扩展场景平衡需实测调参 | 可玩性 | 数据驱动便于迭代 | 开放 |

## 6. 会话记录格式

每次 AI 会话结束时追加：

```
## 会话 YYYY-MM-DD HH:MM
- 范围：P?-? 
- 完成任务：P?-? (✅), P?-? (✅)
- 新增测试：path/to/test.gd
- 遗留问题：...
- 下次建议：...
```

---

## 会话 2026-06-24 08:40
- 范围：P0-1 ~ P0-6
- 完成任务：P0-1 ✅, P0-2 ✅, P0-3 ✅, P0-4 ✅, P0-5 ✅, P0-6 ✅
- 新增测试：
  - `project/tests/unit/example_test.gd`（GUT 冒烟，4 测试）
  - `project/tests/unit/core/result_test.gd`（Result，7 测试）
  - `project/tests/unit/core/data_loader_test.gd`（DataLoader，10 测试）
- 新增源码：
  - `project/project.godot`、`project/icon.svg`
  - `project/src/autoload/paths.gd`
  - `project/src/core/result.gd`（最小骨架，P1-1 扩展）
  - `project/src/core/data_loader.gd`
- 测试结果：21 测试 / 40 断言全绿，退出码 0
- 工具链：Godot 4.3 stable + GUT 9.4.0
- 遗留问题：无
- 决策记录：ADR-006（GUT 锁定 9.4.0，因 9.5.0+ class_name 循环依赖与 Godot 4.3 不兼容）
- 下次建议：进入 P1，从 P1-1 扩展 Result 错误码体系开始，随后 P1-2 资源类型、P1-3 PlayerState、P1-4 GameState、P1-5 数据文件

---

## 会话 2026-06-24 09:30
- 范围：P1-1 ~ P1-6
- 完成任务：P1-1 ✅, P1-2 ✅, P1-3 ✅, P1-4 ✅, P1-5 ✅, P1-6 ✅
- 新增测试：
  - `project/tests/unit/core/result_test.gd`（扩展至 12 测试）
  - `project/tests/unit/core/resource_test.gd`（ResType + ResourceSet，23 测试）
  - `project/tests/unit/core/data_objects_test.gd`（4 数据对象 + 真实文件加载，16 测试）
  - `project/tests/unit/core/player_state_test.gd`（30 测试）
  - `project/tests/unit/core/game_state_test.gd`（30 测试）
  - `project/tests/unit/core/data_loader_extended_test.gd`（强类型加载，12 测试）
- 新增源码：
  - `project/src/core/result.gd`（扩展 22 错误码 + is_rule_error + error_name）
  - `project/src/core/resource_type.gd`（ResType 枚举）
  - `project/src/core/resource_set.gd`（ResourceSet 集合运算）
  - `project/src/core/terrain_def.gd`、`building_def.gd`、`dev_card_def.gd`、`port_def.gd`（4 数据对象）
  - `project/src/core/player_state.gd`（玩家状态）
  - `project/src/core/game_state.gd`（全局状态 + Phase 枚举）
  - `project/src/core/data_loader.gd`（扩展 4 个强类型加载方法）
- 新增数据文件：
  - `project/data/terrains.json`（9 种地形，含海洋扩展）
  - `project/data/buildings.json`（5 种建筑）
  - `project/data/dev_cards.json`（5 种发展卡，共 25 张）
  - `project/data/ports.json`（6 种港口，共 9 个）
- 测试结果：137 测试 / 303 断言全绿，退出码 0
- 决策记录：ADR-007（ResType 命名避开 Godot 内置 ResourceType 冲突）
- 遗留问题：无
- 下次建议：进入 P2 棋盘拓扑与生成，从 P2-1 Hex 坐标系开始

---

## 会话 2026-06-25
- 范围：P2-1 ~ P8-4
- 完成任务：P2 ✅, P3 ✅, P4 ✅, P5 ✅, P6 ✅, P7 ✅, P8 ✅
- 新增测试：
  - `project/tests/unit/core/hex_coord_test.gd`（8 测试）
  - `project/tests/unit/core/board_test.gd`（16 测试）
  - `project/tests/unit/core/action_test.gd`（12 测试）
  - `project/tests/unit/core/event_test.gd`（14 测试）
  - `project/tests/unit/core/rules_engine_test.gd`（约 50 测试，覆盖 P3-P7 全部规则）
  - `project/tests/unit/core/test_helper.gd`（测试辅助）
  - `project/tests/unit/app/turn_fsm_test.gd`（15 测试）
  - `project/tests/unit/app/event_bus_test.gd`（10 测试）
  - `project/tests/unit/app/game_session_test.gd`（14 测试）
  - `project/tests/integration/e2e_simulated_game_test.gd`（端到端模拟对局）
- 新增源码：
  - `project/src/core/hex_coord.gd`（六边形轴向坐标）
  - `project/src/core/board.gd`（棋盘拓扑 + 顶点/边归一化）
  - `project/src/core/board_generator.gd`（棋盘生成 + 种子复现）
  - `project/src/core/placement.gd`（建筑放置记录）
  - `project/src/core/event.gd`（13 种事件）
  - `project/src/core/actions/*.gd`（8 个 Action 文件）
  - `project/src/core/rules_engine.gd`（规则引擎核心：validate/apply + 所有规则）
  - `project/src/app/turn_fsm.gd`（回合状态机：8 个状态）
  - `project/src/app/event_bus.gd`（事件订阅/分发）
  - `project/src/app/game_session.gd`（会话管理：持有 GameState + EventBus）
- 测试结果：270 测试 / 643 断言全绿，退出码 0
- 关键设计：
  - 不可变状态变更（RulesEngine.apply 内部 clone）
  - 命令模式（Action 对象表达所有状态变更）
  - 事件驱动（RulesEngine 产出 Event 列表，EventBus 分发）
  - Placement 键前缀 `v:{id}` / `e:{id}` 避免顶点/边 ID 冲突
  - 顶点归一化用整数物理坐标 `(2q+r+dx, 3r+dy)` 避免浮点误差
  - SETUP 阶段双轮放置（正向 0→N-1，反向 N-1→0）
  - 最长道路 DFS（对手定居点/城市插入则断链）
- 遗留问题：无
- 下次建议：进入 P9 表现层，从 P9-1 BoardView 渲染开始

---

## 会话 2026-06-25 (P9)
- 范围：P9-1 ~ P9-8
- 完成任务：P9-1 ✅, P9-2 ✅, P9-3 ✅, P9-4 ✅, P9-5 ✅, P9-6 ✅, P9-7 ✅, P9-8 ✅
- 新增测试：
  - `project/tests/unit/ui/ui_smoke_test.gd`（UI 冒烟测试，13 测试）
- 新增源码：
  - `project/src/ui/theme_colors.gd`（颜色主题常量：地形/玩家/资源/UI）
  - `project/src/ui/board_view.gd`（棋盘视图：六边形/数字牌/港口/建筑/强盗渲染 + 点击交互）
  - `project/src/ui/hud.gd`（HUD：资源/VP/建筑库存/发展卡/动作按钮/骰子显示）
  - `project/src/ui/trade_dialog.gd`（交易对话框：银行 4:1 / 港口 3:1/2:1 / 玩家间）
  - `project/src/ui/player_switch.gd`（热座玩家切换遮罩）
  - `project/src/ui/victory_screen.gd`（胜利结算界面：排名 + 得分明细）
  - `project/src/ui/game_controller.gd`（游戏控制器：协调子视图 + 游戏流程）
  - `project/scenes/main/main.tscn`（主场景）
- 修改文件：
  - `project/project.godot`（配置 run/main_scene）
- 测试结果：283 测试 / 685 断言全绿，退出码 0
- 关键设计：
  - 表现层仅通过 GameSession.submit_action() 与逻辑层交互（ARCHITECTURE §6）
  - 几何色块渲染，无外部美术素材依赖
  - UIBuildMode 状态机管理建造/移动强盗等交互模式
  - 顶点/边点击转换为位置 ID，由 GameController 校验后提交动作
  - 热座模式：回合切换全屏遮罩，防止信息泄露
  - 弃牌/偷取简化处理（自动弃牌、自动偷取首位玩家）
- 遗留问题：
  - 发展卡使用（道路建设/发明/垄断）参数为简化默认值，后续可扩展选择 UI
  - 玩家间交易简化为与下一位玩家交易，未实现多方议价
- 下次建议：进入 P10 海洋扩展或 P11 网络层
