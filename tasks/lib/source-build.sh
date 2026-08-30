#!/usr/bin/env bash
# 供 setup-*.sh 共用的「同步克隆目录到上游 + 判定是否需要重建」函数。
#
# 返回码:
#   0 = 需要构建
#   1 = 已最新，无需构建
#   2 = 同步失败（信息已打印）
#
# 设计说明（幂等 / 降成本）:
#   - 快路径: 二进制已存在 且 记录版本 == 本地源码版本 时，只做一次 `git ls-remote`
#     轻握手（不 fetch、不下载对象）探测远程；若远程未变则跳过，不执行任何拉取。
#   - 完整路径: 克隆缺失 / 源码≠远程 时，`git fetch` 后 `reset --hard` 无条件回到上游，
#     从根上丢弃本地 dirty/领先提交/detached。
#   - 用记录的 SHA 而非 mtime 判断是否重建，避免对陈旧构建产物误判。

# git 需要认证时不要交互式弹提示（会导致自动化 update 永久挂起），改为快速失败。
export GIT_TERMINAL_PROMPT=0

source "$(dirname "${BASH_SOURCE[0]}")/gh.sh"

sync_source() {
  local repo="$1" dir="$2" target="$3" state="$4"

  # ── 快路径：二进制在 + 记录版本==本地源码 → 轻探测远程，未变则不拉取 ──
  if [ -x "$target" ]; then
    local local_head
    local_head="$(git -C "$dir" rev-parse HEAD 2>/dev/null || echo none)"
    if [ "$(cat "$state" 2>/dev/null || echo none)" = "$local_head" ]; then
      local remote_head
      remote_head="$(git ls-remote "$(gh_git_url "$repo")" HEAD 2>/dev/null | awk '{print $1}' || true)"
      if [ -z "$remote_head" ]; then
        echo "离线：无法确认上游变更，跳过（保留现有二进制）"
        return 1
      fi
      if [ "$remote_head" = "$local_head" ]; then
        echo "$(basename "$target") 已是最新，未拉取"
        return 1
      fi
    fi
  fi

  # ── 克隆 / 同步回上游 ──
  local upstream old sha installed
  local proxied
  proxied="$(gh_git_url "$repo")"

  if [[ ! -d "$dir/.git" ]]; then
    echo "克隆 $(basename "$repo") ..."
    git clone "$proxied" "$dir" || { echo "克隆失败，请检查网络/代理"; return 2; }
  else
    # 让 origin 和脚本传入的仓库 URL 始终一致，避免旧克隆目录残留不同代理地址。
    git -C "$dir" remote set-url origin "$proxied"
    git -C "$dir" fetch --quiet origin || { echo "拉取失败，请检查网络/代理"; return 2; }
  fi

  upstream="$(git -C "$dir" rev-parse --abbrev-ref '@{u}' 2>/dev/null || true)"
  [[ -z "$upstream" ]] && upstream="$(git -C "$dir" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null || true)"
  [[ -z "$upstream" ]] && upstream="origin/master"

  old="$(git -C "$dir" rev-parse HEAD)"
  git -C "$dir" reset --hard "$upstream" >/dev/null || { echo "无法重置到 $upstream（源码状态异常）"; return 2; }
  sha="$(git -C "$dir" rev-parse HEAD)"

  installed="$(cat "$state" 2>/dev/null || echo none)"
  if [ "$installed" = "$sha" ] && [ -x "$target" ]; then
    echo "$(basename "$target") 已是最新（$upstream@$(git -C "$dir" rev-parse --short "$sha")），跳过构建"
    return 1
  fi
  if [ "$old" != "$sha" ]; then
    echo "检测到上游变化（$(git -C "$dir" rev-parse --short "$old") → $(git -C "$dir" rev-parse --short "$sha")），需要重建"
  else
    echo "$(basename "$target") 二进制缺失或与源码不一致，重建（$upstream@$(git -C "$dir" rev-parse --short "$sha")）"
  fi
  return 0
}
