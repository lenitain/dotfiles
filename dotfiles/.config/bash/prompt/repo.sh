# 仓库段数据：最近一层仓库根上有什么标记就画哪几段，结果写进 $repo_ansi。
# 共置仓库（`.jj` 与 `.git` 在同一个根）jj、git 两段都画，只有一种就只画那一种。
# 由 widgets/repo.sh 在子进程里调用，每个提示符一次。
. "${BASH_SOURCE[0]%/*}/lib.sh"

# 最近一层仓库根上的标记写进 REPLY：jj / git / "jj git"，不在仓库里返回 1。
# 只看最近一层：jj 仓库嵌在别的 git 工作树里时，父仓库的分支不属于这份工作副本。
# 按物理路径向上找：$PWD 是逻辑路径，jj/git 自己按物理路径解析。
__bash_prompt_repo_kinds() {
    local dir parent
    __bash_prompt_repo_root=''
    dir=$(pwd -P)
    while :; do
        if [ -e "$dir/.jj" ] || [ -e "$dir/.git" ]; then
            __bash_prompt_repo_root=$dir
            REPLY=''
            [ -e "$dir/.jj" ] && REPLY=jj
            [ -e "$dir/.git" ] && REPLY="${REPLY:+$REPLY }git"
            return 0
        fi
        parent=${dir%/*}
        [ -n "$parent" ] || return 1
        dir=$parent
    done
}

# jj 段先跑：共置仓库里 jj 的 snapshot 可能挪动 git HEAD，随后 git 段看到的是挪完的位置。
# 段间两个空格：两段的主色都是暗灰，书签名和分支名又常是同一个词，靠间距分界。
__bash_prompt_repo() {
    repo_ansi=''
    __bash_prompt_repo_kinds || return 0
    local kinds=$REPLY
    local -a parts=()

    case $kinds in
    *jj*)
        if __bash_prompt_jj; then
            parts+=("$repo_ansi")
        # 有 .jj 但 jj 自己失败（工作副本陈旧、配置错、锁、二进制坏了）：画红色 jj!，
        # 不画 jj 段。共置仓库里 git 段照画：jj! 说明这是 jj 的错误，没有它的话
        # git 的分支名看着像正常结果，会把真正的错误藏掉。
        elif command -v jj >/dev/null 2>&1; then
            parts+=("\[$__bash_prompt_color_red\]jj!\[$__bash_prompt_color_reset\]")
        fi
        ;;
    esac

    case $kinds in
    *git*) __bash_prompt_git && parts+=("$repo_ansi") ;;
    esac

    __bash_prompt_join_into '  ' "${parts[@]}"
    repo_ansi=$REPLY
}

# git 段：branch + dirty(*) + unpushed/unpulled(↑/↓) + 操作中状态（REBASE 2/5 等）。
# branch/dirty 用 brblack，同步用 cyan，操作中状态用黄色；detached 用红色 (detached) 前缀。
# 分支、dirty、上游、ahead/behind 全在 `git status --porcelain=v2 --branch` 的头部，
# 一次 fork 就够（原来分 6 次问 git，约 27ms/提示符，这是一次约 7ms）。
# 没有 stash 段：stash 不是当前动作的 triage，而且它要额外 fork 一次 rev-list。
#
# 操作中状态直接读 gitdir 下的文件，不再 fork 一次 rev-parse：
#   rebase-merge/{msgnum,end} / rebase-apply/{next,last} / MERGE_HEAD /
#   CHERRY_PICK_HEAD / REVERT_HEAD / BISECT_LOG。
# gitdir 从仓库根的 .git 取；.git 是文件时（worktree/submodule）按 gitdir: 行解析。
__bash_prompt_git_dir() { # 仓库根 -> REPLY=gitdir
    local root=$1 dotgit=$1/.git line
    if [ -d "$dotgit" ]; then
        REPLY=$dotgit
        return 0
    fi
    [ -f "$dotgit" ] || return 1
    IFS= read -r line <"$dotgit" || return 1
    line=${line%$'\r'}
    case $line in
    'gitdir: '*) line=${line#'gitdir: '} ;;
    *) return 1 ;;
    esac
    case $line in
    /*) REPLY=$line ;;
    *) REPLY=$root/$line ;;
    esac
    return 0
}

__bash_prompt_git_state() { # gitdir -> REPLY=状态
    local dir=$1 num end
    REPLY=''
    if [ -d "$dir/rebase-merge" ]; then
        read -r num <"$dir/rebase-merge/msgnum" 2>/dev/null || num=''
        read -r end <"$dir/rebase-merge/end" 2>/dev/null || end=''
        REPLY="REBASE${num:+ $num}${end:+/$end}"
        [ -n "$num" ] && [ -n "$end" ] || REPLY=REBASE
        return 0
    fi
    if [ -d "$dir/rebase-apply" ]; then
        read -r num <"$dir/rebase-apply/next" 2>/dev/null || num=''
        read -r end <"$dir/rebase-apply/last" 2>/dev/null || end=''
        REPLY="REBASE${num:+ $num}${end:+/$end}"
        [ -n "$num" ] && [ -n "$end" ] || REPLY=REBASE
        [ -e "$dir/rebase-apply/applying" ] && REPLY="AM${num:+ $num}${end:+/$end}"
        return 0
    fi
    [ -e "$dir/MERGE_HEAD" ] && { REPLY=MERGING; return 0; }
    [ -e "$dir/CHERRY_PICK_HEAD" ] && { REPLY=CHERRY-PICK; return 0; }
    [ -e "$dir/REVERT_HEAD" ] && { REPLY=REVERT; return 0; }
    [ -e "$dir/BISECT_LOG" ] && { REPLY=BISECT; return 0; }
    return 1
}

__bash_prompt_git() {
    command -v git >/dev/null 2>&1 || return 1

    local status
    status=$(command git status --porcelain=v2 --branch --ignore-submodules 2>/dev/null) || return 1
    [ -n "$status" ] || return 1

    local branch='' dirty='' ahead=0 behind=0
    local line left right
    while IFS= read -r line; do
        case $line in
        '# branch.head '*) branch=${line#'# branch.head '} ;;
        '# branch.ab '*)
            read -r left right <<< "${line#'# branch.ab '}"
            ahead=${left#+}
            behind=${right#-}
            ;;
        '#'*) ;;
        *) dirty=$__bash_prompt_symbol_dirty ;;
        esac
    done <<< "$status"

    # detached HEAD 时 porcelain 只说 "(detached)"，用 name-rev 换成人能读的 main~N。
    # refs/jj/* 是 jj 的记账 ref：共置仓库里 jj new 之后 HEAD 常只剩
    # refs/jj/keep/<hash>，画出来是 50 列的哈希；排掉它们，没有名字就画短哈希。
    local detached=''
    if [ "$branch" = '(detached)' ]; then
        branch=$(command git name-rev --exclude='refs/jj/*' --name-only HEAD 2>/dev/null)
        case $branch in
        ''|undefined) branch=$(command git rev-parse --short HEAD 2>/dev/null) ;;
        esac
        detached="\[$__bash_prompt_color_red\](detached)\[$__bash_prompt_color_reset\] "
        # 共置仓库里 jj 会主动把 git HEAD 留在 detached；那是 jj 的正常工作方式，
        # 不是用户需要处理的 detached checkout。jj 段已经画了真实状态。
        [ -n "${__bash_prompt_repo_root-}" ] && [ -e "$__bash_prompt_repo_root/.jj" ] && detached=''
    fi
    [ -n "$branch" ] || return 1
    __bash_prompt_escape "$branch"
    branch=$REPLY

    local ahead_ansi='' behind_ansi=''
    [ "${ahead:-0}" -gt 0 ] 2>/dev/null && ahead_ansi="$__bash_prompt_symbol_ahead"
    [ "${behind:-0}" -gt 0 ] 2>/dev/null && behind_ansi="$__bash_prompt_symbol_behind"

    local state=''
    if [ -n "${__bash_prompt_repo_root-}" ] &&
        __bash_prompt_git_dir "$__bash_prompt_repo_root" &&
        __bash_prompt_git_state "$REPLY"; then
        __bash_prompt_escape "$REPLY"
        state=$REPLY
    fi

    local head_ansi="${detached}\[$__bash_prompt_color_mute\]${branch}${dirty}\[$__bash_prompt_color_reset\]"
    local info=''
    [ -n "$ahead_ansi" ] && info+=" $ahead_ansi"
    [ -n "$behind_ansi" ] && info+=" $behind_ansi"
    if [ -n "$info" ]; then
        head_ansi+="\[$__bash_prompt_color_cyan\]${info}\[$__bash_prompt_color_reset\]"
    fi
    [ -n "$state" ] && head_ansi+=" \[$__bash_prompt_color_yellow\]$state\[$__bash_prompt_color_reset\]"
    repo_ansi=$head_ansi
    return 0
}

__bash_prompt_in_jj_repo() {
    # $PWD 是逻辑路径：从符号链接进仓库子目录时 dotfile 标记不在逻辑路径上，
    # jj/git 自己按物理路径解析，所以这里也要用 pwd -P 对齐。
    local dir parent
    dir=$(pwd -P)
    while :; do
        [ -e "$dir/.jj" ] && return 0
        parent=${dir%/*}
        [ -n "$parent" ] || return 1
        dir=$parent
    done
}

# 提交行的列，顺序就是下面 `read` 的顺序；模板由这份数组拼出来，段数也从它算。
# 完整的 commit_id 与 parents 只用来在 bash 里走 BFS（下面）；显示用 change_id.shortest()。
# 键必须是 commit_id：divergent 的两个提交共享 change_id，用它当键会把两行并成一行。
__bash_prompt_jj_commit_columns=(
    'commit_id'
    'change_id.shortest()'
    'parents.map(|p| p.commit_id()).join("\x1e")'
    # 冲突的书签名后面缀一个 \x1d 哨兵：合法 ref 名里没有控制字符，显示前再剥掉。
    'local_bookmarks.map(|b| b.name() ++ if(b.conflict(), "\x1d", "")).join("\x1e")'
    'if(empty, "1", "0")'
    'if(conflict, "1", "0")'
    'if(divergent, "1", "0")'
)
# 一行 = @ 标志位 + 上面这些列。
__bash_prompt_jj_commit_field_count=$(( ${#__bash_prompt_jj_commit_columns[@]} + 1 ))

# 模板由列数组拼出来，段数从同一个数组算：加一列只改数组和下面的 `read`。
__bash_prompt_jj_commit_template() {
    local flags='if(current_working_copy, "@", "")'
    local -a fields=("$flags" "${__bash_prompt_jj_commit_columns[@]}")
    __bash_prompt_join_into ' ++ "\x1f" ++ ' "${fields[@]}"
    REPLY="$REPLY"' ++ "\n"'
}

__bash_prompt_jj() {
    repo_ansi=''
    command -v jj >/dev/null 2>&1 || return 1
    __bash_prompt_in_jj_repo || return 1

    local depth=20
    local bookmark_walk=$(( depth + 1 ))

    # 参考点用「20 个提交内的祖先书签」，不取 latest()：latest 在 jj 里默认按
    # committer 时间只取 1 个，分叉/merge 时会把更近的书签藏掉。最近一层由下面的
    # BFS 选，所以参考点可以是一组提交。
    local ancestor_refs="ancestors(@, $bookmark_walk) & bookmarks()"
    local ancestor_path="($ancestor_refs)::@"
    local revset="@ | ($ancestor_path)"

    __bash_prompt_jj_commit_template
    local template=$REPLY

    # 不加 --ignore-working-copy：jj 的工作副本本身就是一个提交，只有 snapshot 才能
    # 发现文件变了；git status 那种只读查询在 jj 里不存在（不 snapshot 就只能读上一次
    # 的状态，刚改完文件会一直显示 (empty)）。让 jj 在这里 snapshot，仓库段和 `jj st`
    # 看到的就是同一份状态，代价是文件变过的那次提示符会写一条 snapshot 操作。
    #
    # stderr 不能丢：拒绝 snapshot（新文件超过 snapshot.max-new-file-size、权限）是 warning，
    # 命令本身成功，丢掉就只剩一个看起来正常的 (empty)。收进 per-shell 文件，非空画 !。
    local warn_file=/dev/null at_warn=0
    __bash_prompt_runtime_file jj-warn "$PPID" && warn_file=$REPLY
    local log_output
    log_output=$(command jj --no-pager log --color=never --no-graph \
        --template "$template" --revisions "$revset" 2>"$warn_file") || return 1
    [ -n "$log_output" ] || return 1
    [ -s "$warn_file" ] && at_warn=1

    local flags commit_id change_short parents local_bookmarks empty conflict divergent
    local at_change_id='' at_key='' at_bookmarks='' at_empty=0 at_conflict=0 at_divergent=0
    local ancestor_names=''
    local -a order=() edge_list=()
    local -A parent_map=() bookmark_map=()
    local line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        # 段数与列定义对不上就跳过：热路径不报告，契约由 scripts/repo_check.sh 抓。
        local bare=${line//$'\x1f'/}
        [ $(( ${#line} - ${#bare} + 1 )) -eq "$__bash_prompt_jj_commit_field_count" ] || continue
        IFS=$'\x1f' read -r flags commit_id change_short parents local_bookmarks empty conflict divergent <<< "$line"

        order+=("$commit_id")
        parent_map[$commit_id]=$parents
        bookmark_map[$commit_id]=$local_bookmarks

        case $flags in
            *@*)
                at_change_id=$change_short
                at_key=$commit_id
                at_bookmarks=$local_bookmarks
                at_empty=${empty:-0}
                at_conflict=${conflict:-0}
                at_divergent=${divergent:-0}
                ;;
        esac
    done <<< "$log_output"

    [ -n "$at_key" ] || return 1
    __bash_prompt_escape "$at_change_id"
    at_change_id=$REPLY

    # 距离 = 从 @ 沿 parent 走到书签的边数；只用来选最近一层和判断 + 后缀，
    # 不显示数字。空 @ 不计一步（直接父书签算 "在书签上"，不画 +）。
    local id
    local -A ancestor_depth=()
    local -a queue=()
    local head next level
    ancestor_depth[$at_key]=0
    queue=("$at_key")
    while [ ${#queue[@]} -gt 0 ]; do
        head=${queue[0]}
        queue=("${queue[@]:1}")
        level=$(( ${ancestor_depth[$head]} + 1 ))
        IFS=$'\x1e' read -r -a edge_list <<< "${parent_map[$head]}"
        for next in "${edge_list[@]}"; do
            [ -n "${parent_map[$next]+x}" ] || continue
            [ -n "${ancestor_depth[$next]+x}" ] && continue
            ancestor_depth[$next]=$level
            queue+=("$next")
        done
    done

    # 最近的祖先层里的本地书签；同一层有多个（merge 的两个父提交）就都留下，
    # 用 \x1e 连接，后面按书签逐个画。
    local ancestor_distance=-1 best
    for id in "${order[@]}"; do
        best=${ancestor_depth[$id]-}
        [ -n "$best" ] && [ "$best" -gt 0 ] || continue
        [ -n "${bookmark_map[$id]}" ] || continue
        if [ "$ancestor_distance" -lt 0 ] || [ "$best" -lt "$ancestor_distance" ]; then
            ancestor_distance=$best
            ancestor_names=${bookmark_map[$id]}
        elif [ "$best" -eq "$ancestor_distance" ]; then
            ancestor_names+=$'\x1e'"${bookmark_map[$id]}"
        fi
    done
    [ "$ancestor_distance" -lt 0 ] && ancestor_distance=0

    # empty 工作副本不计入祖先距离。
    if [ "$at_empty" = 1 ] && [ "$ancestor_distance" -gt 0 ]; then
        ancestor_distance=$(( ancestor_distance - 1 ))
    fi

    # 书签就在 @ 上时永远是最佳参考。
    if [ -n "$at_bookmarks" ]; then
        ancestor_names=$at_bookmarks
        ancestor_distance=0
    fi

    local -a reference_parts=()
    local name part conflicted
    local -a name_list=()
    IFS=$'\x1e' read -r -a name_list <<< "$ancestor_names"
    for name in "${name_list[@]}"; do
        [ -n "$name" ] || continue
        # 冲突的书签：jj log <名字> / jj bookmark set 都会报错，不能画成正常书签。
        conflicted=0
        case $name in
            *$'\x1d') conflicted=1; name=${name%$'\x1d'} ;;
        esac
        __bash_prompt_escape "$name"
        name=$REPLY
        [ -n "$name" ] || continue
        part="\[$__bash_prompt_color_mute\]$name"
        [ "$conflicted" = 1 ] && part+="\[$__bash_prompt_color_red\]$__bash_prompt_symbol_warn"
        part+="\[$__bash_prompt_color_reset\]"
        reference_parts+=("$part")
    done

    __bash_prompt_join_into ',' "${reference_parts[@]}"
    local reference_ansi=$REPLY
    # + 修饰整组：main,dev+ 读作"这组书签在 @ 的祖先层上"，而不是每个名字各加一个。
    [ "$ancestor_distance" -gt 0 ] && reference_ansi+="\[$__bash_prompt_color_mute\]+\[$__bash_prompt_color_reset\]"

    local head_ansi="\[$__bash_prompt_color_jj_change\]$at_change_id\[$__bash_prompt_color_reset\]"
    [ -n "$reference_ansi" ] && head_ansi+=" $reference_ansi"
    if [ "$at_empty" = 1 ]; then
        head_ansi+=" \[$__bash_prompt_color_cyan\](empty)\[$__bash_prompt_color_reset\]"
    else
        head_ansi+="\[$__bash_prompt_color_mute\]$__bash_prompt_symbol_dirty\[$__bash_prompt_color_reset\]"
    fi

    local -a status_parts=()
    [ "$at_conflict" = 1 ] && status_parts+=("\[$__bash_prompt_color_red\]×\[$__bash_prompt_color_reset\]")
    [ "$at_divergent" = 1 ] && status_parts+=("\[$__bash_prompt_color_red\]≠\[$__bash_prompt_color_reset\]")
    # jj 自己写了警告（stderr 非空）：常见是拒绝 snapshot 的大文件，`jj st` 看原文。
    [ "$at_warn" = 1 ] && status_parts+=("\[$__bash_prompt_color_yellow\]$__bash_prompt_symbol_warn\[$__bash_prompt_color_reset\]")

    repo_ansi=$head_ansi
    if [ ${#status_parts[@]} -gt 0 ]; then
        __bash_prompt_join_into ' ' "${status_parts[@]}"
        repo_ansi+=" $REPLY"
    fi
    return 0
}
