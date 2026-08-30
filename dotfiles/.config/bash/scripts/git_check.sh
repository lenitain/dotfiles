#!/usr/bin/env bash
# git 段自检：真实仓库里的分支 / dirty / stash / 上游 / detached / bare / 空仓库，
# 以及 widgets/repo.sh 写回的宽度缓存。改 prompt/repo.sh 的 git 分支后跑一遍
# （见 README 的「验证」）；退出码 0 才算过。可以随便 fork：手动脚本，不在热路径上。
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
    out=$(cd "$dir" && __bash_prompt_git && printf '%s' "$repo_ansi")
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

# stash：数字恒开
mkdir "$tmp/stash" && init_repo "$tmp/stash" \
    && printf 'a\n' > "$tmp/stash/a.txt" && commit_in "$tmp/stash" init \
    && printf 'b\n' > "$tmp/stash/b.txt" \
    && git -C "$tmp/stash" add b.txt \
    && git -C "$tmp/stash" stash --quiet
expect_in "main ≡1" "$tmp/stash" "stash"

# 上游：本地领先 2、落后 1（stash / 箭头之间各一个空格）
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
expect_in "main ⇡2 ⇣1" "$tmp/sync" "上游领先 2 / 落后 1"

# 无 upstream：不出箭头
mkdir "$tmp/local" && init_repo "$tmp/local" \
    && printf 'a\n' > "$tmp/local/a.txt" && commit_in "$tmp/local" init
expect_in "main" "$tmp/local" "无 upstream"

# detached HEAD：name-rev 给 main~N
mkdir "$tmp/detached" && init_repo "$tmp/detached" \
    && printf 'a\n' > "$tmp/detached/a.txt" && commit_in "$tmp/detached" one \
    && printf 'b\n' > "$tmp/detached/b.txt" && commit_in "$tmp/detached" two \
    && git -C "$tmp/detached" checkout --quiet HEAD~1
segment_in "$tmp/detached"
case $REPLY in
    main|main~[0-9]*) ;;
    *) report "detached HEAD 期望 main~N，实际 [$REPLY]" ;;
esac

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
