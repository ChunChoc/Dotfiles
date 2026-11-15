// Adaptación de la integración de Herdr a OpenCode V2, gestionada por Home Manager.
// No reinstalar la integración de Herdr encima de este archivo.
import net from "node:net";

export default {
  id: "herdr-agent-state",
  async setup(ctx) {
    const paneID = process.env.HERDR_PANE_ID;
    const socketPath = process.env.HERDR_SOCKET_PATH;
    if (process.env.HERDR_ENV !== "1" || !paneID || !socketPath) return;

    let seq = Date.now() * 1000;
    const children = new Map();
    const controller = new AbortController();

    function request(method, params) {
      const report = {
        id: `herdr:opencode:${++seq}`,
        method,
        params: {
          pane_id: paneID,
          source: "herdr:opencode",
          agent: "opencode",
          seq,
          ...params,
        },
      };
      return new Promise((resolve) => {
        const socket = net.createConnection(socketPath, () => {
          socket.write(`${JSON.stringify(report)}\n`);
        });
        const finish = () => {
          socket.destroy();
          resolve();
        };
        socket.setTimeout(500, finish);
        socket.on("data", finish);
        socket.on("error", finish);
        socket.on("end", finish);
        socket.on("close", resolve);
      });
    }

    async function isChild(sessionID) {
      if (!children.has(sessionID)) {
        const session = await ctx.session.get({ sessionID });
        children.set(sessionID, Boolean(session.parentID));
      }
      return children.get(sessionID);
    }

    function reportState(state, sessionID) {
      return request("pane.report_agent", {
        state,
        ...(sessionID ? { agent_session_id: sessionID } : {}),
      });
    }

    await ctx.session.hook("prompt", async ({ sessionID }) => {
      if (!(await isChild(sessionID))) await reportState("working", sessionID);
    });

    const stream = (async () => {
      for await (const event of ctx.event.subscribe({
        signal: controller.signal,
        types: [
          "session.created", "session.deleted", "session.status", "session.idle",
          "session.execution.failed", "permission.asked", "permission.replied",
          "form.created", "form.replied", "form.cancelled",
        ],
      })) {
        try {
          const data = event.data;
          const sessionID = data.sessionID ?? data.form?.sessionID;
          if (!sessionID) continue;
          if (event.type === "session.deleted") {
            children.delete(sessionID);
            continue;
          }
          if (event.type === "session.created") {
            children.set(sessionID, Boolean(data.parentID));
            if (!data.parentID) {
              await request("pane.report_agent_session", {
                agent_session_id: sessionID,
                session_start_source: "new",
              });
            }
            continue;
          }
          const child = await isChild(sessionID);
          // Un subagente no reemplaza la sesión principal del panel, pero sus
          // solicitudes de intervención sí deben marcarlo como bloqueado.
          switch (event.type) {
            case "permission.asked":
            case "form.created":
              await reportState("blocked", child ? undefined : sessionID);
              break;
            case "permission.replied":
            case "form.replied":
            case "form.cancelled":
              await reportState("working", child ? undefined : sessionID);
              break;
            case "session.execution.failed":
              if (!child) await reportState("blocked", sessionID);
              break;
            case "session.idle":
              if (!child) await reportState("idle", sessionID);
              break;
            case "session.status": {
              const kind = data.status?.type ?? data.status;
              if (!child && ["idle", "busy", "retry"].includes(kind)) {
                await reportState(kind === "idle" ? "idle" : "working", sessionID);
              }
              break;
            }
          }
        } catch (error) {
          if (!controller.signal.aborted) console.error("Herdr event failed", error);
        }
      }
    })();
    void stream.catch((error) => {
      if (!controller.signal.aborted) console.error("Herdr subscription failed", error);
    });
    return async () => {
      controller.abort();
      await stream.catch(() => {});
    };
  },
};
