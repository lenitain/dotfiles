#!/usr/bin/env bash

# Everforest Medium colors for Tmux

set -g mode-style "fg=#7fbbb3,bg=#343f44"

set -g message-style "fg=#7fbbb3,bg=#343f44"
set -g message-command-style "fg=#7fbbb3,bg=#343f44"

set -g pane-border-style "fg=#475258"
set -g pane-active-border-style "fg=#7fbbb3"

set -g status "on"
set -g status-justify "left"

set -g status-style "fg=#7fbbb3,bg=#2d353b"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

set -g status-left "#[fg=#2d353b,bg=#7fbbb3,bold] #S #[fg=#7fbbb3,bg=#2d353b,nobold,nounderscore,noitalics]"
set -g status-right "#[fg=#2d353b,bg=#2d353b,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#2d353b] #{prefix_highlight} #[fg=#475258,bg=#2d353b,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#475258] %Y-%m-%d  %I:%M %p #[fg=#7fbbb3,bg=#475258,nobold,nounderscore,noitalics]#[fg=#2d353b,bg=#7fbbb3,bold] #h "
if-shell '[ "$(tmux show-option -gqv "clock-mode-style")" == "24" ]' {
  set -g status-right "#[fg=#2d353b,bg=#2d353b,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#2d353b] #{prefix_highlight} #[fg=#475258,bg=#2d353b,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#475258] %Y-%m-%d  %H:%M #[fg=#7fbbb3,bg=#475258,nobold,nounderscore,noitalics]#[fg=#2d353b,bg=#7fbbb3,bold] #h "
}

setw -g window-status-activity-style "underscore,fg=#d3c6aa,bg=#2d353b"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#d3c6aa,bg=#2d353b"
setw -g window-status-format "#[fg=#2d353b,bg=#2d353b,nobold,nounderscore,noitalics]#[default] #I  #W #F #[fg=#2d353b,bg=#2d353b,nobold,nounderscore,noitalics]"
setw -g window-status-current-format "#[fg=#2d353b,bg=#343f44,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#343f44,bold] #I  #W #F #[fg=#343f44,bg=#2d353b,nobold,nounderscore,noitalics]"

# tmux-plugins/tmux-prefix-highlight support
set -g @prefix_highlight_output_prefix "#[fg=#dbbc7f]#[bg=#2d353b]#[fg=#2d353b]#[bg=#dbbc7f]"
set -g @prefix_highlight_output_suffix ""