# 架构设计 (ARCHITECTURE)

> 本文件定义项目分层、模块边界、扩展点与网络架构。
> 任何代码编写前必读。架构变更必须同步更新本文件。

---

## 1. 分层总则

项目严格分为 4 层，**依赖方向单向向下**：

```
┌─────────────────────────────────────────────┐
│  Layer 4: 表现层 (Presentation)              │  Godot Scenes / UI / 渲染
├─────────────────────────────────────────────┤
│  Layer 3: 网络层 (Network)                   │  Server / Client / RPC
├─────────────────────────────────────────────┤
│  Layer 2: 应用层 (Application / Game Flow)   │  回合状态机 / 事件分发
├─────────────────────────────────────────────┤
│  Layer 1: 核心层 (Core / Rules Engine)       │  纯逻辑，无 Node 依赖
└─────────────────────────────────────────────┘
```

### 1.1 依赖规则（硬约束）

- **Layer 1 不得依赖任何上层**：核心规则引擎是纯 GDScript `RefCounted`/`Object` 类，禁止继承 `Node`，禁止引用场景资源，禁止使用 `print` 之外的引擎副作用。
- **Layer 2 依赖 Layer 1**：通过调用核心 API 与订阅核心事件实现游戏流程。
- **Layer 3 依赖 Layer 1 + Layer 2**：网络层负责把客户端动作转发给权威核心，并把核心状态变更广播给客户端表现层。
- **Layer 4 仅依赖 Layer 2/3 的接口**：表现层不直接操作核心状态，只读取快照 + 发送动作请求。

### 1.2 为什么这样分

- **可测试性**：Layer 1 可在 GUT 中无场景实例化测试。
- **可替换性**：Layer 4 可从几何色块替换为精美素材而不动逻辑。
- **网络透明**：Layer 1 不知道自己跑在服务器还是客户端；同一份规则代码两端复用。
- **AI 复用**：AI 作为 Layer 2 的特殊"玩家控制器"，调用与人类相同的动作 API。

## 2. 目录结构

按游戏开发标准模式分门别类组织。**每类文件必须放入对应目录**，禁止散落。

```
/workspace/
├── docs/                          # 规格文档（本目录）
├── scripts/                       # 工具脚本（CI、构建等，非 Godot 资源）
│   └── run_tests.sh
└── project/                       # Godot 工程根
    ├── project.godot
    ├── icon.svg
    ├── .gutconfig.json
    ├── addons/                    # 第三方插件（GUT 等，不修改）
    │   └── gut/
    ├── data/                      # 数据驱动资源（规则数据，JSON）
    │   ├── .gdignore              # 阻止 Godot 扫描数据文件
    │   ├── terrains.json          # 地形定义
    │   ├── buildings.json         # 建筑成本与效果
    │   ├── dev_cards.json         # 发展卡定义
    │   ├── ports.json             # 港口定义
    │   └── scenarios/             # 场景布局数据
    │       ├── base_4p.json
    │       ├── seafarers_new_world.json
    │       └── seafarers_desert.json
    ├── assets/                    # 美术与音频资源（按类型细分）
    │   ├── sprites/               # 精灵图
    │   │   ├── terrain/           # 地形六边形贴图
    │   │   ├── buildings/         # 建筑（定居点/城市/道路/船只）
    │   │   ├── cards/             # 资源卡/发展卡图面
    │   │   └── icons/             # UI 图标（骰子/港口/按钮）
    │   ├── audio/
    │   │   ├── music/             # 背景音乐
    │   │   └── sfx/               # 音效（掷骰/建造/交易）
    │   ├── fonts/                 # 字体
    │   ├── themes/                # UI 主题资源（.tres）
    │   └── shaders/               # 着色器
    ├── scenes/                    # 场景文件（.tscn，按用途细分）
    │   ├── main/                  # 主入口场景
    │   ├── board/                 # 棋盘相关场景
    │   └── ui/                    # UI 场景（HUD/对话框/结算）
    ├── src/                       # 源码（按层分，见 §1 分层）
    │   ├── autoload/              # 全局单例（Paths 等仅承载常量/注册表）
    │   │   └── paths.gd
    │   ├── core/                  # Layer 1: 规则引擎（纯逻辑，无 Node）
    │   │   ├── board.gd
    │   │   ├── hex.gd
    │   │   ├── player_state.gd
    │   │   ├── game_state.gd
    │   │   ├── rules_engine.gd
    │   │   ├── result.gd
    │   │   ├── data_loader.gd
    │   │   ├── actions/           # 动作定义（命令模式）
    │   │   │   ├── action.gd
    │   │   │   ├── build_action.gd
    │   │   │   ├── trade_action.gd
    │   │   │   └── ...
    │   │   ├── events/            # 事件定义
    │   │   └── data/              # 数据加载与数据对象
    │   ├── app/                   # Layer 2: 游戏流程
    │   │   ├── turn_fsm.gd
    │   │   ├── game_session.gd
    │   │   └── event_bus.gd
    │   ├── net/                   # Layer 3: 网络
    │   │   ├── server.gd
    │   │   ├── client.gd
    │   │   ├── protocol.gd
    │   │   └── ai_player.gd
    │   └── ui/                    # Layer 4: 表现（脚本，场景在 scenes/）
    │       ├── board_view.gd
    │       ├── hud.gd
    │       └── trade_dialog.gd
    └── tests/                     # GUT 测试
        ├── fixtures/              # 测试数据
        ├── unit/                  # 单元测试（镜像 src/ 结构）
        │   └── core/
        └── integration/           # 集成测试
```

### 2.1 文件归属规则（强制）

| 文件类型 | 必须放入 | 说明 |
|----------|----------|------|
| 规则数据 JSON | `data/` | terrains/buildings/dev_cards/ports |
| 场景布局 JSON | `data/scenarios/` | 各场景地形/数字/港口布局 |
| 精灵图 PNG/SVG | `assets/sprites/<子类>/` | 按 terrain/buildings/cards/icons 细分 |
| 音乐 OGG/MP3 | `assets/audio/music/` | 背景音乐 |
| 音效 WAV/OGG | `assets/audio/sfx/` | 短音效 |
| 字体 TTF/OTF | `assets/fonts/` | |
| UI 主题 .tres | `assets/themes/` | |
| 着色器 .gdshader | `assets/shaders/` | |
| 场景 .tscn | `scenes/<子类>/` | main/board/ui |
| GDScript 源码 | `src/<层>/` | 按分层归属 |
| 测试脚本 | `tests/unit/` 或 `tests/integration/` | 镜像 src/ 结构 |
| 测试数据 | `tests/fixtures/` | |
| 工具脚本 .sh/.py | `scripts/` | 非 Godot 资源 |
| 规格文档 .md | `docs/` | |

### 2.2 命名补充

- 场景文件：`<用途>.tscn`，如 `board_view.tscn`、`trade_dialog.tscn`
- 场景脚本与场景同名放 `src/ui/`，如 `board_view.gd` 对应 `scenes/board/board_view.tscn`
- 资源文件：`snake_case` 扩展名，如 `terrain_mountain.svg`、`sfx_dice_roll.wav`

## 3. 核心层设计 (Layer 1)

### 3.1 棋盘拓扑 (Board)

- 使用轴向坐标系 (axial coordinates q, r) 表示六边形
- 顶点与边用独立 ID 索引，预计算邻接关系
- `Board` 类提供查询：`get_hex(q,r)`、`get_vertex(id)`、`get_edge(id)`、`neighbors(hex)`、`vertex_edges(v)` 等
- **拓扑与规则解耦**：Board 只描述几何关系，不知道"定居点"概念

### 3.2 动作系统 (Command Pattern)

所有状态变更通过 `Action` 对象表达：

```gdscript
# 伪代码示意
class_name BuildAction extends Action
var building_type: StringName  # "settlement" | "city" | "road" | "ship"
var position_id: int
var player_id: int
```

- `RulesEngine.validate(action, state) -> Result`：纯校验，不改状态
- `RulesEngine.apply(action, state) -> Event[]`：执行并返回产生的事件列表
- **不可变状态原则**：`apply` 返回新状态或事件流，便于网络同步与回放

### 3.3 事件系统

- 核心产出 `Event` 对象（资源产出、建筑建成、强盗移动等）
- Layer 2 事件总线订阅分发
- 网络层序列化事件广播
- 表现层监听事件刷新视图

### 3.4 数据驱动加载

- `DataLoader` 在启动时读取 `data/*.json`，构建只读数据对象
- 规则代码引用数据对象，不引用字面量
- 示例：`Buildings.get_cost("settlement")` 而非硬编码 `{wood:1, brick:1, ...}`

## 4. 应用层设计 (Layer 2)

### 4.1 回合状态机 (Turn FSM)

状态：`SETUP_PHASE_1` → `SETUP_PHASE_2` → `ROLL` → `ACTION` → `END_TURN` → (下一位)

- 每个状态定义合法动作集合
- 非法动作在 Layer 1 校验阶段被拒
- 状态转移由事件触发

### 4.2 游戏会话 (GameSession)

- 持有 `GameState` 与 `RulesEngine` 实例
- 对外暴露 `submit_action(action)` 接口
- 是网络层与表现层的统一交互点

## 5. 网络层设计 (Layer 3)

### 5.1 权威服务器模型

```
[Client A] ──action──▶ [Server (权威)]
[Client B] ──action──▶   │ 校验 + apply
[Client C] ──action──▶   │
                         ▼
                   [GameState]
                         │
              ┌──────────┴──────────┐
              ▼                     ▼
        state snapshot        event broadcast
              ▼                     ▼
        [Client A/B/C]       [Client A/B/C]
```

- **服务器持有唯一权威 `GameState`**
- 客户端发送 `Action`，服务器校验后 apply
- 服务器广播 `Event` 流（增量）或定期 `Snapshot`（全量）
- 客户端维护本地"预测状态"用于即时反馈，收到权威事件后对账

### 5.2 协议设计

- 使用 Godot RPC + 自定义序列化
- 消息类型：`JOIN`、`ACTION`、`EVENT`、`SNAPSHOT`、`LEAVE`
- **协议必须版本化**（`protocol_version` 字段），不匹配拒绝连接

### 5.3 断线重连

- 服务器保留玩家会话 N 分钟（可配置）
- 重连后推送完整 `SNAPSHOT` 恢复
- 超时则该玩家转为 AI 接管或踢出（策略可配置）

### 5.4 AI 玩家接入

- `AIPlayer` 实现 `IPlayerController` 接口（与人类客户端相同接口）
- 可运行在服务器进程内（减少延迟）或作为独立客户端
- 策略通过 `IAIStrategy` 接口注入，便于扩展多种 AI

## 6. 表现层设计 (Layer 4)

### 6.1 视图与状态分离

- `BoardView` 监听事件总线，根据 `GameState` 快照渲染
- 用户输入转换为 `Action` 提交给 `GameSession`，不直接改状态
- 几何色块主题通过 `Theme` 资源切换，便于后续替换素材

### 6.2 即时反馈

- 客户端可对自身合法动作做乐观预测渲染
- 收到权威事件后必须对账，丢弃错误预测

## 7. 扩展点 (Extensibility Points)

以下扩展点必须以接口形式预留，新增内容通过注册接入，**不得修改核心主流程**：

| 扩展点 | 接口 | 扩展方式 |
|--------|------|----------|
| 新地形类型 | `ITerrainType` | 数据文件 + 产出规则注册 |
| 新建筑类型 | `IBuildingType` | 数据文件 + 校验规则注册 |
| 新发展卡 | `IDevCardEffect` | 脚本注册到 DevCardRegistry |
| 新场景 | 场景数据文件 | 放入 `data/scenarios/` 即可被选择 |
| 新 AI 策略 | `IAIStrategy` | 注册到 AIStrategyRegistry |
| 新规则变体 | `IRuleVariant` | 注册到 RuleVariantRegistry（如 5-6 人扩展） |
| 新网络传输 | `ITransport` | ENet/WebSocket 之外的实现 |

### 7.1 注册表模式

- 所有扩展点使用 `Registry` 单例（autoload）
- 核心代码通过 Registry 查询，不直接 `if type == "xxx"`
- 启动时各模块向 Registry 注册自身

## 8. 状态同步策略

- **回合制优势**：无需插值/回滚，状态变更离散
- 默认采用 **事件增量广播** + **周期快照校正**
- 关键节点（回合开始、阶段切换）强制推送快照
- 客户端本地状态 = 快照 + 重放事件

## 9. 错误处理与日志

- Layer 1 返回 `Result` 对象（`ok`/`err` + 原因码），不抛异常
- Layer 2/3 记录结构化日志（玩家 ID、动作、结果）
- 网络层错误码标准化，客户端可本地化展示

## 10. 性能与边界

- 单局状态变更频率低（回合制），性能非首要瓶颈
- 状态序列化须控制体积（事件流优先于全量快照）
- AI 决策须有思考时间上限（避免阻塞服务器），默认 ≤2s/动作

## 11. 架构变更流程

1. 在本文件提出变更并说明动机
2. 评估对既有测试的影响
3. 更新受影响的模块
4. 全量测试通过后合并
5. 在 [PROGRESS.md](05_PROGRESS.md) 记录架构变更条目
