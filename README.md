# dotfiles(mise)

## 目录

```
~/.config/mise/
├── config.toml        # [settings]
├── .pre-commit-config.yaml  # gitleaks 配置（由 prek 调度）
├── conf.d/            # 片段（字母序自动合并）
│   ├── tools.toml     #   [tools]
│   ├── dotfiles.toml  #   [dotfiles]
│   ├── packages.toml  #   [bootstrap.packages]
│   ├── system.toml    #   [bootstrap.*]
│   ├── mirrors.toml   #   [env] + [settings] 下载镜像（唯一来源）
│   └── hooks.toml     #   [bootstrap.hooks]
├── dotfiles/          # dotfile 源树（home 相对）
├── xray/              # 远程 VPS 供给（ansible）
└── tasks/             # 任务
```

## 日常

`mise bootstrap` = 先全量升级，再声明式收敛：`[bootstrap.hooks.pre-packages]`
（见 conf.d/hooks.toml）在 packages 阶段前跑 `sudo pacman -Syu --noconfirm`。
追最新走 `mise run setup-all`（= bootstrap + `mise upgrade` + 各 sync 任务）。

> 为什么 -Syu 必须紧贴 packages 阶段：mise 装缺包只发 `pacman -S --needed`
>（不刷新同步库），仅在同步库不新于已装版本时才安全；库比系统新时会变成 Arch
> 不支持的 [partial upgrade](https://wiki.archlinux.org/title/System_maintenance#Partial_upgrades_are_unsupported)。
> hook 失败会中止 bootstrap，所以 packages 不会在危险状态下执行。
> 注意 `mise bootstrap packages apply` / `use` 这类分部命令不经过 hooks，只依赖
> 「库不新于系统」；而 `packages upgrade` 与 `apply --update`（都先 `pacman -Sy`
> 再只动声明包）不要用，升级统一走 setup-all。

```bash
mise run setup-all              # 日常唯一入口：收敛 + 全量升级
mise bootstrap --yes            # 收敛 + 全量升级 (pre-packages hook 先 -Syu)
mise bootstrap --dry-run        # 模拟 apply，打印将执行的变更，不改任何东西
mise tasks                      # 列任务
mise ls                         # 已装工具
```

## 提交前密钥检查（prek + gitleaks）

`.pre-commit-config.yaml` 只配了 gitleaks 一个 hook，运行器用 prek（pre-commit 的 Rust
重写，直接读取原配置文件）。**未安装 git 钩子**（`prek install` 会在 `.git/hooks/`
写脚本，属于本地状态），改为手动运行：

```bash
prek run --all-files            # 跑配置里的全部 hook
prek run gitleaks --all-files   # 只跑 gitleaks
```

> 当前两者**效果相同**——全量模式就是按配置顺序跑所有 hook，而配置里只有 gitleaks。
> 等以后加入其他 hook（black、shellcheck 等），`run gitleaks` 才用于只跑密钥扫描。

习惯：`git commit` 前手动跑一次；需要自动拦截时 `prek install` 可恢复钩子。

## 体检（只读）

```bash
mise bootstrap status                    # 逐资源一行：资源 / 当前值 / 期望值 / 来源配置
mise bootstrap status --missing          # 同上；只要有资源未达期望态就 exit 1（脚本/CI 用）
mise bootstrap plan                      # 逐资源并排「当前 vs 期望」，即 apply 会改成的样子
mise bootstrap plan --detailed-exitcode  # 0=无变更 2=有变更 1=计划失败或有资源 unknown
mise bootstrap dotfiles apply --dry-run --verbose   # dotfile 逐文件 diff
```

各部分单独 `status`（支持 `--json`；`dotfiles` 状态值为 applied/differs/missing，`packages` 为 installed/missing）：

```bash
mise bootstrap dotfiles status   # ~/.config/fish  copy  <src>  <cfg>  applied
mise bootstrap packages status   # pacman:niri  26.04-1.1  installed
mise bootstrap files status      # file:/etc/greetd/config.toml  当前 mode/owner  vs  期望
mise bootstrap services status   # service:greetd  active; enabled  vs  期望
mise bootstrap accounts status   # user:lenitain  present ...   vs  期望
mise bootstrap repos status      # git 仓库
mise bootstrap user status       # 登录 shell
```

> systemd user 单元不走 `[bootstrap.linux.systemd.units]`，而是作为普通文件由
> `[dotfiles]` 的 `~/.config/systemd/user` 收敛。

## 改配置

```bash
# dotfiles（copy；改源→部署 / 改已部署→回存）
mise bootstrap dotfiles apply
mise bootstrap dotfiles add ~/.config/xxx
mise bootstrap dotfiles edit ~/.config/xxx

# 系统配置 /etc：改 conf.d/system.toml 的 content
mise bootstrap files apply          # 有变化才 sudo

# 登录 shell：改 conf.d/system.toml 的 [bootstrap.user] login_shell
mise bootstrap user status          # 当前 vs 期望；--missing 不一致则 exit 1
mise bootstrap user apply           # 必要时写 /etc/shells + chsh -s（本机已是 fish，为 no-op）

# 工具
mise use -g <tool>@<version>
mise install / mise upgrade / mise ls

# 系统包
mise bootstrap packages use pacman:foo@version   # 或编辑 conf.d/packages.toml
# 分部命令不经过 pre-packages hook, 只在「库不新于系统」时安全, 先跑 setup-all 最稳;
# 别用 `packages upgrade` / `apply --update`（partial upgrade，见上文「日常」）
```

## 任务

`mise run <task>`；`mise tasks` 是权威列表（`setup-all` 会调其中除 `setup-boot`
和 `uninstall-help` 外的全部）。

| 任务                  | 作用                                                           | 权限 |
| --------------------- | -------------------------------------------------------------- | ---- |
| `setup-all`           | 聚合入口：收敛 + 全量升级                                      | sudo |
| `setup-boot`          | systemd-boot / sdboot-manage（守卫，**手动**，不入 setup-all） | sudo |
| `setup-desktop`       | dconf + XDG 用户目录                                           | 用户 |
| `setup-rust`          | rustup + rust-analyzer                                         | 用户 |
| `setup-fonts`         | Maple Mono 字体                                                | 用户 |
| `setup-flatpak`       | flathub + Flatpak 应用                                         | 用户 |
| `setup-moonbit`       | MoonBit 工具链                                                 | 用户 |
| `setup-yazi`          | yazi 插件/配色（安装+更新）                                    | 用户 |
| `setup-just-talk`     | 二进制 → ~/.local/bin                                          | 用户 |
| `setup-pi`            | Pi agent + 扩展                                                | 用户 |
| `setup-rime-wanxiang` | 万象拼音 → fcitx5                                              | 用户 |
| `uninstall-help`      | 卸载命令（仅文档，不删任何东西）                               | —    |

> bat 缓存由 `conf.d/hooks.toml` 的 post-dotfiles 钩子重建，不在任何 setup-* 里。

## 新机器

```bash
sudo pacman -Syu git mise ansible   # -Syu: 先同步库+全量升级, 再装引导工具
                                     # (裸 -S 用 ISO 上的陈旧库, 可能 404 或留下 partial upgrade)
git clone <repo> ~/.config/mise
cd ~/.config/mise
mise trust
mise bootstrap --yes                 # 内含 -Syu (hook), 之后 -S 装缺包安全
```

## 远程 VPS（xray，非 mise）

```bash
cd ~/.config/mise/xray
python3 scripts/gen-keys.py <VPS_IP>        # 写 host_vars/<IP>.yml（gitignore 保护）
ansible-playbook deploy-xray.yml --limit <VPS_IP>
```

## 笔记本电池续航保护

> 不同厂商/型号的电池养护接口各异，无法统一命令。以下为本机（联想 81YN）的 udev 方案作为参考：

```bash
# /etc/udev/rules.d/99-battery-charge-limit.rules
ACTION=="add", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{charge_types}="Long_Life"
```

```bash
# 当前值查看
cat /sys/class/power_supply/BAT1/charge_types
# Fast / Standard / Long_Life   ← Long_Life 约 60% 上限
```
