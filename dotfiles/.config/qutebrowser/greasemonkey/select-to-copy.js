// ==UserScript==
// @name        select-to-copy
// @description 选中网页文字即自动复制到剪贴板，与终端（foot selection-target=both）行为一致
// @include     *
// @run-at      document-end
// ==/UserScript==

(() => {
    'use strict';

    // qutebrowser 在 :greasemonkey-reload 时会把脚本重新注入已打开的页面，
    // 页面级标记保证监听器不会叠加。
    if (window.__selectToCopyInstalled) {
        return;
    }
    window.__selectToCopyInstalled = true;

    // 拖选时 selectionchange 随每个字触发，必须等选区安定后再复制，
    // 否则每多选一个字，剪贴板历史里就多一份这段文字的前缀。
    const SETTLE_MS = 250;

    let lastCopied = '';
    let settleTimer = 0;
    let pointerDown = false;

    // 输入框/文本域里的选区不在 document selection 里，要单独取
    const currentText = () => {
        const active = document.activeElement;
        if (active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA')) {
            if (active.type === 'password' || active.selectionStart === active.selectionEnd) {
                return '';
            }
            return active.value.slice(active.selectionStart, active.selectionEnd);
        }
        const selection = window.getSelection();
        // 不能按 isCollapsed 过滤：Chromium 把 shadow DOM 里的选区暴露成一个
        // 塌缩的 document selection（anchor/focus 落在宿主上、offset 都是 0），
        // isCollapsed 为真，但 toString() 仍返回实际选中的文字。
        if (!selection || selection.rangeCount === 0) {
            return '';
        }
        return selection.toString();
    };

    const execCopy = () => document.execCommand('copy');

    // 只写纯文本：异步 API 不必把整段 DOM 序列化成 HTML（复杂页面可达数十毫秒），
    // 也不会触发页面自己的 copy 处理器。http 页面没有 navigator.clipboard，退回 execCommand。
    const writeClipboard = (text) => {
        try {
            navigator.clipboard.writeText(text).catch(() => {
                if (currentText() === text) {
                    execCopy();
                }
            });
        } catch (e) {
            execCopy();
        }
    };

    const copySelection = () => {
        const text = currentText();
        if (!text) {
            // 选区被清空：允许下次重新选中同一段文字时再次复制
            lastCopied = '';
            return;
        }
        if (text === lastCopied) {
            return;
        }
        lastCopied = text;
        if (navigator.clipboard && navigator.clipboard.writeText) {
            writeClipboard(text);
        } else {
            execCopy();
        }
    };

    const cancelSettle = () => {
        if (settleTimer) {
            clearTimeout(settleTimer);
            settleTimer = 0;
        }
    };

    const scheduleCopy = () => {
        cancelSettle();
        // 按住鼠标拖选期间只累积选区，松手时（pointerup）一次复制。
        if (!pointerDown) {
            settleTimer = setTimeout(() => {
                settleTimer = 0;
                copySelection();
            }, SETTLE_MS);
        }
    };

    // 捕获阶段监听，避免页面的 stopPropagation 挡掉手势事件
    document.addEventListener('pointerdown', (event) => {
        if (event.button !== 0) {
            return;
        }
        pointerDown = true;
        cancelSettle();
    }, true);
    document.addEventListener('pointerup', (event) => {
        if (event.button !== 0) {
            return;
        }
        pointerDown = false;
        cancelSettle();
        copySelection();
    }, true);
    document.addEventListener('pointercancel', () => {
        pointerDown = false;
        scheduleCopy();
    }, true);
    document.addEventListener('selectionchange', scheduleCopy);

    // 在窗口外松开鼠标收不到 pointerup，避免 pointerDown 一直为真
    window.addEventListener('blur', () => {
        pointerDown = false;
        cancelSettle();
    });
})();
