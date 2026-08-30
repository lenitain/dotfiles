# scripts

`~/.local/bin/scripts` 里的可执行脚本，都在 PATH 上。

## run-vm

用 QEMU + KVM 启动虚拟机。以磁盘（`.qcow2`）为中心：磁盘是持久状态，ISO 只是首次
安装用的引导介质。虚拟机文件都放在当前目录。

```bash
cd ~/vms
run-vm --install --iso ~/Downloads/fedora.iso --new fedora44   # 首次安装
run-vm fedora44.qcow2                                          # 之后启动
run-vm                                                         # 交互选择磁盘
```

| 选项                | 说明                                                                          |
| ------------------- | ----------------------------------------------------------------------------- |
| `--install`         | 安装模式：挂载 ISO 并从光驱引导                                               |
| `--iso FILE`        | 指定 ISO，任意路径；不给则按同名自动找（磁盘旁边 → 当前目录 → `~/Downloads`） |
| `--new NAME`        | 新建 `NAME.qcow2` 并进入安装模式                                              |
| `--bios`            | 用 SeaBIOS 启动 —— 唯一支持「硬盘优先、光驱兜底」的模式                       |
| `--disk-size SIZE`  | 新建磁盘大小，默认 `32G`                                                      |
| `--mem SIZE`        | 内存，默认 `8G`                                                               |
| `--cpus N`          | 核心数，默认 `6`                                                              |
| `--res WxH`         | 分辨率，默认取已连接显示器的最大模式                                          |
| `--gpu virtio\|vga` | `virtio`（默认，分辨率跟窗口）或 `vga`（固定 `--res`，无 3D）                 |
| `--display BACKEND` | 显示后端，默认 `gtk`；还有 `sdl`、`vnc`、`dbus`、`none`                       |
| `--gl`              | OpenGL（virgl）：`virtio-vga-gl` + `-display ...,gl=on`                       |
| `--fullscreen`      | 全屏                                                                          |
| `--no-reboot`       | guest 重启时退出 QEMU（默认允许正常重启）                                     |
| `--dry-run`         | 只打印将要执行的 qemu 命令                                                    |

位置参数给 `.qcow2` 是启动这台虚拟机，给 `.iso` 是装系统（磁盘固定落在当前目录）。

### 文件怎么摆

```
当前目录（或你指定的磁盘所在目录）
├── fedora44.qcow2          ← 虚拟磁盘：系统与数据
└── fedora44.OVMF_VARS.fd   ← 固件变量：Boot#### 引导项，必须和磁盘作伴

ISO 随便放：~/Downloads/xxx.iso、/media/usb/xxx.iso …
```

磁盘和 `.OVMF_VARS.fd` 永远同目录同基名；ISO 不受这个约束。不传参数时在当前目录
里选磁盘，固件变量文件就在它旁边。

### 分辨率

virtio-vga 的 EDID 只上报一条首选模式（设备属性 `xres`/`yres`），但 gtk/sdl 会把**窗口的
逻辑尺寸**通过 ui_info 写回 EDID：窗口多大，guest 就多大。在 1.5 倍缩放的显示器上，窗口
逻辑尺寸是物理的 1/1.5，guest 只能拿到 1707x960 再被放大 —— 看着就是“低分辨率”。

- 要 guest 真跑满显示器：`--gpu vga`。std-VGA 没有 ui_info，`--res` 说了算（默认取已连接
  显示器的最大模式）；代价是没有 3D 加速。
- 默认的 virtio + gtk：分辨率跟着窗口，配合 `--gl` 有 virgl 3D。
- `--display none` / `vnc` 这类无窗口后端不受窗口干扰，`--res` 直接生效。

### UEFI 下的两个坑（实测）

- **只要挂载光驱，固件就优先引导光驱**，`-boot order=c` 改不动（`set_boot_dev()` 只写
  CMOS，那是 SeaBIOS 的机制；UEFI 走 fw_cfg 的 `bootorder`，而 virtio 盘默认不在里面）。
  所以正常启动不挂 ISO；需要「硬盘优先、光驱兜底」只能用 `--bios`。
- **硬盘要靠 OVMF 变量里的 `Boot####` 项才能被引导**，ESP 里的
  `\EFI\BOOT\BOOTX64.EFI` 兜底路径只对可移动介质生效，对硬盘不生效。所以
  `<磁盘名>.OVMF_VARS.fd` 必须和磁盘放在一起保留，丢了引导项就引导不了硬盘。

### 注意

- 装完在 guest 里执行 `poweroff`，**别用 `reboot`** —— UEFI 下重启会再被光驱抢走引导权。
- `.OVMF_VARS.fd` 不能删：系统还在盘里，但固件不知道从哪启动。
- 别让两台虚拟机共用同一个 `.OVMF_VARS.fd`：磁盘有文件锁会挡住你，固件变量文件没有，
  两个 VM 会互相覆盖引导项。
- Ctrl+C、`kill`（SIGTERM）都会让 QEMU 优雅关闭并刷盘，只有 `kill -9` 是硬杀。

## 其它脚本

| 脚本                     | 用途                                                                     |
| ------------------------ | ------------------------------------------------------------------------ |
| `qb-open`                | qutebrowser 毫秒级启动器（`qb-open.c` + Makefile，`make c-static` 构建） |
| `qb-server`              | qutebrowser 常驻实例                                                     |
| `proxy-on` / `proxy-off` | 开关本地代理（sing-box + qutebrowser 的 content.proxy）                  |
| `xdg-terminal-exec`      | 终端兜底：默认用 foot，可用 `$TERMINAL` 覆盖                             |
