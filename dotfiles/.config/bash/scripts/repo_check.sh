#!/usr/bin/env bash
# repo 段自检：模板的段数契约 + 端到端场景（参考点、merge、符号链接）。
# 改 prompt/repo.sh 的列数组、模板或参考点选择之后跑一遍（见 README 的「验证」）；
# 退出码 0 才算过。这里可以随便 fork，热路径不行 —— 所以检查不放 widget 里。
# 只检查自己所在的这棵树（符号链接进来也一样），不看 BASH_CONFIG_HOME：
# 否则拿一份改过的副本跑，实际测的是另一份。

# shellcheck source=/dev/null
. "${BASH_SOURCE[0]%/*}/../prompt/repo.sh"

fail=0
report() { printf 'repo_check: %s\n' "$1" >&2; fail=1; }

# jj 的 per-repo config 落在 $XDG_CONFIG_HOME/jj/repos；隔离到临时目录才不会把
# /tmp 场景仓库的配置留在 ~/.config/jj/repos。用户配置也一起隔离，场景只依赖
# jj 默认行为；身份只在建提交时需要，写进临时 config。
check_home=$(mktemp -d) || { printf 'repo_check: mktemp 失败\n' >&2; exit 1; }
trap 'rm -rf "$check_home"' EXIT
export XDG_CONFIG_HOME="$check_home/xdg"
mkdir -p "$XDG_CONFIG_HOME/jj" || exit 1
printf '[user]\nname = "repo-check"\nemail = "repo-check@example.com"\n' > "$XDG_CONFIG_HOME/jj/config.toml" || exit 1

strip_ansi() { sed $'s/\x1b\\[[0-9;]*m//g; s/\\\\\\[//g; s/\\\\\\]//g'; }

# 模板里的 \x1f 是四个字面字符；个数 + 1 就是行段数，必须等于列定义给出的段数。
check_template() {
    local label=$1 template=$2 field_count=$3 bare count
    bare=${template//\\x1f/}
    count=$(( (${#template} - ${#bare}) / 4 + 1 ))
    [ "$count" -eq "$field_count" ] || report "$label 模板产出 $count 段，列定义是 $field_count 段"
}

__bash_prompt_jj_commit_template
check_template 提交行 "$REPLY" "$__bash_prompt_jj_commit_field_count"

# 端到端：在真仓库里跑 __bash_prompt_jj，扣掉随机的 change id 后比对黄金行。
# 这一层覆盖提交行的解析、参考点的选择、距离的计算和空工作副本的减一。
expect_segment() {
    local want=$1 dir=$2 label=$3 out got
    out=$(cd "$dir" && __bash_prompt_jj && printf '%s' "$repo_ansi")
    got=$(printf '%s' "$out" | strip_ansi)
    # change id 每次建库都不同，黄金行里用 <id> 占位。
    case $got in
        *' '*) got="<id> ${got#* }" ;;
    esac
    [ "$got" = "$want" ] || report "$label 期望 [$want] 实际 [$got]"
}

# 场景：root → c1(main) → c2 → @(空)。最近的书签是祖先 main，
# @ 离它 2 个提交，但空工作副本不计 → 距离 1。
scenario_ancestor() {
    local dir=$1
    mkdir -p "$dir" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet . >/dev/null 2>&1 || exit 1
        jj describe -m c1 >/dev/null 2>&1
        jj bookmark create main >/dev/null 2>&1
        jj new >/dev/null 2>&1
        jj describe -m c2 >/dev/null 2>&1
        jj new >/dev/null 2>&1
    ) || return 1
    expect_segment "<id> main~1 (empty)" "$dir" "祖先参考点"
}

# 场景：从符号链接进仓库子目录。$PWD 是逻辑路径，jj/git 按物理路径解析；向上找
# .jj 也必须用物理路径，否则会落到 git 兜底（colocated 仓库里会画出 jj/keep/<hash>）。
scenario_symlink() {  # dir link，dir 已经是 scenario_ancestor 建的仓库
    local dir=$1 link=$2
    mkdir -p "$dir/sub" || return 1
    ln -sfn "$dir/sub" "$link" || return 1
    expect_segment "<id> main~1 (empty)" "$link" "符号链接子目录"
}

# 场景：两条分支各有一个书签，@ 是它们的 merge（空）。两个书签都在最近一层，
# 必须都画出来；latest() 会按提交时间只留一个。log 顺序是 B、A（B 的 index 更大）。
scenario_merge() {
    local dir=$1
    mkdir -p "$dir" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet . >/dev/null 2>&1 || exit 1
        jj describe -m base >/dev/null 2>&1 || exit 1
        jj bookmark create base >/dev/null 2>&1 || exit 1
        jj new >/dev/null 2>&1 || exit 1
        jj describe -m a >/dev/null 2>&1 || exit 1
        jj bookmark create A >/dev/null 2>&1 || exit 1
        jj new base >/dev/null 2>&1 || exit 1
        jj describe -m b >/dev/null 2>&1 || exit 1
        jj bookmark create B >/dev/null 2>&1 || exit 1
        jj new A B >/dev/null 2>&1 || exit 1
    ) || return 1
    expect_segment "<id> B,A (empty)" "$dir" "merge 的两个父书签"
}

# 场景：书签就在 @ 上 → 距离 0，只画书签名。
scenario_bookmark_on_at() {
    local dir=$1
    mkdir -p "$dir" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet . >/dev/null 2>&1 || exit 1
        jj bookmark create feat >/dev/null 2>&1
    ) || return 1
    expect_segment "<id> feat (empty)" "$dir" "书签在 @ 上"
}

if command -v jj >/dev/null 2>&1; then
    scenario_dir=$(mktemp -d) || report "端到端: mktemp 失败"
    if [ -n "${scenario_dir-}" ]; then
        scenario_ancestor "$scenario_dir/ancestor"
        scenario_symlink "$scenario_dir/ancestor" "$scenario_dir/link"
        scenario_merge "$scenario_dir/merge"
        scenario_bookmark_on_at "$scenario_dir/on_at"
        rm -rf "$scenario_dir"
    fi
else
    printf 'repo_check: 跳过端到端场景（没有 jj）\n'
fi

[ "$fail" = 0 ] && printf 'repo_check: ok\n'
exit "$fail"
