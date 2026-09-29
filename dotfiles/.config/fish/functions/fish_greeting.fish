function fish_greeting
    # zig zen
    # fish builtin read: no fork/exec, so this is the cheapest way to dump the
    # file. `cat` and `bat` both cost a process spawn per terminal open.
    while read -l line
        echo $line
    end <"$HOME/.config/fish/zig-zen.txt"
end
