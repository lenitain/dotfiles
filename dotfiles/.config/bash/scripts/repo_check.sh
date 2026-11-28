#!/usr/bin/env bash
# repo 段自检：模板的段数契约 + 端到端场景（参考点、merge、符号链接、未 snapshot 的改动、
# snapshot 警告、书签冲突、jj 报错、共置仓库的两段、jj 段嵌在 git 工作树里）。
# jj 书签只画名字和 +；距离数字已移除，多个同层书签写成 main,dev+（+ 修饰整组）。
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
# snapshot 警告走 $XDG_RUNTIME_DIR 下的 per-shell 文件；隔离到临时目录，不碰真实 runtime dir。
export XDG_RUNTIME_DIR="$check_home/run"
mkdir -p "$XDG_RUNTIME_DIR" || exit 1

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

# 端到端：在真仓库里跑 $4（默认 __bash_prompt_jj），扣掉随机的 change id 后比对
# 黄金行。这一层覆盖提交行的解析、参考点的选择、距离的计算和空工作副本的减一。
expect_segment() {  # want dir label [fn]
    local want=$1 dir=$2 label=$3 fn=${4:-__bash_prompt_jj} out got
    out=$(cd "$dir" && "$fn" && printf '%s' "$repo_ansi")
    got=$(printf '%s' "$out" | strip_ansi)
    # change id 每次建库都不同，黄金行里用 <id> 占位。
    case $got in
        *' '*) got="<id> ${got#* }" ;;
    esac
    [ "$got" = "$want" ] || report "$label 期望 [$want] 实际 [$got]"
}

# 场景：root → c1(main) → c2 → @(空)。最近的书签是祖先 main，
# @ 离它 2 个提交，但空工作副本不计 → 仍画 +（不是书签上）。
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
    expect_segment "<id> main+ (empty)" "$dir" "祖先参考点"
}

# 场景：改完文件、还没跑任何 jj 命令。提示符必须自己 snapshot，立刻画出 * 和 +；
# 退回 --ignore-working-copy 读旧状态时这里会停在 `<id> main (empty)`（回归测试）。
scenario_unsnapshotted_change() {
    local dir=$1
    mkdir -p "$dir" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet . >/dev/null 2>&1 || exit 1
        printf 'a\n' > f || exit 1
        jj describe -m c1 >/dev/null 2>&1 || exit 1
        jj bookmark create main >/dev/null 2>&1 || exit 1
        jj new >/dev/null 2>&1 || exit 1
    ) || return 1
    expect_segment "<id> main (empty)" "$dir" "改动前的空工作副本"
    printf 'b\n' >> "$dir/f"
    expect_segment "<id> main+*" "$dir" "未 snapshot 的改动"
}

# 场景：新文件超过 snapshot.max-new-file-size（默认 1MiB）。jj 拒绝 snapshot，
# 只在 stderr 写 warning；仓库段必须画 !，否则提示符看起来正常、文件却没进 jj。
scenario_snapshot_warning() {
    local dir=$1
    mkdir -p "$dir" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet . >/dev/null 2>&1 || exit 1
        jj describe -m c1 >/dev/null 2>&1 || exit 1
        jj bookmark create main >/dev/null 2>&1 || exit 1
        jj new >/dev/null 2>&1 || exit 1
        head -c 2000000 /dev/zero | tr '\0' 'x' > big.bin || exit 1
    ) || return 1
    expect_segment "<id> main (empty) !" "$dir" "snapshot 警告"
}

# 场景：书签冲突——本地移过书签、远端又前进了。jj st 会警告、jj log <名字> 直接报错，
# 仓库段必须在书签名后面画 !，不能画成正常书签。
scenario_conflicted_bookmark() {  # dir remote seed
    local dir=$1 remote=$2 seed=$3
    local -a ident=(-c user.name=repo-check -c user.email=repo-check@example.com)
    git init --bare --quiet --initial-branch=main "$remote" || return 1
    git clone --quiet "$remote" "$seed" 2>/dev/null || return 1
    printf 'a\n' > "$seed/a" && git -C "$seed" add a &&
        git -C "$seed" "${ident[@]}" commit -qm init &&
        git -C "$seed" push --quiet origin main || return 1

    jj git clone "$remote" "$dir" >/dev/null 2>&1 || return 1
    (
        cd "$dir" || exit 1
        jj new main >/dev/null 2>&1 || exit 1
        printf 'b\n' > b || exit 1
        jj bookmark set main -r @ >/dev/null 2>&1 || exit 1
    ) || return 1

    # 远端再走一个提交 → 本地 main 与 main@origin 分叉，main 变 conflicted。
    printf 'c\n' > "$seed/c" && git -C "$seed" add c &&
        git -C "$seed" "${ident[@]}" commit -qm remote &&
        git -C "$seed" push --quiet origin main || return 1
    ( cd "$dir" && jj git fetch >/dev/null 2>&1 ) || return 1

    expect_segment "<id> main!*" "$dir" "冲突的书签"
}

# 场景：jj 仓库里 jj 自己报错（工作副本陈旧、配置错、锁、二进制坏了）。必须画失败标记，
# 不能画成一份看起来正常的结果。伪造一个 exit 1 的 jj 来模拟。非共置：共置仓库里
# git 段照画的情形由 scenario_colocated_jj_failure 覆盖。
scenario_jj_failure() {  # dir fake_bin
    local dir=$1 fake=$2 out got
    mkdir -p "$dir" "$fake" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet --no-colocate . >/dev/null 2>&1 || exit 1
        jj describe -m c1 >/dev/null 2>&1 || exit 1
        jj bookmark create main >/dev/null 2>&1 || exit 1
        jj new >/dev/null 2>&1 || exit 1
    ) || return 1
    printf '#!/bin/sh\nexit 1\n' > "$fake/jj" && chmod +x "$fake/jj" || return 1
    out=$(cd "$dir" && PATH="$fake:$PATH" __bash_prompt_repo && printf '%s' "$repo_ansi")
    got=$(printf '%s' "$out" | strip_ansi)
    [ "$got" = 'jj!' ] || report "jj 报错时 期望 [jj!] 实际 [$got]"
}

# 场景：共置仓库（最近的仓库根上 .jj 与 .git 都在）：jj 段与 git 段都画，jj 在前，
# 中间两个空格。@ 是 main 上的空提交，jj 会把 git HEAD 留在 main 上，两段都出现 main
# 正是实际的样子；不靠用户的 init.defaultBranch。
scenario_colocated() {
    local dir=$1
    mkdir -p "$dir" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet --colocate . >/dev/null 2>&1 || exit 1
        jj describe -m c1 >/dev/null 2>&1 || exit 1
        jj bookmark create main >/dev/null 2>&1 || exit 1
        jj new >/dev/null 2>&1 || exit 1
    ) || return 1
    expect_segment "<id> main (empty)  main" "$dir" "共置仓库的两段" __bash_prompt_repo
}

# 场景：共置仓库里 jj 报错：jj! 在前，git 段照画。jj! 本身说明错误，git 段只是
# 补充 git 那边的状态；不画 jj! 的话，正常的 git 分支名会把错误藏掉。
scenario_colocated_jj_failure() {  # dir fake_bin
    local dir=$1 fake=$2 out got
    mkdir -p "$dir" "$fake" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet --colocate . >/dev/null 2>&1 || exit 1
        jj bookmark create main >/dev/null 2>&1 || exit 1
        jj new >/dev/null 2>&1 || exit 1
    ) || return 1
    printf '#!/bin/sh\nexit 1\n' > "$fake/jj" && chmod +x "$fake/jj" || return 1
    out=$(cd "$dir" && PATH="$fake:$PATH" __bash_prompt_repo && printf '%s' "$repo_ansi")
    got=$(printf '%s' "$out" | strip_ansi)
    [ "$got" = 'jj!  main' ] || report "共置仓库 jj 报错时 期望 [jj!  main] 实际 [$got]"
}

# 场景：只装了 jj 的仓库（非共置）嵌在 git 工作树里。最近一层仓库根是 .jj，
# git 段不能画出父仓库的分支——那不属于这份工作副本。
scenario_jj_in_git_tree() {
    local dir=$1
    mkdir -p "$dir/inner" || return 1
    (
        cd "$dir" || exit 1
        git init --quiet --initial-branch=parent . || exit 1
        cd inner || exit 1
        jj git init --quiet --no-colocate . >/dev/null 2>&1 || exit 1
        jj bookmark create inner >/dev/null 2>&1 || exit 1
    ) || return 1
    expect_segment "<id> inner (empty)" "$dir/inner" "jj 仓库嵌在 git 工作树里" __bash_prompt_repo
}

# 场景：从符号链接进仓库子目录。$PWD 是逻辑路径，jj/git 按物理路径解析；向上找
# 仓库标记也必须用物理路径，否则标记扫描什么都找不到，共置仓库里两段都会空掉。
scenario_symlink() {  # dir link，dir 已经是 scenario_ancestor 建的仓库
    local dir=$1 link=$2
    mkdir -p "$dir/sub" || return 1
    ln -sfn "$dir/sub" "$link" || return 1
    expect_segment "<id> main+ (empty)" "$link" "符号链接子目录"
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

# 场景：两个书签在同一个祖先提交上，@ 是非空子提交。必须画成 main,dev+（+ 修饰整组），
# 不能写成 main+,dev+，也不能把 + 贴到每个名字后面。书签顺序由 jj 自己决定，两种都接受。
scenario_group_bookmark() {
    local dir=$1 out got
    mkdir -p "$dir" || return 1
    (
        cd "$dir" || exit 1
        jj git init --quiet . >/dev/null 2>&1 || exit 1
        jj describe -m c1 >/dev/null 2>&1 || exit 1
        jj bookmark create main >/dev/null 2>&1 || exit 1
        jj bookmark create dev >/dev/null 2>&1 || exit 1
        jj new >/dev/null 2>&1 || exit 1
        printf 'x\n' > f || exit 1
    ) || return 1
    out=$(cd "$dir" && __bash_prompt_jj && printf '%s' "$repo_ansi")
    got=$(printf '%s' "$out" | strip_ansi)
    got=${got#* }
    case $got in
        'dev,main+*'|'main,dev+*') ;;
        *) report "同层两个书签 期望 [dev,main+*] 或 [main,dev+*]，实际 [$got]" ;;
    esac
}

if command -v jj >/dev/null 2>&1; then
    scenario_dir=$(mktemp -d) || report "端到端: mktemp 失败"
    if [ -n "${scenario_dir-}" ]; then
        scenario_ancestor "$scenario_dir/ancestor"
        scenario_unsnapshotted_change "$scenario_dir/unsnapshotted"
        scenario_snapshot_warning "$scenario_dir/warning"
        scenario_conflicted_bookmark "$scenario_dir/conflicted" \
            "$scenario_dir/remote.git" "$scenario_dir/seed"
        scenario_jj_failure "$scenario_dir/jj_failure" "$scenario_dir/fakebin"
        scenario_colocated "$scenario_dir/colocated"
        scenario_colocated_jj_failure "$scenario_dir/colocated_failure" "$scenario_dir/fakebin2"
        scenario_jj_in_git_tree "$scenario_dir/jj_in_git_tree"
        scenario_symlink "$scenario_dir/ancestor" "$scenario_dir/link"
        scenario_merge "$scenario_dir/merge"
        scenario_bookmark_on_at "$scenario_dir/on_at"
        scenario_group_bookmark "$scenario_dir/group"
        rm -rf "$scenario_dir"
    fi
else
    printf 'repo_check: 跳过端到端场景（没有 jj）\n'
fi

[ "$fail" = 0 ] && printf 'repo_check: ok\n'
exit "$fail"
