# 仓库段数据：jj 仓库优先，否则回退 git，结果写进 $repo_ansi。
# 由 widgets/repo.sh 在子进程里调用，每个提示符一次。
. "${BASH_SOURCE[0]%/*}/lib.sh"

__bash_prompt_repo() {
    repo_ansi=''
    if __bash_prompt_jj; then
        return 0
    fi
    __bash_prompt_git
}

# git 段：branch + dirty(*) + stash(≡N) + unpushed/unpulled(⇡N/⇣N)。
# branch/dirty 用 brblack，stash/同步用 cyan；数字同 pure 的 pure_show_numbered_git_indicator。
#
# 分支、dirty、上游、ahead/behind 全在 `git status --porcelain=v2 --branch` 的头部，
# 一次 fork 就够（原来分 6 次问 git，约 27ms/提示符，这是一次约 7ms）。
# stash 数不在 status 里，仍在 refs/stash 的 reflog 上另查一次。
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
    if [ "$branch" = '(detached)' ]; then
        branch=$(command git name-rev --name-only HEAD 2>/dev/null)
    fi
    [ -n "$branch" ] || return 1

    local stash='' stash_count
    stash_count=$(command git rev-list --walk-reflogs --count refs/stash 2>/dev/null) || stash_count=0
    [ "${stash_count:-0}" -gt 0 ] 2>/dev/null && stash=" $__bash_prompt_symbol_stash$stash_count"

    local ahead_ansi='' behind_ansi=''
    [ "${ahead:-0}" -gt 0 ] 2>/dev/null && ahead_ansi="$__bash_prompt_symbol_ahead$ahead"
    [ "${behind:-0}" -gt 0 ] 2>/dev/null && behind_ansi="$__bash_prompt_symbol_behind$behind"

    local head_ansi="\[$__bash_prompt_color_mute\]${branch}${dirty}\[$__bash_prompt_color_reset\]"
    local info=''
    info+="$stash"
    [ -n "$ahead_ansi" ] && info+=" $ahead_ansi"
    [ -n "$behind_ansi" ] && info+=" $behind_ansi"
    if [ -n "$info" ]; then
        head_ansi+="\[$__bash_prompt_color_cyan\]${info}\[$__bash_prompt_color_reset\]"
    fi
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
    'local_bookmarks.map(|b| b.name()).join("\x1e")'
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
    # committer 时间只取 1 个，分叉/merge 时会把更近的书签藏掉。距离由下面的
    # BFS 算，所以参考点可以是一组提交。
    local ancestor_refs="ancestors(@, $bookmark_walk) & bookmarks()"
    local ancestor_path="($ancestor_refs)::@"
    local revset="@ | ($ancestor_path)"

    __bash_prompt_jj_commit_template
    local template=$REPLY

    local log_output
    log_output=$(command jj --no-pager log --ignore-working-copy --color=never --no-graph \
        --template "$template" --revisions "$revset" 2>/dev/null) || return 1
    [ -n "$log_output" ] || return 1

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

    # 距离 = 从 @ 沿 parent 走到书签的边数；空 @ 不计一步，和原来的口径一致
    # （直接父书签距离 0，再上一个距离 1）。
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
    local name part
    local -a name_list=()
    IFS=$'\x1e' read -r -a name_list <<< "$ancestor_names"
    for name in "${name_list[@]}"; do
        [ -n "$name" ] || continue
        part="\[$__bash_prompt_color_mute\]$name"
        [ "$ancestor_distance" -gt 0 ] && part+="~${ancestor_distance}"
        part+="\[$__bash_prompt_color_reset\]"
        reference_parts+=("$part")
    done

    __bash_prompt_join_into ',' "${reference_parts[@]}"
    local reference_ansi=$REPLY

    local head_ansi="\[$__bash_prompt_color_mute\]$at_change_id\[$__bash_prompt_color_reset\]"
    [ -n "$reference_ansi" ] && head_ansi+=" $reference_ansi"
    if [ "$at_empty" = 1 ]; then
        head_ansi+=" \[$__bash_prompt_color_cyan\](empty)\[$__bash_prompt_color_reset\]"
    else
        head_ansi+="\[$__bash_prompt_color_mute\]$__bash_prompt_symbol_dirty\[$__bash_prompt_color_reset\]"
    fi

    local -a status_parts=()
    [ "$at_conflict" = 1 ] && status_parts+=("\[$__bash_prompt_color_red\]×\[$__bash_prompt_color_reset\]")
    [ "$at_divergent" = 1 ] && status_parts+=("\[$__bash_prompt_color_red\]≠\[$__bash_prompt_color_reset\]")

    repo_ansi=$head_ansi
    if [ ${#status_parts[@]} -gt 0 ]; then
        __bash_prompt_join_into ' ' "${status_parts[@]}"
        repo_ansi+=" $REPLY"
    fi
    return 0
}
