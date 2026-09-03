# ARCHITECTURE

> 权威职责：说明“系统应该如何设计”。由高阶 Planner 维护；重大长期改变应同时建立 ADR。

## Current Architecture Status

ACCEPTED_FOR_MVP

相关长期决策：

- ADR-001：权威服务端、命令协议、视图投影与恢复模型；
- ADR-002：TypeScript 单仓库技术栈与包边界；
- ADR-003：原创视觉与品牌隔离。

## Architecture Goals

1. 规则唯一：相同状态与命令只能得到一个服务端结果。
2. 秘密安全：玩家只能看到自己的手牌/未使用发展卡和允许公开的信息。
3. 可恢复：重复命令、短暂断线、页面刷新及服务重启不会破坏游戏。
4. 可测试：规则和随机算法不依赖网络、时钟、文件系统或 UI。
5. 可演进：规则、传输、客户端和存储有明确边界，不允许跨层“顺手修正”。
6. 可部署：一条本地启动流程即可供同一局域网设备访问。

## System Context

    Browser A ─┐
    Browser B ─┼─ WebSocket + HTTP ─> Authoritative Node Server ─> Versioned Local Snapshots
    Browser C ─┤                              │
    Browser D ─┘                              └─ Pure Domain Engine

信任边界：

- 浏览器是不可信输入方，只提交命令和展示投影。
- 服务端进程是唯一裁判，持有完整 GameState、随机源和秘密。
- 本地快照仅供服务端恢复，不直接由浏览器读取。
- 局域网不是绝对安全边界，因此仍需校验输入、隐藏令牌、限制来源和消息大小。

## Repository Shape

    apps/
      client/          React 浏览器客户端
      server/          HTTP、WebSocket、房间、会话、快照与启动入口
    packages/
      domain/          纯规则状态机、命令处理、地图、计分、投影
      protocol/        共享消息 schema、DTO、错误码和版本
      test-support/    场景构造器、确定性随机源、多客户端测试工具
    tests/
      e2e/             Playwright 多浏览器上下文测试
    assets/
      original/        原创或明确许可的源资产及许可说明
    data/               运行时本地快照；默认 gitignore
    docs/

不允许在 apps/client 复制一套“真正的规则”来决定动作合法性。客户端可做预测提示，但服务端响应始终覆盖预测。

## Components

| Component | Responsibility | Allowed Dependencies | Forbidden |
|---|---|---|---|
| domain/model | GameState、Board、Player、Bank、牌堆和值对象 | 仅 domain 内无副作用模块 | Socket、React、文件系统、系统时间 |
| domain/engine | 校验并应用命令，产生新状态和领域事件 | domain/model、注入的 RNG/clock | 直接发送网络消息或写盘 |
| domain/map | 六角拓扑、固定/随机布局、港口、种子算法 | 纯工具与 RNG 接口 | 浏览器随机数作为权威输入 |
| domain/scoring | 最长道路、最大骑士、胜利分计算 | domain/model | 缓存成为第二事实源 |
| domain/projection | 从完整状态生成公开视图和单玩家私有视图 | domain/model | 泄露他人牌面、令牌、牌堆顺序 |
| protocol | 命令、事件、快照和错误的运行时 schema | schema 库 | 业务状态变更 |
| server/room | 房间生命周期、座位、commandId 幂等、revision、广播 | domain、protocol | 接受客户端声明的资源或骰子结果 |
| server/session | 房间码、playerId、重连令牌校验、连接替换 | protocol、加密哈希工具 | 把令牌写入广播/普通日志 |
| server/snapshot | 版本化快照、原子写入、恢复和隔离损坏文件 | server adapter、序列化 schema | 修改领域规则 |
| client/state | 收取投影、连接状态、命令 pending/error | protocol | 保存其他玩家秘密或自行提交状态 |
| client/ui | 大厅、棋盘、手牌、交易、建造、强盗、终局体验 | client/state、原创视觉 | 官方品牌/美术资产 |
| test-support | 固定 RNG、场景 DSL、协议和多客户端测试工具 | domain、protocol | 成为生产状态依赖 |

## Domain State

GameState 至少包含：

- schemaVersion、gameId、rulesetVersion、revision、status；
- roomConfig：seatCount、mapMode、mapSeed；
- players：稳定 playerId、seat、昵称、颜色、连接状态之外的游戏数据；
- board：hex、vertex、edge、port 的稳定 ID 与邻接关系；
- bank：五类资源余量、道路/聚落/城市库存、发展牌堆；
- turn：当前座位、回合号、phase、是否已掷骰、当回合发展卡使用记录；
- pendingAction：弃牌集合、强盗移动/偷取、自由道路、丰收资源等子流程；
- awards：最长道路持有者与长度、最大骑士持有者与已打出数量；
- publicLog：去除秘密的领域事件摘要；
- serverOnly：幂等命令结果缓存、完整秘密和快照元数据。

资源种类使用中性内部枚举，例如 BRICK、LUMBER、WOOL、GRAIN、ORE；UI 名称和图形由原创主题映射。

## Board and Map Invariants

- 基础岛含 19 个陆地六角：4 林地、4 牧地、4 农田、3 丘陵、3 山地、1 沙漠。
- 数字分布为 2/12 各 1 个；3/4/5/6/8/9/10/11 各 2 个；沙漠无数字。
- 港口共 9 个：5 个资源专港和 4 个通用港，均绑定两个海岸顶点。
- 固定地图用仓库中明确坐标和种子版本的原创数据文件表示，不依赖截图解析。
- 随机地图同一种子和 rulesetVersion 必须生成同一结果；默认约束相邻六角不得同时为 6/8。
- 顶点和边使用规范化 ID；所有客户端使用服务端下发的拓扑，不各自重算另一套 ID。
- 强盗初始位于沙漠。

## Rules State Machine

主要状态：

    LOBBY
      -> SETUP_FORWARD
      -> SETUP_REVERSE
      -> TURN_BEFORE_ROLL
      -> ROLL_RESOLUTION
          -> ROBBER_DISCARD -> ROBBER_MOVE -> ROBBER_STEAL
          -> TURN_ACTIONS
      -> TURN_BEFORE_ROLL (next player)
      -> FINISHED

允许在自己回合、尚未使用发展卡时，于掷骰前或行动阶段进入相应发展卡子流程。每个 pendingAction 必须显式记录允许的下一组命令，不能用 UI 顺序代替服务端约束。

## Core Rule Invariants

### Setup

- 服务端确定首位玩家和顺时针顺序；第一轮正序，第二轮反序。
- 每次放置聚落后必须放一条与该聚落相连的道路。
- 初始聚落仍遵守距离规则；初始道路无需连接既有网络。
- 第二个初始聚落放置后，玩家从其每个相邻非沙漠地形获得 1 张对应资源，受银行库存约束。

### Turn and Production

- 每回合通常只允许当前玩家掷一次骰；骰子由服务端 RNG 生成两个 1–6 值。
- 非 7 点时，未被强盗阻挡且数字命中的六角向相邻聚落产 1、城市产 2。
- 每类资源分别处理短缺：若多个玩家应得总量超过银行库存，则该类无人获得；若只有一个玩家应得但库存不足，该玩家获得该类全部剩余卡。
- 公开事件可显示骰点和各玩家获得的资源张数，但不显示具体种类给无权玩家，除非产品决定公开该信息。

### Seven and Robber

- 掷出 7 时，手牌总数大于 7 的玩家必须弃掉向下取整的一半；所有需弃牌玩家完成前不可交易、建造或移动强盗。
- 弃牌选择由各自私密命令提交，服务端验证精确数量与持有量。
- 强盗必须移动到不同六角，可移动到沙漠；其所在六角不生产。
- 若新位置邻接多个有资源的对手，当前玩家选择目标；资源种类由服务端从目标手牌随机抽取。无合法目标时流程直接结束。
- 骑士移动强盗但不触发 7 点弃牌。

### Trading

- 只有当前玩家在 TURN_ACTIONS 可发起和完成玩家交易；其他玩家只能回应当前玩家的有效报价。
- 报价双方都必须至少付出 1 张资源；禁止同资源空转、赠送、赊账、未来承诺和第三方三角交易。
- 接受时必须以最新 revision 重新验证双方库存，交易一次性原子结算。
- 银行默认 4:1；拥有通用港为 3:1；拥有对应资源专港为该资源 2:1；使用玩家当前最优合法比例。
- 交易与建造可在行动阶段自由交错，直至结束回合。

### Building

- 成本：道路=砖+木；聚落=砖+木+粮+羊；城市=2 粮+3 矿；发展卡=粮+羊+矿。
- 每位玩家库存上限：15 道路、5 聚落、4 城市。
- 道路须连接自己的道路/建筑，不能穿过对手建筑继续连接。
- 聚落须连接自己的道路，且相邻顶点不得有任意玩家建筑。
- 城市只能升级自己的聚落；升级后聚落棋子归还库存。
- 所有资源扣除、库存变化、地图占用和奖项重算在同一事务式状态转换中完成。

### Development Cards

- 牌堆为 25 张：14 骑士、5 隐藏胜利点、2 道路建设、2 丰收、2 垄断。
- 可在同回合购买任意多张，受资源与牌堆限制；除隐藏胜利点用于宣告胜利外，新购卡当回合不可使用。
- 每回合最多使用 1 张非胜利点发展卡，可在掷骰前或行动阶段按规则使用。
- 道路建设按连续子流程免费放至多 2 条合法道路；无棋子或无合法位置时允许提前结束。
- 丰收从银行选择总计至多 2 张可用资源；垄断取得所有对手持有的指定资源；骑士移动强盗并计入最大骑士。
- 未使用发展卡内容仅本人可见；公开数据只显示未使用总数、已打出骑士数和公开动作。

### Awards and Victory

- 最长道路至少 5 段；边不可重复，分叉取单条最长连续路径；对手建筑会切断该玩家路径，自己的建筑不会。
- 持有人与他人同长时保留；有人严格更长且至少 5 时转移。若原持有人失去资格且多人并列最高，则无人持有。
- 最大骑士至少 3 张已打出骑士；他人必须严格超过现持有人数量才转移。
- 聚落 1 分、城市 2 分、最长道路 2 分、最大骑士 2 分、隐藏胜利点各 1 分。
- 玩家在自己的回合达到至少 10 分时立即结束；服务端用包含隐藏胜利点的真实分数判定，终局才公开必要牌面。

## Command and Event Contract

ClientCommand 必含：

- protocolVersion、gameId、playerId；
- commandId（客户端生成、同玩家范围唯一）；
- expectedRevision；
- type 与经 schema 校验的 payload。

ServerResponse 为以下之一：

- CommandAccepted：commandId、newRevision、给该连接的最新投影/事件；
- CommandRejected：commandId、stable errorCode、当前 revision、可安全展示的信息；
- Snapshot：公开视图 + 当前玩家私有视图 + revision；
- PresenceChanged：只改变连接呈现，不改变游戏规则状态时仍需定义清晰序列。

规则：

- 相同 commandId 重试返回同一结果，不重复应用。
- expectedRevision 过期返回 STALE_REVISION，并触发快照追平。
- 服务端每次状态变更单调递增 revision。
- 错误码是协议的一部分；客户端不得解析自由文本来决定流程。
- protocolVersion 或 snapshot schema 不兼容时明确拒绝，不静默猜测。

## Player View Projection

公开给所有人的信息：

- 地图、建筑、道路、强盗、回合/阶段、骰子、连接状态；
- 每位玩家资源总数、未使用发展卡总数、已打出骑士、公开得分；
- 当前待完成动作的参与者和公开事件日志。

只给本人的信息：

- 资源按种类明细、未使用发展卡明细；
- 自己待弃牌数、可用动作与 pending command 状态；
- 重连成功后的玩家身份确认。

永不下发：

- 他人的手牌明细、未使用发展卡内容；
- 发展牌堆顺序、服务端 RNG 内部状态；
- 任何玩家重连令牌或令牌哈希；
- 幂等缓存中的私密命令 payload。

## Reconnection and Persistence

- 首次入座生成高熵 reconnectToken；浏览器本地保存，服务端只保存校验用摘要。
- 新连接以 roomCode + playerId + token 恢复；同一身份新连接成功后替换旧连接。
- 重连总是先发送完整玩家投影和当前 revision，再接受新命令。
- 断线不移除座位、不改变轮次、不自动行动。
- 每个成功改变游戏状态的命令进入串行房间队列，并在广播前或按明确 durability 策略写入原子快照。
- 快照含 schemaVersion 与 rulesetVersion，采用临时文件写入后原子替换；损坏或不兼容快照隔离并给出可操作错误。
- 服务重启扫描未结束房间并恢复；令牌摘要、秘密牌面仅留在服务端文件。
- 运行目录加入 gitignore，普通日志不记录令牌、完整手牌或牌堆。

## HTTP and WebSocket Surface

HTTP：

- GET /health：进程与版本；
- POST /api/rooms：创建房间；
- POST /api/rooms/:code/join：加入并领取身份；
- GET /api/rooms/:code：仅返回可公开的大厅摘要；
- GET /：客户端静态资源。

WebSocket：

- /ws 使用首次认证消息或受保护的短期连接参数；
- 心跳检测断连，设消息大小和频率上限；
- 生产构建限制允许的 Origin；局域网地址配置可解释。

最终路径和 payload 必须在 packages/protocol 的 schema 与测试中确定；Executor 不得创建无 schema 的旁路接口。

## Cross-Cutting Concerns

### Error Handling

- 领域错误使用稳定代码：NOT_YOUR_TURN、WRONG_PHASE、STALE_REVISION、INSUFFICIENT_RESOURCES、ILLEGAL_PLACEMENT、INVALID_TRADE、AUTH_FAILED 等。
- 预期非法动作不作为服务器异常；未知异常不向客户端泄露堆栈或秘密。

### Observability

- 结构化日志包含 gameId、playerId（可截断/匿名化）、commandId、revision 和错误码。
- 禁止记录 reconnectToken、完整资源明细、未公开发展卡和 RNG 状态。
- 提供房间数、连接数、命令拒绝数等轻量指标可后置，不阻塞 MVP。

### Security

- 所有 payload 运行时校验；昵称长度、房间码、枚举、数组大小受限。
- 房间命令串行化，避免并发双花。
- 使用安全随机生成令牌；比较令牌摘要时避免明显时序泄露。
- 不承诺公网安全；启动文档明确防火墙和可信局域网假设。

### Accessibility and UX

- 颜色之外同时使用图形/文本区分玩家与资源。
- 棋盘可缩放；关键动作有键盘可达控件、确认和错误恢复。
- 私密信息明确标识，交易和弃牌不得因连接抖动重复提交。

### Testing Strategy

测试金字塔：

1. domain 单元/性质测试：拓扑、状态机、成本、不变量、奖项、随机确定性；
2. scenario 测试：从给定状态执行命令并断言事件、投影和拒绝；
3. protocol 合约测试：schema、版本、秘密字段快照；
4. server 集成测试：多连接、幂等、并发、断线和快照恢复；
5. Playwright 多 context E2E：3 人、4 人、刷新重连和一局关键路径；
6. 局域网真机手工测试：不同设备通过主机 IP 加入。

## Dependency Rules for Executors

- apps/client 可依赖 protocol，不可依赖 domain 内部状态实现。
- apps/server 可依赖 domain 与 protocol；domain 不可反向依赖 apps。
- protocol 不包含规则执行；domain 不包含传输 DTO 的 UI 细节。
- 任何新增跨包依赖、数据库、消息中间件或公共协议变更都需 Planner 审批。
- 测试不得通过直接篡改生产私有字段来掩盖不可测试设计；应使用 test-support 场景构造器。
- 若需求与本文件冲突，Executor 在 TASK Problems 中记录并停止扩大实现。

## Related ADRs

- docs/decisions/ADR-001-authoritative-server.md
- docs/decisions/ADR-002-typescript-monorepo.md
- docs/decisions/ADR-003-original-identity-assets.md
