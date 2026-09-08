import { StrictMode, useEffect, useState, type ReactElement } from "react";
import { createRoot } from "react-dom/client";
import "./styles.css";

type ConnectionStatus = "connecting" | "connected" | "disconnected";

function websocketUrl(): string {
  const protocol = window.location.protocol === "https:" ? "wss:" : "ws:";
  const port = window.location.port === "" ? "" : `:${window.location.port}`;
  return `${protocol}//${window.location.hostname}${port}/ws`;
}

function App(): ReactElement {
  const [connectionStatus, setConnectionStatus] = useState<ConnectionStatus>("connecting");

  useEffect(() => {
    const socket = new WebSocket(websocketUrl());

    socket.addEventListener("message", (event) => {
      try {
        const message = JSON.parse(String(event.data)) as {
          type?: string;
          protocolVersion?: number;
        };
        if (message.type === "SERVER_READY" && message.protocolVersion === 1) {
          setConnectionStatus("connected");
        }
      } catch {
        setConnectionStatus("disconnected");
      }
    });
    socket.addEventListener("error", () => {
      setConnectionStatus("disconnected");
    });
    socket.addEventListener("close", () => {
      setConnectionStatus("disconnected");
    });

    return () => {
      socket.close();
    };
  }, []);

  const connectionText = {
    connecting: "正在连接服务…",
    connected: "服务已连接",
    disconnected: "连接已断开",
  }[connectionStatus];

  return (
    <main className="page-shell">
      <section className="hero-card" aria-labelledby="page-title">
        <p className="eyebrow">局域网工程验证</p>
        <h1 id="page-title">游戏功能尚未实现</h1>
        <p className="intro">
          这是工程验证页，用来确认主机服务、静态资源和局域网连接状态。
        </p>

        <div className={`connection-panel connection-${connectionStatus}`} aria-live="polite">
          <span className="status-dot" aria-hidden="true" />
          <span>{connectionText}</span>
        </div>

        <div className="notice-card">
          <h2>当前阶段说明</h2>
          <p>主机重启会丢失当前游戏。棋盘、房间和回合功能将在后续阶段实现。</p>
        </div>
      </section>
    </main>
  );
}

const root = document.getElementById("root");
if (root === null) {
  throw new Error("页面缺少根节点");
}

createRoot(root).render(
  <StrictMode>
    <App />
  </StrictMode>,
);
