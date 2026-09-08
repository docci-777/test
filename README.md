# 局域网游戏工程验证

当前版本提供一个可从局域网访问的工程验证页。页面会显示服务连接状态，游戏功能尚未实现；主机重启会丢失当前游戏。棋盘、房间、回合、登录、数据库和云服务不在本阶段范围内。

## 使用 Docker 安装和构建

项目命令都在官方 `node:22.23.2` 镜像中执行。先在项目目录运行：

```sh
docker run --rm \
  -v "$PWD":/workspace \
  -w /workspace \
  node:22.23.2 \
  sh -lc 'npm ci && npm run typecheck && npm run build && npm run test:smoke && npm run check:offline'
```

`npm ci` 使用根 `package-lock.json` 重装精确依赖。构建产物位于 `apps/web/dist` 和 `apps/server/dist`，不需要提交 `node_modules` 或 `dist`。

## 启动服务

默认端口是 3000。使用 Docker 启动时需要发布对应端口：

```sh
docker run --rm -it \
  -p 3000:3000 \
  -v "$PWD":/workspace \
  -w /workspace \
  node:22.23.2 \
  sh -lc 'npm start'
```

局域网访问通常使用自定义端口，例如 3100：

```sh
docker run --rm -it \
  -p 3100:3100 \
  -v "$PWD":/workspace \
  -w /workspace \
  node:22.23.2 \
  sh -lc 'PORT=3100 npm start'
```

服务只监听 `0.0.0.0`。启动输出会列出 localhost 和检测到的非内部 IPv4 候选。Docker 容器中的接口地址不等于访问者应使用的地址；浏览器应打开 `http://<主机局域网IP>:3100`，端口映射由 `-p 3100:3100` 提供。

在主机上查询局域网 IP：

```sh
# macOS（按实际网络接口选择 en0 或 en1）
ipconfig getifaddr en0

# Linux
hostname -I
```

关闭前台服务使用 `Ctrl-C`，Docker 容器随后会因为 `--rm` 自动移除。端口必须是 1 到 65535 的十进制整数；端口被占用或端口值非法时，服务会输出中文错误并以非零状态退出，不会静默换端口。

## 局域网排查

确认主机和访问设备连接到同一局域网，并使用主机 IP 与已发布端口。主机防火墙需要允许 TCP 3100（或你选择的端口）入站；公司或公共网络可能启用客户端隔离，导致设备之间无法互访。可以从另一台设备访问 `http://<主机局域网IP>:3100/health`，成功时响应为 `{"ok":true}`。

页面不依赖 CDN、遥测或在线 API。页面上的 WebSocket 地址根据当前页面的主机名、协议和端口生成，HTTP 页面使用 `ws`，HTTPS 页面使用 `wss`。

## 当前限制

这是工程验证页，用于确认静态资源、HTTP health、局域网监听和临时 WebSocket 探针。页面显示“游戏功能尚未实现”，服务重启会丢失当前游戏；当前没有真实游戏状态、房间或回合协议。`SERVER_READY`/`NOT_IMPLEMENTED` 仅用于本阶段工程探针，后续协议任务会替换它。
