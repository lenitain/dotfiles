function _pure_prompt_git \
    --description 'Print repository information: jj change id in jj repositories, git branch/dirty/upstream otherwise'

    set ABORT_FEATURE 2

    if set --query pure_enable_git; and test "$pure_enable_git" != true
        return
    end

    # jj repository detection: pure-fish upward walk for `.jj`, zero forks.
    # jj wins over git (colocated repos included): the jj change id is the
    # navigation identity here, git would only show a detached-HEAD hash.
    set --local jj_root (_pure_find_jj_root)
    if test -n "$jj_root"; and type -q --no-functions jj
        _pure_prompt_jj
        return
    end

    if not type -q --no-functions git  # skip git-related features when `git` is not available
        return $ABORT_FEATURE
    end

    set --local is_git_repository (command git rev-parse --is-inside-work-tree 2>/dev/null)

    if test -n "$is_git_repository"
        set --local git_prompt (_pure_prompt_git_branch)(_pure_prompt_git_dirty)(_pure_prompt_git_stash)
        set --local git_pending_commits (_pure_prompt_git_pending_commits)

        if test (_pure_string_width $git_pending_commits) -ne 0
            set --append git_prompt $git_pending_commits
        end

        echo $git_prompt
    end
end

function _pure_find_jj_root \
    --description 'Print nearest ancestor directory containing .jj (pure fish, no forks)'
    set --local dir $PWD
    while true
        if test -e "$dir/.jj"
            echo $dir
            return
        end
        set --local parent (string replace --regex '/[^/]*$' '' -- $dir)
        if test "$parent" = $dir
            return
        end
        set dir $parent
    end
end

function _pure_prompt_jj \
    --description 'Print jj repository information: change id, bookmarks, status flags, trunk ahead/behind'
    # One `jj log` renders everything (change id, bookmarks + push state,
    # empty/conflict/divergent flags, ahead/behind vs trunk()):
    #   line kinds: I = @ info (tab-separated fields),
    #               a = ahead commit, B = behind commit,
    #               T = trunk commit, Z = trunk resolved to root (no real trunk)
    #   ahead/behind share this single invocation: `trunk()..@` and
    #   `::trunk() & ~::@` are evaluated in the same revset union.
    #   Empty @ (jj's auto-scaffold after pushing trunk) does not count as
    #   ahead: it is not a commit anyone would push.
    set --local template 'if(self.contained_in("@"), "I\t" ++ change_id.shortest() ++ "\t" ++ local_bookmarks.map(|b| b.name() ++ if(remote_bookmarks.any(|rb| rb.name() == b.name() && rb.remote() != "git"), "", "*")).join(",") ++ "\t" ++ if(empty, "e", "-") ++ if(conflict, "c", "-") ++ if(divergent, "d", "-") ++ "\t" ++ if(self.contained_in("trunk()..@") && !empty, "A", "X") ++ "\n", if(self.contained_in("::trunk() & ~::@"), "B\n", if(self.contained_in("trunk()"), if(self.contained_in("root()"), "Z\n", "T\n"), "a\n")))'
    set --local revset '@ | trunk()..@ | (::trunk() & ~::@) | trunk()'

    set --local lines (
        command jj log --ignore-working-copy --color=never --no-graph \
            --template "$template" --revisions "$revset" 2>/dev/null
    )
    test (count $lines) -gt 0; or return

    set --local change_id
    set --local bookmarks
    set --local flags
    set --local counts_toward_ahead false
    set --local ahead 0
    set --local behind 0
    set --local trunk_trusted false # trunk() resolved to a real commit (T line, or behind > 0)

    for line in $lines
        switch $line
            case B
                set behind (math $behind + 1)
                set trunk_trusted true
            case a
                set ahead (math $ahead + 1)
            case T
                set trunk_trusted true
            case Z
                true # trunk() is root(): no real trunk, hide ahead/behind counts
            case 'I*'
                set --local fields (string split -- \t $line)
                if test (count $fields) -ge 5
                    set change_id $fields[2]
                    set bookmarks $fields[3]
                    set flags $fields[4]
                    if test $fields[5] = A
                        set counts_toward_ahead true
                    end
                end
            case '*'
                true # unknown line kind, ignore
        end
    end

    test -n "$change_id"; or return

    if test "$trunk_trusted" = true # counts stay hidden without a real trunk (git parity: no upstream, no arrows)
        if test "$counts_toward_ahead" = true
            set ahead (math $ahead + 1)
        end
    else
        set ahead 0
        set behind 0
    end

    set --local branch_color (_pure_set_color $pure_color_git_branch)
    set --local segment "$branch_color$change_id"

    if test -n "$bookmarks"
        set segment "$segment $bookmarks"
    end

    # status flags: danger first, informational last
    if string match --quiet '*c*' -- $flags
        set segment "$segment "(_pure_set_color $pure_color_danger)"×"
    end
    if string match --quiet '*d*' -- $flags
        set segment "$segment "(_pure_set_color $pure_color_danger)"≠"
    end
    if string match --quiet '*e*' -- $flags
        set segment "$segment "(_pure_set_color $pure_color_info)"(empty)"
    end

    if test $ahead -gt 0; or test $behind -gt 0
        if test $ahead -gt 0
            set segment "$segment "(_pure_set_color $pure_color_git_unpushed_commits)$pure_symbol_git_unpushed_commits
            if test "$pure_show_numbered_git_indicator" = true
                set segment "$segment$ahead"
            end
        end
        if test $behind -gt 0
            set segment "$segment "(_pure_set_color $pure_color_git_unpulled_commits)$pure_symbol_git_unpulled_commits
            if test "$pure_show_numbered_git_indicator" = true
                set segment "$segment$behind"
            end
        end
    end

    echo $segment
end
