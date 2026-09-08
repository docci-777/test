# 问题台账
日期：2026-09-07。以下为阅读原稿发现的设计缺口，尚非运行故障。历史初始状态：Owner均为Planner，状态均OPEN，阻塞T01及相应实施任务。最新处置见下方追加记录；保留原始问题描述。
|ID|问题/证据|必须明确的内容|
|---|---|---|
|G01|第3/10节没有固定坐标|地图225格、基地/据点/初始单位坐标及三方通路|
|G02|第8/10节仅说在大本营招募|出生格、占满处理、新兵行动、招募阶段结束时点|
|G03|第8节未说基地占格与攻城细节|基地格能否站人、攻击基地距离/伤害/守军优先级|
|G04|第6/8/9节轮和回合混用|每玩家回合结算一次还是全轮结算；首回合收入|
|G05|第11节连续三轮条件不完整|轮开始采样时点、中途失控是否归零、争夺计数|
|G06|第8/11节淘汰处理不完整|清除单位/据点、跳过玩家、最后存活者获胜、排名是否排除淘汰者|
|G07|第5/7节攻击边界|弓兵直线定义、受近战时能否反击、冲锋按格数非移动成本|
|G08|第9节争夺后恢复不明确|敌人离开仍争夺还是恢复；重新占领如何改变控制权|
|G09|原稿无房间协议|房主离开、刷新、席位凭据、掉线暂停、主动退出、再开与房间清理|
## 记录规范
新问题写日期、发现者、任务/提交、影响、复现或来源、状态、Owner、决策链接、关闭证据。不能用“已解决”替代说明。运行故障和规则争议分别标识。旧记录保留。


## 2026-09-07 T01 v1设计处置（Planner）
来源：main c2dc0f7的原稿/问题表；任务：T01 v1，分支planner/t01-contract-v1。以下RESOLVED_PENDING_REVIEW表示已有确定设计，尚非独立验证关闭；T01审查合并前仍阻塞实施。
|ID|状态|Owner|决策/处置证据|
|---|---|---|---|
|G01|RESOLVED_PENDING_REVIEW|Planner|D07；contracts/map-v1.json、RULES-v1地图节及MAP-VALIDATION；225格/通路实测PASS|
|G02|RESOLVED_PENDING_REVIEW|Planner|D08；RULES-v1回合/招募：四邻出生、失败保留阶段、新兵休眠|
|G03|RESOLVED_PENDING_REVIEW|Planner|D09；RULES-v1基地/伤害：未毁基地阻挡、显式攻城、无同格守军|
|G04|RESOLVED_PENDING_REVIEW|Planner|D10；RULES-v1回合：每玩家回合开始一次收入，初始可操作资源6/4/4|
|G05|RESOLVED_PENDING_REVIEW|Planner|D11；RULES-v1连续控制：轮开始采样、中途跌破2即归零|
|G06|RESOLVED_PENDING_REVIEW|Planner|D12；RULES-v1淘汰：立即清场、过滤顺序、最后存活者及25轮排序|
|G07|RESOLVED_PENDING_REVIEW|Planner|D13；RULES-v1战斗：横竖距离、弓兵被近战可反击、冲锋按路径格数|
|G08|RESOLVED_PENDING_REVIEW|Planner|D14；RULES-v1据点：争夺不自动恢复、步兵再次占领|
|G09|RESOLVED_PENDING_REVIEW|Planner|D15；PROTOCOL-v1：随机席位token、串行版本与去重、掉线暂停/恢复/退出/再开/回收|

## 非阻塞后续风险
|ID|类型/日期/发现者|状态/Owner|来源与影响|安排/关闭证据要求|
|---|---|---|---|---|
|P10|设计平衡风险；2026-09-07；Planner|OPEN / Planner|T01地图到中心均6，但到最近据点A5/B4/C4；未验证20～40分钟|T07真实实玩记录座位、轮数、时长、胜法；有明显位置优势时由Planner另发地图修订任务；当前NOT_RUN，不阻塞工程搭建|
|P11|环境验证缺口；2026-09-07创建、2026-09-08更新；Planner|OPEN / Executor(T02)|历史“没有依赖安装、构建或真实局域网设备验证”已由Docker安装/构建、浏览器及相关自动验证补充；当前仅T02-A5真实第二设备/LAN证据缺失，继续阻断T02批准|补真实设备、浏览器、主机IP、步骤和截图；A5完成前保持OPEN，不能批准T02或开放T03|
|P12|资源容量风险；2026-09-07；Planner|OPEN / Planner|T05请求去重缓存按房间生命周期保留，长期开房会占内存|T07记录正常25轮三人局缓存数量/内存；本期不做互联网承载承诺，若异常增长提交明确修订；不得在Executor中静默过期已成功请求|

## 2026-09-08 T02 PR15返工问题（阻断T02批准）

来源：PR15 head `4534a2acc9d9a89bda9f0c1fdd07b2dfbea0778e`；Reviewer 结论 `CHANGES_REQUESTED`；详细证据见`/private/tmp/test-t02-review.md`及`docs/REVIEW.md`。以下新增问题不覆盖原始P11或T02失败历史。

|ID|类型/日期/发现者|状态/Owner|来源与影响|R1安排/关闭证据要求|
|---|---|---|---|---|
|P13|health等待超时；2026-09-08；Reviewer|CLOSED / Executor(T02)|`scripts/smoke.mjs:93-112`的`waitForHealth`每次`fetch`无单次剩余deadline；无响应health夹具约12秒仍被外部timeout终止，T02-A2失败历史保留|R1修复后由Reviewer复核代码SHA `c86df40f12e47cad9292c2d061f4c2751dd98710`：无响应夹具10263ms、exit 1、PID清理通过；P13 CLOSED。A5实机缺证仍由P11阻断整体批准|
|P14|离线资源扫描误报HTML文档链接；2026-09-08；Reviewer|CLOSED / Executor(T02)|`scripts/check-offline-assets.mjs:40-42`把普通`<a href="https://…">`当资源引用，合法文档导航导致T02-A4失败历史保留|R1修复后由Reviewer复核代码SHA `c86df40f12e47cad9292c2d061f4c2751dd98710`：正反资源夹具通过，导航/canonical例外及指定实际资源关系均覆盖；P14 CLOSED。A5实机缺证仍由P11阻断整体批准|

P11关联：P11原有“没有依赖安装、构建或真实局域网设备验证”的记录保留为历史；当前T02-A1/A3/A6已有通过证据，但T02-A5真实第二设备/LAN证据（设备、浏览器、主机IP、步骤和截图）仍`NOT_RUN`，继续阻断批准。R1只修复P13/P14，不关闭P11、不批准T02、不开放T03。

## 2026-09-07 流程事实校正（Planner）
原始T01 PR #13 已在独立审查前合并（合并提交 `8bc63014bd47702c64414bdff6e0a44b2623cb38`，原始head `cc613daedb4a61d74010c8cdbbc3f60a7b8d9967`）。Reviewer已反馈四项验收通过，Planner据此将T01置DONE并释放T02 READY给`luna_worker_executor`；三个角色均由Luna承担，T02完成后停止等待用户，不开放T03。Owner：Planner。

## G01～G09 当前关闭证据（2026-09-07）

独立 Reviewer `luna_worker_reviewer` 已审查 T01 v1 原始 head `cc613daedb4a61d74010c8cdbbc3f60a7b8d9967`，结论为 `APPROVED`；该内容已合并为 `8bc63014bd47702c64414bdff6e0a44b2623cb38`。以下状态覆盖上方历史的 `RESOLVED_PENDING_REVIEW`，保留原记录不覆盖：

|ID|当前状态|关闭证据|审查依据|
|---|---|---|---|
|G01|CLOSED|D07、`contracts/map-v1.json`、`MAP-VALIDATION.md`|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G02|CLOSED|D08、`RULES-v1.md` 招募与回合规则|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G03|CLOSED|D09、`RULES-v1.md` 基地与攻城规则|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G04|CLOSED|D10、`RULES-v1.md` 收入与回合规则|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G05|CLOSED|D11、`RULES-v1.md` 连续控制规则|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G06|CLOSED|D12、`RULES-v1.md` 淘汰与胜负规则|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G07|CLOSED|D13、`RULES-v1.md` 战斗边界规则|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G08|CLOSED|D14、`RULES-v1.md` 据点控制规则|T01 v1 Reviewer APPROVED，原始 head `cc613da`|
|G09|CLOSED|D15、`PROTOCOL-v1.md` 房间与重连协议|T01 v1 Reviewer APPROVED，原始 head `cc613da`|


## 2026-09-08 T02 A5 实机验收收尾
|编号|状态|验收记录|处理结果|
|---|---|---|---|
|P11|CLOSED / Planner|用户确认另一台 Android 手机以 Microsoft Edge 访问 `http://192.168.0.3:3100`，页面显示“服务已连接”。会话中未附截图或录像，因此该项是用户的人工实机验收声明，不是自动化或 Reviewer 亲自复现的证据。|T02-A5 记录为 PASS；既有 A1～A4、A6 和 R1 复核保持有效。实现已由 PR #16 合入 `main`（`452fdfc387b07cf4d341e1ecd3bc658b85a41dfc`），T02 DONE；T03 继续 DRAFT。|
