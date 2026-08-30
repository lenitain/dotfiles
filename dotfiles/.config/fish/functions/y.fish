# yazi 包装函数：退出时把 shell 切换到鸭子内的最后访问目录
# 原理：yazi 退出时把最后访问目录写入 --cwd-file，这里读取并 cd
# 需要配合 keymap.toml 中 Q → quit 的绑定（quit 才会输出 cwd-file）
function y
	set tmp (mktemp -t "yazi-cwd.XXXXXX")
	command yazi $argv --cwd-file="$tmp"
	if read -z cwd < "$tmp"; and [ "$cwd" != "$PWD" ]; and test -d "$cwd"
		builtin cd -- "$cwd"
	end
	command rm -f -- "$tmp"
end
