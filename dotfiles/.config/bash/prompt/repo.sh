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

# git 段：branch + dirty(*) + stash(≡) + unpushed/unpulled(⇡/⇣)。
# branch/dirty 用 brblack，stash/同步用 cyan。
__bash_prompt_git() {
    command -v git >/dev/null 2>&1 || return 1
    [ "$(command git rev-parse --is-inside-work-tree 2>/dev/null)" = true ] || return 1

    local branch
    branch=$(command git symbolic-ref --short HEAD 2>/dev/null) \
        || branch=$(command git name-rev --name-only HEAD 2>/dev/null)
    [ -n "$branch" ] || return 1

    local dirty=''
    [ -n "$(command git status --porcelain --ignore-submodules 2>/dev/null)" ] && dirty='*'

    local stash='' stash_count
    stash_count=$(command git rev-list --walk-reflogs --count refs/stash 2>/dev/null) || stash_count=0
    [ "${stash_count:-0}" -gt 0 ] 2>/dev/null && stash=' ≡'

    local ahead='' behind=''
    local upstream
    upstream=$(command git rev-parse --abbrev-ref '@{upstream}' 2>/dev/null)
    if [ -n "$upstream" ]; then
        local counts ahead_count behind_count
        counts=$(command git rev-list --left-right --count 'HEAD...@{upstream}' 2>/dev/null)
        if [ -n "$counts" ]; then
            ahead_count=${counts%%$'\t'*}
            behind_count=${counts##*$'\t'}
            [ "${ahead_count:-0}" -gt 0 ] 2>/dev/null && ahead='⇡'
            [ "${behind_count:-0}" -gt 0 ] 2>/dev/null && behind='⇣'
        fi
    fi

    local head_ansi="\[$__bash_prompt_color_mute\]${branch}${dirty}\[$__bash_prompt_color_reset\]"
    local info=''
    info+="$stash"
    [ -n "$ahead" ] && info+=" $ahead"
    [ -n "$behind" ] && info+=" $behind"
    if [ -n "$info" ]; then
        head_ansi+="\[$__bash_prompt_color_cyan\]${info}\[$__bash_prompt_color_reset\]"
    fi
    repo_ansi=$head_ansi
    return 0
}

__bash_prompt_jj_repo_root() {
    local dir=$PWD parent
    while :; do
        [ -e "$dir/.jj" ] && return 0
        parent=${dir%/*}
        [ -n "$parent" ] || return 1
        dir=$parent
    done
}

# 书签同步后缀：只看开关打开的部分，写进 __bash_prompt_jj_suffix。
__bash_prompt_jj_bookmark_suffix() {
    local name=$1 rows=$2
    __bash_prompt_jj_suffix=''

    local has_local=0 has_tracked=0 has_untracked=0 conflict=0
    local ahead=0 behind=0
    local row
    while IFS= read -r row; do
        [ -n "$row" ] || continue
        local row_name remote tracked present synced ahead_exact ahead_lower behind_exact behind_lower row_conflict
        IFS=$'\x1f' read -r row_name remote tracked present synced ahead_exact ahead_lower behind_exact behind_lower row_conflict <<< "$row"
        [ "$row_name" = "$name" ] || continue

        if [ "$remote" = '-' ]; then
            has_local=1
            [ "$row_conflict" = true ] && conflict=1
            continue
        fi
        [ "$remote" = git ] && continue

        if [ "$tracked" != 1 ] || [ "$present" != 1 ]; then
            has_untracked=1
            continue
        fi
        has_tracked=1

        local remote_ahead=0 remote_behind=0
        if [ -n "$ahead_exact" ]; then
            remote_ahead=$ahead_exact
        elif [ -n "$ahead_lower" ]; then
            remote_ahead=$ahead_lower
        fi
        if [ -n "$behind_exact" ]; then
            remote_behind=$behind_exact
        elif [ -n "$behind_lower" ]; then
            remote_behind=$behind_lower
        fi
        case $remote_ahead in ''|*[!0-9]*) remote_ahead=0 ;; esac
        case $remote_behind in ''|*[!0-9]*) remote_behind=0 ;; esac

        # remote 领先本地 = 本地 behind；remote 落后本地 = 本地 ahead。
        [ "$remote_ahead" -gt "$behind" ] && behind=$remote_ahead
        [ "$remote_behind" -gt "$ahead" ] && ahead=$remote_behind
    done <<< "$rows"

    [ "$has_local" = 1 ] || return 0

    if [ "$has_tracked" = 1 ]; then
        [ "$ahead" -gt 0 ] && __bash_prompt_jj_suffix+="\[$__bash_prompt_color_cyan\]⇡\[$__bash_prompt_color_reset\]"
        [ "$behind" -gt 0 ] && __bash_prompt_jj_suffix+="\[$__bash_prompt_color_cyan\]⇣\[$__bash_prompt_color_reset\]"
        [ "$has_untracked" = 1 ] && __bash_prompt_jj_suffix+="\[$__bash_prompt_color_yellow\]?\[$__bash_prompt_color_reset\]"
    else
        __bash_prompt_jj_suffix+="\[$__bash_prompt_color_yellow\]?\[$__bash_prompt_color_reset\]"
    fi
    [ "$conflict" = 1 ] && __bash_prompt_jj_suffix+="\[$__bash_prompt_color_red\]!\[$__bash_prompt_color_reset\]"
    return 0
}

__bash_prompt_jj() {
    repo_ansi=''
    command -v jj >/dev/null 2>&1 || return 1
    __bash_prompt_jj_repo_root || return 1

    local depth=20
    local bookmark_walk=$(( depth + 1 ))
    local trunk_walk=$(( depth + 2 ))
    local trunk_label=trunk

    local ancestor_ref="latest(heads(ancestors(@, $bookmark_walk) & bookmarks()))"
    local descendant_ref="latest(roots(descendants(@, $bookmark_walk) & bookmarks()))"
    local ancestor_path="$ancestor_ref::@"
    local descendant_path="@::$descendant_ref"
    local trunk_ahead="ancestors(@, $trunk_walk) & trunk()..@"
    local trunk_behind="ancestors(trunk(), $trunk_walk) & (::trunk() & ~::@)"
    local revset="@ | ($ancestor_path) | ($descendant_path) | ($trunk_ahead) | ($trunk_behind) | trunk()"

    local template
    template='concat('
    template+='if(self.contained_in("@"), "@", ""), '
    template+='if(self.contained_in("'"$ancestor_path"'"), "P", ""), '
    template+='if(self.contained_in("'"$ancestor_ref"'"), "p", ""), '
    template+='if(self.contained_in("'"$descendant_path"'"), "Q", ""), '
    template+='if(self.contained_in("'"$descendant_ref"'"), "q", ""), '
    template+='if(self.contained_in("trunk()"), "T", ""), '
    template+='if(self.contained_in("root()"), "Z", ""), '
    template+='if(self.contained_in("'"$trunk_ahead"'"), "a", ""), '
    template+='if(self.contained_in("'"$trunk_behind"'"), "b", ""), '
    template+='"\x1f", change_id.shortest(), '
    template+='"\x1f", local_bookmarks.map(|b| b.name()).join("\x1e"), '
    template+='"\x1f", if(empty, "1", "0"), '
    template+='"\x1f", if(conflict, "1", "0"), '
    template+='"\x1f", if(divergent, "1", "0"), '
    template+='"\x1f", if(self.contained_in("trunk()"), self.bookmarks().map(|b| b.name()).join("\x1e"), ""), '
    template+='"\n")'

    local log_output
    log_output=$(command jj --no-pager log --ignore-working-copy --color=never --no-graph \
        --template "$template" --revisions "$revset" 2>/dev/null) || return 1
    [ -n "$log_output" ] || return 1

    local flags change_id local_bookmarks empty conflict divergent trunk_bookmarks
    local at_change_id='' at_bookmarks='' at_empty=0 at_conflict=0 at_divergent=0
    local ancestor_lines=0 descendant_lines=0
    local ancestor_names='' descendant_names=''
    local trunk_seen=0 trunk_is_root=0 trunk_names=''
    local ahead_lines=0 behind_lines=0
    local line
    while IFS= read -r line; do
        [ -n "$line" ] || continue
        IFS=$'\x1f' read -r flags change_id local_bookmarks empty conflict divergent trunk_bookmarks <<< "$line"

        case $flags in
            *@*)
                at_change_id=$change_id
                at_bookmarks=$local_bookmarks
                at_empty=${empty:-0}
                at_conflict=${conflict:-0}
                at_divergent=${divergent:-0}
                ;;
        esac
        case $flags in *P*) ancestor_lines=$(( ancestor_lines + 1 )) ;; esac
        case $flags in *p*) ancestor_names=$local_bookmarks ;; esac
        case $flags in *Q*) descendant_lines=$(( descendant_lines + 1 )) ;; esac
        case $flags in *q*) descendant_names=$local_bookmarks ;; esac
        case $flags in
            *T*)
                trunk_seen=1
                trunk_names=$trunk_bookmarks
                ;;
        esac
        case $flags in *Z*) trunk_is_root=1 ;; esac
        case $flags in *a*) ahead_lines=$(( ahead_lines + 1 )) ;; esac
        case $flags in *b*) behind_lines=$(( behind_lines + 1 )) ;; esac
    done <<< "$log_output"

    [ -n "$at_change_id" ] || return 1

    # empty 工作副本不计入祖先距离。
    local ancestor_distance=$(( ancestor_lines - 1 ))
    [ "$ancestor_distance" -lt 0 ] && ancestor_distance=0
    if [ "$at_empty" = 1 ] && [ "$ancestor_distance" -gt 0 ]; then
        ancestor_distance=$(( ancestor_distance - 1 ))
    fi
    local descendant_distance=$(( descendant_lines - 1 ))
    [ "$descendant_distance" -lt 0 ] && descendant_distance=0

    # 书签就在 @ 上时永远是最佳参考。
    if [ -n "$at_bookmarks" ]; then
        ancestor_names=$at_bookmarks
        ancestor_distance=0
    fi

    local -a direction=() distance=() names=()
    local has_ancestor=0 has_descendant=0
    [ -n "$ancestor_names" ] && has_ancestor=1
    [ -n "$descendant_names" ] && has_descendant=1

    if [ "$has_ancestor" = 1 ] && [ "$has_descendant" = 1 ]; then
        if [ "$ancestor_distance" -eq 0 ] && [ "$descendant_distance" -eq 0 ]; then
            direction+=(ancestor); distance+=("$ancestor_distance"); names+=("$ancestor_names")
            direction+=(descendant); distance+=("$descendant_distance"); names+=("$descendant_names")
        elif [ "$ancestor_distance" -lt "$descendant_distance" ]; then
            direction+=(ancestor); distance+=("$ancestor_distance"); names+=("$ancestor_names")
        elif [ "$descendant_distance" -lt "$ancestor_distance" ]; then
            direction+=(descendant); distance+=("$descendant_distance"); names+=("$descendant_names")
        else
            direction+=(ancestor); distance+=("$ancestor_distance"); names+=("$ancestor_names")
            direction+=(descendant); distance+=("$descendant_distance"); names+=("$descendant_names")
        fi
    elif [ "$has_ancestor" = 1 ]; then
        direction+=(ancestor); distance+=("$ancestor_distance"); names+=("$ancestor_names")
    elif [ "$has_descendant" = 1 ]; then
        direction+=(descendant); distance+=("$descendant_distance"); names+=("$descendant_names")
    fi

    # trunk 距离额外多走两个提交，边界外的距离显示为 20+。
    local ahead_text='' behind_text=''
    local ahead_count=$ahead_lines
    if [ "$at_empty" = 1 ] && [ "$ahead_count" -gt 0 ]; then
        ahead_count=$(( ahead_count - 1 ))
    fi
    if [ "$ahead_count" -gt "$depth" ]; then
        ahead_text="${ahead_count}+"
    elif [ "$ahead_count" -gt 0 ]; then
        ahead_text=$ahead_count
    fi
    if [ "$behind_lines" -gt "$depth" ]; then
        behind_text="${behind_lines}+"
    elif [ "$behind_lines" -gt 0 ]; then
        behind_text=$behind_lines
    fi

    local bookmark_rows=''
    if [ ${#direction[@]} -gt 0 ] || [ -n "$trunk_names" ]; then
        local bookmark_template='name ++ "\x1f" ++ if(remote, remote, "-") ++ "\x1f" ++ if(remote, if(self.tracked(), "1", "0"), "0") ++ "\x1f" ++ if(remote, if(self.tracking_present(), "1", "0"), "0") ++ "\x1f" ++ self.synced() ++ "\x1f" ++ try(self.tracking_ahead_count().exact(), "") ++ "\x1f" ++ try(self.tracking_ahead_count().lower(), "") ++ "\x1f" ++ try(self.tracking_behind_count().exact(), "") ++ "\x1f" ++ try(self.tracking_behind_count().lower(), "") ++ "\x1f" ++ self.conflict() ++ "\n"'
        bookmark_rows=$(command jj --no-pager bookmark list --ignore-working-copy --color=never \
            --all-remotes -r '@' -r "$ancestor_ref" -r "$descendant_ref" -r 'trunk()' \
            --template "$bookmark_template" 2>/dev/null)
    fi

    local -a reference_parts=()
    local index name part
    local -a name_list
    for index in "${!direction[@]}"; do
        IFS=$'\x1e' read -r -a name_list <<< "${names[index]}"
        for name in "${name_list[@]}"; do
            [ -n "$name" ] || continue
            part="\[$__bash_prompt_color_mute\]$name"
            if [ "${distance[index]}" -gt 0 ]; then
                if [ "${direction[index]}" = ancestor ]; then
                    part+="~${distance[index]}"
                else
                    part+="+${distance[index]}"
                fi
            fi
            __bash_prompt_jj_bookmark_suffix "$name" "$bookmark_rows"
            part+="$__bash_prompt_jj_suffix\[$__bash_prompt_color_reset\]"
            reference_parts+=("$part")
        done
    done

    # 没有任何本地书签做参考时，退回 trunk 的书签名（没有就用 trunk_label）。
    if [ ${#reference_parts[@]} -eq 0 ] && [ "$trunk_seen" = 1 ] && [ "$trunk_is_root" = 0 ]; then
        local -a trunk_candidates=() unique_names=()
        local -A seen_names=()
        IFS=$'\x1e' read -r -a trunk_candidates <<< "$trunk_names"
        for name in "${trunk_candidates[@]}"; do
            [ -n "$name" ] || continue
            [ -n "${seen_names[$name]-}" ] && continue
            seen_names[$name]=1
            unique_names+=("$name")
        done
        [ ${#unique_names[@]} -gt 0 ] || unique_names=("$trunk_label")

        for name in "${unique_names[@]}"; do
            part="\[$__bash_prompt_color_mute\]$name"
            if [ -n "$ahead_text" ] && [ -n "$behind_text" ]; then
                part+="~$ahead_text+$behind_text"
            elif [ -n "$ahead_text" ]; then
                part+="~$ahead_text"
            elif [ -n "$behind_text" ]; then
                part+="+$behind_text"
            fi
            __bash_prompt_jj_bookmark_suffix "$name" "$bookmark_rows"
            part+="$__bash_prompt_jj_suffix\[$__bash_prompt_color_reset\]"
            reference_parts+=("$part")
        done
    fi

    __bash_prompt_join_into ',' "${reference_parts[@]}"
    local reference_ansi=$REPLY

    local head_ansi="\[$__bash_prompt_color_mute\]$at_change_id\[$__bash_prompt_color_reset\]"
    [ -n "$reference_ansi" ] && head_ansi+=" $reference_ansi"
    if [ "$at_empty" = 1 ]; then
        head_ansi+=" \[$__bash_prompt_color_cyan\](empty)\[$__bash_prompt_color_reset\]"
    else
        head_ansi+="\[$__bash_prompt_color_mute\]*\[$__bash_prompt_color_reset\]"
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
