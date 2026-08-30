# dotfiles(mise)

Arch + niri 工作站的声明式配置。mise 管工具版本与系统收敛，`dotfiles/` 是家目录的源树，
`tasks/` 是一次性同步任务，`xray/` 管远程 VPS。

## 结构

```
~/.config/mise/
├── config.toml           # 根配置：[settings]
├── conf.d/               # 按字母序合并进 config.toml
│   ├── tools.toml        #   [tools]               版本化工具
│   ├── dotfiles.toml     #   [dotfiles]            家目录文件清单
│   ├── packages.toml     #   [bootstrap.packages]  pacman / flatpak 包
│   ├── system.toml       #   [bootstrap.*]         文件/目录/服务/账号/登录 shell
│   ├── mirrors.toml      #   [env] + [settings]    下载镜像
│   └── hooks.toml        #   [bootstrap.hooks]     声明式段覆盖不到的命令
├── dotfiles/             # 家目录源树（相对 HOME），symlink 部署
├── tasks/                # 一次性同步任务（lib/ 是共用库）
├── xray/                 # 远程 VPS 的 xray 部署（ansible）
└── README.md
```

每个文件管什么写在它自己的注释里，改之前先看那一份。

## 日常

```bash
mise run setup-all     # 唯一入口：收敛 + 全量升级 + 各同步任务
mise bootstrap         # 只做声明式收敛（需要 sudo）
mise tasks             # 任务列表
mise ls                # 已装工具
```

`setup-all` 依次跑：`mise bootstrap` → `mise install` + `mise upgrade` → `setup-tuning` →
`setup-desktop` → `setup-pig` → `setup-fonts` → `setup-rime-wanxiang` → `setup-yazi`。
更新类步骤软失败：挂了只 warn，不中断后面的收敛。

升级只在 `setup-all` 里做：它先 `sudo pacman -Syu --noconfirm` 再装声明里的包
（`pre-packages` hook，见 `conf.d/hooks.toml`）。mise 装包只发 `pacman -S --needed`，
不刷新同步库，库比系统新时那是 Arch 不支持的 partial upgrade。不要用
`mise bootstrap packages upgrade` / `apply --update`；`packages apply` / `use` 不经过 hook，
只在同步库不新于系统时安全。

## 改配置

| 要改什么                          | 改哪儿                 | 命令                                                                           |
| --------------------------------- | ---------------------- | ------------------------------------------------------------------------------ |
| 家目录里的配置                    | `dotfiles/` 源树       | `mise bootstrap dotfiles apply`                                                |
| 纳管一个新的文件                  | —                      | `mise bootstrap dotfiles add ~/.config/xxx`                                    |
| 工具版本                          | `conf.d/tools.toml`    | `mise use -g <tool>@<version>`、`mise install`、`mise upgrade`                 |
| 系统包                            | `conf.d/packages.toml` | `mise bootstrap packages use -g pacman:foo@version`                            |
| /etc 文件、服务、账号、登录 shell | `conf.d/system.toml`   | `mise bootstrap files apply`、`services apply`、`accounts apply`、`user apply` |

- dotfiles 是 symlink 模式：改源即生效；本机改过的内容用 `add` 回存到源。
- `mise use -g`、`packages use` 把新条目写进全局 `config.toml`，要保持分层就直接编辑
  `conf.d/tools.toml`、`conf.d/packages.toml`。
- `~/.pig` 只按文件纳管：配置文件列进 `conf.d/dotfiles.toml`，运行时产物留在实机。新增一个要两步：
  `mise bootstrap dotfiles add ~/.pig/agent/<文件>` + 根 `.gitignore` 补 `!dotfiles/.pig/agent/<文件>`。
- systemd user 单元（`qb-server.service`、`sing-box.service`）不声明在
  `[bootstrap.linux.systemd.units]`，随 `~/.config/systemd/user` 由 dotfiles 收敛。

## 任务

`mise run <task>`，`mise tasks` 是权威列表。

| 任务                  | 作用                                                         | 权限 |
| --------------------- | ------------------------------------------------------------ | ---- |
| `setup-all`           | 聚合入口                                                     | sudo |
| `setup-tuning`        | 桌面性能调优（BBR / Wi-Fi 省电 / 电源档位），立即应用 + 体检 | sudo  |
| `setup-boot`          | systemd-boot / sdboot-manage；带守卫，手动跑，不入 setup-all | sudo |
| `setup-desktop`       | dconf 桌面设置 + XDG 用户目录                                | 用户 |
| `setup-fonts`         | Maple Mono 字体                                              | 用户 |
| `setup-pig`           | PiG agent + 扩展                                             | 用户 |
| `setup-rime-wanxiang` | 万象拼音 → fcitx5                                            | 用户 |
| `setup-yazi`          | yazi 插件（simple-status / smart-enter）                     | 用户 |
| `uninstall-help`      | 各生态卸载命令清单（只打印，不删）                           | —    |

`setup-boot` 只新建 / 收敛，不卸载现有引导器；检测到 Limine / GRUB / UKI 接管内核安装会中止
并提示先 `pacman -Rns`。

## 按需

体检（只读，不改任何东西）：

```bash
mise bootstrap --dry-run    # 打印将执行的改动
mise bootstrap status        # 逐资源一行：资源 / 当前值 / 期望值
mise bootstrap plan          # 并排「当前 vs 期望」
```

新机器：

```bash
sudo pacman -Syu git mise ansible
git clone <repo> ~/.config/mise && cd ~/.config/mise
mise trust
mise bootstrap --yes
```

提交前扫密钥（`.pre-commit-config.yaml` 里只有 gitleaks；没装 git 钩子，所以手动跑）：

```bash
prek run --all-files
```

远程 VPS（xray，不走 mise，详见 `xray/README.md`）：

```bash
cd xray
python3 scripts/gen-keys.py <IP>
ansible-playbook deploy-xray.yml --limit <IP>
```

## 不入库的东西

| 路径                                              | 原因                                             |
| ------------------------------------------------- | ------------------------------------------------ |
| `dotfiles/.pig/**`                                | 运行时产物；只放行 `agent/` 下显式声明的配置文件 |
| `dotfiles/.config/bash/conf.d/*KEY.sh`            | 密钥；不随 dotfiles 同步，需单独备份             |
| `dotfiles/.config/go/env`                        | `go env -w` 写的运行时文件；镜像由 mise `[env]` 注入 |
| `dotfiles/.config/niri/output.kdl`                | 显示配置与硬件相关                               |
| `dotfiles/.config/jj/repos`、`workspaces`         | 每个仓库的本地状态                               |
| `dotfiles/.config/nvim/lazy-lock.json`            | 插件锁文件                                       |
| `dotfiles/.config/qutebrowser/bookmarks/`、`quickmarks` | 浏览器自己读写的书签与快标                 |
| `dotfiles/.config/yazi/plugins/*`、`package.toml` | 由 `setup-yazi` 生成                             |
| `dotfiles/.local/bin/scripts/qb-open`             | 编译产物                                         |
| `dotfiles/.local/share/wallpapers/*.svg`、`*.png` | 壁纸生成产物（脚本入库）                         |
| `xray/host_vars/*.yml`                            | 私钥（`_template.yml` 除外）                     |
| `xray/inventory.yml`                              | 真实 VPS 地址（模板是 `inventory.template.yml`） |
| `.ruff_cache/`                                    | ruff 缓存                                        |

## 附录

### 桌面性能调优

场景是编程 / 等编译 / 等下载。三件事由 `conf.d/system.toml` 声明，bootstrap 收敛到新机器：

| 内容              | 落点                                                       | 作用                                   |
| ----------------- | ---------------------------------------------------------- | -------------------------------------- |
| TCP 拥塞控制 BBR  | `/etc/sysctl.d/99-net-tuning.conf`（+ `net.core.default_qdisc=fq`） | Wi-Fi / 高 RTT 链路吞吐优于 cubic |
| 关 Wi-Fi 省电     | `/usr/local/bin/wifi-powersave-off` + `.service` + udev 规则 | rtw88 等省电下掉吞吐、加延迟           |
| 电源档位随供电走  | `/usr/local/bin/power-profile` + `.service` + udev 规则      | 插电 performance / 电池 balanced       |

立即生效 + 体检：

```bash
mise run setup-tuning
```

供电状态一变，udev 触发 `power-profile` 重判档位（插电 performance / 拔电 balanced）；
无线网卡热插拔后 udev 重关一次省电。

两个已知限制：

- 本机 `power-profiles-daemon` 只驱动 firmware 的 `platform_profile`，不碰 cpufreq
  governor，所以 governor 由 `power-profile` 脚本直接写（`cpupower frequency-set`）。
- 内核参数 `amd_pstate=active` 能让 amd-pstate 接管频率（比 `performance` governor 更细），
  但要改引导配置并重编 initramfs，`setup-tuning` 不碰 `/boot`。

### 电池充电上限

本机（联想 81YN）用 udev：不同厂商接口各异，规则按机型写。

`/etc/udev/rules.d/99-battery-charge-limit.rules`

```
ACTION=="add", SUBSYSTEM=="power_supply", ATTR{type}=="Battery", ATTR{charge_types}="Long_Life"
```

当前值：`cat /sys/class/power_supply/BAT1/charge_types` —— `Fast` / `Standard` / `Long_Life`，
`Long_Life` 约 60% 上限。

### niri 显示布局

`~/.config/niri/output.kdl` 与硬件绑定，不入库（根 `.gitignore`）。`config.kdl` 用
`include optional=true "output.kdl"` 引入它，换机器缺这个文件也不报错。

布局改这个文件：`position` 用逻辑像素（按各屏 scale 缩放后算），主屏要显式固定在原点，
否则 niri 会把它挪到外屏右边。约束是 cursor 只能在**直接相邻**的输出之间移动 —— 外屏得贴住
主屏边缘才跳得过去，本机的具体数值写在文件注释里。

### 壁纸

`dotfiles/.local/share/wallpapers/`：`build_all.py` 生成 SVG，`derive.sh` 用 resvg + oxipng 导出
3840×2160 PNG（产物都不入库）。

```bash
cd ~/.local/share/wallpapers && python3 build_all.py && ./derive.sh
```

### qb-open

qutebrowser 的毫秒级启动器：往常驻 qb-server 的 IPC socket 写 JSON，不起 Python/Qt；
server 没跑就回退冷启动。

```bash
cd ~/.local/bin/scripts && make c-static   # 或 make c-dynamic
```

## 相关文档

- **bash 配置**：`dotfiles/.config/bash/README.md`
- **xray（VPS）**：`xray/README.md`
- **PiG 配置**：`dotfiles/.pig/agent/`
- **技能**：`dotfiles/.agents/skills/`（caveman、planning-tasks、wrfm）
- **代理开关**：`dotfiles/.local/bin/scripts/proxy-on` / `proxy-off`
