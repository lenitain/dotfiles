# activate 负责工具版本、PATH 和 chpwd hook。
# .bash_profile 和 .bashrc 都会调用（登录 + 交互），用非导出的标记避免重复 activate。
# 非导出变量不会传给子 shell，所以每个新 bash 仍会各自 activate。
if [ -z "${__bash_mise_activated-}" ] && command -v mise >/dev/null 2>&1; then
    eval "$(mise activate bash)"
    __bash_mise_activated=1
    # activate 会把 shims 和 ~/.cargo/bin 再前置一遍（不查重），这里马上收尾，
    # 免得每嵌套一层 shell PATH 就长一截。函数由 conf.d/env.sh 定义。
    __bash_path_dedupe
fi
