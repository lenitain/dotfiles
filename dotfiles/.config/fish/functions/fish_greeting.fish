function fish_greeting
    while read -l line
        echo $line
    end <"$HOME/.config/fish/zig-zen.txt"
end
