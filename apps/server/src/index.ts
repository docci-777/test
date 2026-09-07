import { networkInterfaces } from "node:os";
import { fileURLToPath } from "node:url";
import { createServer, type IncomingMessage, type ServerResponse } from "node:http";
import { readFile, stat } from "node:fs/promises";
import { dirname, extname, relative, resolve, sep } from "node:path";
import { WebSocketServer } from "ws";

const port = parsePort(process.env.PORT);
const staticRoot = resolve(dirname(fileURLToPath(import.meta.url)), "../../web/dist");

const contentTypes: Record<string, string> = {
  ".css": "text/css; charset=utf-8",
  ".html": "text/html; charset=utf-8",
  ".ico": "image/x-icon",
  ".js": "text/javascript; charset=utf-8",
  ".json": "application/json; charset=utf-8",
  ".map": "application/json; charset=utf-8",
  ".png": "image/png",
  ".svg": "image/svg+xml",
  ".webp": "image/webp",
};

function parsePort(value: string | undefined): number | null {
  if (value === undefined) {
    return 3000;
  }

  if (!/^[0-9]+$/.test(value)) {
    console.error("PORT 必须是 1 到 65535 之间的十进制整数。");
    return null;
  }

  const parsed = Number(value);
  if (!Number.isSafeInteger(parsed) || parsed < 1 || parsed > 65535) {
    console.error("PORT 必须是 1 到 65535 之间的十进制整数。");
    return null;
  }

  return parsed;
}

function requestUrl(request: IncomingMessage): URL {
  return new URL(request.url ?? "/", `http://${request.headers.host ?? "localhost"}`);
}

function sendNotFound(response: ServerResponse): void {
  response.statusCode = 404;
  response.setHeader("Content-Type", "text/plain; charset=utf-8");
  response.end("未找到资源");
}

function sendMethodNotAllowed(response: ServerResponse): void {
  response.statusCode = 405;
  response.setHeader("Allow", "GET");
  response.setHeader("Content-Type", "text/plain; charset=utf-8");
  response.end("仅支持 GET 请求");
}

function decodeSafePath(pathname: string): string | null {
  try {
    const decodedPath = decodeURIComponent(pathname);
    if (decodedPath.includes("\0") || decodedPath.includes("\\")) {
      return null;
    }

    if (decodedPath.split("/").some((segment) => segment === "..")) {
      return null;
    }

    return decodedPath;
  } catch {
    return null;
  }
}

function resolveStaticFile(pathname: string): string | null {
  const decodedPath = decodeSafePath(pathname);
  if (decodedPath === null) {
    return null;
  }

  const requestedPath = decodedPath === "/" ? "index.html" : decodedPath.replace(/^\/+/, "");
  const candidate = resolve(staticRoot, requestedPath);
  const candidateRelativeToRoot = relative(staticRoot, candidate);
  if (
    candidateRelativeToRoot === ".." ||
    candidateRelativeToRoot.startsWith(`..${sep}`) ||
    candidateRelativeToRoot.includes(`..${sep}`)
  ) {
    return null;
  }

  return candidate;
}

async function serveStaticFile(response: ServerResponse, pathname: string): Promise<void> {
  const filePath = resolveStaticFile(pathname);
  if (filePath === null) {
    sendNotFound(response);
    return;
  }

  try {
    const fileInfo = await stat(filePath);
    if (!fileInfo.isFile()) {
      sendNotFound(response);
      return;
    }

    const contents = await readFile(filePath);
    response.statusCode = 200;
    response.setHeader("Content-Type", contentTypes[extname(filePath)] ?? "application/octet-stream");
    response.end(contents);
  } catch (error) {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "ENOENT" || code === "ENOTDIR") {
      sendNotFound(response);
      return;
    }

    response.statusCode = 500;
    response.setHeader("Content-Type", "text/plain; charset=utf-8");
    response.end("读取资源失败");
  }
}

async function handleRequest(request: IncomingMessage, response: ServerResponse): Promise<void> {
  if (request.method !== "GET") {
    sendMethodNotAllowed(response);
    return;
  }

  const rawPathname = (request.url ?? "/").split("?", 1)[0];
  if (decodeSafePath(rawPathname) === null) {
    sendNotFound(response);
    return;
  }

  const url = requestUrl(request);
  if (url.pathname === "/health") {
    response.statusCode = 200;
    response.setHeader("Content-Type", "application/json");
    response.end('{"ok":true}');
    return;
  }

  await serveStaticFile(response, url.pathname);
}

function printListeningUrls(listeningPort: number): void {
  console.log(`服务已启动：http://localhost:${listeningPort}`);

  const candidates = Object.values(networkInterfaces())
    .flatMap((interfaces) => interfaces ?? [])
    .filter((entry) => entry.family === "IPv4" && !entry.internal)
    .map((entry) => `http://${entry.address}:${listeningPort}`);

  if (candidates.length === 0) {
    console.log("没有可用的局域网 IPv4 地址候选。");
    return;
  }

  for (const candidate of candidates) {
    console.log(`局域网地址：${candidate}`);
  }
}

function rejectUpgrade(socket: NodeJS.WritableStream): void {
  socket.write("HTTP/1.1 404 Not Found\r\nConnection: close\r\n\r\n");
  socket.end();
}

function startServer(listeningPort: number): void {
  const server = createServer((request, response) => {
    void handleRequest(request, response).catch(() => {
      if (!response.headersSent) {
        response.statusCode = 500;
        response.setHeader("Content-Type", "text/plain; charset=utf-8");
      }
      response.end("服务器处理失败");
    });
  });
  const webSocketServer = new WebSocketServer({ noServer: true });

  webSocketServer.on("connection", (socket) => {
    socket.send(JSON.stringify({ type: "SERVER_READY", protocolVersion: 1 }));
    socket.on("message", () => {
      socket.send(JSON.stringify({ type: "ERROR", code: "NOT_IMPLEMENTED" }));
    });
    socket.on("error", () => {
      // The client may disconnect while the probe response is in flight.
    });
  });

  server.on("upgrade", (request, socket, head) => {
    const rawPathname = (request.url ?? "/").split("?", 1)[0];
    if (decodeSafePath(rawPathname) === null) {
      rejectUpgrade(socket);
      return;
    }

    let url: URL;
    try {
      url = requestUrl(request);
    } catch {
      rejectUpgrade(socket);
      return;
    }

    if (url.pathname !== "/ws") {
      rejectUpgrade(socket);
      return;
    }

    webSocketServer.handleUpgrade(request, socket, head, (webSocket) => {
      webSocketServer.emit("connection", webSocket, request);
    });
  });

  server.on("error", (error) => {
    const code = (error as NodeJS.ErrnoException).code;
    if (code === "EADDRINUSE") {
      console.error(`端口 ${listeningPort} 已被占用。`);
    } else {
      console.error(`服务启动失败：${error instanceof Error ? error.message : String(error)}`);
    }
    process.exitCode = 1;
  });

  server.listen(listeningPort, "0.0.0.0", () => {
    printListeningUrls(listeningPort);
  });
}

if (port === null) {
  process.exitCode = 1;
} else {
  startServer(port);
}
