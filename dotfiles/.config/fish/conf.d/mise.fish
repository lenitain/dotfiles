if command -v mise &>/dev/null
    mise activate --no-hook-env fish | source
    mise hook-env -s fish | source
end
