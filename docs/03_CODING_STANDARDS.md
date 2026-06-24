# 编码规范 (CODING_STANDARDS)

> 本文件规定 GDScript 代码风格、命名、文件组织与质量要求。
> 所有提交代码必须符合本规范。CI 须配置静态检查拦截违规。

---

## 1. 总则

- 以 [Godot 官方 GDScript 风格指南](https://docs.godotengine.org/en/stable/tutorials/scripting/gdscript/gdscript_styleguide.html) 为基线
- 本文件未覆盖处，以官方指南为准；本文件覆盖处，以本文件为准
- **类型注解强制**：所有变量、参数、返回值必须有静态类型
- **静态类型优先**：使用 `:=` 推断时仍须可推断出类型，否则显式标注

## 2. 文件与类

### 2.1 文件命名
- `snake_case.gd`
- 一个文件一个 `class_name`（核心层强制；表现层节点脚本可省略）
- 文件名与 `class_name` 一致：`rules_engine.gd` → `class_name RulesEngine`

### 2.2 类声明顺序（强制）
```gdscript
class_name Foo extends RefCounted  # 或 Object / Node

# 1. 信号
signal something_happened(value: int)

# 2. 常量与枚举
const MAX_PLAYERS: int = 4
enum State { ROLL, ACTION, END }

# 3. 导出属性（仅 Node）
@export var speed: float = 1.0

# 4. 公共变量
var public_field: int = 0

# 5. 私有变量（_ 前缀）
var _internal: int = 0

# 6. 静态变量
static var s_counter: int = 0

# 7. 内置虚方法 / 生命周期
func _init() -> void: pass
func _ready() -> void: pass

# 8. 公共方法
func do_something(x: int) -> bool: return true

# 9. 私有方法
func _helper() -> void: pass

# 10. 静态方法
static func create() -> Foo: return Foo.new()
```

## 3. 命名约定

| 类别 | 风格 | 示例 |
|------|------|------|
| 类 / class_name | PascalCase | `RulesEngine` |
| 变量 / 函数 | snake_case | `apply_action` |
| 常量 | SCREAMING_SNAKE | `MAX_PLAYERS` |
| 枚举值 | SCREAMING_SNAKE | `State.ROLL` |
| 信号 | snake_case 过去式 | `turn_ended` |
| 私有成员 | `_` 前缀 | `_internal_state` |
| 信号回调 | `_on_<node>_<signal>` | `_on_button_pressed` |
| 布尔变量 | `is_`/`has_`/`can_` 前缀 | `is_current_player` |
| 接口（约定） | `I` 前缀 PascalCase | `IAIStrategy` |

### 3.1 禁止
- 匈牙利记号（`strName`、`intCount`）
- 单字母变量（循环索引 `i/j/k` 除外）
- 缩写（除领域通用：`hex`、`id`、`rpc`）

## 4. 类型与空值

- 禁止无类型 `var x`，必须 `var x: int` 或 `var x := 0`
- 可空引用用 `Variant` 或显式 `null` 检查，并在文档注释说明
- 集合指定元素类型：`var players: Array[PlayerState] = []`
- 字典键值类型注释：`var costs: Dictionary = {} # StringName -> int`

## 5. 函数

- 参数与返回值必须标注类型
- 单一职责，建议 ≤40 行；超过须拆分并说明
- 纯函数（无副作用）优先，尤其在 Layer 1
- **Layer 1 函数禁止 `print`**，错误通过 `Result` 返回

### 5.1 Result 模式（Layer 1 强制）
```gdscript
class_name Result extends RefCounted
var ok: bool
var error_code: int
var error_message: String
var value: Variant

static func success(v: Variant = null) -> Result: ...
static func failure(code: int, msg: String) -> Result: ...
```

## 6. 信号与事件

- Layer 1 不使用 Godot `signal`（避免 Node 依赖），改用自定义事件总线或回调
- Layer 2+ 可使用 `signal`
- 信号携带数据用强类型参数：`signal resource_produced(player_id: int, resource: StringName, amount: int)`

## 7. 注释与文档

### 7.1 必须文档化的对象
- 所有公共类（`##` 文档注释置于 class_name 上方）
- 所有公共函数
- 所有公共常量与枚举
- 所有扩展点接口

### 7.2 文档注释格式
```gdscript
## 校验并执行一个动作。
## [param action] 待执行动作
## [param state] 当前游戏状态
## [return] Result，成功时 value 为产生的事件数组
func apply_action(action: Action, state: GameState) -> Result:
```

### 7.3 禁止
- 无信息量注释（`# 设置 x 为 0` 紧跟 `x = 0`）
- 注释掉的死代码（直接删除）
- TODO 不带责任人或 issue 编号；TODO 须格式 `TODO(name): 描述`

## 8. 错误处理

- Layer 1：返回 `Result`，不 `push_error`、不 `assert`（测试中可用 assert）
- Layer 2/3：可 `push_error` 记录，但不得吞异常
- 输入校验在边界（网络入口、UI 入口）做一次，内部信任已校验数据
- 禁止空 `catch`/忽略错误码

## 9. 文件组织与依赖

- 严格遵循 [ARCHITECTURE.md](02_ARCHITECTURE.md) 分层依赖方向
- 禁止循环依赖；必要时引入接口或事件解耦
- `class_name` 全局可见，谨慎命名避免冲突
- `preload` 用于本模块内资源；跨模块用 `class_name` 引用

## 10. 资源与数据

- 数据文件统一 JSON（人类可读、易 diff）
- Godot 资源 `.tres` 用于强类型场景配置
- 美术资源放 `assets/`，按主题子目录组织
- 禁止在脚本中硬编码路径字符串字面量散落；集中到 `paths.gd` 常量

## 11. Git 提交规范

- 提交信息格式：`<type>(<scope>): <subject>`
  - type: `feat`/`fix`/`refactor`/`test`/`docs`/`chore`/`perf`
  - scope: 模块名（`core`/`net`/`ui`/`rules`...）
  - subject: 祈使句，≤50 字
- 示例：`feat(core): 实现定居点建造校验`
- 单次提交只做一件事；混合改动须拆分
- 提交前必须本地跑通全部测试

## 12. 禁止清单

- 禁止 `eval`、动态字符串执行
- 禁止全局可变单例承载游戏状态（autoload 仅用于注册表/配置）
- 禁止在 Layer 1 引入 `Node`/场景依赖
- 禁止魔法数字；常量集中定义
- 禁止复制粘贴超过 3 处的重复代码（须抽象）
- 禁止未类型化的 `var`、未文档化的公共 API
- 禁止为实现便利而绕过测试（如临时 `if OS.is_debug_build()` 跳过校验）

## 13. 审查清单 (PR Checklist)

提交前自检：

- [ ] 类型注解完整
- [ ] 公共 API 有文档注释
- [ ] 无 Layer 1 向上依赖
- [ ] 无硬编码规则数据
- [ ] 新增/修改功能有对应测试且通过
- [ ] 既有测试全绿
- [ ] 提交信息符合规范
- [ ] 未引入 OUT OF SCOPE 内容
- [ ] [PROGRESS.md](05_PROGRESS.md) 已更新（如涉及进度）
