import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

const soundFile = new URL("pi-notify.ogg", import.meta.url).pathname;

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async (event, ctx) => {
    // 播放提示音
    try {
      await execAsync(`paplay ${soundFile}`);
    } catch {
      // paplay 不存在时静默忽略
    }

    // 统计本轮消息数 / tool 调用数
    const msgCount = event.messages.length;
    const toolCalls = event.messages.filter(
      (m: any) => m.role === "assistant" && m.content?.some((c: any) => c.type === "tool_use"),
    ).length;

    const summary = toolCalls > 0
      ? `${msgCount} 条消息 · ${toolCalls} 次工具调用`
      : `${msgCount} 条消息`;

    // 弹窗通知
    try {
      const cwd = ctx.cwd;
      await execAsync(
        `notify-send "pi (${cwd})" "对话完成: ${summary}" --app-name=pi --icon=dialog-information`,
      );
    } catch {
      // notify-send 可能不存在，静默忽略
    }
  });
}
