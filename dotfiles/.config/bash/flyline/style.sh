# flyline 的配色：Everforest Dark Medium 的全部 12 个槽位。
# 颜色值只有 theme/ 一份（conf.d/fzf.sh 也读它），改色只改那里。
# 没列出的槽位（normal-text、markdown-*、tutorial-hint、key-sequence-style）保持默认，
# 只在帮助/changelog 里可见。

. "${BASH_CONFIG_HOME:-$HOME/.config/bash}/theme/everforest_dark_medium.sh"

flyline set-style \
    recognised-command="#$EVERFOREST_CYAN" \
    unrecognised-command="#$EVERFOREST_RED" \
    single-quoted-text="#$EVERFOREST_YELLOW" \
    double-quoted-text="#$EVERFOREST_YELLOW" \
    comment="#$EVERFOREST_COMMENT" \
    inline-suggestion="#$EVERFOREST_COMMENT" \
    env-var="#$EVERFOREST_PURPLE" \
    bash-reserved="#$EVERFOREST_PURPLE" \
    selected-text="on #$EVERFOREST_SELECTION" \
    matching-char="bold underline #$EVERFOREST_GREEN" \
    opening-and-closing-pair="bold underline #$EVERFOREST_GREEN" \
    secondary-text="#$EVERFOREST_COMMENT"
