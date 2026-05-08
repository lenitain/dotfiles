import type { ExtensionAPI } from "@earendil-works/pi-coding-agent";
import { exec } from "node:child_process";
import { promisify } from "node:util";

const execAsync = promisify(exec);

export default function (pi: ExtensionAPI) {
  pi.on("agent_end", async (event, ctx) => {
    // 获取模型信息（如果有）
    const modelLabel = ctx.model
      ? `${ctx.model.provider}/${ctx.model.id}`
      : "pi";

    // 统计本轮消息数 / tool 调用数
    const msgCount = event.messages.length;
    const toolCalls = event.messages.filter(
      (m: any) => m.role === "assistant" && m.content?.some((c: any) => c.type === "tool_use"),
    ).length;

    const summary = toolCalls > 0
      ? `${msgCount} 条消息 · ${toolCalls} 次工具调用`
      : `${msgCount} 条消息`;

    try {
      const cwd = ctx.cwd;
      await execAsync(
        `notify-send "pi (${cwd})" "对话完成: ${summary}" --app-name=pi --icon=dialog-information`,
      );
    } catch {
      // notify-send 可能不存在（非 Linux 桌面），静默忽略
    }
  });
}
