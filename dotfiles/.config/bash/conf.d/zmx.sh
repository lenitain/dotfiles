# zmx 会话面板：补全 + Alt+n。
# 提示符上的 [session] 前缀由 prompt/ps1.sh 读取 $ZMX_SESSION。

if command -v zmx >/dev/null 2>&1; then
    source <(zmx completions bash)
fi

if [ -n "${__bash_flyline_enabled-}" ] && [ -z "${__bash_zmx_keys_bound-}" ]; then
    # runBashCommand 只看得见 shell 函数名。
    flyline key bind Alt+n 'always=runBashCommand(__flyline_widget_zmx_select)'
    __bash_zmx_keys_bound=1
fi
