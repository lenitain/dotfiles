# 历史存储是 bash 的职责：!! / !$ / history 都依赖它的内存历史。
# 切到 flyline 的 JSONL 后端会丢掉这些，所以只让 flyline 负责历史搜索的界面。

HISTSIZE=100000
HISTFILESIZE=200000
HISTCONTROL=ignoredups
HISTTIMEFORMAT='%F %T '
shopt -s histappend
shopt -s checkwinsize
