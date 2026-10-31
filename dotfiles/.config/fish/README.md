# fish 配置管理

这份目录由 mise dotfiles 部署（`~/.config/fish` 是 symlink）。原则是**每个组件只有一个 owner、一条加载路径**。

## 组件归属

| 组件 | 来源 | Owner / 更新方式 | 加载方式 |
| --- | --- | --- | --- |
| fish | pacman | `conf.d/packages.toml` → `mise run setup-all` | `/usr/share/fish` |
| fish-autopair | pacman | 同上 | vendor functions |
| fish-pure-prompt（pure 本体） | pacman | 同上 | vendor functions |
| jujutsu | pacman | 同上 | `jj` 命令 |
| 本目录的 config / theme / functions | `~/.config/mise/dotfiles` | mise dotfiles | symlink |
| pure-jj（个人扩展） | `~/.projects/pure-jj` | 独立 Git 仓库；远程就绪后由 `[bootstrap.repos]` 管理 | `conf.d/personal_plugins.fish` |
| `_pure_place_iterm2_prompt_mark.fish` | 本目录 | 有意的 pure no-op override | 覆盖 vendor 同名函数 |
| `~/.cloned/pure` | 手动 git clone | 上游参考，**不参与运行** | 不在 `fish_function_path` |
| `fish_variables` | fish 自动生成，gitignore | 不手改、不作为跨机配置源 | universal 状态 |
| Fisher / `fish_plugins` | 未安装 | 不使用 | — |

## 规则

- **上游插件只走 pacman**，并声明在 `~/.config/mise/conf.d/packages.toml`。不要再用 Fisher / git clone / 手拷同一份插件。
- **个人配置只走 dotfiles**。`~/.config/fish` 是 mise 的 symlink，Fisher 会直接写进 dotfiles 源树，所以这台机器不用 Fisher。
- **个人可复用代码只走一个独立 repo**，并由 mise `[bootstrap.repos]` 声明；不要保留“手写项目 + 手写 loader 但 mise 不知道”的中间态。
- **`~/.cloned` 只做参考**，永远不要加进 `fish_function_path`。
- **`fish_variables` 是状态不是源**。需要跨机保留的设置写到 tracked 的 `conf.d/*.fish`。
- 一个组件一个 owner；用 `mise bootstrap status --missing` 查漂移。

## pure-jj 的加载

`conf.d/personal_plugins.fish` 是个人 fish 插件的唯一注册点：

```fish
set --query fish_personal_plugin_dirs
or set --global fish_personal_plugin_dirs $HOME/.projects/pure-jj
```

它会把每个插件目录的 `functions/`、`completions/` 加进 fish 路径，并 source 其 `conf.d/*.fish`。pure-jj 的源码和完整配置说明在 `~/.projects/pure-jj/README.md`。

### 远程仓库就绪后启用 bootstrap

当前 `~/.config/mise/conf.d/repos.toml` 里的 `[bootstrap.repos]` 是注释状态，避免远程不存在时 `mise bootstrap` 因 origin 不匹配而中止。远程建好后：

```fish
git -C ~/.projects/pure-jj remote add origin git@github.com:lenitain/pure-jj.git
git -C ~/.projects/pure-jj push -u origin main
```

然后取消 `conf.d/repos.toml` 中这两行的注释：

```toml
[bootstrap.repos]
"~/.projects/pure-jj" = { url = "git@github.com:lenitain/pure-jj.git", ref = "main" }
```

并运行：

```fish
mise bootstrap repos apply
mise bootstrap status --missing
```

之后 `mise run setup-all` 会同时更新 pacman 包、dotfiles 和 pure-jj 仓库。

## 验证

```fish
functions --details _pure_prompt_git   # 应指向 ~/.projects/pure-jj/functions/_pure_prompt_git.fish
printf '%s\n' $fish_function_path      # 第一项应是 pure-jj/functions
mise bootstrap dotfiles status         # ~/.config/fish 应为 applied
mise bootstrap repos status            # 启用后应显示 pure-jj 的 origin/ref
```
