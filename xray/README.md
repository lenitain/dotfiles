# Xray(服务端)+ sing-box(客户端)— VLESS + REALITY + Vision

把代理链路:
- **服务端**:VPS 上运行 **Xray**(`v26.7.28`),入站 `VLESS + REALITY + Vision`
- **客户端**:本机 **sing-box**,本地 SOCKS5/HTTP 代理,手动开关控制国内外

```
浏览器/应用 ──> sing-box(127.0.0.1:1080/1081)
                  └── VLESS+REALITY+Vision ──> Xray(VPS:8443)
```

## 目录结构

```
chezmoi/ansible/xray-setup/        ← 本目录(chezmoi 管理)
├── README.md
├── ansible.cfg
├── inventory.yml                  # 变量①:IP
├── deploy-xray.yml                # 部署入口
├── host_vars/
│   └── _template.yml              # 手动方式:复制后填密钥
├── scripts/
│   └── gen-keys.py                # 推荐:一键生成密钥并写入 host_vars/<IP>.yml
└── roles/xray/                    # 可复用 role
    ├── defaults/main.yml
    ├── tasks/main.yml             # 幂等;密钥首次自动持久化到 VPS
    ├── handlers/main.yml
    └── templates/
        ├── xray-config.json.j2
        └── xray.service.j2
```

## 已生成的连接参数(当前部署)

| 参数 | 值 |
|---|---|
| server | 198.44.58.138 |
| port | 8443 |
| protocol | VLESS |
| flow | xtls-rprx-vision |
| uuid / 密钥 / short_id | 见 `scripts/gen-keys.py` 生成的 `host_vars/<IP>.yml`(首次部署后持久化在 VPS `/etc/xray/reality_keys.yml`) |
| server_name (SNI) = dest | `www.cloudflare.com` |
| fingerprint | chrome |

---

## 一、自动化部署:两个变量 + 一条命令

> **自动化逻辑:只要填好「IP」和「密钥」两个变量,跑一条命令,Ansible 会自动完成
> 「密钥分发(写入 VPS 的 /etc/xray/reality_keys.yml)+ 部署 xray + 开 BBR + 放行防火墙」。**
> 不需要手动 SSH 推送密钥;也不需要每次重跑都填(首次持久化后,之后复用)。

### 变量①:IP

在 `inventory.yml` 里登记主机(host_vars 文件名也用这个 IP):

```yaml
all:
  hosts:
    198.44.58.138:
      ansible_user: root
      ansible_ssh_private_key_file: /home/lenitain/.ssh/id_ed25519
```

### 变量②:密钥

在 `host_vars/<IP>.yml` 里填。两种方式任选:
- **推荐**:`python3 scripts/gen-keys.py <IP>` 一键生成;
- 或手动复制 `host_vars/_template.yml` 后填入:

```yaml
xray_port: 8443
xray_dest: "www.cloudflare.com:443"
xray_server_names:
  - "www.cloudflare.com"

xray_uuid: "<uuid>"
xray_private_key: "<private_key>"   # 标准 base64;角色自动转 URL-safe
xray_public_key: "<public_key>"
xray_short_id: "<short_id>"
```

生成密钥(推荐用脚本,无需 xray):

```bash
cd ~/.local/share/chezmoi/ansible/xray-setup
python3 scripts/gen-keys.py
```

脚本会直接输出「填进 host_vars」和「填进 sing-box 客户端」两组值,照着贴即可。
(或传统方式:`xray x25519` + `xray uuid` + `openssl rand -hex 4`)

### 一条命令自动执行

```bash
cd ~/.local/share/chezmoi/ansible/xray-setup
ansible-playbook deploy-xray.yml
```

脚本做的事(全部幂等):
1. 安装 xray `v26.7.28`;
2. **密钥分发**:VPS 上还没有 `/etc/xray/reality_keys.yml` → 把 host_vars 里的密钥(或自动生成的)持久化上去;已有 → 直接复用,绝不轮换;
3. 写入 `/etc/xray/config.json`(VLESS+REALITY+Vision,端口 8443,dest=cloudflare,`minClientVer: "0.0.0"`);
4. 启动 systemd 服务并设开机自启;
5. 开启 BBR;
6. 检测 ufw/firewalld,放行端口;
7. 打印客户端参数(public_key 为 URL-safe 无填充,可直接用)。

验证:

```bash
ssh root@198.44.58.138 'systemctl status xray --no-pager | head -3; ss -lntp | grep 8443'
```

---

## 二、配置客户端(sing-box)

配置分两个文件:
- `chezmoi/dot_config/sing-box/_template.json` = **空凭据模板**,入仓库但不安装(`_` 前缀);
- `~/.config/sing-box/config.json`(手动维护,不入库)= **真实配置**,由 `gen-keys.py` 输出的值填写。

### 方式 A(推荐):用户级 systemd 服务

服务单元文件由 chezmoi 管理(`dot_config/systemd/user/sing-box.service` → `~/.config/systemd/user/`),内容固定,不需要手工创建。

**首次启用(允许 linger + 启用开机自启 + 立即启动):**

```bash
# ① 允许 linger:不登录也开机自启(一次性,已启用会静默跳过)
loginctl enable-linger "$USER"

# ② 启用开机自启 + 立即启动
systemctl --user enable --now sing-box
```

**日常管理:**

| 操作 | 命令 |
|---|---|
| 查看状态 | `systemctl --user status sing-box` |
| 实时日志 | `journalctl --user -u sing-box -f` |
| 热重载配置(改完 config.json) | `systemctl --user reload sing-box` |
| 重启 | `systemctl --user restart sing-box` |
| 停止(应急全直连) | `systemctl --user stop sing-box` |
| 取消开机自启 | `systemctl --user disable sing-box` |

**验证代理连通:**

```bash
curl --socks5-hostname 127.0.0.1:1080 https://www.google.com -I
```

> 前提:`~/.config/sing-box/config.json` 已生成(凭据来自 `gen-keys.py` 输出,不入库);缺失时服务会启动失败。

### 方式 B(备选):前台手动运行

```bash
sing-box run -D ~/.local/share/sing-box -c ~/.config/sing-box/config.json
```

- **SOCKS5 `127.0.0.1:1080`、HTTP `127.0.0.1:1081`**
- 行为:开启时**所有流量走代理**;关闭即全直连(手动开关模式)
- 停止:`Ctrl+C`;改配置后重跑(或 `kill -HUP` 热重载)

> 每新增一个 VPS,客户端要**手动填一次**该 VPS 的 `public_key`(URL-safe 无填充)+ `uuid` + `short_id`(这是唯一手动步骤,因为客户端是另一台机器,无法由服务端脚本代填)。
---

## 三、多 VPS 复用(每台 = 填变量 → 一条命令)

```bash
# ① 生成 host_vars/<新VPSIP>.yml —— 二选一:
#    推荐:python3 scripts/gen-keys.py <新VPSIP>(含全新密钥)
#    手动:cp host_vars/_template.yml host_vars/<新VPSIP>.yml 再填密钥
# ② 编辑 inventory.yml 加入新主机
# ③ (可选)改 host_vars 里的端口/dest
# ④ 一条命令自动部署(自动完成密钥分发到该 VPS + 部署):
ansible-playbook deploy-xray.yml --limit <新VPSIP>
# ⑤ 客户端填入该 VPS 的 public_key/uuid/short_id 后即可用
```

> 跑完后可删除 host_vars 里的密钥字段(角色已持久化到该 VPS),重跑不受影响。

---

## 四、故障排查

| 现象 | 排查 |
|---|---|
| 客户端报 `reality verification failed` | 密钥/SNI/short_id 有一处不一致,或 xray ≥26.3.27 默认最低客户端版本门槛拒绝 sing-box(本角色已设 `minClientVer: "0.0.0"`) |
| 服务端报 `handshake did not complete successfully` | **dest 别用 `www.microsoft.com`**——其超大 TLS Certificate 记录会让 REALITY 握手卡死;用 `www.cloudflare.com` / `www.apple.com`(本角色默认已是 cloudflare) |
| xray 启动报 `invalid "privateKey"` | REALITY 密钥需 URL-safe 无填充 base64(本角色已自动转换) |
| xray 启动报 `geoip.dat: no such file` | 部署时需把 zip 里的 `geoip.dat`/`geosite.dat` 一并解压(本角色已处理) |
| 客户端连不上但服务端正常 | 检查端口防火墙/安全组;`nc -vz <IP> <port>` |

## 五、安全注意

- 私钥会在 host_vars 里**短暂出现**(用于自动化分发);角色首次部署后已持久化到 VPS,建议随后**删除 host_vars 里的密钥字段**;
- 若担心私钥进 chezmoi 仓库:可用 chezmoi 的 age 加密(`chezmoi add --encrypt`)处理 host_vars;
- 客户端持有 `public_key` + `uuid` + `short_id`,uuid 是连接凭据,泄露 = 节点被免费使用;
- 每台 VPS 用各自密钥对,不要跨机复用;换 VPS 建议重新生成。

## 附录:一键生成密钥(推荐)

```bash
cd ~/.local/share/chezmoi/ansible/xray-setup
python3 scripts/gen-keys.py
```

无参数,直接输出两个去向(照着填即可):
- **【1】host_vars/<IP>.yml**:`xray_uuid` / `xray_private_key` / `xray_public_key` / `xray_short_id`;
- **【2】~/.config/sing-box/config.json**:`"uuid"` / `"public_key"`(URL-safe 无填充)/ `"short_id"`(手动填,不入库;启动用 `-c` 指定)。

行为:
- `host_vars/<IP>.yml` **已存在时拒绝生成**(exit=1,不覆盖),防止误轮换密钥;
- 生成后打印客户端需手动复制的 `uuid` / `public_key` / `short_id`;
- 每台 VPS 用各自一套密钥,不要跨机共用。

依赖 `cryptography`:`python3 -m pip install cryptography`。
