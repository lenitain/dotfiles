# Xray 服务端部署 — VLESS + REALITY + Vision

本目录**只管服务端**。客户端（Clash Verge）配置不在仓库里存，由服务端信息动态生成（见下文）。

## 部署：三条命令

```bash
cd ~/.config/mise/xray
python3 scripts/gen-keys.py <IP>        # 生成密钥 → host_vars/<IP>.yml（已 gitignore）
ansible-playbook deploy-xray.yml --limit <IP>   # inventory.yml 里先登记 <IP>
```

幂等，随时重跑。自动完成：装 xray → 写配置 → systemd 开机自启 → 开 BBR → 放行防火墙 → 打印连接参数。

**密钥只生成一次**：首次部署后持久化在 VPS `/etc/xray/reality_keys.yml`，重跑绝不轮换；host_vars 里的密钥字段随后可删。

## 服务端信息（客户端配置的唯一来源）

```bash
ssh root@<IP> cat /etc/xray/reality_keys.yml   # uuid / public_key / short_id（+ private_key，别外传）
ssh root@<IP> cat /etc/xray/config.json        # 端口 / dest / serverNames / flow —— 以它为准
```

注意：`config.json` 才是实际生效值（host_vars、defaults 里的端口可能已过时）。

## 生成 Clash Verge 客户端配置

拿到上面的值后拼 mihomo proxy 片段：

```yaml
- name: vps-<IP>
  type: vless
  server: <IP>
  port: <config.json 的端口>
  uuid: <reality_keys.yml 的 xray_uuid>
  network: tcp
  tls: true
  udp: true
  flow: xtls-rprx-vision                 # config.json 的 flow
  servername: <config.json serverNames[0]>
  client-fingerprint: chrome             # 服务端不校验，保持 chrome 即可
  reality-opts:
    public-key: <xray_public_key 转 URL-safe 无填充>
    short-id: <xray_short_id>
```

**唯一坑**：public_key 必须是 URL-safe base64 **无填充**（`+`→`-`、`/`→`_`、去掉 `=`）；其余值原样粘贴。

## 故障排查

| 现象 | 处理 |
| --- | --- |
| 连接报 `reality verification failed` | uuid/SNI/short_id 三处对不上（逐字比对两边）；或 xray ≥26.3.27 版本门槛（本角色已设 `minClientVer: "0.0.0"`） |
| `handshake did not complete successfully` | dest 别用 `www.microsoft.com`（TLS 证书记录超大会卡死握手），默认 `www.cloudflare.com` |
| xray 启动报 `invalid "privateKey"` | 密钥必须 URL-safe 无填充（角色已自动转换） |
| 外部连不上 | 查防火墙/安全组，`nc -vz <IP> <port>` |

## 安全

- 私钥部署后从 host_vars 删除；VPS 上 0600 存放，客户端永远不需要它
- uuid 泄露 = 节点被免费使用；每台 VPS 独立密钥，不跨机复用
