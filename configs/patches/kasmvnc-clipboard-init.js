/*
 * KasmVNC 剪贴板自动同步
 * 在 KasmVNC web 客户端加载后自动：
 *   (1) 开启 Clipboard Seamless（浏览器系统剪贴板 ↔ VNC 双向同步）
 *   (2) 开启 Clipboard Up / Down
 *   (3) 开启 IME Input Mode
 * 这样用户在浏览器里复制 → 直接粘贴进 Chromium，反之亦然
 */
(function () {
  'use strict';

  function setCheckbox(id, checked) {
    var el = document.getElementById(id);
    if (el && el.type === 'checkbox') {
      if (el.checked !== checked) {
        el.checked = checked;
        el.dispatchEvent(new Event('change', { bubbles: true }));
        el.dispatchEvent(new Event('click', { bubbles: true }));
      }
    }
  }

  function applyDefaults() {
    setCheckbox('noVNC_setting_clipboard_seamless', true);
    setCheckbox('noVNC_setting_clipboard_up', true);
    setCheckbox('noVNC_setting_clipboard_down', true);
    setCheckbox('noVNC_setting_enable_ime', true);
  }

  // KasmVNC 的 UI 是异步渲染的，用 MutationObserver 等待目标元素出现
  var observer = new MutationObserver(function (mutations, obs) {
    if (document.getElementById('noVNC_setting_clipboard_seamless')) {
      applyDefaults();
      obs.disconnect();
    }
  });

  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', function () {
      observer.observe(document.body, { childList: true, subtree: true });
    });
  } else {
    observer.observe(document.body, { childList: true, subtree: true });
  }

  // 兜底：5 秒后强制再设一次
  setTimeout(applyDefaults, 5000);
})();
