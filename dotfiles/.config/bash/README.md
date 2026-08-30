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
主 shell 不必为每个提示符常驻 300 多行 jj/git 代码。

`widgets/`、`theme/`、`scripts/` 不自动 source：`widgets/` 由 flyline 以子进程方式调用，
`scripts/` 由外部程序（如 fzf 的 `--preview`）执行，`theme/` 由需要配色的 `conf.d` 显式 source。

> **为什么非交互的登录 shell 也要加载环境层**：`niri-session` 会用登录 shell 再执行一次自己
> （`exec bash -c "exec -l '$SHELL' -c 'niri-session -l'"`），那个 shell 不认识 `.bashrc`。
> 现在它读的是 `init.sh`，拿完环境层就返回——PATH 就绪，但别名/键位/提示符一个都不会进。
> （MOD+B 就是这么坏过一次：PATH 只在 `.bashrc` 里设置，niri 的 `spawn` 找不到命令。）

## 目录

```
├── init.sh           唯一入口（按是否交互分两层加载）
├── conf.d/           装配层：变量、别名、fzf/zmx 配置、PS1 接线、密钥
├── flyline/          flyline 的加载与全部设置：load / style / widget / behavior
├── functions/        命令：一个文件一个功能，文件头一句话说明作用
├── prompt/           提示符实现：lib.sh（配色/拼接）、ps1.sh、repo.sh、hooks.sh
├── widgets/          flyline 子进程入口（repo.sh）
├── scripts/          被外部程序执行的小脚本（fzf 预览）
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
| fzf 主题 | `conf.d/fzf.sh` | 从 theme 文件生成 `FZF_DEFAULT_OPTS` |
| fzf 预览脚本 | `~/.config/bash/scripts/fzf_preview.sh` | fzf 子进程调用 |
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
| shell integration codes（OSC 133 / 633；OSC 7 只在 shell 启动时发一次） | 窗口标题 OSC 0（flyline 不发标题）、OSC 7 目录上报（`prompt/hooks.sh`，每条提示符发一次） |
| 历史搜索界面 | 历史存储：bash 内存历史 + `history -a` |

几条会踩坑的事实（来自 flyline 源码，改配置前先看）：

- **`FLYLINE_VERSION` 是 flyline 导出的环境变量**，子 bash 会继承它但并没有加载 builtin。所以不
  能拿它判断“要不要 `enable -f`”，本目录用不导出的 `__bash_flyline_enabled`。
- **flyline 自定义 widget 的宽度 bash 看不到**（PS1 里只有占位符名字）。`prompt/ps1.sh`
  按上限预留列宽；慢命令超时后 flyline 先显示上一次的输出，所以仓库段可能比当前目录慢一拍。
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
[zmx] ~/path  main* ⇡ ≡            ← cwd(蓝) + git/jj(暗灰/青)
❯                                  ← 洋红
```

- git/jj 段由 `widgets/repo.sh` 输出（jj 仓库优先，否则 git）：变更 id / 书签 / `~N`/`+N` /
  `⇡⇣?!×≠` / `(empty)`。flyline 只等 100ms，慢的时候先显示上一次的输出，提示符不再被 `jj log`
  或 `git status` 卡住。
- 命令耗时默认不显示。想打开就取消 `conf.d/flyline.sh` 里的 `last-command-duration` 注册，
  并把 `FLYLINE_DURATION` 补回 `PS1`（记得同时为它留 8 列宽度）。
- 宽度：`FLYLINE_REPO` 预留 32 列（只在仓库里预留）；cwd 按 `COLUMNS` 减去这些预算决定
  是否缩略成 `…/尾段`。
- cwd 缩略只有 `…/tail` 形式能让 flyline 把整段识别成 cwd，其余段落的点击跳转因此保留。
- 提示符本身是 `PROMPT_COMMAND` 的第一个元素；窗口标题和 `history -a` 跟在后面。
- 不用瞬态提示符：`PS1_FINAL` 被 unset，命令提交后 flyline 的最后一次重绘沿用完整 `PS1`，
  历史里那条已输入命令保留第一行（会话段 + cwd + 仓库段）和命令前的空行。
- 窗口标题只显示当前目录：`prompt/hooks.sh` 发 OSC 0（家目录写成 `~`）。
  `/etc/bash.bashrc` 自带的 `user@host:cwd` 标题命令会被摘掉：两条 OSC 0 连发会让
  终端先显示系统标题再被覆盖，标题会闪一下。
- OSC 7 每条提示符发一次（`prompt/hooks.sh`）：foot 只有在收到 OSC 7 时才知道
  当前目录，`Ctrl+Shift+N` 才能在当前目录里开新终端。flyline 的 OSC 7 只在 shell 启动时
  发一次，`cd` 之后不更新，所以这条由 bash 补。

## 已知差异

- 路径宽度按字符数计算，CJK 双宽路径比终端列宽略宽。
- 仓库段是按上限预留列宽的：仓库段异常长（超长分支名、多个书签）时第一行可能折行一次。
- Tab 补全/历史搜索 UI 由 flyline 提供。
- 历史后端用 bash 原生（`histappend` + 提示符后 `history -a`）；换成 flyline 的 JSONL 后端会
  丢掉 `!!`/`!$`/`history`，所以不建议。
- `history -a` 只把当前会话的新命令**写盘**；别的会话要看得到得重开或手动 `history -r`，
  不存在“即时共享”。

## 验证

```bash
bash -n ~/.bashrc ~/.bash_profile ~/.config/bash/init.sh \
    ~/.config/bash/conf.d/*.sh ~/.config/bash/functions/*.sh \
    ~/.config/bash/prompt/*.sh ~/.config/bash/widgets/*.sh
~/.config/bash/widgets/repo.sh          # 仓库里输出单行、仓库外输出空，两种情况退出码都必须是 0
bash -i -c 'type ll; flyline settings; flyline key list'   # 需要 pty
mise bootstrap dotfiles status
```

伪终端里测试 flyline 时务必设置 `COLUMNS/LINES`，否则 flyline 会 panic。
