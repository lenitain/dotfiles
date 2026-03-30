#!/usr/bin/env bash

# Everforest Soft colors for Tmux

set -g mode-style "fg=#7fbbb3,bg=#3a464c"

set -g message-style "fg=#7fbbb3,bg=#3a464c"
set -g message-command-style "fg=#7fbbb3,bg=#3a464c"

set -g pane-border-style "fg=#3a464c"
set -g pane-active-border-style "fg=#7fbbb3"

set -g status "on"
set -g status-justify "left"

set -g status-style "fg=#7fbbb3,bg=#2b3339"

set -g status-left-length "100"
set -g status-right-length "100"

set -g status-left-style NONE
set -g status-right-style NONE

set -g status-left "#[fg=#2b3339,bg=#7fbbb3,bold] #S #[fg=#7fbbb3,bg=#2b3339,nobold,nounderscore,noitalics]"
set -g status-right "#[fg=#2b3339,bg=#2b3339,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#2b3339] #{prefix_highlight} #[fg=#3a464c,bg=#2b3339,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#3a464c] %Y-%m-%d  %I:%M %p #[fg=#7fbbb3,bg=#3a464c,nobold,nounderscore,noitalics]#[fg=#2b3339,bg=#7fbbb3,bold] #h "
if-shell '[ "$(tmux show-option -gqv "clock-mode-style")" == "24" ]' {
  set -g status-right "#[fg=#2b3339,bg=#2b3339,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#2b3339] #{prefix_highlight} #[fg=#3a464c,bg=#2b3339,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#3a464c] %Y-%m-%d  %H:%M #[fg=#7fbbb3,bg=#3a464c,nobold,nounderscore,noitalics]#[fg=#2b3339,bg=#7fbbb3,bold] #h "
}

setw -g window-status-activity-style "underscore,fg=#d3c6aa,bg=#2b3339"
setw -g window-status-separator ""
setw -g window-status-style "NONE,fg=#d3c6aa,bg=#2b3339"
setw -g window-status-format "#[fg=#2b3339,bg=#2b3339,nobold,nounderscore,noitalics]#[default] #I  #W #F #[fg=#2b3339,bg=#2b3339,nobold,nounderscore,noitalics]"
setw -g window-status-current-format "#[fg=#2b3339,bg=#3a464c,nobold,nounderscore,noitalics]#[fg=#7fbbb3,bg=#3a464c,bold] #I  #W #F #[fg=#3a464c,bg=#2b3339,nobold,nounderscore,noitalics]"

# tmux-plugins/tmux-prefix-highlight support
set -g @prefix_highlight_output_prefix "#[fg=#dbbc7f]#[bg=#2b3339]#[fg=#2b3339]#[bg=#dbbc7f]"
set -g @prefix_highlight_output_suffix ""