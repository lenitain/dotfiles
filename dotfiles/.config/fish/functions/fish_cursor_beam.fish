function fish_cursor_beam --on-event fish_prompt --on-event fish_postexec
    set -g fish_cursor_default beam
    set -g fish_cursor_insert beam
    printf '\e[6 q'
end