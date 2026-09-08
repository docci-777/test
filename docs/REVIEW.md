# 审查文档
负责人：独立高阶 Reviewer。
## 输入与步骤
1. 读取 AGENTS、本文件、实施任务指定版本、对应 PR diff 和提交 SHA。
2. 检查任务已经 REVIEW、依赖完成、变更均在范围内。
3. 对每条验收标准检查代码和证据，独立运行有意义的验证；没有条件执行时记录 NOT_RUN 和影响，不假称通过。
4. 核对规则与冻结契约、服务端校验、三浏览器状态一致、重复请求、刷新恢复及退出处理。
5. 核对执行记录、STATUS、ISSUES、DECISIONS及用户说明是否与代码同步。
6. 输出 APPROVED 或 CHANGES_REQUESTED；不能验证的关键验收不得批准。
## 必查游戏边界
加权路径与骑兵禁山；冲锋按实际经过格数；弓兵直线射程与无反击；单位行动次数；招募资源/格位/上限；收入结算次数；争夺据点；淘汰顺序；连续控制；第25轮排名和平局。
具体预期以 T01 冻结后写入实施任务的规则为准，不由 Reviewer 临场发明。
## 必查局域网路径
三名玩家无登录开局；并发加入不重座；不能控制别人的棋子；未轮到拒绝动作；重复消息不重复扣资源/伤害；旧版本拒绝后重新同步；刷新不会多占席位；房满有提示；掉线不静默跳过回合；主机重启丢局说明。
跨设备网络验证必须列设备、浏览器、主机地址及步骤；三个上下文的模拟不能冒充真实三设备。
## 审查记录格式
每次审查在本文件追加：日期、Reviewer会话/模型、任务与版本、PR、被审查SHA、逐项验收结果、独立验证命令/结果、问题严重程度/位置/复现/期望、结论。
P0/P1和关键验证缺失阻断批准。可延后项必须有问题编号、影响与Planner安排。
批准后发生代码变更需要重新审查。批准不是已合并，DONE必须有合并证据和文档收尾。
## 历史
2026-09-07：尚无代码审查；本轮规划文档尚未经过独立高阶审查。

## 2026-09-07 独立审查记录：T01 v1

- Reviewer会话/模型：`luna_worker_reviewer` / `gpt-5.6-luna`
- 任务与版本：T01 规则与接口契约 / v1
- PR：#13（`docci-777/test`），原始 PR head：`cc613daedb4a61d74010c8cdbbc3f60a7b8d9967`
- 实际合并提交：`8bc63014bd47702c64414bdff6e0a44b2623cb38`
- 审查范围：合并内容中的 T01 契约、地图数据/验证脚本、原稿验收映射及 T02 实施任务；未审查后续实现（当前无应用代码）。

### 逐项验收

1. **G01～G09 规则缺口：PASS。** D07～D15 分别给出明确处置；RULES-v1、PROTOCOL-v1、DECISIONS、ISSUES 及必验实例相互对应，没有发现实施所需的未决规则。
2. **地图与通路：PASS。** `map-v1.json` 固定 15×15、225 格、三基地、三据点、12 个初始单位；设施/单位无重叠。验证脚本覆盖地形、步兵/弓兵及骑兵可达性、每基地两条内部不相交路线和加权距离比较。
3. **原稿验收及边界：PASS。** O01～O19、E01～E12 均有任务映射、最小输入和预期；战斗、据点、收入、淘汰、三种胜负、第25轮排名及平局均在契约中定义。
4. **T02 可执行性：PASS。** T02 已提供允许文件、Node/npm 与精确依赖选择方法、安装/构建/启动/冒烟/离线/局域网验收、命令和预期，并要求 T01 审查批准且收尾后才置 READY。

### 独立验证

```text
python docs/contracts/verify_map.py          PASS
python -m json.tool docs/contracts/map-v1.json  PASS
git diff c2dc0f743dbe0dc40951e80d2ca125cbdd7647d9..HEAD --check  PASS
```

应用构建、规则测试、浏览器、真实三设备和局域网验证均为 `NOT_RUN`，因为当前没有应用；这些缺失没有被规划自检冒充为通过。

### 问题与边界

- 未发现 P0/P1 契约阻断项。
- 原始文档曾写 PR 未合并、旧基线及审查状态过时；Planner 后续提交已补充 PR head、merge SHA 和“合并不等于批准”的事实说明。
- 地图验证脚本验证的是基地、据点和初始单位坐标集合无重叠，未定义独立的“出生区”字段；后续实现应按契约明确解释该术语，不得据此扩展规则。
- P10 地图平衡、P11 环境/真实设备验证、P12 请求缓存容量仍按 ISSUE 记录延后，不阻断 T01 契约批准。

**结论：APPROVED。** 本结论锁定上述原始 PR head 及其合并内容；若后续修改契约或 T02 指令，须重新锁定 SHA 审查。

## 2026-09-07 固定 SHA 复核记录：T01 v1

- Reviewer 会话：`/root/reviewer`
- 模型/推理强度：`gpt-5.6-luna` / `max`
- 任务与版本：T01 规则与接口契约 / v1
- PR：#13（`docci-777/test`）
- 原始 PR head：`cc613daedb4a61d74010c8cdbbc3f60a7b8d9967`
- 实际合并提交：`8bc63014bd47702c64414bdff6e0a44b2623cb38`
- 四项验收：G01～G09 规则缺口 **PASS**；地图与通路 **PASS**；原稿 O01～O19/E01～E12 映射及边界 **PASS**；T02 可执行性 **PASS**。

独立证据详见 `/private/tmp/test-reviewer-report.md`。Docker 中执行：

```text
docker run --rm --entrypoint sh -v /private/tmp/test-collaboration-0907:/workspace -w /workspace catan-e2e:latest -c 'set -eu; python3 docs/contracts/verify_map.py; python3 -m json.tool docs/contracts/map-v1.json >/dev/null; git diff cc613daedb4a61d74010c8cdbbc3f60a7b8d9967^ cc613daedb4a61d74010c8cdbbc3f60a7b8d9967 --check'
```

结果：地图 225 格、设施/12 个初始单位无重叠、步兵/弓兵与骑兵可达性、三方双路线和加权距离检查均 **PASS**；JSON 及原始提交 diff 检查 **PASS**。结论：**APPROVED**，仅适用于上述固定 SHA；未批准 T02 实现。T02 的 npm 安装、构建、规则测试、浏览器、真实三设备/LAN 和服务实际验证均仍为 **NOT_RUN**，因当前阶段只有契约/地图，按 T02/T07 后续任务执行。

## 2026-09-08 T02 v1 独立审查记录：PR15

- Reviewer 会话：`/root/reviewer`；模型/推理强度：`gpt-5.6-luna` / `max`
- 任务与版本：T02 工程与单服务局域网启动 / v1
- PR：#15；被审 head：`4534a2acc9d9a89bda9f0c1fdd07b2dfbea0778e`；base：`b48af71e2f77a55511dc642d6c5b4025278355f0`
- 审查范围：25 文件 diff、T02 任务、源码、smoke/offline 脚本及浏览器证据；未审查后续 T03～T07。

### T02 验收矩阵

1. **A1 PASS。** Docker 中 `npm ci`、`npm ls --all`、`npm run typecheck`、`npm run build` 均 exit 0；依赖树 JSON `problems=[]`。
2. **A2 FAIL（P1）。** 正常 `npm run test:smoke` exit 0，覆盖 health、首页 JS/CSS、404、WS、非法/占用端口；但用不响应 `/health` 的 Docker 临时服务夹具运行 `timeout 12s node scripts/smoke.mjs` 得到 exit 124。`smoke.mjs:93-112` 单次 fetch 无硬超时，10 秒 deadline 可被卡住的请求突破。期望：10 秒内非零退出并清理。
3. **A3 PASS。** Docker 临时端口 `31837` 的 127.0.0.1 与容器非内部 IP health/首页通过；`PORT=bad`、`65536`、占用端口均 exit 1 且中文报错。
4. **A4 FAIL（P2）。** 正常 `check:offline` exit 0、`externalReferences=[]`；文档 Markdown/普通 URL 不误报，fetch/CSS `@import`/HTML link 正向外部加载夹具均被检出。但合法 `<a href="https://docs.example.invalid/reference">` 被 `check-offline-assets.mjs:40-42` 当资源报错。期望：保留实际加载引用检测并忽略 HTML 文档锚点。
5. **A5 NOT_RUN（P1，阻断）。** `/private/tmp/test-t02-browser-proof.json` 明确是 Docker browser，且注明不是第二实体设备；桌面/手机截图不能替代真实第二设备。缺少设备、浏览器、主机 IP、步骤和截图的真实 LAN 证据。
6. **A6 PASS。** README 覆盖 Docker 安装/build、默认/自定义端口、关闭、LAN IP、防火墙排查和当前限制；变更在 T02 允许文件内；Docker `git diff --check` exit 0。官方 `node:22.23.2` 镜像核对为 Node `22.23.2`、npm `10.9.8`。

### 独立验证与结论

正常路径 Docker 命令：`npm ci`、`npm ls --all`、`npm run typecheck`、`npm run build`、`npm run test:smoke`、`npm run check:offline`、`git diff --check`；A1/A3/A6 及正常 A2/A4 结果如上。临时夹具只写 Docker `/tmp`，未停止 `test-t02-app-0907` 或 `test-t02-browser-0907`。详细复现、期望和浏览器证据见 `/private/tmp/test-t02-review.md`。

**结论：CHANGES_REQUESTED。** A2 的 smoke 硬超时、A4 的 HTML 文档链接误报需修复，A5 需补真实第二设备证据；在三项完成并重新锁定 head 前，不批准 T02、不置 DONE、不开放 T03。

## 2026-09-08 T02 v1 R1 独立定向复核记录：PR15

- Reviewer 会话：`/root/reviewer`；模型/推理强度：`gpt-5.6-luna` / `max`
- 被审 head：`c86df40f12e47cad9292c2d061f4c2751dd98710`；R1 基线：`9a8c7d77034a75b12aaaabbb302ec7e3f7b40c11`
- 范围：仅 P13 health 总 10 秒 deadline/清理和 P14 离线资源导航例外、实际加载资源检出；保留 PR15 的 A2/A4 失败历史，不重跑 A1/A3/A6 或浏览器。

### R1 逐项结论

1. **P13 PASS，可关闭。** Docker 无响应 `/health` 夹具未使用外层 `timeout`，`SMOKE_SERVER_ENTRY=/tmp/t02-r1-nohealth.mjs npm run test:smoke` 在 10263 ms 后 exit 1，输出 `health 未在 10000ms 内可用`；夹具 PID 的结束后 `kill -0` 检查为 `pid_alive=no`，`finally` 清理通过。
2. **P14 PASS，可关闭。** 正向夹具的外部 `<a href>`、`<area href>`、`<link rel="canonical" href>` 未误报，exit 0 且 `externalReferences: []`。负向夹具 exit 1，检出 stylesheet/preload/modulepreload/icon/prefetch、script、img/audio/video/source/iframe/track，以及 CSS `url`/`@import`、fetch、动态 import、WebSocket 外链。

### 回归命令与范围

`catan-e2e:latest` Docker（`--network none`）中 `npm run test:smoke` exit 0，startup/health/首页 JS-CSS/404/WS/非法和占用端口均通过；`npm run check:offline` exit 0，`externalReferences: []`。P13/P14 完整夹具证据见 [`/private/tmp/test-t02-r1-review.md`](file:///private/tmp/test-t02-r1-review.md)；夹具只存在容器 `/tmp`，未停止主代理验收容器。

**结论：P13/P14 修复通过，原两项返工问题关闭；整体仍 CHANGES_REQUESTED。** A5 真实第二设备仍 NOT_RUN，Docker 浏览器/同机截图不能替代实体局域网设备，该 P11 证据门槛仍阻断 T02 APPROVED/DONE 和 T03 开放。


## 2026-09-08 T02 A5 用户实机验收确认与收尾
- 任务与版本：T02 工程与单服务局域网启动 / v1。
- 已合入实现：PR #16，`main` 合并提交 `452fdfc387b07cf4d341e1ecd3bc658b85a41dfc`。
- A5 验收来源：用户在本协作会话中确认，另一台 Android 手机使用 Microsoft Edge 访问 `http://192.168.0.3:3100`，页面显示“服务已连接”。
- 证据范围：会话中未提供截图或录像。该项记录为用户完成的人工实机验收；不将其表述为自动化检查或 Reviewer 的独立设备复现。
- 结论：A5 按用户确认记为 PASS。结合此前 A1、A2、A3、A4、A6 的通过记录、P13/P14 的 R1 复核关闭及 PR #16 的既有合入，T02 状态为 DONE。T03 仍为 DRAFT，须等待用户确认后启动。
