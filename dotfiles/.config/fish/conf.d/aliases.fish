# ─── File Listing ───
alias ls='eza -al --color=always --group-directories-first --icons=always'
alias la='eza -a --color=always --group-directories-first --icons=always'
alias ll='eza -l --color=always --group-directories-first --icons=always'
alias lt='eza -aT --color=always --group-directories-first --icons=always'
alias l.="eza -a | grep -e '^\.'"

# ─── Navigation ───
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias ......='cd ../../../../..'

# ─── Search ───
alias grep='grep --color=auto'
alias fgrep='fgrep --color=auto'
alias egrep='egrep --color=auto'
alias rg='rg --color=auto'

# ─── Package Management ───
alias sps='sudo pacman -S --needed'
alias update='sudo pacman -Syu'
alias delete='sudo pacman -R'
alias all_delete='sudo pacman -Rns'
alias uninstall-help='mise run uninstall-help'
alias cleanup='sudo pacman -Rns (pacman -Qtdq)'
alias fixpacman="sudo rm /var/lib/pacman/db.lck"
alias mirror="sudo cachyos-rate-mirrors"
alias gitpkg='pacman -Q | grep -i "\-git" | wc -l'

# ─── System ───
alias jctl="journalctl -p 3 -xb"
alias hw='hwinfo --short'
alias ssu='systemctl suspend'

alias psmem='ps auxf | sort -nr -k 4'
alias psmem10='ps auxf | sort -nr -k 4 | head -10'

# ─── Download & Archive ───
alias tarnow='tar -acf '
alias untar='tar -zxvf '
alias wget='wget -c '
alias a='aria2c -c'

# ─── App Shortcuts ───
alias n='nvim'
alias np='nvim $(pfzf)'
alias oc='opencode'
alias wf='wireforge'
alias zl='zellij'
alias lg='lazygit'
alias mc='cd ~/.config/mise'
alias mh='mise hook-env -s fish | source'
alias ms='mise run setup-all'
alias ap='ansible-playbook'
