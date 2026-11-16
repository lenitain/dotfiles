// ==UserScript==
// @name        select-to-copy
// @description 选中网页文字即自动复制到剪贴板，与终端（foot selection-target=both）行为一致
// @include     *
// @run-at      document-end
// ==/UserScript==

(() => {
    'use strict';

    let lastCopied = '';

    // 输入框/文本域里的选区不在 document selection 里，要单独取
    const currentText = () => {
        const active = document.activeElement;
        if (active && (active.tagName === 'INPUT' || active.tagName === 'TEXTAREA')) {
            if (active.type === 'password') {
                return '';
            }
            return active.value.slice(active.selectionStart, active.selectionEnd);
        }
        const selection = window.getSelection();
        return selection ? selection.toString() : '';
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
        // execCommand 走的是 QtWebEngine 的“用户交互即可写剪贴板”通道，不需要额外授权；
        // 被拒时再退回异步 Clipboard API。
        if (!document.execCommand('copy')) {
            navigator.clipboard.writeText(text).catch(() => {});
        }
    };

    document.addEventListener('selectionchange', copySelection);
})();
