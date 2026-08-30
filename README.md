# dotfiles(mise)

## 目录

```
~/.config/mise/
├── config.toml        # [settings]
├── conf.d/            # 片段（字母序自动合并）
│   ├── tools.toml     #   [tools]
│   ├── dotfiles.toml  #   [dotfiles]
│   ├── packages.toml  #   [bootstrap.packages]
│   ├── system.toml    #   [bootstrap.*]
│   ├── env.toml       #   [env]
│   └── hooks.toml     #   [bootstrap.hooks]
├── dotfiles/          # dotfile 源树（home 相对）
├── templates/         # 不直接部署的模板
├── xray/              # 远程 VPS 供给（ansible）
└── tasks/             # 任务
```

## 日常（唯一入口）

```bash
mise bootstrap --yes            # 声明式收敛 + 全量升级（pacman -Syu + mise upgrade）
mise bootstrap --dry-run        # 模拟 apply，打印将执行的变更，不改任何东西
mise tasks                      # 列任务
mise ls                         # 已装工具
```

## 体检（只读）

```bash
mise bootstrap status                    # 逐资源一行：资源 / 当前值 / 期望值 / 来源配置
mise bootstrap status --missing          # 同上；只要有资源未达期望态就 exit 1（脚本/CI 用）
mise bootstrap plan                      # 逐资源并排「当前 vs 期望」，即 apply 会改成的样子
mise bootstrap plan --detailed-exitcode  # 0=无变更 2=有变更 1=计划失败或有资源 unknown
mise bootstrap --dry-run                 # 全量模拟 apply，打印将执行的动作
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
mise bootstrap linux systemd-units status   # systemd 用户单元
```

## 改配置

```bash
# dotfiles（copy；改源→部署 / 改已部署→回存）
mise bootstrap dotfiles apply
mise bootstrap dotfiles add ~/.config/xxx
mise bootstrap dotfiles edit ~/.config/xxx

# 系统配置 /etc：改 conf.d/system.toml 的 content
mise bootstrap files apply          # 有变化才 sudo

# 工具
mise use -g <tool>@<version>
mise install / mise upgrade / mise ls

# 系统包
mise bootstrap packages use pacman:foo@version   # 或编辑 conf.d/packages.toml
```

## 任务

`mise run <task>`；`mise tasks` 列全部。`bootstrap` 是聚合入口。

| 任务                 | 作用                                           | 权限 |
| -------------------- | ---------------------------------------------- | ---- |
| `bootstrap`          | 全量 sync+升级                                 | sudo |
| `setup-boot`         | systemd-boot / sdboot-manage（守卫，**手动**） | sudo |
| `setup-desktop`      | dconf + XDG 用户目录                           | 用户 |
| `setup-rust`         | rustup + rust-analyzer                         | 用户 |
| `setup-dict`         | ECDICT 词典                                    | 用户 |
| `setup-fonts`        | Maple Mono 字体                                | 用户 |
| `setup-flatpak`      | flathub + Flatpak 应用                         | 用户 |
| `setup-moonbit`      | MoonBit 工具链                                 | 用户 |
| `setup-yazi`         | yazi 插件/配色                                 | 用户 |
| `setup-just-talk`    | 构建到 ~/.local/bin                            | 用户 |
| `setup-wl-screenrec` | 同上                                           | 用户 |

| `setup-pi`           | Pi agent + 扩展                                | 用户 |
| `uninstall-help`     | 卸载命令（文档）                               | —    |

> `conf.d/hooks.toml` post-dotfiles 钩子自动重建 bat 缓存。

## 新机器

```bash
sudo pacman -S git mise ansible
git clone <repo> ~/.config/mise
cd ~/.config/mise
mise trust
mise bootstrap --yes
```

## 远程 VPS（xray，非 mise）

```bash
cd ~/.config/mise/xray
python3 scripts/gen-keys.py <VPS_IP>        # 写 host_vars/<IP>.yml（gitignore 保护）
ansible-playbook deploy-xray.yml --limit <VPS_IP>
```

客户端 sing-box 用户服务随 dotfiles 管理；`~/.config/sing-box/config.json` 用 gen-keys 输出手填。

## 笔记本电池续航保护

> 不同厂商/型号的电池养护接口各异，无法统一命令。以下为本机（联想 81YN）的 udev 方案作为参考：

```bash
# /etc/udev/rules.d/99-battery-charge-limit.rules
ACTION=="add", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{charge_types}="Long_Life"
```

```bash
# 当前值查看
cat /sys/class/power_supply/BAT1/charge_types
# Fast / Standard / Long_Life（约 60% 上限）
```
