# 启动时用 `mise env` 一次性注入全局工具 PATH 和 [env] 变量。
# 不用 `mise activate`：它挂 PROMPT_COMMAND + chpwd 钩子，每次 cd、每个提示符
# 都重算一遍（本机约 40ms）。代价：cd 不再自动换工具版本，手动敲 `mr` 刷新。
# 标记不导出：同一 shell 只注入一次，新 shell 各自注入。
if [ -z "${__bash_mise_activated-}" ] && command -v mise >/dev/null 2>&1; then
    eval "$(mise env -s bash)"
    __bash_mise_activated=1
    # mise env 在干净 shell 里不带 shims，自己补上（给 IDE、niri spawn 等
    # 不读 bashrc 的程序用）。放末尾：优先跑直接安装的工具，shims 只兜底。
    case ":$PATH:" in
        *":$HOME/.local/share/mise/shims:"*) ;;
        *) PATH="$PATH:$HOME/.local/share/mise/shims" ;;
    esac
    # 去重，免得每嵌套一层 shell PATH 就长一截。函数由 conf.d/env.sh 定义。
    __bash_path_dedupe
fi

# 手动刷新（别名 mr）：按当前目录重算环境，再补 shims、去重 PATH。
__bash_mise_refresh() {
    eval "$(mise hook-env -s bash)"
    case ":$PATH:" in
        *":$HOME/.local/share/mise/shims:"*) ;;
        *) PATH="$PATH:$HOME/.local/share/mise/shims" ;;
    esac
    __bash_path_dedupe
}
