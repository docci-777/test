import { createServer as createProbeServer } from "node:http";
import { spawn } from "node:child_process";
import { once } from "node:events";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { WebSocket } from "ws";

const root = resolve(dirname(fileURLToPath(import.meta.url)), "..");
const serverEntry = process.env.SMOKE_SERVER_ENTRY
  ? resolve(process.env.SMOKE_SERVER_ENTRY)
  : resolve(root, "apps/server/dist/index.js");
const healthTimeoutMs = 10_000;
const probeTimeoutMs = 5_000;
const cleanupTimeoutMs = 1_000;

function assert(condition, message) {
  if (!condition) {
    throw new Error(message);
  }
}

function delay(milliseconds) {
  return new Promise((resolvePromise) => setTimeout(resolvePromise, milliseconds));
}

async function withTimeout(promise, milliseconds, message) {
  let timer;
  const timeout = new Promise((_, reject) => {
    timer = setTimeout(() => reject(new Error(message)), milliseconds);
  });

  try {
    return await Promise.race([promise, timeout]);
  } finally {
    clearTimeout(timer);
  }
}

async function choosePort() {
  const probeServer = createProbeServer();
  await new Promise((resolvePromise, reject) => {
    probeServer.once("error", reject);
    probeServer.listen(0, "127.0.0.1", resolvePromise);
  });

  const address = probeServer.address();
  assert(address && typeof address === "object", "无法读取可用端口");
  const port = address.port;
  await new Promise((resolvePromise, reject) => {
    probeServer.close((error) => (error ? reject(error) : resolvePromise()));
  });
  return port;
}

function startServer(port) {
  const child = spawn(process.execPath, [serverEntry], {
    cwd: root,
    env: { ...process.env, PORT: String(port) },
    stdio: ["ignore", "pipe", "pipe"],
  });
  let stdout = "";
  let stderr = "";
  child.stdout.setEncoding("utf8");
  child.stderr.setEncoding("utf8");
  child.stdout.on("data", (chunk) => {
    stdout += chunk;
  });
  child.stderr.on("data", (chunk) => {
    stderr += chunk;
  });
  return { child, get stdout() { return stdout; }, get stderr() { return stderr; } };
}

async function waitForExit(processInfo, milliseconds = probeTimeoutMs) {
  if (processInfo.child.exitCode !== null) {
    return { code: processInfo.child.exitCode, signal: processInfo.child.signalCode };
  }

  const [code, signal] = await withTimeout(once(processInfo.child, "exit"), milliseconds, "进程未在期限内退出");
  return { code, signal };
}

async function stopServer(processInfo) {
  if (processInfo?.child.exitCode !== null) {
    return;
  }

  processInfo.child.kill("SIGTERM");
  await waitForExit(processInfo, cleanupTimeoutMs).catch(() => {
    if (processInfo.child.exitCode === null) {
      processInfo.child.kill("SIGKILL");
    }
  });
}

async function waitForHealth(port, processInfo) {
  const deadline = Date.now() + healthTimeoutMs;
  while (Date.now() < deadline) {
    if (processInfo.child.exitCode !== null) {
      throw new Error(`server 在等待 health 时退出，stderr：${processInfo.stderr}`);
    }

    const remainingMs = deadline - Date.now();
    if (remainingMs <= 0) {
      break;
    }

    try {
      const response = await fetch(`http://127.0.0.1:${port}/health`, {
        signal: AbortSignal.timeout(remainingMs),
      });
      if (response.status === 200) {
        return;
      }
    } catch {
      // Server may still be binding the port.
    }
    const delayMs = Math.min(100, Math.max(0, deadline - Date.now()));
    if (delayMs > 0) {
      await delay(delayMs);
    }
  }

  throw new Error(`health 未在 ${healthTimeoutMs}ms 内可用`);
}

async function getAssetPaths(html) {
  return [...html.matchAll(/(?:src|href)="([^"]+)"/g)]
    .map((match) => match[1])
    .filter((path) => path.startsWith("/"));
}

async function fetchWebSocketMessage(socket) {
  return withTimeout(new Promise((resolvePromise, reject) => {
    socket.once("message", (data) => resolvePromise(String(data)));
    socket.once("error", reject);
  }), probeTimeoutMs, "WebSocket 消息超时");
}

async function runOneShot(portValue) {
  const processInfo = startServer(portValue);
  try {
    const result = await waitForExit(processInfo);
    return { ...result, stdout: processInfo.stdout, stderr: processInfo.stderr };
  } catch (error) {
    await stopServer(processInfo);
    throw error;
  }
}

async function main() {
  const port = await choosePort();
  const baseUrl = `http://127.0.0.1:${port}`;
  const processInfo = startServer(port);
  const result = { port, checks: [] };

  try {
    await waitForHealth(port, processInfo);
    assert(processInfo.stdout.includes("http://localhost:"), "启动输出缺少 localhost 地址");
    assert(
      processInfo.stdout.includes("局域网地址") || processInfo.stdout.includes("没有可用的局域网 IPv4 地址候选"),
      "启动输出缺少局域网候选说明",
    );
    result.checks.push("startup");

    const healthResponse = await fetch(`${baseUrl}/health`);
    assert(healthResponse.status === 200, "health 状态码不是 200");
    assert(healthResponse.headers.get("content-type") === "application/json", "health Content-Type 不是 application/json");
    assert((await healthResponse.text()) === '{"ok":true}', "health JSON 不精确匹配");
    result.checks.push("health");

    const homeResponse = await fetch(`${baseUrl}/`);
    const homeHtml = await homeResponse.text();
    assert(homeResponse.status === 200, "首页状态码不是 200");
    const assetPaths = await getAssetPaths(homeHtml);
    const javascriptPath = assetPaths.find((path) => path.endsWith(".js"));
    const stylesheetPath = assetPaths.find((path) => path.endsWith(".css"));
    assert(javascriptPath, "首页没有实际 JS 资源引用");
    assert(stylesheetPath, "首页没有实际 CSS 资源引用");
    for (const assetPath of [javascriptPath, stylesheetPath]) {
      const assetResponse = await fetch(`${baseUrl}${assetPath}`);
      assert(assetResponse.status === 200, `资源 ${assetPath} 未返回 200`);
      assert((await assetResponse.text()).length > 0, `资源 ${assetPath} 内容为空`);
    }
    result.checks.push("home-and-assets");

    const missingResponse = await fetch(`${baseUrl}/missing-t02-resource`);
    assert(missingResponse.status === 404, "随机缺失路径未返回 404");
    result.checks.push("missing-404");

    const websocket = new WebSocket(`ws://127.0.0.1:${port}/ws`);
    const ready = JSON.parse(await fetchWebSocketMessage(websocket));
    assert(ready.type === "SERVER_READY" && ready.protocolVersion === 1, "SERVER_READY 消息不匹配");
    websocket.send(JSON.stringify({ type: "SMOKE_PROBE" }));
    const notImplemented = JSON.parse(await fetchWebSocketMessage(websocket));
    assert(notImplemented.type === "ERROR" && notImplemented.code === "NOT_IMPLEMENTED", "NOT_IMPLEMENTED 消息不匹配");
    websocket.close();
    await withTimeout(once(websocket, "close"), probeTimeoutMs, "WebSocket 未关闭");
    result.checks.push("websocket");

    const invalidText = await runOneShot("bad");
    assert(invalidText.code !== 0, "PORT=bad 意外成功");
    assert(invalidText.stderr.includes("PORT 必须是 1 到 65535 之间的十进制整数"), "PORT=bad 缺少中文错误");
    const invalidRange = await runOneShot("65536");
    assert(invalidRange.code !== 0, "PORT=65536 意外成功");
    assert(invalidRange.stderr.includes("PORT 必须是 1 到 65535 之间的十进制整数"), "PORT=65536 缺少中文错误");
    result.checks.push("invalid-port");

    const occupied = await runOneShot(String(port));
    assert(occupied.code !== 0, "占用端口意外成功");
    assert(occupied.stderr.includes(`端口 ${port} 已被占用`), "占用端口缺少中文错误");
    result.checks.push("occupied-port");

    console.log(JSON.stringify(result, null, 2));
  } finally {
    await stopServer(processInfo);
  }
}

try {
  await main();
} catch (error) {
  console.error(error instanceof Error ? error.stack : error);
  process.exitCode = 1;
}
