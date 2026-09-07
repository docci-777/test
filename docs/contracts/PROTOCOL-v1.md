# 实施附件：数据与房间协议 v1

Owner：Planner；2026-09-07；T01 待独立审查。适用 T03～T06；T02 只建立工程和健康检查，不实现这些业务。所有字段名、字面值为接口契约，省略字段仅限明确 optional。JSON 不允许 NaN/Infinity；整数必须符合所列边界。共享类型放 packages/game、packages/protocol；服务端做运行时结构和语义校验，不能只依赖 TS。

## GameState / Command / Result

```ts
type PlayerId = 'A' | 'B' | 'C';
type Pos = {x:number; y:number}; // 整数0..14
type UnitKind = 'infantry' | 'cavalry' | 'archer';
type Unit = {id:string; owner:PlayerId; kind:UnitKind; pos:Pos;
  hp:number; moved:boolean; acted:boolean; movedSteps:number};
type Player = {id:PlayerId; resources:number; eliminated:boolean;
  base:{pos:Pos; hp:number}; holdStreak:number};
type Outpost = {id:string; pos:Pos; owner:PlayerId|null; contested:boolean};
type Outcome = {reason:'ELIMINATION'|'CONTROL'|'ROUND_LIMIT';
  winners:PlayerId[]; draw:boolean};
type GameState = {schemaVersion:1; mapId:'map-v1'; gameId:string;
  round:number; order:PlayerId[]; turnIndex:number;
  currentPlayer:PlayerId; phase:'RECRUIT'|'ACTION'|'FINISHED';
  players:Record<PlayerId,Player>; units:Unit[]; outposts:Outpost[];
  nextUnitSeq:number; outcome:Outcome|null};
type Command =
  | {type:'RECRUIT'; kind:UnitKind; pos:Pos}
  | {type:'SKIP_RECRUIT'}
  | {type:'MOVE'; unitId:string; path:Pos[]}
  | {type:'ATTACK'; unitId:string;
      target:{kind:'unit'; unitId:string}|{kind:'base'; owner:PlayerId}}
  | {type:'CAPTURE'; unitId:string}
  | {type:'END_TURN'};
type GameEvent = {type:'RECRUIT'|'MOVE'|'ATTACK'|'CAPTURE'|'INCOME'|
  'TURN_STARTED'|'ELIMINATED'|'GAME_FINISHED'; actor:PlayerId|null; text:string};
type Result = {ok:true; state:GameState; events:GameEvent[]}
  | {ok:false; code:string};
// 纯函数，不读时钟/网络/随机数，不修改入参。
// createGame(gameId:string): GameState，初始收入已结算。
// applyCommand(state:GameState, actor:PlayerId, command:Command): Result
// eliminatePlayer(state:GameState, actor:PlayerId): Result
```

gameId 由服务端生成UUID并传入规则层。初始单位ID为 A-I1/A-I2/A-C1/A-R1（B/C同理）；新兵ID为 `${gameId}-u${nextUnitSeq}`，序号从1起成功招募后加1。mapId绑定随应用打包的map-v1数据；不从客户端接收地形、HP、伤害、资源或胜者。FINISHED 保留终局 currentPlayer/turnIndex 供展示，禁止依其继续行动；跳过淘汰座位时 turnIndex 指向 order 中下一存活者，轮末重建数组。
Result.code 的玩法集合：GAME_FINISHED、PLAYER_ELIMINATED、NOT_YOUR_TURN、WRONG_PHASE、UNIT_NOT_FOUND、NOT_OWNER、ALREADY_MOVED、ALREADY_ACTED、INVALID_PATH、OCCUPIED、IMPASSABLE、MOVE_TOO_FAR、INVALID_TARGET、OUT_OF_RANGE、NOT_INFANTRY、NOT_ON_OUTPOST、ALREADY_CONTROLLED、INSUFFICIENT_RESOURCES、UNIT_LIMIT、NO_SPAWN_CELL、INVALID_SPAWN。按全局状态/actor → 阶段 → 单位存在归属/行动标志 → 参数/路径/目标 → 资源顺序校验；一个字段有多个错误时取上述最先层，层内测试仅构造单一错误。新兵移动返回 ALREADY_MOVED，已acted但未moved的单位移动返回 ALREADY_ACTED。失败不得部分修改状态、收入、随机ID序号或日志。
MOVE进入未毁基地与单位占格均为OCCUPIED；骑兵进入山地为IMPASSABLE；攻击已不存在的目标为INVALID_TARGET（攻击者不存在才是UNIT_NOT_FOUND）。SURRENDER走eliminatePlayer，跳过“当前玩家/阶段”校验，但已淘汰或已终局仍拒绝。

## 连接与游客席位（G09）

同源 HTTP 静态页面、GET /health，WebSocket /ws；协议版本1。主机重启清空房间、凭据、去重缓存。页面始终提示“主机重启会丢失当前对局”。不做账号登录和外网服务。
首次玩家创建房间；房间ID为服务端UUID，邀请链接 `/?room=<roomId>`。房间内自动分配最低空座 A/B/C，显示游客A/B/C；不输入密码、不要求昵称。房主为创建者。未占座浏览器必须显式点加入，打开链接本身不占席位。
席位token由服务端加密安全随机生成32字节、base64url编码，仅在相应玩家的 WELCOME 中返回；客户端 localStorage 按 roomId 保存，刷新后先RESUME，不再JOIN。token不是账号；不用其防御不可信局域网攻击。不得在广播、URL、日志里泄露token。错误或过期token不能驱逐已有连接；成功RESUME替换本席旧socket，旧socket收到 SESSION_REPLACED 后关闭，之后消息不得被接受。
新socket只可发 CREATE/JOIN/RESUME；绑定成功后才允许房间请求。相同socket不得二次绑定不同席位。CREATE 为 `{type:'CREATE', protocolVersion:1}`，JOIN为 `{type:'JOIN', protocolVersion:1, roomId:string}`，RESUME为 `{type:'RESUME', protocolVersion:1, roomId:string, seatToken:string}`。握手一次一条；成功返回 `{type:'WELCOME', protocolVersion:1, roomId, seatId, seatToken, snapshot}`，失败 `{type:'HANDSHAKE_ERROR', code}`，不创建额外席位；客户端不自动重试CREATE。创建断线且没收到凭据的空房按清理规则回收。

## 房间快照与命令封装

```ts
type RoomSnapshot = {roomId:string; version:number;
  status:'LOBBY'|'PLAYING'|'PAUSED'|'FINISHED';
  hostSeat:PlayerId; seats:Array<{id:PlayerId; name:string;
    connected:boolean; eliminated:boolean}>;
  game:GameState|null; pauseMissing:PlayerId[];
  events:Array<GameEvent & {seq:number}>};
type RoomAction = {type:'START'} | {type:'REMATCH'} | {type:'LEAVE'}
  | {type:'SURRENDER'} | {type:'GAME'; gameId:string; command:Command};
type Request = {type:'REQUEST'; requestId:string; expectedVersion:number;
  action:RoomAction};
// 无副作用同步请求 {type:'SYNC'}，返回当前SNAPSHOT。
type Reply = {type:'ACK'; requestId:string; appliedVersion:number}
  | {type:'ERROR'; requestId:string; code:string; currentVersion:number};
// 广播 {type:'SNAPSHOT', snapshot:RoomSnapshot}
```

seats 仅包含已占席位，按 A/B/C 排序，最多3；LOBBY/重开后 game=null、eliminated=false。version创建时0，所有成功房间变更、玩法动作、在线状态改变各以一次原子转换递增1；SYNC/失败/重复请求不递增。events保留最近200条，seq房间生命周期内递增，不按客户端重置；人读text无规则权威性。
requestId为客户端UUID。每房间串行队列处理加入、恢复、断开、命令，广播完整快照，客户端只接受不低于已应用version的快照。命令只带意图，actor取socket绑定席位。
校验顺序：消息JSON/大小/结构与协议 → socket仍有效绑定 → 查本席位requestId缓存 → expectedVersion → 房间状态/权限 → GAME的gameId → 玩法规则。缓存保存已确认合法封装请求的原始action+expectedVersion与ACK/ERROR，直至房间删除或席位主动释放；同ID同内容只重放原响应及最新快照，不重执；同ID不同内容返回 REQUEST_ID_REUSED。版本不等返回 STALE_VERSION，并送当前快照；用户根据最新局面重新确认动作，换新requestId，禁止盲目重放失败动作。未结束房间的缓存不做时间淘汰，首期小规模内存开销记录为后续风险。
成功时 ACK(appliedVersion) 后广播 SNAPSHOT；错误发 ERROR 和当前 SNAPSHOT（绑定前除外）。帧上限64KiB，超限关闭code1009；非法JSON/结构返回 INVALID_MESSAGE，不变更状态；不支持的protocolVersion返回 PROTOCOL_MISMATCH并关闭。服务每15秒WebSocket ping，连续30秒无pong断开，触发正常断线状态处理；浏览器重连间隔1/2/4/8秒后固定8秒，只RESUME，直到恢复或ROOM_NOT_FOUND/INVALID_TOKEN。
房间错误：ROOM_NOT_FOUND、ROOM_FULL、INVALID_TOKEN、ALREADY_BOUND、SESSION_REPLACED、PROTOCOL_MISMATCH、INVALID_MESSAGE、REQUEST_ID_REUSED、STALE_VERSION、HOST_ONLY、NOT_READY、ROOM_PAUSED、INVALID_ROOM_STATE、GAME_ID_MISMATCH、USE_SURRENDER。前端有中文提示、重新同步及可重试操作，不得让原始异常堆栈替代用户说明。

## 生命周期

LOBBY：需三席占满且全部在线才允许房主START，一次创建游戏并进入PLAYING；未满/有人离线 NOT_READY。并发加入串行，第四人ROOM_FULL；无观众席。掉线保留座位120秒，期间可RESUME；超时释放凭据/缓存，若房主失去席位，转给最早仍占席者（同时间按A/B/C）。LOBBY主动LEAVE立即释放；无人则立即删除房间。
PLAYING：任一未淘汰玩家掉线立即PAUSED，不跳回合、不重复收入；全部未淘汰者恢复后PLAYING。PAUSED拒绝GAME，允许SYNC、RESUME、SURRENDER；暂停没有自动判负时限。活跃玩家LEAVE返回USE_SURRENDER，UI先明确“退出将投降”再发SURRENDER。SURRENDER不要求轮到自己，也不受招募阶段限制；按玩法淘汰后若未结束且无缺席存活者则恢复PLAYING。淘汰者掉线不暂停对局。PLAYING/PAUSED不释放离线席位、不接受新玩家顶替。
FINISHED：房间保留三席和终局，房主且三席在线时可REMATCH，一次清空游戏回LOBBY，随后START生成新gameId并资源/HP全重置；保留token，version不重置，旧gameId动作拒绝。FINISHED允许LEAVE并释放席位，房主转移规则同LOBBY；新人只能在返回LOBBY后JOIN。若有人离开，剩余在线席位的房主也可REMATCH回LOBBY（要求全部仍占席位在线），再补齐三人START；未释放但离线的席位按LOBBY一样120秒后释放。
活跃对局房主掉线保留房主，避免隐式换主；房主淘汰（包括投降）转给按A/B/C顺序首个存活者；旧房主可观战，不能START/REMATCH。淘汰者在PLAYING/PAUSED发送LEAVE只解绑socket并保留该已淘汰座位与token直至FINISHED，不能填补该席。
所有人均离线持续30分钟则删除PLAYING/PAUSED/FINISHED房间；有人重连清零该计时。LOBBY按120秒席位清理即可。删除后恢复返回ROOM_NOT_FOUND，清本地token并显示返回首页。服务器时间只用于连接/房间清理，不影响规则回合。服务进程关闭无持久恢复。

## 必验实例

- 两个socket抢最后一个席位：只一个WELCOME，另一ROOM_FULL；版本和座位一致。
- A发控制B单位/未轮到动作：NOT_OWNER/NOT_YOUR_TURN；无状态改变。
- 成功招募ACK丢失后以同ID重发：只扣一次、返回原ACK和最新快照；同ID改兵种返回REQUEST_ID_REUSED。
- A刷新：RESUME回原席，旧连接失效；全员恢复只取消暂停，不增加收入、不重置行动。
- 两命令同expectedVersion：串行第一合法命令成功，第二STALE_VERSION；客户端同步后由用户重新发起。
- 活跃B掉线：其他玩法ROOM_PAUSED；B恢复继续原阶段；B不自动淘汰。B主动投降则清单位并检查胜负。
- 房主在大厅离开：凭据失效、继任房主可补人开局；终局缺席离开后REMATCH可回大厅。
- 游戏重开后提交旧gameId动作：GAME_ID_MISMATCH；进程重启RESUME：ROOM_NOT_FOUND。
