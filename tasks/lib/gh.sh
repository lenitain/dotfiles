#!/usr/bin/env bash
# 供 setup-*.sh 共用的 GitHub 镜像代理函数。
#
# 提供三个场景：
#   gh_api <endpoint>           — GitHub API 调用（输出 JSON）
#   gh_download <url> <output>  — 资产下载（写入文件）
#   gh_git_url <repo_url>       — Git 克隆/拉取（输出代理后 URL）

GH_MIRRORS=(
  "gh-proxy.com"
  "gh-proxy.org"
  "ghfast.top"
)

gh_api() {
  local endpoint="$1"
  for p in "${GH_MIRRORS[@]}"; do
    if curl -fsSL --max-time 20 "https://$p/https://api.github.com$endpoint" 2>/dev/null; then
      return 0
    fi
    echo "镜像 $p 获取 API 失败，尝试下一个 ..." >&2
  done
  return 1
}

gh_download() {
  local url="$1" output="$2"
  for p in "${GH_MIRRORS[@]}"; do
    echo "下载 (镜像 $p) ..." >&2
    if curl -fL --retry 2 --max-time 600 "https://$p/$url" -o "$output" 2>/dev/null; then
      return 0
    fi
    echo "镜像 $p 下载失败，尝试下一个 ..." >&2
  done
  return 1
}

gh_git_url() {
  local repo_url="$1"
  for p in "${GH_MIRRORS[@]}"; do
    if git ls-remote --exit-code "https://$p/$repo_url" HEAD &>/dev/null; then
      echo "https://$p/$repo_url"
      return 0
    fi
  done
  # 所有镜像不可用，回退原 URL
  echo "警告：所有镜像不可用，回退原 URL" >&2
  echo "$repo_url"
}
