# bash 配置

由 mise dotfiles 部署（`~/.bashrc`、`~/.bash_profile`、`~/.config/bash` 都是 symlink）。原则：**每个组件只有一个 owner、一条加载路径**。

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
（`mise install` 换版本、`mise use` 改配置）自动重算。有项目 `mise.toml` 的目录
不用缓存——项目 env 跟着 cwd 走，写进全局缓存会张冠李戴。`mr` 会作废缓存。

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
| 提示符 | 本目录（pure 4.19.2 的 bash 版） | `conf.d/prompt.sh` 接线 → `prompt/ps1.sh` |
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
| 所有异步 widget 的执行、超时、`prev` 缓存 | cwd 的宽度取舍（flyline 不截断提示符） |
| 键位与 remap、`runBashCommand` 调 bash 函数 | 会话内不变的段：`[zmx]`、SSH 的 user@host |
| 补全/建议/模糊历史搜索、光标绘制、鼠标、帧率 | — |
| shell integration codes（OSC 133 / 633；OSC 7 只在 shell 启动时发一次） | 窗口标题 OSC 0（flyline 不发标题；空闲时 cwd，执行中 cwd – 程序）、OSC 7 目录上报（`prompt/hooks.sh`，每条提示符发一次） |
| 历史搜索界面 | 历史存储：bash 内存历史 + `history -a` |

几条会踩坑的事实（来自 flyline 源码，改配置前先看）：

- **`FLYLINE_VERSION` 是 flyline 导出的环境变量**，子 bash 会继承它但并没有加载 builtin。所以不
  能拿它判断“要不要 `enable -f`”，本目录用不导出的 `__bash_flyline_enabled`。
- **flyline 自定义 widget 的宽度 bash 看不到**（PS1 里只有占位符名字）。`prompt/ps1.sh`
  先用上限预留，之后按 widget 写回的实际宽度缩 cwd（`prompt/lib.sh` 的
  `__bash_prompt_repo_width_*`）；慢命令超时后显示空白，不会画出上一个仓库的段。
- **cwd 只有“真实路径的后缀”才能被 flyline 认出来**：`find_cwd_in_span` 匹配 cwd 表示形式的最长
  后缀，并允许前缀是 `…`（或点串）。所以缩略用 `…/tail/segments`，每段仍然可点击跳转；
  `~/.c/m/d/foo` 这种“每段只留首字母”的写法 flyline 只能匹配到最后一段。
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
[zmx] [docker] user@host  ~/path  main* ≡2 ⇡1 ⇣3   ← 会话段 + cwd(蓝) + git/jj(暗灰/青)
# ❄impure (venv) |0|1 ❯                              ← 上下文(红/青/暗灰) + 退出码(红) + 符号(洋红)
```

- git/jj 段由 `widgets/repo.sh` 输出（jj 仓库优先，否则 git）：git 是
  branch / dirty(`*`) / stash(`≡N`) / `⇡N` `⇣N`（分支、dirty、上游、ahead/behind
  都来自同一次 `git status --porcelain=v2 --branch`，stash 另查一次）；jj 是变更 id / 最近的祖先书签
  （`~N` 距离）/ `(empty)`，以及 @ 的冲突 `×` 和 divergent `≠`。
  jj 的书签只在 @ 的 20 个祖先提交内查找，距离是从 @ 沿父边走过去的边数
  （空 @ 不计一步），最近的本地书签超出这个范围就不显示；merge 时同一距离上的
  多个书签都画出来（逗号分隔）。jj 不画同步状态；要看远端跟踪用
  `jj bookmark list`。jj 用 `--ignore-working-copy` 读最后一次 snapshot：刚改完
  文件、还没跑任何 jj 命令时，`(empty)` / `*` 仍是上一次的状态（提示符不写 op log）。
  flyline 只等 100ms，超时那段时间仓库段是空白
  （`--placeholder 0`），提示符不再被 `jj log` 或 `git status` 卡住。
- 符号行（第 2 行）的段按 pure 的顺序拼，每条提示符重算，都只读变量和内建、不 fork：
  root 的 `#`（`$EUID`）/ nix develop 的 `❄`+`$IN_NIX_SHELL` / venv 名
  （`VIRTUAL_ENV_PROMPT` → `VIRTUAL_ENV` → `CONDA_DEFAULT_ENV`，只取末段）/ 上一条命令的
  退出码。venv 自带的前缀由 `VIRTUAL_ENV_DISABLE_PROMPT` 关掉，名字只由这里画。
- 退出码列表（`pure_show_exit_status` 的 bash 版）：只有管道最后一个状态非 0 才显示，
  整条管道的 `PIPESTATUS` 用 `|` 连起来，`128+N` 换成信号名（`143` → `SIGTERM`）。
  所以 `ps1.sh` 里 `PIPESTATUS` 必须是 `__bash_prompt` 的第一条语句，任何 `printf` 之后
  就只剩它自己的 0 了。
- 会话段（第 1 行，会话内只算一次）：`[zmx]`、SSH 的 `user@host`、容器里的
  `[docker] user@host`。容器检测读固定路径、不 fork，顺序是标记文件（`/.dockerenv`、
  `/run/.containerenv`）→ `/run/systemd/container` → `/proc/1/cgroup` → PID 1；
  cgroup v2 只有一行 `0::/`，rootless 运行时只能由 PID 1 兜底，那时只能给出泛称 `[container]`。
- 命令耗时默认不显示。想打开就取消 `conf.d/flyline.sh` 里的 `last-command-duration` 注册，
  并把 `FLYLINE_DURATION` 补回 `PS1`（记得同时为它留 8 列宽度）。
- 宽度：仓库里第一条提示符按上限 40 列预留；widget 每次把实际可见宽度写进
  `$XDG_RUNTIME_DIR/bash-prompt-repo-width.<shell pid>`，之后 cwd 按 `COLUMNS` 减去
  这个实际值决定是否缩略成 `…/尾段`（切仓库后的第一条提示符用上一个仓库的宽度）。
  第 2 行不参与这个预算。
- cwd 缩略只有 `…/tail` 形式能让 flyline 把整段识别成 cwd，其余段落的点击跳转因此保留。
- 提示符本身是 `PROMPT_COMMAND` 的第一个元素；窗口标题（空闲时的路径）和 `history -a`
  跟在后面，执行中的程序名由 `PS0` 在命令开始前补。
- 不用瞬态提示符：`PS1_FINAL` 被 unset，命令提交后 flyline 的最后一次重绘沿用完整 `PS1`，
  历史里那条已输入命令保留第一行（会话段 + cwd + 仓库段）和命令前的空行。
- 窗口标题空闲时只显示当前目录：`prompt/hooks.sh` 发 OSC 0（家目录写成 `~`）。
  命令开始执行前 `PS0` 再发一次 `cwd – 程序名`，程序名取刚读入的历史行的第一个词
  （跳过 `VAR=value` 前缀和路径），提示符出现后恢复成纯路径。
  `/etc/bash.bashrc` 自带的 `user@host:cwd` 标题命令会被摘掉：两条 OSC 0 连发会让
  终端先显示系统标题再被覆盖，标题会闪一下。
- OSC 7 每条提示符发一次（`prompt/hooks.sh`）：foot 只有在收到 OSC 7 时才知道
  当前目录，`Ctrl+Shift+N` 才能在当前目录里开新终端。flyline 的 OSC 7 只在 shell 启动时
  发一次，`cd` 之后不更新，所以这条由 bash 补。

## 已知差异

- 路径宽度按字符数计算，CJK 双宽路径比终端列宽略宽。
- 仓库段的宽度缓存按 shell 而不是按仓库：刚 `cd` 进另一个仓库时，第一条提示符用的是
  上一个仓库的实际宽度；第一次进仓库（没有缓存）用 40 列上限。仓库段超过预算
  （超长分支名、多个书签）时第一行仍可能折行一次。
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
    ~/.config/bash/scripts/*.sh
~/.config/bash/scripts/repo_check.sh    # repo 段：模板段数契约 + 端到端场景（参考点、merge、符号链接），退出码必须是 0
~/.config/bash/scripts/git_check.sh     # git 段：分支/dirty/stash/上游/detached/bare/空仓库 + 宽度缓存，退出码必须是 0
~/.config/bash/widgets/repo.sh          # 仓库里输出单行、仓库外输出空，两种情况退出码都必须是 0
bash -i -c 'type ll; flyline settings; flyline key list'   # 需要 pty
mise bootstrap dotfiles status
```

伪终端里测试 flyline 时务必设置 `COLUMNS/LINES`，否则 flyline 会 panic。
