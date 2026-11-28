#!/usr/bin/env bash
# git 段自检：真实仓库里的分支 / dirty / 上游 / 操作中状态 / detached（含只剩 jj 记账 ref）/
# bare / 空仓库，以及 widgets/repo.sh 写回的宽度缓存。改 prompt/repo.sh 的 git 分支后跑一遍
# （见 README 的「验证」）；退出码 0 才算过。可以随便 fork：手动脚本，不在热路径上。
# stash 是故意不画的；下面保留一个 stash 场景，验证它不会出现在段里。
# 每个仓库都用 --initial-branch=main 初始化，结果不依赖本机的 init.defaultBranch。

config=${BASH_CONFIG_HOME:-$HOME/.config/bash}

# shellcheck source=/dev/null
. "$config/prompt/repo.sh"

fail=0
report() { printf 'git_check: %s\n' "$1" >&2; fail=1; }

strip_ansi() { sed $'s/\x1b\\[[0-9;]*m//g; s/\\\\\\[//g; s/\\\\\\]//g'; }

# 在目录里跑 __bash_prompt_git：去掉颜色后的输出写进 REPLY，退出码原样返回。
segment_in() {
    local dir=$1 out rc
    out=$(cd "$dir" && __bash_prompt_repo_kinds && __bash_prompt_git && printf '%s' "$repo_ansi")
    rc=$?
    REPLY=$(printf '%s' "$out" | strip_ansi)
    return $rc
}

expect_in() {
    local want=$1 dir=$2 label=$3 rc
    segment_in "$dir"
    rc=$?
    if [ "$rc" -ne 0 ] || [ "$REPLY" != "$want" ]; then
        report "$label 期望 [_$want_] rc=0，实际 [_$REPLY_] rc=$rc"
    fi
}

expect_none_in() {
    local dir=$1 label=$2 rc
    segment_in "$dir"
    rc=$?
    if [ "$rc" -eq 0 ] || [ -n "$REPLY" ]; then
        report "$label 期望无输出 rc!=0，实际 [_$REPLY_] rc=$rc"
    fi
}

init_repo() {
    git init --quiet --initial-branch=main "$1" || { report "git init $1 失败"; return 1; }
    git -C "$1" config user.email git-check@example.com
    git -C "$1" config user.name git-check
}

commit_in() {  # dir message
    git -C "$1" add -A || return 1
    git -C "$1" commit --quiet -m "$2"
}

tmp=$(mktemp -d) || { printf 'git_check: mktemp 失败\n' >&2; exit 1; }
trap 'rm -rf "$tmp"' EXIT
export XDG_RUNTIME_DIR=$tmp

# 仓库外：没有仓库段
mkdir "$tmp/outside"
expect_none_in "$tmp/outside" "仓库外"

# 未提交（unborn）：只有分支名
mkdir "$tmp/unborn" && init_repo "$tmp/unborn"
expect_in "main" "$tmp/unborn" "未提交仓库"

# 干净仓库
mkdir "$tmp/clean" && init_repo "$tmp/clean" \
    && printf 'a\n' > "$tmp/clean/a.txt" && commit_in "$tmp/clean" init
expect_in "main" "$tmp/clean" "干净仓库"

# dirty：未跟踪文件也算
printf 'u\n' > "$tmp/clean/u.txt"
expect_in "main*" "$tmp/clean" "dirty 仓库"
rm -f "$tmp/clean/u.txt"

# stash：不再画；stash 之后工作区是干净的，段里只有分支名
mkdir "$tmp/stash" && init_repo "$tmp/stash" \
    && printf 'a\n' > "$tmp/stash/a.txt" && commit_in "$tmp/stash" init \
    && printf 'b\n' > "$tmp/stash/b.txt" \
    && git -C "$tmp/stash" add b.txt \
    && git -C "$tmp/stash" stash --quiet
expect_in "main" "$tmp/stash" "stash 不画"

# 上游：本地领先 2、落后 1；只画方向，不画数字
git init --bare --quiet --initial-branch=main "$tmp/remote.git"
git clone --quiet "$tmp/remote.git" "$tmp/sync" 2>/dev/null
git -C "$tmp/sync" config user.email git-check@example.com
git -C "$tmp/sync" config user.name git-check
printf 'a\n' > "$tmp/sync/a.txt" && commit_in "$tmp/sync" init
git -C "$tmp/sync" push --quiet --set-upstream origin HEAD
git clone --quiet "$tmp/remote.git" "$tmp/other" 2>/dev/null
git -C "$tmp/other" config user.email git-check@example.com
git -C "$tmp/other" config user.name git-check
printf 'r\n' > "$tmp/other/r.txt" && commit_in "$tmp/other" remote
git -C "$tmp/other" push --quiet
printf '1\n' > "$tmp/sync/1.txt" && commit_in "$tmp/sync" one
printf '2\n' > "$tmp/sync/2.txt" && commit_in "$tmp/sync" two
git -C "$tmp/sync" fetch --quiet
expect_in "main ↑ ↓" "$tmp/sync" "上游领先 2 / 落后 1"

# 无 upstream：不出箭头
mkdir "$tmp/local" && init_repo "$tmp/local" \
    && printf 'a\n' > "$tmp/local/a.txt" && commit_in "$tmp/local" init
expect_in "main" "$tmp/local" "无 upstream"

# detached HEAD：name-rev 给 main~N，段首画 (detached)
mkdir "$tmp/detached" && init_repo "$tmp/detached" \
    && printf 'a\n' > "$tmp/detached/a.txt" && commit_in "$tmp/detached" one \
    && printf 'b\n' > "$tmp/detached/b.txt" && commit_in "$tmp/detached" two \
    && git -C "$tmp/detached" checkout --quiet HEAD~1
segment_in "$tmp/detached"
case $REPLY in
    '(detached) main'|'(detached) main~'[0-9]*) ;;
    *) report "detached HEAD 期望 (detached) main~N，实际 [$REPLY]" ;;
esac

# detached HEAD、唯一指向它的 ref 是 jj 的记账 ref（共置仓库里 jj new 之后的样子）：
# refs/jj/* 不能画进 git 段，要换成短哈希。
mkdir "$tmp/detached-jj-keep" && init_repo "$tmp/detached-jj-keep" \
    && printf 'a\n' > "$tmp/detached-jj-keep/a.txt" && commit_in "$tmp/detached-jj-keep" one \
    && git -C "$tmp/detached-jj-keep" checkout --quiet --detach HEAD \
    && oid=$(git -C "$tmp/detached-jj-keep" rev-parse HEAD) \
    && git -C "$tmp/detached-jj-keep" update-ref "refs/jj/keep/$oid" "$oid" \
    && git -C "$tmp/detached-jj-keep" branch --quiet -D main
expect_in "(detached) $(git -C "$tmp/detached-jj-keep" rev-parse --short HEAD)" \
    "$tmp/detached-jj-keep" "只剩 jj 记账 ref 的 detached HEAD"

# 操作中状态：直接读 gitdir/rebase-merge 的 msgnum 与 end，不额外 fork。
mkdir "$tmp/rebase" && init_repo "$tmp/rebase" \
    && printf 'a\n' > "$tmp/rebase/a.txt" && commit_in "$tmp/rebase" init \
    && mkdir -p "$tmp/rebase/.git/rebase-merge" \
    && printf '2\n' > "$tmp/rebase/.git/rebase-merge/msgnum" \
    && printf '5\n' > "$tmp/rebase/.git/rebase-merge/end"
expect_in "main REBASE 2/5" "$tmp/rebase" "rebase-merge 状态"

# worktree：.git 是文件，状态文件在 gitdir: 指向的目录里。
mkdir "$tmp/wt" && init_repo "$tmp/wt" \
    && printf 'a\n' > "$tmp/wt/a.txt" && commit_in "$tmp/wt" init \
    && git -C "$tmp/wt" worktree add --quiet "$tmp/wt-linked" -b linked
wt_gitdir=$(git -C "$tmp/wt-linked" rev-parse --git-dir)
mkdir -p "$wt_gitdir/rebase-merge" \
    && printf '3\n' > "$wt_gitdir/rebase-merge/msgnum" \
    && printf '7\n' > "$wt_gitdir/rebase-merge/end"
expect_in "linked REBASE 3/7" "$tmp/wt-linked" "worktree 的 rebase 状态"

# 空仓库 clone：@{upstream} 会吐出字面量，不能出箭头，也不能报错
git init --bare --quiet --initial-branch=main "$tmp/empty-remote.git"
git clone --quiet "$tmp/empty-remote.git" "$tmp/empty" 2>/dev/null
expect_in "main" "$tmp/empty" "空仓库 clone"

# bare 仓库：is-inside-work-tree 是 false，按约定不出仓库段
git init --bare --quiet --initial-branch=main "$tmp/bare.git"
expect_none_in "$tmp/bare.git" "bare 仓库"

# 宽度缓存：widget 必须把输出的可见宽度写给 ps1.sh；仓库外写 0。
# 用 exec 在目标目录里直接跑：进程号换成 widget 但父进程仍是本脚本，
# widget 里的 $PPID 才等于本脚本的 $$。
width_cache() {  # dir label
    local dir=$1 label=$2 out cache width
    ( cd "$dir" && exec "$config/widgets/repo.sh" ) > "$tmp/out"
    out=$(<"$tmp/out")
    __bash_prompt_repo_width_read "$$" || { report "$label 没有写出宽度缓存"; return; }
    cache=$REPLY
    __bash_prompt_visible_length "$out"
    width=$REPLY
    [ "$cache" = "$width" ] || report "$label 缓存宽度期望 $width 实际 $cache"
}
width_cache "$tmp/sync" "宽度缓存（仓库里）"
width_cache "$tmp/outside" "宽度缓存（仓库外）"

# 缓存内容不是数字时必须拒绝，ps1.sh 才能安全地退回上限。
__bash_prompt_repo_width_file "$$" && printf 'abc\n' > "$REPLY"
__bash_prompt_repo_width_read "$$" && report "宽度缓存: 非数字内容应被拒绝"

[ "$fail" = 0 ] && printf 'git_check: ok\n'
exit "$fail"
