# 计划实施文档
版本：0.2；2026-09-07；任务明细唯一来源；实施者当前无 READY 任务。
## 实施者协议
只执行被明确指派、状态 READY 且依赖 DONE 的任务。任务缺少接口、规则、文件范围、验收或可运行验证命令时记录 BLOCKED，交 Planner 补全。
读取指定源代码和任务附件是允许的；不要据路线图或审查意见自行新增功能。只更新本任务执行/测试/问题区域及 STATUS 对应摘要，不能改规划区域。
每次交接记录已做、未做、问题、下一步、分支和提交证据。所有测试标记 PASS/FAIL/NOT_RUN及原因。
## 任务表
|ID|负责人|状态|目标|依赖|
|---|---|---|---|---|
|T01|Planner|DONE|冻结玩法、地图、协议和房间生命周期|无|
|T02|Executor（luna_worker_executor）|READY|工程与局域网启动|T01|
|T03|Executor|DRAFT|初始化、移动、回合规则|T02|
|T04|Executor|DRAFT|战斗到胜负完整规则|T03|
|T05|Executor|DRAFT|房间和权威联机|T04|
|T06|Executor|DRAFT|完整浏览器交互|T05|
|T07|Executor|DRAFT|集成、实玩与说明|T06|
DRAFT 是有意保留的规划阶段，不能把以上摘要当成完整实施指令。
## T01 — 规则与接口契约 / v1 / DONE / Planner
目标：将 ISSUES 的 G01～G09 全部转成明确规则，记录 DECISIONS，并把结果完整内嵌到相关 T02～T07 任务或它们的实施附件。
交付：固定15×15地图坐标与225格地形数据、初始单位坐标；规则优先级、判定时点和实例；GameState/Command/Result数据契约；房间状态与重连/退出约定。
验收：
- G01～G09逐条关闭或形成显式延期范围；无实施所需未决规则。
- 地图三出生区无重叠，每个大本营两条通中央路线，有距离比较和可达性检查方案。
- 每条原稿验收有任务及验证实例；每种胜负、淘汰和边界有预期。
- T02具备允许文件、具体依赖版本选择方法、命令和验收；通过规划契约审查后可 READY。
### 本轮交付与版本锁定
基线 main `c2dc0f743dbe0dc40951e80d2ca125cbdd7647d9`；分支 `planner/t01-contract-v1`。以下附件均为任务指定资料；实施者无需从 PLANNING、ISSUES 或原稿自行推导规则：
- [玩法契约](contracts/RULES-v1.md)：G01～G08、数值、结算顺序及边界。
- [协议契约](contracts/PROTOCOL-v1.md)：GameState/Command/Result、G09及房间错误。
- [地图数据](contracts/map-v1.json)、[验证脚本](contracts/verify_map.py)、[验证证据](contracts/MAP-VALIDATION.md)。
- [原稿验收与补充边界映射](contracts/ACCEPTANCE-v1.md)：O01～O19及E01～E12。
同一PR提交中的附件共同构成T01 v1，不允许任意混用其他分支版本。独立Reviewer在REVIEW中锁定本PR实际head SHA；本文不写自引用提交SHA。

### Planner执行/交接记录
2026-09-07：读取main全部10个文件，确认原规划已进入main，无应用代码。历史v0.1状态与当前main不同，已同步STATUS；制定D07～D16，G01～G09有明确设计处置，尚待审查确认关闭。
验证：`python docs/contracts/verify_map.py` PASS（225格、12兵、全可通行格连通、每基地两条内部不相交通路、距离比较）；详见附件证据。规划文档本地链接/映射检查PASS。应用构建/规则测试/浏览器/三设备验证均NOT_RUN，无应用；独立审查NOT_RUN。
未完成：Reviewer正式审查记录已追加；已收到独立Reviewer对原始head `cc613daedb4a61d74010c8cdbbc3f60a7b8d9967` 四项验收通过的反馈。原始PR #13合并提交为`8bc63014bd47702c64414bdff6e0a44b2623cb38`，据此完成T01收尾。若后续记录发现需返工，Planner升任务/附件版本并保留旧决策，不交实施者直接改契约。
下一角色：`luna_worker_executor`按T02 READY任务实施；Reviewer正式记录已写入`docs/REVIEW.md`。Planner未编写业务代码、未代做独立审查。
完成区域：Reviewer已批准原始head `cc613daedb4a61d74010c8cdbbc3f60a7b8d9967` 的四项验收；原始PR #13合并提交为`8bc63014bd47702c64414bdff6e0a44b2623cb38`；2026-09-07，T01置DONE。G01～G09关闭证据为D07～D15及T01契约审查。T02现为READY，指派`luna_worker_executor`；T03仍DRAFT。

### 2026-09-07 跟进记录（Planner）
核实（历史）：T01原始head `cc613daedb4a61d74010c8cdbbc3f60a7b8d9967` 已由PR #13合并为 `8bc63014bd47702c64414bdff6e0a44b2623cb38`；当时独立Reviewer尚未给出结论。后续Reviewer已批准，Planner完成T01收尾并释放T02。此处仅校正文档事实，未修改任何契约；三个角色均由Luna承担；T02完成后停止等待用户，不开放T03。

## T02 — 工程与单服务局域网启动 / v1 / READY / Executor（luna_worker_executor）

### 规划区域（仅Planner写）
目标：创建可安装、类型检查、构建、启动的TypeScript npm工作区；主机单Node进程同时提供静态Web页面、GET /health及 /ws升级入口，让局域网其他设备访问。交付仅工程壳，页面明确“游戏功能尚未实现”，展示连接状态与重启丢局说明。
依赖：T01 v1独立审查APPROVED且已合并，Planner记录合并SHA并将本任务置READY后才能执行。依赖完成证据：Reviewer批准原始head `cc613daedb4a61d74010c8cdbbc3f60a7b8d9967`；合并提交`8bc63014bd47702c64414bdff6e0a44b2623cb38`。
包含：React/Vite页面、Node HTTP + ws服务、共享包占位、可配置端口、同源连接、构建/启动脚本、最小服务冒烟与使用说明。排除：棋盘、单位/房间/回合业务、登录、数据库、云服务、部署平台、外网发布及新增游戏设计。

允许文件：根 package.json/package-lock.json/tsconfig.base.json/.gitignore/.nvmrc；apps/web/{package.json,tsconfig.json,index.html,vite.config.ts,src/**}；apps/server/{package.json,tsconfig.json,src/**}；packages/game/{package.json,tsconfig.json,src/index.ts}；packages/protocol/{package.json,tsconfig.json,src/index.ts}；scripts/{smoke.mjs,check-offline-assets.mjs}；README.md；本任务执行/测试/问题区域；STATUS对应摘要；ISSUES追加执行问题。除上述内容外先BLOCKED交Planner，不改AGENTS、规划区域、契约、审查结论，不引入CI或容器作为额外交付。

依赖选择方法（须在实施环境实际查询，不把规划当作已安装验证）：
1. 运行 `node --version`、`npm --version`；选择Node22系列且>=22.12.0的可用补丁版，.nvmrc锁实际精确版，package.json engines指定 `>=22.12.0 <23`，根packageManager锁实际npm精确版。环境不能满足则BLOCKED，记录实际值，不擅改技术栈。
2. 候选主版本：react/react-dom 19、vite7、@vitejs/plugin-react5、typescript5、ws8、@types/node22、@types/react19、@types/react-dom19、@types/ws8。逐个执行 `npm view '<名称>@<主版本>' version engines peerDependencies --json`，从该主版本选择满足Node22及peerDependencies的最高非预发布版本，再 `npm view '<名称>@<精确版本>' engines peerDependencies --json` 确认。根或所属workspace写精确版本，不写^/~/latest；首次安装生成并提交唯一根锁文件。查询受限/无兼容版本则BLOCKED附输出，交Planner，不能静默换主版本。Vitest/Playwright在后续任务引入，T02不为了空包添加测试依赖。
3. `npm install` 后检查 `npm ls --all` 无 invalid/missing；锁文件存在后以 `npm ci` 重装验证。执行记录保留所选版本、Node/npm及兼容证据。

规划依据：[Vite 7官方迁移要求](https://v7.vite.dev/guide/migration)确认Node22.12+门槛；[Node 22官方LTS说明](https://nodejs.org/en/blog/release/v22.11.0)说明该系列维护至2027年4月。此处选定兼容主版本范围，不声称它们是最新主版本；精确补丁与peer依赖仍须按上述命令当场验证。

接口和固定操作：
- workspace名称 `@lan-game/web`、`@lan-game/server`、`@lan-game/game`、`@lan-game/protocol`。共享包仅 `export {};`，不提前实现T03～T05。
- 根脚本：`typecheck`依次检查四包（tsc --noEmit）；`build`先game/protocol再server/web；`start`执行编译后的server入口；`test:smoke`执行 `node scripts/smoke.mjs`；`check:offline`执行 `node scripts/check-offline-assets.mjs`。各包产物dist，git忽略node_modules/dist及日志，不提交构建产物。
- ESM；server用Node内置HTTP，WebSocket用ws；Web用React+Vite。生产服务读取apps/web/dist；静态路径相对于模块位置定位，不依赖启动shell当前目录；GET / 返回页面。GET /health返回200和 `{"ok":true}`、application/json；未知URL返回404，不误发页面；拒绝目录穿越，不暴露仓库文件。本期无需前端路由fallback。
- 只监听0.0.0.0；PORT缺省3000，指定值须十进制整数1..65535，非法值启动退出码非0并中文说明；端口占用同样明确报错，不静默另选端口。启动后列出localhost和os.networkInterfaces中非内部IPv4候选URL；无可用网卡时说明没有候选，不伪造LAN地址。
- 页面通过当前location.hostname/protocol/port建立 `/ws`，http对应ws、https对应wss；不得写死localhost。Vite开发代理如配置也不得用于生产连接。T02的/ws接受连接后立即发送 `{"type":"SERVER_READY","protocolVersion":1}`；界面收到后显示“服务已连接”；断开显示“连接已断开”。这是明确的临时工程探针，不代表T05业务WELCOME；T05任务必须移除SERVER_READY并使用PROTOCOL-v1握手。收到客户端任何业务消息不改变状态，回复 `{"type":"ERROR","code":"NOT_IMPLEMENTED"}`。
- 字体用系统字体，资源随构建本地提供；不请求CDN/遥测/在线API。页面中文说明：这是工程验证页、游戏尚未实现、主机重启丢局。

步骤：确认READY及依赖SHA → 记录开始/基线/独立 `executor/t02-bootstrap` 分支 → 查询并固定版本 → 搭建工作区和类型构建 → 实现HTTP/静态/WS探针 → 编写冒烟与资源检查 → 执行下列验收 → README写首次安装、构建、默认/自定义端口、关闭服务、局域网访问/防火墙排查及当前功能限制 → 同提交同步执行记录/STATUS/ISSUES → 开一个T02 PR并置REVIEW。不得自行合并或置DONE。

|验收|命令/操作|预期|
|---|---|---|
|T02-A1|`npm ci`、`npm ls --all`、`npm run typecheck`、`npm run build`|全退出0，无缺失/不兼容依赖；四包可构建|
|T02-A2|`npm run test:smoke`|脚本spawn已构建server，选择可用端口、等health（最长10秒）；断言health JSON、首页200、实际JS/CSS可取、随机缺失路径404、/ws收到SERVER_READY、客户端消息返回NOT_IMPLEMENTED；finally停止子进程，失败非0|
|T02-A3|`PORT=3100 npm start`；访问输出地址|0.0.0.0:3100提供同一页面/WS；`PORT=bad npm start`、`PORT=65536 npm start`非0；已占端口启动非0。smoke中覆盖非法端口/占用错误，避免悬挂进程|
|T02-A4|`npm run check:offline`；浏览器禁用外网后访问已构建服务|脚本检查源/构建HTML CSS JS无外网资源引用（可识别文本URL与实际加载引用，不把文档链接误报）；浏览器网络面板加载来源仅当前主机、页面显示已连接。自动扫描不能代替浏览器证据|
|T02-A5|主机与另一台真实局域网设备打开打印URL，记录设备/浏览器/主机IP与截图|页面及WS连接正常；不能以localhost或同机浏览器上下文代替。无设备则NOT_RUN，记录阻塞，关键验收缺失不得批准|
|T02-A6|核对README与上述命令，`git diff --check`|说明可复现，当前无游戏表述准确；仅允许文件变更，无业务越界|

验证清单即上表；未执行标NOT_RUN及原因，不能凭规划填PASS。结果保存本任务区域（简要原始输出/退出码、人工证据位置），不上传凭据。T02-A5可由用户提供实机证据后Reviewer核对，但当前没有证据。

### 执行区域（Executor填写）
开始时间/模型：未开始；分支/基线SHA：待填；实际依赖版本：待填。已指派：`luna_worker_executor`。
变更文件/日志：无。T02-A1～A6：全部NOT_RUN（READY，尚未开始）。
未完成：全部实施；问题：无实施记录；PR/交接：待填。
### 审查区域（Reviewer填写）
审查记录链接/被审SHA/结论/返工问题：未审查。
### 完成区域（Planner填写）
T01已由Reviewer批准并由Planner于2026-09-07完成收尾；合并提交`8bc63014bd47702c64414bdff6e0a44b2623cb38`。T02已READY并指派`luna_worker_executor`；T03保持DRAFT且不开放。

## 后续任务附件约束
T03～T07仍是路线图摘要，均DRAFT，不构成可执行任务。T03必须携带map-v1/RULES-v1/PROTOCOL-v1及O01/O03～O08/E01/E05；T04携带完整玩法及O09～O19/E01～E06；T05携带协议及E07～E10；T06携带全部契约和交互验收；T07携带完整映射及真实设备记录要求。Planner在各依赖DONE后补齐文件范围、明确步骤、可运行验证命令与执行区域，再逐项READY。
## 后续任务必须使用的完整模板
### Txx：名称 / 版本 / 状态 / 被指派角色
规划区域（仅Planner写）：目标；包含/排除范围；依赖及完成证据；允许文件；输入输出和错误码；内嵌规则；分步操作；验收编号与输入/预期；验证命令；文档更新清单。
执行区域（Executor写）：开始时间；分支；基线SHA；变更文件；执行日志；命令/结果/证据；未完成事项；问题编号；PR；交接说明。
审查区域（Reviewer写）：审查文档记录链接；被审查SHA；结论；返工问题。
完成区域（Planner写）：合并PR/提交；完成日期；剩余风险；下一任务。
