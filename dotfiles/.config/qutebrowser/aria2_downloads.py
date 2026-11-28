"""把下载交给 aria2c。

patch 的是 qutebrowser.browser.downloads 里的两个通用方法，webengine 的
DownloadManager 不改：

  - 这个模块在 app.py 顶层就被 import，不会随 config.py 执行结束被清理。
    config/configfiles.py#L1014 的 saved_sys_properties() 会删掉本次新增的
    sys.modules 条目，所以在 config.py 里首次 import webenginedownloads 再 patch
    类属性是无效的：那个模块实例随后就被丢弃，真正使用的是重新 import 的那份。
  - QtNetwork 和 QtWebEngine 两个后端都经过这两个方法。

分工：
  _init_item  决定这次下载要不要交出去。要交就起 userscript 进程、给 item 打标记、
              不调原方法——item 不入模型，下载条不会出现条目。
  set_target  紧接着被调用。看到标记就 cancel，浏览器不会 accept 这次下载。

原始方法和进行中的任务表都挂在类上，所以 `:config-source` 重新执行 config.py
时能换成新代码，既不会叠加包装，也不会丢掉正在下载的任务。
"""

import os
import subprocess
from pathlib import Path

from qutebrowser.browser import downloads
from qutebrowser.config import config, websettings
from qutebrowser.qt.core import QUrl
from qutebrowser.utils import log

# aria2 能自己拉的协议。file:// 留给原流程：qutebrowser 对 file→file 有特殊处理
# （直接打开而不是下载），见 browser/downloads.py#L819 cancel_for_origin()。
_SCHEMES = frozenset({"http", "https", "ftp", "ftps"})

# 实际调用 aria2c 的实现。自动接管和 `,d`（hint links userscript）共用这一份。
_SCRIPT = Path(__file__).parent / "userscripts" / "aria2"

_HANDOVER = "aria2_handover"


def _origin(download) -> QUrl:
    """发起这次下载的页面，用作 Referer。"""
    try:
        return download.origin()
    except RuntimeError:
        # 页面在请求到达前就被销毁了
        return QUrl()


def _refusal(download, *, auto_remove: bool):
    """不能交给 aria2c 的原因；可以交则返回 None。"""
    if hasattr(download, "_is_page_download"):
        # webengine 后端。auto_remove 在这里就是 handle_download 算出的
        # use_pdfjs；_is_page_download() 覆盖 :download --mhtml。两者都由浏览器
        # 自己产出内容，没有可重放的 URL。
        if auto_remove:
            return "pdfjs"
        if download._is_page_download():
            return "save-page"

    scheme = download.url().scheme().lower()
    if scheme not in _SCHEMES:
        # blob: 只在浏览器进程内有效，data: 没有可请求的地址
        return f"scheme {scheme}"

    # 这里不查 downloads.prevent_mixed_content：webengine 的 handle_download 在
    # downloads.location.prompt 为 false 时拿到路径就 set_target 并 return
    # （webenginedownloads.py#L290），轮不到 cancel_for_origin() 执行。把这个检查
    # 补在这里只会把 http 资源退回浏览器，而 Chromium 会自己拦掉混合内容下载，
    # 结果就是下载失败。
    return None


def _spawn(url: QUrl, origin: QUrl) -> subprocess.Popen:
    """起一个 userscript 进程，由它调 aria2c。"""
    flags = QUrl.ComponentFormattingOption.FullyEncoded
    env = os.environ.copy()
    env["QUTE_URL"] = url.toString(flags)
    env["QUTE_USER_AGENT"] = websettings.user_agent(url)
    env["QUTE_DOWNLOAD_DIR"] = downloads.download_dir()
    if origin.isValid():
        env["QUTE_CURRENT_URL"] = origin.toString(flags)

    return subprocess.Popen(
        [str(_SCRIPT)],
        env=env,
        stdin=subprocess.DEVNULL,
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL,
        start_new_session=True,
    )


def _install() -> None:
    """包装 _init_item 和 set_target。可以反复调用，用来热载新代码。"""
    manager_cls = downloads.AbstractDownloadManager
    item_cls = downloads.AbstractDownloadItem

    # 只在第一次保存原方法，后续 reload 都基于它重新包装，不会 wrapper 套 wrapper
    if "_aria2_original_init_item" not in manager_cls.__dict__:
        manager_cls._aria2_original_init_item = manager_cls._init_item
    if "_aria2_original_set_target" not in item_cls.__dict__:
        item_cls._aria2_original_set_target = item_cls.set_target
    if "_aria2_in_flight" not in manager_cls.__dict__:
        manager_cls._aria2_in_flight = {}

    original_init_item = manager_cls._aria2_original_init_item
    original_set_target = item_cls._aria2_original_set_target
    in_flight = manager_cls._aria2_in_flight

    def _init_item(self, download, auto_remove, suggested_filename):
        refusal = _refusal(download, auto_remove=auto_remove)
        if refusal is not None:
            log.downloads.debug(
                f"{download.url().toString()} stays in the browser: {refusal}")
            return original_init_item(self, download, auto_remove,
                                      suggested_filename)

        url = download.url()
        key = url.toString(QUrl.ComponentFormattingOption.FullyEncoded)

        for finished in [k for k, proc in in_flight.items()
                         if proc.poll() is not None]:
            del in_flight[finished]

        if key in in_flight:
            # 同一个 URL 已经有一个 aria2c 在拉。再起一个会去抢同一个 .aria2
            # 控制文件，两边都不安全，这次点击只取消浏览器的下载。
            log.downloads.debug(f"aria2 is already fetching {key}")
            download.setProperty(_HANDOVER, True)
            return

        try:
            in_flight[key] = _spawn(url, _origin(download))
        except OSError as e:
            # 脚本缺失或不可执行：交回内置下载器，至少能下到东西
            log.downloads.error(f"Failed to start aria2 userscript: {e}")
            return original_init_item(self, download, auto_remove,
                                      suggested_filename)

        download.setProperty(_HANDOVER, True)

    def set_target(self, target):
        if self.property(_HANDOVER):
            # 不 accept 就不下载。item 由 Qt 侧拥有，cancel 之后自行销毁。
            self.cancel(remove_data=False)
            return
        return original_set_target(self, target)

    manager_cls._init_item = _init_item
    item_cls.set_target = set_target


_install()
