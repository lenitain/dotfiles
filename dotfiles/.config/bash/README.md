# bash 配置

由 mise dotfiles 部署（`~/.bashrc`、`~/.bash_profile` 是 symlink，`~/.config/bash` 是硬链接的目录）。原则：**每个组件只有一个 owner、一条加载路径**。

> fish 已于 2026-11-01 移除（包与 `~/.config/fish` 都已删除）：这棵树现在是唯一的 shell 配置。

## 入口与加载顺序

`~/.bashrc` 与 `~/.bash_profile` 各只有两行：定好 `BASH_CONFIG_HOME`，然后 source `init.sh`。
**加载逻辑只在 `init.sh` 一处**，它按当前 shell 是否交互分两层：

环境层（所有 shell）：

1. `conf.d/env.sh`、`conf.d/mise.sh` —— 变量、PATH、工具链
2. `conf.d/*KEY.sh` —— 密钥（约定见「密钥」）

交互层（`$-` 含 `i` 才继续）：

3. `functions/*.sh` —— 只定义函数、互不依赖，所以用 glob，加文件不用登记
4. `prompt/ps1.sh`、`prompt/hooks.sh` —— PS1 构建与 `PROMPT_COMMAND` 钩子
5. `conf.d/` —— 显式有序：`aliases` → `flyline` → `fzf` → `history` → `prompt` → `zmx`

顺序即依赖：`flyline` 必须先于 `fzf`/`zmx`（两者靠 `__bash_flyline_enabled` 决定要不要绑键），
`conf.d/prompt.sh` 在 source 阶段就要调用 `prompt/hooks.sh` 里的函数。

`prompt/repo.sh` 不在上面任何一条里：它只在 `widgets/repo.sh` 的子进程里被 source，
主 shell 不必为每个提示符常驻约 230 行 jj/git 代码。

`widgets/`、`theme/`、`scripts/` 不自动 source：`widgets/` 由 flyline 以子进程方式调用，
`scripts/` 由外部程序（如 fzf 的 `--preview`）或手动（验证脚本）执行，`theme/` 由需要配色的 `conf.d` 显式 source。

> **为什么非交互的登录 shell 也要加载环境层**：`niri-session` 会用登录 shell 再执行一次自己
> （`exec bash -c "exec -l '$SHELL' -c 'niri-session -l'"`），那个 shell 不认识 `.bashrc`。
> 现在它读的是 `init.sh`，拿完环境层就返回——PATH 就绪，但别名/键位/提示符一个都不会进。
> （MOD+B 就是这么坏过一次：PATH 只在 `.bashrc` 里设置，niri 的 `spawn` 找不到命令。）

## 工具链（mise）：手动激活

启动时用 `mise env` 一次性注入环境，**不用 `mise activate`**——activate 挂钩子，
每次 cd、每个提示符都重算（本机约 40ms）。

`mise env` 本身约 60ms，所以结果按「全局配置 + mise 二进制 + 启动时的 PATH」
缓存在 `~/.cache/mise/env.sh`：三者都没变就直接 source，省掉这 60ms；任一变了
（`mise install` 换版本、`mise use` 改配置）自动重算。有项目配置的目录不用缓存——
项目 env 跟着 cwd 走，写进全局缓存会张冠李戴。设置 `MISE_ENV` 或 `MISE_CONFIG_FILE`
时也不用缓存。`mr` 会作废缓存。

项目配置的完整清单按 mise 2026.11.14 的 `mise config ls`：`mise.toml`、`.mise.toml`、
`mise.local.toml`、`.mise.local.toml`、`.tool-versions`、`mise/config.toml`、
`.config/mise.toml`、`.config/mise/config.toml`，以及 `MISE_ENV` 对应的
`mise.$MISE_ENV.toml` / `.mise.$MISE_ENV.toml`。`$HOME` 下的
`.config/mise.toml` 与 `.config/mise/config.toml` 是全局配置，不算项目配置；
走到 `$HOME/.config` 时也按全局处理，避免把 `~/.config` 当成项目根（否则进入
`~/.config` 下的任何目录都会被当成项目目录）。`$HOME/mise.toml`、`$HOME/.tool-versions`
仍然算（mise 会加载它们）。

代价：cd 不再自动换工具版本。要切项目版本，敲 `mr` 手动刷新。

- `auto_install = false`：缺工具只警告不下载，装什么由 `mise install` 决定。
- 于是进项目看到 `mise WARN missing: node@20.19.0`、`node` 报「未找到」是正常的——
  PATH 里本来就没那个版本。

## 目录

```
├── init.sh           唯一入口（按是否交互分两层加载）
├── conf.d/           装配层：变量、别名、fzf/zmx 配置、PS1 接线、密钥
├── flyline/          flyline 的加载与全部设置：load / style / widget / behavior
├── functions/        命令：一个文件一个功能，文件头一句话说明作用
├── prompt/           提示符实现：lib.sh（配色/拼接）、ps1.sh、repo.sh、hooks.sh
├── widgets/          flyline 子进程入口（repo.sh）
├── scripts/          外部/手动执行的脚本（fzf 预览、repo 段自检）
├── theme/            配色常量
└── README.md
```

## 组件归属

| 组件 | 来源 | 加载方式 |
| --- | --- | --- |
| bash / bash-completion | pacman | `/etc/bash.bashrc` |
| flyline | mise `github:HalFrgrd/flyline` | `flyline/load.sh`：`enable -f <latest>/libflyline.so*` |
| flyline 全部配置 | `flyline/`（style / widget / behavior） | 每个会话重新声明（flyline 没有配置文件） |
| 提示符 | 本目录（照 pure 的 zsh 版布局在 bash 里重写） | `conf.d/prompt.sh` 接线 → `prompt/ps1.sh` |
| 提示符 widget | `widgets/repo.sh` → `prompt/repo.sh` | `conf.d/flyline.sh` 注册，flyline 子进程调用 |
| 配色 | `theme/everforest_dark_medium.sh` | `conf.d/flyline.sh` 与 `conf.d/fzf.sh` 共用的十六进制值 |
| fzf 主题与布局 | `conf.d/fzf.sh` | `__bash_fzf_opts` 生成 `FZF_DEFAULT_OPTS`（布局 reverse：输入栏在上） |
| fzf 预览脚本 | `~/.config/bash/scripts/fzf_preview.sh` | fzf 子进程调用 |
| repo 段自检 | `~/.config/bash/scripts/repo_check.sh` | 手动：改 `prompt/repo.sh` 后跑（见「验证」） |
| zmx | mise | `conf.d/zmx.sh` + `functions/zmx-select.sh` |
| 密钥 | `conf.d/API_KEY.sh`（gitignored） | `.bashrc` 的 conf.d glob + `.bash_profile` 的 `*KEY.sh` glob |

## flyline 的职责边界

flyline 是 bash 的 loadable builtin（不是独立进程），但它和 bash 的分工有硬边界，配置就按这个边界放：

| 归 flyline | 归 bash |
| --- | --- |
| PS1/RPS1/PS1_FILL/PROMPT_RULER/PS2 的解析与渲染（`\[ \]`、ANSI、`\D{}` 动态时间、widget 占位符、`*_FINAL` 瞬态提示符） | `PROMPT_COMMAND` 执行点（flyline 不跑任何 hook） |
| widget 的执行：同步等待（`--block`）或后台跑（`--placeholder prev`）、超时处理 | cwd 完整显示；仓库段是否另起一行 |
| 键位与 remap、`runBashCommand` 调 bash 函数 | 会话内不变的段：`[zmx]`、SSH 的 user@host |
| 补全/建议/模糊历史搜索、光标绘制、鼠标、帧率 | — |
| shell integration codes（OSC 133 / 633；OSC 7 只在 shell 启动时发一次） | 窗口标题 OSC 0（flyline 不发标题；空闲时 cwd，执行中 cwd – 程序）、OSC 7 目录上报（`prompt/hooks.sh`，每条提示符发一次） |
| 历史搜索界面 | 历史存储：bash 内存历史 + `history -a` |

几条会踩坑的事实（来自 flyline 源码，改配置前先看）：

- **`FLYLINE_VERSION` 是 flyline 导出的环境变量**，子 bash 会继承它但并没有加载 builtin。所以不
  能拿它判断“要不要 `enable -f`”，本目录用不导出的 `__bash_flyline_enabled`。
- **flyline 自定义 widget 的宽度 bash 看不到**（PS1 里只有占位符名字）。`prompt/ps1.sh`
  按 widget 写回的实际宽度（`prompt/lib.sh` 的 `__bash_prompt_repo_width_*`）决定
  仓库段是否另起一行；widget 超时后这一轮没有仓库段（`--placeholder 0`），
  不会画出上一个仓库的段。cwd 不缩略。
- **flyline 的 widget 默认是同步等待**：`--block <毫秒>` 表示提示符最多等这么久，
  超时就放弃等待、改用 `--placeholder` 的占位（这里是 0，不占位），子进程在后台跑完但
  结果丢弃，下一条提示符重新 spawn 一次。不带 `--block` 才是后台跑、显示上一次的结果；
  这里不用后台模式，因为上一个仓库/上一条命令的结果会是错的。flyline 的
  `--placeholder` 只接受数字或 `prev`；`prev` 会显示旧仓库，空格没有信息量，所以选 0。
- **cwd 完整显示，flyline 按最长后缀识别**：`find_cwd_in_span` 匹配 cwd 表示形式的最长
  后缀，并允许前缀是 `…`。不缩略时整条路径都是真实后缀；路径被终端折行时点击可能只认
  其中一段（见「已知差异」）。
- **`set-cursor --backend terminal` 时 flyline 不画光标也不发 DECSCUSR**，光标形状只能由
  `PROMPT_COMMAND` 里的 `printf '\e[6 q'` 负责。
- **`history --backend flyline` 不写 bash 的内存历史**，`!!`、`!$`、`history` 会失效。所以历史
  存储留在 bash，flyline 只用它读历史做搜索。

## flyline 配置放哪

- 加载、配色、widget 注册、编辑器/光标/补全/历史的开关：**全部在 `flyline/`**——
  `load.sh`（enable builtin）、`style.sh`（12 个槽位）、`widget.sh`（提示符 widget）、
  `behavior.sh`（其余开关）。`conf.d/flyline.sh` 只剩一个入口：加载成功就按顺序
  source 这四段，失败就整段跳过。
- `flyline key bind`：放在**提供被绑定函数**的那个 conf.d 里（`conf.d/fzf.sh` 绑 fzf，
  `conf.d/zmx.sh` 绑 zmx），函数和键位一起读，不用来回跳文件。
- 需要单独进程跑的东西放 `widgets/`，由 `flyline/widget.sh` 注册。
- 加载失败（bash 升级后 ABI 不匹配、`.so` 损坏）会在 stderr 说一句；同时
  `prompt/ps1.sh` 不会把 `FLYLINE_REPO` 写进 PS1，提示符只是退化成普通样式，
  不会露出占位符字符串。

## 密钥

唯一来源是 `conf.d/API_KEY.sh`（被仓库根 `.gitignore` 的 `conf.d/*KEY.sh` 忽略）。格式是
纯 bash 的 `export NAME='value'`，没有解析层，两条路径都直接 source：

- `.bashrc` 的 `conf.d` glob —— 交互 shell；
- `.bash_profile` 的 `conf.d/*KEY.sh` glob —— 登录 shell，包括 niri 那条非交互路径。

后者只收 `*KEY.sh`，是为了不把 alias / flyline / fzf / prompt 这些交互配置带进非交互 shell。
文件名以 `KEY.sh` 结尾因此同时被两处依赖：gitignore 和 `.bash_profile`。
新增或轮换密钥只改这一份文件；缺文件时静默跳过。它不随 dotfiles 同步，是**本机唯一副本**，
记得单独备份。

## 提示符

`prompt/ps1.sh` 每次 `PROMPT_COMMAND` 重建 `PS1`，其中仓库段是 flyline 的
widget 占位符（`FLYLINE_REPO`），由 flyline 换成真实输出：

```
[zmx] [docker] host  ~/path  main* ↑   ← 会话段 + cwd(蓝) + 仓库段(暗灰/青/黄)
(venv) ✗ 0|1 ❯                        ← 环境(暗灰) + 退出码(红/黄) + 符号(洋红)
```

- cwd 完整显示，只把 `$HOME` 写成 `~`；不缩略。第一行放不下时，在仓库段前插一个
  换行，仓库段整体到下一行（短路径一行，长路径两行；路径本身超过终端宽度时只能让
  终端折行）。第二行不参与这个判断。
- 仓库段由 `widgets/repo.sh` 输出，看最近一层仓库根上的标记：共置仓库（`.jj` 与
  `.git` 在同一个根）jj、git 两段都画，jj 在前、中间两个空格，例如
  `r main+*  main* ↑`；只有一种标记就只画那一种，父目录里的 git 分支不会混进来。
  git 段是 branch / dirty(`*`) / `↑` `↓` / 操作中状态（`REBASE 2/5`、`MERGING` 等）：
  分支、dirty、上游、ahead/behind 都来自同一次 `git status --porcelain=v2 --branch`，
  不画 stash，也不画数字；操作中状态直接读 gitdir 下的文件，不额外 fork。
  detached HEAD 画红色的 `(detached)` 加 name-rev 的名字（`main~1`）；共置仓库里
  jj 会主动把 git HEAD 留在 detached，那时不画 `(detached)`，jj 段已经说明状态。
  jj 的记账 ref（`refs/jj/*`）不参与取名，没有名字就画短哈希。
  jj 是变更 id / 最近的祖先书签（`+` 表示在书签之上，不带数字）/ `(empty)`，
  以及 @ 的冲突 `×`、divergent `≠`、snapshot 警告 `!`。
  jj 的书签只在 @ 的 20 个祖先提交内查找，距离是从 @ 沿父边走过去的边数
  （空 @ 不计一步），最近的本地书签超出这个范围就不显示；同一距离上的多个书签
  写成 `main,dev+`（`+` 修饰整组）。jj 不画同步状态；要看远端跟踪用
  `jj bookmark list`。jj 段每次都让 jj 做一次 snapshot：jj 的工作副本就是一个提交，
  只有 snapshot 能发现文件变化（没有 git status 那种只读查询），所以 `(empty)` / `*`
  和 `jj st` 永远一致。代价是文件改过的那次提示符会写一条 snapshot 操作；没变化时
  只做一次 stat 扫描，大仓库可以装 watchman 并设 `fsmonitor.backend = "watchman"` 提速。
  jj 自己失败时（工作副本陈旧、配置错、锁）jj 段画红色的 `jj!`，报错细节跑一次
  `jj st` 看；共置仓库里 git 段照画，`jj!` 说明是 jj 那边出的错。没装 jj 时没有 jj 段。
  jj 往 stderr 写警告时（典型是超过 `snapshot.max-new-file-size` 的新文件被拒绝，
  权限错误同理）段尾画黄色 `!`：命令本身成功，但那个文件没进 jj，不标的话提示符是
  一份看起来正常的 `(empty)`；原文跑 `jj st` 看（一次性的提示也会亮一次，比如共置仓库里
  git HEAD 变过、jj 重置了工作副本父提交）。冲突的书签名后面画红色 `!`
  （`main!+`、`main!`）：`jj log <名字>` 会直接报 `Name ... is conflicted`，
  `jj bookmark list` 看两个目标，`jj bookmark set <名字> -r <rev>` 定夺。
  仓库段由 flyline 有界等待至多 100ms（`--block 100`）：这一轮提示符被
  `jj log` / `git status` 拖住至多 100ms，超时则这一轮没有仓库段
  （`--placeholder 0`）。不是后台异步：后台模式会显示上一个仓库/上一条命令的结果，
  和“结果必须对应当前状态”冲突。
- 符号行（第 2 行）的段：root 的 `#`（`$EUID`）/ venv 名
  （`VIRTUAL_ENV_PROMPT` → `VIRTUAL_ENV` → `CONDA_DEFAULT_ENV`，只取末段）/
  上一条命令的退出码。venv 自带的前缀由 `VIRTUAL_ENV_DISABLE_PROMPT` 关掉，
  名字只由这里画。nix 段已删除。
- 退出码列表：只有管道最后一个状态非 0 才显示，`✗` 是失败标志，`|` 只分隔管道的
  各个阶段（`✗ 0|1`）；`128+N` 换成信号名（`143` → `SIGTERM`）。SIGINT（130）用黄色，
  其它失败用红色。所以 `ps1.sh` 里 `PIPESTATUS` 必须是 `__bash_prompt` 的第一条语句，
  任何 `printf` 之后就只剩它自己的 0 了。
- 会话段（第 1 行，会话内只算一次）：`[zmx]`、SSH 的 `user@host`、容器里的
  `[docker] host`（完整 hostname，不画 user）。容器检测读固定路径、不 fork，顺序是
  标记文件（`/.dockerenv`、`/run/.containerenv`）→ `/run/systemd/container` →
  `/proc/1/cgroup` → PID 1；cgroup v2 只有一行 `0::/`，rootless 运行时只能由 PID 1
  兜底，那时只能给出泛称 `[container]`。
- 命令耗时默认不显示。想打开就取消 `conf.d/flyline.sh` 里的 `last-command-duration`
  注册，并把 `FLYLINE_DURATION` 补回 `PS1`（记得同时为它留 8 列宽度）。
- 宽度：cwd 不缩略；widget 每次把实际可见宽度写进
  `$XDG_RUNTIME_DIR/bash-prompt-repo-width.<shell pid>`，`prompt/ps1.sh` 用这个宽度
  决定仓库段是否另起一行。没有缓存（本仓库第一条提示符）时不预留；
  切仓库后的第一条提示符用上一个仓库的宽度。
- 提示符本身是 `PROMPT_COMMAND` 的第一个元素；窗口标题（空闲时的路径）和 `history -a`
  跟在后面，执行中的程序名由 `PS0` 在命令开始前补。
- 不用瞬态提示符：`PS1_FINAL` 被 unset，命令提交后 flyline 的最后一次重绘沿用完整
  `PS1`，历史里那条已输入命令保留第一行（会话段 + cwd + 仓库段）和命令前的空行。
- 窗口标题空闲时只显示当前目录：`prompt/hooks.sh` 发 OSC 0（家目录写成 `~`）。
  命令开始执行前 `PS0` 再发一次 `cwd – 程序名`，程序名取刚读入的历史行的第一个词
  （跳过 `VAR=value` 前缀和路径），提示符出现后恢复成纯路径。
  `/etc/bash.bashrc` 自带的 `user@host:cwd` 标题命令会被摘掉：两条 OSC 0 连发会让
  终端先显示系统标题再被覆盖，标题会闪一下。
- OSC 7 每条提示符发一次（`prompt/hooks.sh`）：foot 只有在收到 OSC 7 时才知道
  当前目录，`Ctrl+Shift+N` 才能在当前目录里开新终端。flyline 的 OSC 7 只在 shell 启动时
  发一次，`cd` 之后不更新，所以这条由 bash 补。

## 已知差异

- 路径宽度按字符数计算，CJK 双宽路径比终端列宽略宽；仓库段前的折行判断会因此偏晚。
- 字形全部在主字体里：`✗`（U+2717）、`↑` `↓`、`×`、`≠`、`❯`。
  `✖`（U+2716）、`⇡` `⇣`、`≡` 不在 Maple Mono NL NF CN 里，已不用；`✗` 和 `×`
  同时出现时靠行和上下文区分。
- 仓库段宽度缓存按 shell 而不是按仓库：刚 `cd` 进另一个仓库时，第一条提示符用上一个
  仓库的实际宽度；第一次进仓库（没有缓存）不预留。仓库段超长（超长分支名、
  多个书签）时在仓库段前折行，仓库段本身不会被拆开。
- cwd 完整显示；路径本身超过终端宽度时由终端折行，flyline 的 cwd 点击在折行处可能只认
  其中一段。这是不缩略的代价。
- 仓库段每条提示符都要跑一次 jj/git，`--block 100` 是有界等待：本机实测提示符构造
  平均多约 70ms（`flyline perf dump` 里的 `startup: prompt manager`），慢仓库顶到
  100ms 时那轮仓库段为空。
- 占位符选 0（不占位）：flyline 的 `--placeholder` 只接受数字或 `prev`；`prev` 会
  显示旧仓库的结果，空格只是空洞，0 最干净。超时那一条提示符停在 cwd，下一条按实际
  宽度出现。
- Tab 补全/历史搜索 UI 由 flyline 提供。
- 历史后端用 bash 原生（`histappend` + 提示符后 `history -a`）；换成 flyline 的 JSONL 后端会
  丢掉 `!!`/`!$`/`history`，所以不建议。
- `history -a` 只把当前会话的新命令**写盘**；别的会话要看得到得重开或手动 `history -r`，
  不存在“即时共享”。

## 验证

```bash
bash -n ~/.bashrc ~/.bash_profile ~/.config/bash/init.sh \
    ~/.config/bash/conf.d/*.sh ~/.config/bash/functions/*.sh \
    ~/.config/bash/prompt/*.sh ~/.config/bash/widgets/*.sh \
    ~/.config/bash/scripts/*.sh ~/.config/bash/flyline/*.sh
~/.config/bash/scripts/repo_check.sh    # repo 段：模板段数契约 + 端到端场景（参考点、merge、符号链接、未 snapshot 的改动、snapshot 警告、书签冲突、jj 报错、共置仓库的两段、jj 段嵌在 git 工作树里、同层两个书签的 main,dev+），退出码必须是 0
~/.config/bash/scripts/git_check.sh     # git 段：分支/dirty/上游/操作中状态（rebase-merge、worktree）/detached/jj 记账 ref/bare/空仓库 + 宽度缓存，stash 不画；退出码必须是 0
~/.config/bash/widgets/repo.sh          # 仓库里输出单行、仓库外输出空，两种情况退出码都必须是 0
bash -i -c 'type ll; flyline settings; flyline key list'   # 需要 pty
mise bootstrap dotfiles status
```

伪终端里测试 flyline 时务必设置 `COLUMNS/LINES`，否则 flyline 会 panic。
