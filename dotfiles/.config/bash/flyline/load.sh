# flyline 的加载：mise 把它装成 bash loadable builtin，没有配置文件，
# 所有设置都在本目录其它文件里、每个 shell 重放一次。
#
# FLYLINE_VERSION 是 flyline 自己导出的环境变量：子 bash 会继承它，但 builtin 并没有加载，
# 所以不能拿它判断要不要 enable。用不导出的 __bash_flyline_enabled 只记「本 shell 已加载」。
#
# stdin/stdout 都不是终端时不加载：flyline 渲染依赖终端尺寸，stdout 被重定向时也不该接管行编辑。

if [ -z "${__bash_flyline_enabled-}" ] && [ -t 0 ] && [ -t 1 ]; then
    # `enable flyline` 靠 BASH_LOADABLES_PATH 找不到 mise 的版本化文件名，必须显式 -f。
    # latest 是 mise 维护的软链，升级后跟得上。
    for _bash_flyline_lib in "$HOME"/.local/share/mise/installs/github-hal-frgrd-flyline/latest/libflyline.so*; do
        [ -f "$_bash_flyline_lib" ] || continue
        if enable -f "$_bash_flyline_lib" flyline 2>/dev/null; then
            __bash_flyline_enabled=1
            break
        fi
        _bash_flyline_failed=$_bash_flyline_lib
    done
    # 文件在、但 enable 失败（bash 升级后 ABI 不匹配、.so 损坏）必须出声：
    # 否则表现只是「提示符里多出 FLYLINE_REPO」和「flyline 不生效」，没有任何线索。
    if [ -z "${__bash_flyline_enabled-}" ] && [ -n "${_bash_flyline_failed-}" ]; then
        printf 'bash: flyline 加载失败（%s），本会话退回 bash 原生行编辑\n' "$_bash_flyline_failed" >&2
    fi
    unset _bash_flyline_lib _bash_flyline_failed
fi
