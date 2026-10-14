# ds — 一键重启 dsh 的 zmx 会话，后台跑 `dsh web --no-open`
#
# 流程：先看 `zmx list` 有没有叫 dsh 的会话，有就 kill；再用
# `zmx run dsh -d dsh web --no-open` 创建会话并把命令发进去。
# run 自带创建语义，且 -d 让它立刻返回、不接管前台 PTY——
# 因此这个函数永远不 attach，想看会话时手动 `zmx attach dsh`。
#
# 用法：ds
function ds --description 'Recreate the dsh zmx session running dsh web --no-open'
    if zmx list 2>/dev/null | string match -rq '^[[:blank:]]*name=dsh\t'
        zmx kill dsh
    end
    zmx run dsh -d dsh web --no-open
end
