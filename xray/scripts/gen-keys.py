#!/usr/bin/env python3
"""
gen-keys.py — 为指定 IP 的 VPS 生成一套 REALITY 密钥,并直接写入 host_vars/<IP>.yml。

用法:
    python3 scripts/gen-keys.py <新VPSIP>

示例:
    python3 scripts/gen-keys.py 203.0.113.10
      → 生成 host_vars/203.0.113.10.yml(含全新密钥 + 端口/dest 默认值)
      → 打印客户端需要手动复制的三个值

说明:
    - 每台 VPS 用各自独立的一套密钥,不要跨机共用;
    - 文件已存在时拒绝覆盖(防止误轮换密钥);
    - 客户端三个值需手动复制进 ~/.config/sing-box/config.json。
"""
import base64
import ipaddress
import secrets
import sys
import uuid
from pathlib import Path

try:
    from cryptography.hazmat.primitives import serialization
    from cryptography.hazmat.primitives.asymmetric.x25519 import X25519PrivateKey
except ImportError:
    sys.exit("缺少依赖 cryptography。安装: python3 -m pip install cryptography")


def main():
    if len(sys.argv) != 2:
        print(__doc__)
        sys.exit(1)
    ip = sys.argv[1]
    try:
        ipaddress.ip_address(ip)
    except ValueError:
        sys.exit(f"ERROR: 不是合法 IP 地址: {ip}")

    priv = X25519PrivateKey.generate()
    priv_bytes = priv.private_bytes(
        serialization.Encoding.Raw, serialization.PrivateFormat.Raw, serialization.NoEncryption()
    )
    pub_bytes = priv.public_key().public_bytes(
        serialization.Encoding.Raw, serialization.PublicFormat.Raw
    )
    uuid_v = str(uuid.uuid4())
    priv_b64 = base64.b64encode(priv_bytes).decode()
    pub_b64 = base64.b64encode(pub_bytes).decode()
    pub_urlsafe = base64.urlsafe_b64encode(pub_bytes).rstrip(b"=").decode()
    short_id = secrets.token_hex(4)

    repo_root = Path(__file__).resolve().parent.parent
    dest = repo_root / "host_vars" / f"{ip}.yml"
    if dest.exists():
        sys.exit(f"ERROR: {dest} 已存在,拒绝覆盖(如需更换密钥请先手动删除该文件)")

    content = f"""---
# 新 VPS {ip}:自动生成(密钥已就位)
xray_port: 8443
xray_dest: "www.cloudflare.com:443"
xray_server_names:
  - "www.cloudflare.com"

# ---- 密钥(每台 VPS 用各自的一套,不要共用) ----
xray_uuid: "{uuid_v}"
xray_private_key: "{priv_b64}"
xray_public_key: "{pub_b64}"
xray_short_id: "{short_id}"
"""
    dest.write_text(content)

    print(f"✅ 已生成 {dest}\n")
    print("客户端手动复制到 ~/.config/sing-box/config.json:")
    print(f'  "uuid": "{uuid_v}",')
    print(f'  "public_key": "{pub_urlsafe}",')
    print(f'  "short_id": "{short_id}"')
    print()
    print("下一步: 在 inventory.yml 加入主机后运行:")
    print(f"  ansible-playbook deploy-xray.yml --limit {ip}")


if __name__ == "__main__":
    main()
