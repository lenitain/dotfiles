/**
 * Session Browser Extension — /sessions command
 *
 * Two-level TUI browser:
 *   Level 1: Project folders (decoded from session directory names)
 *   Level 2: Sessions in selected folder with preview (date, messages, first line)
 *
 * Works via ~/.pi/agent/extensions/ — no core project changes.
 */

import type { ExtensionAPI, Theme } from "@earendil-works/pi-coding-agent";
import { matchesKey, truncateToWidth, visibleWidth } from "@earendil-works/pi-tui";
import { Type } from "typebox";
import * as fs from "node:fs/promises";
import * as path from "node:path";

// ── Types ──

interface SessionInfo {
  file: string;
  name: string;
  displayPath: string;
  date: Date;
  messageCount: number;
  preview: string;
}

interface FolderInfo {
  dirName: string;
  displayName: string;
  sessionCount: number;
}

// ── Dir name decode (mirrors SessionManager encoding: `/` → `-`, wrapped in `--`) ──

function decodeDirName(dirName: string): string {
  const home = process.env.HOME || "/home/pilot";
  const decoded = dirName
    .replace(/^--|--$/g, "")
    .replace(/-/g, "/")
    .replace(/^\/+|\/+$/g, "");
  const fullPath = `/${decoded}`;
  return fullPath.startsWith(home) ? `~${fullPath.slice(home.length)}` : fullPath;
}

// ── Session Scanner ──

const SESSION_DIR = path.join(
  process.env.HOME || process.env.USERPROFILE || "/home/pilot",
  ".pi/agent/sessions",
);

async function readFirstLine(filePath: string): Promise<string> {
  try {
    const content = await fs.readFile(filePath, "utf-8");
    const lines = content.trim().split("\n");
    for (const line of lines) {
      if (!line) continue;
      try {
        const entry = JSON.parse(line);
        if (entry.type === "message" && entry.message?.role === "user") {
          const text = entry.message.content
            ?.map((c: any) => (typeof c === "string" ? c : c.text || ""))
            .filter(Boolean)
            .join(" ") || "";
          const cleaned = text.replace(/[\x00-\x1f\x7f]/g, " ").trim();
          return cleaned.slice(0, 120);
        }
      } catch {
        continue;
      }
    }
  } catch {
    // ignore
  }
  return "";
}

async function scanFolders(): Promise<FolderInfo[]> {
  const folders: FolderInfo[] = [];
  let dirEntries: fs.Dirent[];
  try {
    dirEntries = await fs.readdir(SESSION_DIR, { withFileTypes: true });
  } catch {
    return folders;
  }
  for (const entry of dirEntries) {
    if (!entry.isDirectory()) continue;
    const subdir = path.join(SESSION_DIR, entry.name);
    let files: string[];
    try {
      files = await fs.readdir(subdir);
    } catch {
      continue;
    }
    const sessionFiles = files.filter((f) => f.endsWith(".jsonl"));
    if (sessionFiles.length === 0) continue;
    folders.push({
      dirName: entry.name,
      displayName: decodeDirName(entry.name),
      sessionCount: sessionFiles.length,
    });
  }
  folders.sort((a, b) => b.sessionCount - a.sessionCount || a.displayName.localeCompare(b.displayName));
  return folders;
}

async function scanSessionsInFolder(folderName: string): Promise<SessionInfo[]> {
  const sessions: SessionInfo[] = [];
  const folderPath = path.join(SESSION_DIR, folderName);
  let files: string[];
  try {
    files = await fs.readdir(folderPath);
  } catch {
    return sessions;
  }
  for (const file of files) {
    if (!file.endsWith(".jsonl")) continue;
    const filePath = path.join(folderPath, file);
    let stats: fs.Stats;
    try {
      stats = await fs.stat(filePath);
    } catch {
      continue;
    }
    let name = "";
    let messageCount = 0;
    try {
      const content = await fs.readFile(filePath, "utf-8");
      const lines = content.trim().split("\n");
      const header = lines[0] ? JSON.parse(lines[0]) : null;
      if (header?.name) name = header.name;
      messageCount = Math.max(0, lines.length - 1);
    } catch {
      // corrupt file
    }
    const preview = await readFirstLine(filePath);
    sessions.push({ file: filePath, name, displayPath: file, date: stats.mtime, messageCount, preview });
  }
  sessions.sort((a, b) => b.date.getTime() - a.date.getTime());
  return sessions;
}

// ── Two-Level TUI Component ──

class ImportPicker {
  private phase: "folders" | "sessions" = "folders";
  private folders: FolderInfo[] = [];
  private sessions: SessionInfo[] = [];
  private folderIndex = 0;
  private sessionIndex = 0;
  private selectedFolder: string | null = null;
  private theme: Theme;
  private onClose: (session: SessionInfo | null) => void;
  private requestRender: () => void;
  private done = false;
  private cachedWidth?: number;
  private cachedLines?: string[];

  constructor(folders: FolderInfo[], theme: Theme, onClose: (session: SessionInfo | null) => void, requestRender: () => void) {
    this.folders = folders;
    this.theme = theme;
    this.onClose = onClose;
    this.requestRender = requestRender;
  }

  handleInput(data: string): void {
    if (this.done) return;
    if (matchesKey(data, "escape") || matchesKey(data, "ctrl+c")) {
      if (this.phase === "sessions") {
        this.phase = "folders";
        this.sessionIndex = 0;
        this.selectedFolder = null;
        this.sessions = [];
        this.invalidate();
        return;
      }
      this.done = true;
      this.onClose(null);
      return;
    }
    if (this.phase === "folders") this.handleFolderInput(data);
    else this.handleSessionInput(data);
  }

  private handleFolderInput(data: string): void {
    if (matchesKey(data, "up") || data === "k") { this.folderIndex = Math.max(0, this.folderIndex - 1); this.invalidate(); return; }
    if (matchesKey(data, "down") || data === "j") { this.folderIndex = Math.min(this.folders.length - 1, this.folderIndex + 1); this.invalidate(); return; }
    if (data === "g") { this.folderIndex = 0; this.invalidate(); return; }
    if (data === "G") { this.folderIndex = this.folders.length - 1; this.invalidate(); return; }
    if (matchesKey(data, "enter") || matchesKey(data, "return")) {
      const folder = this.folders[this.folderIndex];
      if (!folder) return;
      this.selectedFolder = folder.dirName;
      this.phase = "sessions";
      this.sessionIndex = 0;
      this.invalidate();
      scanSessionsInFolder(folder.dirName).then((sessions) => {
        this.sessions = sessions;
        this.invalidate();
        this.requestRender();
      });
    }
  }

  private handleSessionInput(data: string): void {
    if (matchesKey(data, "up") || data === "k") { this.sessionIndex = Math.max(0, this.sessionIndex - 1); this.invalidate(); return; }
    if (matchesKey(data, "down") || data === "j") { this.sessionIndex = Math.min(this.sessions.length - 1, this.sessionIndex + 1); this.invalidate(); return; }
    if (data === "g") { this.sessionIndex = 0; this.invalidate(); return; }
    if (data === "G") { this.sessionIndex = this.sessions.length - 1; this.invalidate(); return; }
    if (matchesKey(data, "enter") || matchesKey(data, "return")) {
      const session = this.sessions[this.sessionIndex];
      if (!session) return;
      this.done = true;
      this.onClose(session);
    }
  }

  private formatDate(d: Date): string {
    const now = new Date();
    const diff = now.getTime() - d.getTime();
    const days = Math.floor(diff / 86400000);
    if (days === 0) return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
    if (days === 1) return "1d ago";
    if (days < 7) return `${days}d ago`;
    if (days < 30) return `${Math.floor(days / 7)}w ago`;
    return d.toLocaleDateString([], { month: "short", day: "numeric" });
  }

  invalidate(): void { this.cachedWidth = undefined; this.cachedLines = undefined; }

  render(width: number): string[] {
    if (this.cachedLines && this.cachedWidth === width) return this.cachedLines;
    const th = this.theme;
    const lines: string[] = [];
    lines.push("");
    if (this.phase === "folders") this.renderFolders(lines, th, width);
    else this.renderSessions(lines, th, width);
    lines.push("");
    this.cachedWidth = width;
    this.cachedLines = lines;
    return lines;
  }

  private renderFolders(lines: string[], th: Theme, width: number): void {
    const title = th.fg("accent", " Import Session ");
    const dash = th.fg("borderMuted", "\u2500");
    const pad = Math.max(0, width - 14);
    lines.push(truncateToWidth(`${dash}${title}${th.fg("borderMuted", "\u2500".repeat(pad))}`, width));
    lines.push("");

    if (this.folders.length === 0) {
      lines.push(truncateToWidth(`  ${th.fg("dim", "No session folders found")}`, width));
      lines.push("");
      lines.push(truncateToWidth(`  ${th.fg("dim", "\u2191\u2193/jk · Enter select · Esc cancel")}`, width));
      return;
    }

    lines.push(truncateToWidth(
      `  ${th.fg("muted", `${this.folders.length} project${this.folders.length > 1 ? "s" : ""}`)}  ${th.fg("dim", "(\u2191\u2193/jk navigate · Enter open · Esc cancel)")}`, width));
    lines.push("");

    const maxVisible = Math.min(this.folders.length, 12);
    const startIdx = Math.max(0, Math.min(this.folderIndex - Math.floor(maxVisible / 2), this.folders.length - maxVisible));
    const endIdx = Math.min(startIdx + maxVisible, this.folders.length);

    for (let i = startIdx; i < endIdx; i++) {
      const f = this.folders[i];
      const isSel = i === this.folderIndex;
      const prefix = isSel ? th.fg("accent", " \u25C6 ") : "   ";
      const countStr = th.fg("dim", `${f.sessionCount} session${f.sessionCount > 1 ? "s" : ""}`);
      const nameStr = th.fg("text", f.displayName);
      const line = `${prefix}${nameStr}  ${countStr}`;
      lines.push(truncateToWidth(isSel ? th.bg("selectedBg", line) : line, width));
    }

    if (this.folders.length > maxVisible) {
      lines.push(truncateToWidth(`  ${th.fg("dim", `(${this.folderIndex + 1}/${this.folders.length})`)}`, width));
    }
    lines.push("");
    lines.push(truncateToWidth(
      `  ${th.fg("dim", "\u2191\u2193/jk navigate · Enter open · g top · G bottom · Esc cancel")}`, width));
  }

  private renderSessions(lines: string[], th: Theme, width: number): void {
    const folder = this.folders.find((f) => f.dirName === this.selectedFolder);
    const folderLabel = folder ? th.fg("borderMuted", ` ${folder.displayName} `) : "";
    const title = th.fg("accent", ` Sessions${folderLabel}`);
    const dash = th.fg("borderMuted", "\u2500");
    const pad = Math.max(0, width - 12);
    lines.push(truncateToWidth(`${dash}${title}${th.fg("borderMuted", "\u2500".repeat(pad))}`, width));
    lines.push("");

    if (this.sessions.length === 0) {
      const msg = this.selectedFolder && !this.sessions.length ? "Loading sessions..." : "No sessions found";
      lines.push(truncateToWidth(`  ${th.fg("dim", msg)}`, width));
      lines.push("");
      lines.push(truncateToWidth(`  ${th.fg("dim", "Esc back")}`, width));
      return;
    }

    lines.push(truncateToWidth(
      `  ${th.fg("muted", `${this.sessions.length} session${this.sessions.length > 1 ? "s" : ""}`)}  ${th.fg("dim", "(\u2191\u2193/jk navigate · Enter import · Esc back)")}`, width));
    lines.push("");

    const maxVisible = Math.min(this.sessions.length, 12);
    const startIdx = Math.max(0, Math.min(this.sessionIndex - Math.floor(maxVisible / 2), this.sessions.length - maxVisible));
    const endIdx = Math.min(startIdx + maxVisible, this.sessions.length);

    for (let i = startIdx; i < endIdx; i++) {
      const s = this.sessions[i];
      const isSel = i === this.sessionIndex;
      const prefix = isSel ? th.fg("accent", " \u25C6 ") : "   ";

      const mainText = s.name ? th.fg("warning", s.name) : th.fg("text", s.preview || "(empty)");
      const dateStr = this.formatDate(s.date);
      const countStr = `${s.messageCount} msgs`;
      const rightStr = `${dateStr}  ${countStr}`;

      // Build left part, then pad to push right part to the edge
      const leftPart = `${prefix}${mainText}`;
      const rightW = visibleWidth(rightStr) + 2; // +2 spacing
      const availLeft = width - rightW;
      const truncatedLeft = truncateToWidth(leftPart, Math.max(10, availLeft - 1), "\u2026");
      const padAmt = Math.max(1, width - visibleWidth(truncatedLeft) - visibleWidth(rightStr));
      const line = truncatedLeft + " ".repeat(padAmt) + dateStr + "  " + countStr;

      lines.push(truncateToWidth(isSel ? th.bg("selectedBg", line) : line, width));

      // Preview line below selected session
      if (isSel && s.name && s.preview) {
        const indent = th.fg("dim", "   \u2514 ");
        const pl = truncateToWidth(`${indent}${th.fg("muted", s.preview)}`, width);
        lines.push(pl);
      }
    }

    if (this.sessions.length > maxVisible) {
      lines.push(truncateToWidth(`  ${th.fg("dim", `(${this.sessionIndex + 1}/${this.sessions.length})`)}`, width));
    }
    lines.push("");
    lines.push(truncateToWidth(
      `  ${th.fg("dim", "\u2191\u2193/jk navigate · Enter import · Esc back to folders · g top · G bottom")}`, width));
  }
}

// ── Extension Entry ──

export default function (pi: ExtensionAPI) {
  // ── /sessions command — two-level TUI browser ──
  pi.registerCommand("sessions", {
    description: "Browse project folders and import a session",
    handler: async (_args, ctx) => {
      if (!ctx.hasUI) {
        ctx.ui.notify("/import requires interactive mode", "error");
        return;
      }
      const folders = await scanFolders();
      if (folders.length === 0) {
        ctx.ui.notify("No sessions found in ~/.pi/agent/sessions/", "warning");
        return;
      }
      const picked = await ctx.ui.custom<SessionInfo | null>(
        (tui, theme, _kb, done) => new ImportPicker(folders, theme, (s) => done(s), () => tui.requestRender()),
      );
      if (picked) {
        const label = picked.name ? `${picked.name} (${picked.displayPath})` : picked.displayPath;
        ctx.ui.notify(`Importing: ${label}`, "info");
        pi.sendUserMessage(`/resume "${picked.file}"`, { deliverAs: "followUp" });
      }
    },
  });

  // ── `import_session` tool for LLM ──
  pi.registerTool({
    name: "import_session",
    label: "Import Session",
    description:
      "List available sessions or import one by file path. Call with action=list first to discover sessions.",
    parameters: Type.Object({
      action: Type.Union(
        [Type.Literal("list"), Type.Literal("import")],
        { description: "list to show sessions, import to load one" },
      ),
      file: Type.Optional(
        Type.String({
          description: "Full path to the .jsonl session file (required when action=import)",
        }),
      ),
    }),
    async execute(_toolCallId, params, _signal, _onUpdate, _ctx) {
      if (params.action === "list") {
        const folders = await scanFolders();
        if (folders.length === 0) {
          return { content: [{ type: "text", text: "No sessions found in ~/.pi/agent/sessions/." }] };
        }
        const lines = folders.map((f, i) =>
          `${String(i + 1).padStart(2)}. ${f.displayName}  (${f.sessionCount} sessions)`,
        );
        return {
          content: [
            {
              type: "text",
              text: `Found ${folders.length} project folder(s):\n\n${lines.join("\n")}\n\n` +
                `To import: call import_session with action="import" and the full session file path.`,
            },
          ],
          details: {
            folders: folders.map((f) => ({
              displayName: f.displayName,
              dirName: f.dirName,
              sessionCount: f.sessionCount,
            })),
          },
        };
      }
      if (!params.file) {
        return {
          content: [{ type: "text", text: "Error: file path is required for import. Use action=list first." }],
        };
      }
      pi.sendUserMessage(`/resume "${params.file}"`, { deliverAs: "followUp" });
      return {
        content: [{ type: "text", text: `Importing session: ${params.file}. /resume queued as follow-up.` }],
      };
    },
  });
}
