/*!
 * jt-glogi18n — Graylog Web UI Localization Pack (zh-TW / ja)
 * Client-side translation engine: loads dictionaries, walks the DOM,
 * and keeps translations in sync with SPA route changes.
 *
 * Copyright (c) Jason Cheng (Jason Tools) <jason@jason.tools>
 * Licensed under the Apache License, Version 2.0.
 * https://github.com/jasoncheng7115/jt-glogi18n
 */
(function () {
    'use strict';

    var BASE_URL = '/graylog-i18n/';
    var LOCALES_URL = BASE_URL + 'graylog-i18n-locales.json';
    var DEFAULT_LOCALE = 'zh-TW';
    var STORAGE_KEY = 'graylog-i18n-locale';
    var LEGACY_DISABLED_KEY = 'graylog-i18n-disabled';

    var DEBUG = false;
    try { DEBUG = localStorage.getItem('graylog-i18n-debug') === 'true'; } catch (e) {}

    function log() {
        if (DEBUG) console.log.apply(console, ['[i18n]'].concat(Array.prototype.slice.call(arguments)));
    }

    var currentLocale = null;
    var manifest = null;

    // Auto-detect locale from navigator.languages when the user has not yet
    // made an explicit choice. If the browser preference does not match any
    // supported locale, fall back to 'en' (no translation) so non-CJK users
    // are not forced into Chinese.
    function detectPreferredLocale() {
        var supported = ['zh-TW', 'ja'];
        var langs = [];
        try {
            if (navigator.languages && navigator.languages.length) {
                langs = Array.prototype.slice.call(navigator.languages);
            } else if (navigator.language) {
                langs = [navigator.language];
            }
        } catch (e) {}
        for (var i = 0; i < langs.length; i++) {
            var lang = langs[i];
            if (!lang) continue;
            for (var j = 0; j < supported.length; j++) {
                if (lang.toLowerCase() === supported[j].toLowerCase()) return supported[j];
            }
            if (/^zh-(TW|HK|MO|Hant)(?:-|$)/i.test(lang) && supported.indexOf('zh-TW') !== -1) {
                return 'zh-TW';
            }
            if (/^ja(?:-|$)/i.test(lang) && supported.indexOf('ja') !== -1) {
                return 'ja';
            }
        }
        return 'en';
    }

    try {
        currentLocale = localStorage.getItem(STORAGE_KEY);
        if (!currentLocale && localStorage.getItem(LEGACY_DISABLED_KEY) === 'true') {
            currentLocale = 'en';
            localStorage.setItem(STORAGE_KEY, 'en');
            localStorage.removeItem(LEGACY_DISABLED_KEY);
        }
    } catch (e) {}
    if (!currentLocale) currentLocale = detectPreferredLocale();

    function loadJSON(url, cb) {
        var xhr = new XMLHttpRequest();
        xhr.open('GET', url, true);
        xhr.onload = function () {
            if (xhr.status === 200) {
                try { cb(null, JSON.parse(xhr.responseText)); }
                catch (e) { cb(e); }
            } else cb(new Error('HTTP ' + xhr.status));
        };
        xhr.onerror = function () { cb(new Error('network error')); };
        xhr.send();
    }

    function injectToggle() {
        function build() {
            if (document.getElementById('graylog-i18n-toggle')) return;
            var style = document.createElement('style');
            style.id = 'graylog-i18n-toggle-style';
            style.textContent = [
                '#graylog-i18n-toggle-root{position:fixed;bottom:14px;right:14px;z-index:2147483647;',
                  'font:600 10px/1 -apple-system,"Segoe UI",sans-serif;opacity:.55;transition:opacity .15s ease;}',
                '#graylog-i18n-toggle-root:hover,#graylog-i18n-toggle-root.open{opacity:1;}',
                '#graylog-i18n-toggle-root.dragging #graylog-i18n-toggle{cursor:grabbing;}',
                '#graylog-i18n-toggle-root.dragging{transition:none;}',
                '#graylog-i18n-toggle{',
                  'padding:5px 9px;border-radius:999px;border:1px solid;',
                  'cursor:grab;user-select:none;display:flex;align-items:center;gap:5px;',
                  'box-shadow:0 1px 4px rgba(0,0,0,.12);',
                  'transition:transform .12s ease,box-shadow .12s ease,background .12s ease;',
                  'backdrop-filter:saturate(1.5) blur(8px);-webkit-backdrop-filter:saturate(1.5) blur(8px);',
                  'background:rgba(255,255,255,.55);color:#252D47;border-color:rgba(0,0,0,.06);',
                  'font:inherit;',
                '}',
                '#graylog-i18n-menu{',
                  'position:absolute;bottom:calc(100% + 8px);right:0;min-width:160px;',
                  'background:rgba(255,255,255,.96);color:#252D47;border:1px solid rgba(0,0,0,.08);',
                  'border-radius:12px;padding:6px;display:none;flex-direction:column;',
                  'box-shadow:0 8px 24px rgba(0,0,0,.18),0 2px 6px rgba(0,0,0,.1);',
                  'backdrop-filter:saturate(1.5) blur(10px);-webkit-backdrop-filter:saturate(1.5) blur(10px);',
                '}',
                '#graylog-i18n-toggle-root.open #graylog-i18n-menu{display:flex;}',
                '#graylog-i18n-menu button{',
                  'all:unset;cursor:pointer;padding:8px 12px;border-radius:8px;',
                  'display:flex;align-items:center;gap:8px;font:inherit;',
                '}',
                '#graylog-i18n-menu button:hover{background:rgba(0,0,0,.05);}',
                '#graylog-i18n-menu button.active{background:rgba(16,185,129,.12);color:#047857;}',
                '#graylog-i18n-menu .gi-check{width:14px;text-align:center;opacity:0;}',
                '#graylog-i18n-menu button.active .gi-check{opacity:1;}',
                'html[data-mantine-color-scheme="dark"] #graylog-i18n-toggle,',
                'body.dark #graylog-i18n-toggle{',
                  'background:rgba(40,44,56,.55);color:#E5E7EB;border-color:rgba(255,255,255,.08);',
                  'box-shadow:0 1px 4px rgba(0,0,0,.4);',
                '}',
                'html[data-mantine-color-scheme="dark"] #graylog-i18n-menu,',
                'body.dark #graylog-i18n-menu{',
                  'background:rgba(40,44,56,.96);color:#E5E7EB;border-color:rgba(255,255,255,.08);',
                  'box-shadow:0 8px 24px rgba(0,0,0,.5),0 2px 6px rgba(0,0,0,.3);',
                '}',
                'html[data-mantine-color-scheme="dark"] #graylog-i18n-menu button:hover,',
                'body.dark #graylog-i18n-menu button:hover{background:rgba(255,255,255,.06);}',
                'html[data-mantine-color-scheme="dark"] #graylog-i18n-menu button.active,',
                'body.dark #graylog-i18n-menu button.active{background:rgba(16,185,129,.18);color:#34D399;}',
                '@media (prefers-color-scheme:dark){',
                  'html:not([data-mantine-color-scheme="light"]) #graylog-i18n-toggle{',
                    'background:rgba(40,44,56,.55);color:#E5E7EB;border-color:rgba(255,255,255,.08);',
                  '}',
                  'html:not([data-mantine-color-scheme="light"]) #graylog-i18n-menu{',
                    'background:rgba(40,44,56,.96);color:#E5E7EB;border-color:rgba(255,255,255,.08);',
                  '}',
                  'html:not([data-mantine-color-scheme="light"]) #graylog-i18n-menu button:hover{background:rgba(255,255,255,.06);}',
                '}',
                '#graylog-i18n-toggle:hover{transform:translateY(-1px);box-shadow:0 4px 12px rgba(0,0,0,.18),0 2px 4px rgba(0,0,0,.12);}',
                '#graylog-i18n-toggle:active{transform:translateY(0);}',
                '#graylog-i18n-toggle .gi-dot{width:5px;height:5px;border-radius:50%;background:#10B981;}',
                '#graylog-i18n-toggle.gi-off .gi-dot{background:#9CA3AF;}',
                '#graylog-i18n-toggle .gi-caret{margin-left:1px;opacity:.6;font-size:8px;}'
            ].join('');
            document.head.appendChild(style);

            var localesList = (manifest && manifest.locales) || [
                { code: 'en', short: 'EN', native: 'English' },
                { code: DEFAULT_LOCALE, short: '中', native: '繁體中文' }
            ];
            var current = localesList.find(function (l) { return l.code === currentLocale; }) || localesList[0];
            var shortLabel = current.short || current.code.split('-')[0].toUpperCase();

            var root = document.createElement('div');
            root.id = 'graylog-i18n-toggle-root';

            var btn = document.createElement('button');
            btn.id = 'graylog-i18n-toggle';
            btn.type = 'button';
            btn.className = currentLocale === 'en' ? 'gi-off' : '';
            btn.title = '切換語言 / Switch language';
            btn.innerHTML = '<span class="gi-dot"></span><span>' + escapeHtml(shortLabel) + '</span><span class="gi-caret">▾</span>';

            var menu = document.createElement('div');
            menu.id = 'graylog-i18n-menu';
            menu.setAttribute('role', 'menu');
            localesList.forEach(function (l) {
                var item = document.createElement('button');
                item.type = 'button';
                if (l.code === currentLocale) item.className = 'active';
                item.innerHTML = '<span class="gi-check">✓</span><span>' + escapeHtml(l.native) + '</span>';
                item.addEventListener('click', function () {
                    if (l.code === currentLocale) { root.classList.remove('open'); return; }
                    try { localStorage.setItem(STORAGE_KEY, l.code); } catch (e) {}
                    location.reload();
                });
                menu.appendChild(item);
            });

            var dragState = { active: false, moved: false, startX: 0, startY: 0, originLeft: 0, originTop: 0 };
            var POS_KEY = 'graylog-i18n-toggle-pos';
            var savedPos = null;
            try {
                var s = JSON.parse(localStorage.getItem(POS_KEY));
                if (s && typeof s.left === 'number' && typeof s.top === 'number') savedPos = s;
            } catch (e) {}

            function clamp(val, min, max) { return Math.max(min, Math.min(max, val)); }

            btn.addEventListener('mousedown', function (e) {
                if (e.button !== 0) return;
                var rect = root.getBoundingClientRect();
                dragState.active = true;
                dragState.moved = false;
                dragState.startX = e.clientX;
                dragState.startY = e.clientY;
                dragState.originLeft = rect.left;
                dragState.originTop = rect.top;
                e.preventDefault();
            });

            document.addEventListener('mousemove', function (e) {
                if (!dragState.active) return;
                var dx = e.clientX - dragState.startX;
                var dy = e.clientY - dragState.startY;
                if (!dragState.moved && Math.abs(dx) + Math.abs(dy) < 4) return;
                dragState.moved = true;
                root.classList.add('dragging');
                var w = root.offsetWidth, h = root.offsetHeight;
                var left = clamp(dragState.originLeft + dx, 4, window.innerWidth - w - 4);
                var top = clamp(dragState.originTop + dy, 4, window.innerHeight - h - 4);
                root.style.left = left + 'px';
                root.style.top = top + 'px';
                root.style.right = 'auto';
                root.style.bottom = 'auto';
            });

            document.addEventListener('mouseup', function () {
                if (!dragState.active) return;
                var wasMoved = dragState.moved;
                dragState.active = false;
                dragState.moved = false;
                root.classList.remove('dragging');
                if (wasMoved) {
                    var rect = root.getBoundingClientRect();
                    try { localStorage.setItem(POS_KEY, JSON.stringify({ left: rect.left, top: rect.top })); } catch (e) {}
                }
            });

            btn.addEventListener('click', function (e) {
                e.stopPropagation();
                if (dragState.moved) return;
                root.classList.toggle('open');
            });
            document.addEventListener('click', function (e) {
                if (!root.contains(e.target)) root.classList.remove('open');
            });

            root.appendChild(menu);
            root.appendChild(btn);
            document.body.appendChild(root);

            if (savedPos) {
                var w = root.offsetWidth || 60, h = root.offsetHeight || 24;
                var left = clamp(savedPos.left, 4, Math.max(4, window.innerWidth - w - 4));
                var top = clamp(savedPos.top, 4, Math.max(4, window.innerHeight - h - 4));
                root.style.left = left + 'px';
                root.style.top = top + 'px';
                root.style.right = 'auto';
                root.style.bottom = 'auto';
            }

            // Keep the toggle inside the viewport when the window shrinks.
            // If the user never dragged, root still uses the default right/bottom
            // anchoring, which survives resize on its own — nothing to do.
            function clampToViewport() {
                if (!root.style.left && !root.style.top) return;
                var w = root.offsetWidth || 60, h = root.offsetHeight || 24;
                var maxLeft = Math.max(4, window.innerWidth - w - 4);
                var maxTop = Math.max(4, window.innerHeight - h - 4);
                var rect = root.getBoundingClientRect();
                var left = clamp(rect.left, 4, maxLeft);
                var top = clamp(rect.top, 4, maxTop);
                if (left !== rect.left) root.style.left = left + 'px';
                if (top !== rect.top) root.style.top = top + 'px';
            }
            var resizeRaf = null;
            window.addEventListener('resize', function () {
                if (resizeRaf) return;
                resizeRaf = requestAnimationFrame(function () {
                    resizeRaf = null;
                    clampToViewport();
                });
            });
        }
        function escapeHtml(s) {
            return String(s).replace(/[&<>"']/g, function (c) {
                return { '&': '&amp;', '<': '&lt;', '>': '&gt;', '"': '&quot;', "'": '&#39;' }[c];
            });
        }
        if (document.body) build();
        else document.addEventListener('DOMContentLoaded', build);
    }

    function bootstrapToggle() {
        loadJSON(LOCALES_URL, function (err, data) {
            if (!err && data) manifest = data;
            injectToggle();
        });
    }

    var localeEntry = null;
    function findLocaleEntry() {
        if (!manifest) return null;
        for (var i = 0; i < manifest.locales.length; i++) {
            if (manifest.locales[i].code === currentLocale) return manifest.locales[i];
        }
        return null;
    }

    if (currentLocale === 'en') {
        bootstrapToggle();
        return;
    }

    var SKIP_SELECTORS = [
        '.message-field',
        '.message-field-value',
        '.message-details-fields',
        '[class*="MessageDetail"]',
        '[class*="MessageField"]',
        '[class*="FieldValue"]',
        '.search-result-message',
        '[class*="MessageTableEntry"]',
        '[class*="ResultMessage"]',
        '[class*="MessageList"]',
        '[class*="LogView"]',
        '[class*="MessagesContainer"]',
        '[class*="RawMessage"]',
        '[class*="MessagePreview"]',
        'code',
        'pre',
        '.ace_editor',
        '.CodeMirror',
        '[class*="QueryInput"]',
        '[class*="SearchBar"]',
        '[class*="FieldTypeFilter"]',
        'input',
        'textarea',
        'select',
        'option',
        '[class*="field-element"]',
        '.field-element',
        '.mantine-Menu-dropdown > li',
        '[class*="FieldName"]',
        '[class*="FieldList"]',
        '[class*="FieldItem"]',
        '[class*="FieldSelect"]',
        '[class*="FieldGroup"]',
        '[class*="FieldTypes"]',
        '[class*="FieldType"]',
        '[class*="SidebarField"]',
        '[class*="FieldsList"]',
        '[class*="field-list"]',
        '[class*="types-list"]',
        '[class*="TypeIcon"]',
        '[class*="TypeListItem"]',
        '.field-name',
        '[class*="WidgetValue"]',
        '[class*="EntityId"]',
        '[class*="StreamId"]',
        '[class*="NodeId"]',
        '[class*="ClusterId"]',
        '[class*="IndexName"]',
        '[class*="FieldValueRenderer"]',
        '.json-viewer',
        '[class*="JsonViewer"]',
        '[class*="Highlight"]',
        'script',
        'style',
        '[contenteditable="true"]',
        '[class*="material-symbols"]',
        '[class*="material-icons"]',
        '[class*="Markdown"]',
        '[class*="markdown"]'
    ];

    var COMBINED_SKIP = SKIP_SELECTORS.join(',');

    var translations = new Map();
    var patterns = [];
    // Substring patterns (marked with "substring": true in dict). Applied
    // globally after the primary pattern loop — useful for chunks that
    // appear inside longer error traces with dynamic numbers.
    var substringPatterns = [];
    var pendingFrame = null;
    var stats = { translated: 0, skipped: 0, patterns: 0, elapsed: 0 };

    var FORCE_TRANSLATE_SELECTORS = '.ace_placeholder, option[disabled], .mantine-Menu-dropdown, .mantine-Menu-itemLabel, .mantine-Button-label, .mantine-Button-inner';
    // Icon font containers. `material-symbols-*` / `material-icons-*` render the
    // text content as a glyph — translating "search" → "搜尋" breaks the icon.
    // Must win over FORCE_TRANSLATE (Mantine buttons host icons inside label).
    var HARD_SKIP_SELECTORS = '[class*="material-symbols"], [class*="material-icons"]';
    // Exact text matches that should always translate, even if the parent
    // container is in a SKIP zone (e.g. widget value cells may render
    // "(Empty Value)" which is UI placeholder, not user data).
    var ALWAYS_TRANSLATE_TEXTS = {
        '(Empty Value)': true
    };
    // Same idea but regex — lets long dynamic error messages bypass the
    // SKIP zones (email-send failure traces are often wrapped in alert
    // containers that match [class*="Highlight"] etc.).
    var ALWAYS_TRANSLATE_PATTERNS = [
        /^An error was encountered while trying to send an email\./,
        /^Notification has email recipients and is triggered, but sending emails failed\./
    ];

    function isInSkipZone(node) {
        var el = node.nodeType === Node.TEXT_NODE ? node.parentElement : node;
        if (!el) return true;
        if (el.closest(HARD_SKIP_SELECTORS)) return true;
        if (el.closest(FORCE_TRANSLATE_SELECTORS)) return false;
        return el.closest(COMBINED_SKIP) !== null;
    }

    function looksLikeDataOrIdentifier(text) {
        if (!text) return true;

        if (/@/.test(text)) return true;
        if (/^\d{1,3}(?:\.\d{1,3}){3}(?::\d+)?$/.test(text)) return true;
        if (/^\/[A-Za-z0-9._/-]+$/.test(text)) return true;
        if (/^https?:\/\/\S+$/.test(text)) return true;
        if (/^[A-Za-z0-9.-]+(?:_[A-Za-z0-9.-]+)+$/.test(text)) return true;
        if (/^(?:[A-Z][a-z]+|[A-Z]{2,}|[a-z]+)\s*:\s*.+$/.test(text) && /[/.0-9]/.test(text)) return true;
        if (/^\S+\s*=\s*(string|number|long|int|integer|double|float|boolean|bool|date|datetime|keyword|ip|geo_point|text|binary|byte|short)$/i.test(text)) return true;

        return false;
    }

    // Activity-log / audit verbs. When a text node trims to one of these
    // words AND the previous sibling is "was" / "被", translate.
    // Keeps the engine safe from over-translating these common English
    // words in other UI contexts (e.g. "Status: updated").
    var ACTIVITY_VERBS = {
        'shared':    '分享',
        'unshared':  '取消分享',
        'created':   '建立',
        'updated':   '更新',
        'deleted':   '刪除',
        'removed':   '移除',
        'added':     '新增',
        'modified':  '修改',
        'changed':   '變更',
        'started':   '啟動',
        'stopped':   '停止',
        'restarted': '重新啟動',
        'renamed':   '重新命名',
        'enabled':   '啟用',
        'disabled':  '停用',
        'imported':  '匯入',
        'exported':  '匯出',
        'saved':     '儲存',
        'archived':  '封存',
        'restored':  '還原',
        'moved':     '移動'
    };

    var _verbEn = Object.keys(ACTIVITY_VERBS);
    var _verbZh = _verbEn.map(function (k) { return ACTIVITY_VERBS[k]; });
    var _verbRE = new RegExp('^(' + _verbEn.concat(_verbZh).join('|') + ')$');
    var _verbTailRE = new RegExp('(' + _verbEn.concat(_verbZh).join('|') + ')$');
    var _wasOrBeiRE = /(^|\s)(was|被)$/;

    var CONDITIONAL = {
        'in': { to: '於', prev: /\d[\d,.\s]*\s*(messages?|bytes?|%|則訊息|個位元組|筆|條)?$|前$/i },
        'of': { to: '/', prev: /[\d.,]+\s*(GiB|MiB|KiB|GB|MB|KB|bytes?|TB)$/i },
        '.': { to: '。', check: function (n) {
            // Convert period to full-width when prev sibling ends with CJK/fw
            // punctuation, OR when the surrounding paragraph is Chinese-heavy.
            // EXCEPTION: if prev is just digits (list numbering like "1. Label"),
            // keep the ASCII period.
            var prev = prevTextContent(n);
            if (/^\d+$/.test(prev)) return false;
            if (/[\u4e00-\u9fff\uff01-\uff5e]$/.test(prev)) return true;
            var p = n.parentElement;
            if (p && /[\u4e00-\u9fff]/.test(p.textContent || '')) return true;
            return false;
        }},
        'was': { to: '被', next: _verbRE },
        'details': { to: '詳細資訊', prev: /(Show|Hide|顯示|隱藏)$/ },
        'Every': { to: '每', next: /^\d/ },
        // "total" after a digit sibling -> "筆". Handles DOM-split counters
        // like <span>16</span><span> total</span>.
        'total': { to: '筆', prev: /\d$/ },
        'indices': { to: '個索引', prev: /\d$/ },
        'documents': { to: '筆文件', prev: /\d$/ },
        // "after <N> days" following "Deleted" / "刪除" — retention UI
        'after': { to: '於', prev: /(Deleted|刪除)$/ },
        // "took" in counters like "1234 ops (took 3 minutes)" — DOM may
        // split the inner duration into a separate span.
        'took': { to: '耗時', prev: /\($/ },
        'messages': { to: '則訊息', prev: /\d$|[\d,]\d$/ },
        'message': { to: '則訊息', prev: /\d$|[\d,]\d$/ },
        // "1 item selected" split across text nodes: <span>1</span><span>item</span><span> selected</span>
        'item': { to: '個項目已選取', prev: /\d$/, next: /^selected$/ },
        'items': { to: '個項目已選取', prev: /\d$/, next: /^selected$/ },
        'selected': { to: '', prev: /(個項目已選取|item|items)$/ },
        // Drop the linking verb "is" when it sits between a product name
        // and a status label (e.g. "Graylog Plugin Enterprise is not installed").
        'is': { to: '', prev: /(Enterprise|Graylog Plugin|Graylog Open|Graylog Operations)$/ },
        // Drop "The" when it's immediately before a product name like Graylog
        // / OpenSearch / Elasticsearch — Chinese doesn't need the article.
        // Keeps "The" everywhere else untouched (CLAUDE.md forbids standalone
        // translation).
        'The': { to: '', next: /^(Graylog|OpenSearch|Elasticsearch|Sidecar|Marketplace)\b/ },
        // "This is <em>not</em> the leader node" style — translate bold "not"
        // to "非" only when the surrounding text mentions leader node. Never
        // translate a standalone "not" (CLAUDE.md forbids it).
        'not': { to: '非', check: function (n) {
            // The text node lives inside <em>, so direct siblings are empty.
            // Walk up to the parent element's surrounding text for context.
            var par = n.parentElement;
            var surround = par && par.parentElement ? (par.parentElement.textContent || '') : '';
            return /leader|領導/.test(surround);
        }},
        // Table headers — only translate when inside <th> to avoid false
        // positives on message fields or widget values.
        'Filename': { to: '檔案名稱', parent: 'th' },
        'Size': { to: '大小', parent: 'th' },
        // OpenSearch node role badge — only translate when inside a Bootstrap
        // label span. Avoids over-translating "data" elsewhere in prose.
        'data': { to: '資料', check: function (n) {
            var p = n.parentElement;
            if (!p) return false;
            return !!p.closest('[class*="label-"],[class*="Label-"],[class*="badge"],[class*="Badge"]');
        }},
        // DOM-split "No <noun>." fragments: <span>No </span><em>noun</em><span>.</span>
        'events': { to: '事件', prev: /(沒有|No)$/ },
        'dashboards': { to: '看板', prev: /(沒有|No)$/ },
        'streams': { to: '串流', prev: /(沒有|No)$/ },
        'searches': { to: '搜尋', prev: /(沒有|No)$/ },
        'alerts': { to: '警報', prev: /(沒有|No)$/ },
        'notifications': { to: '通知', prev: /(沒有|No)$/ },
        'event notifications': { to: '事件通知', prev: /(沒有|No)$/ },
        'event definitions': { to: '事件定義', prev: /(沒有|No)$/ },
        'pipelines': { to: '管線', prev: /(沒有|No)$/ },
        'rules': { to: '規則', prev: /(沒有|No)$/ },
        'users': { to: '使用者', prev: /(沒有|No)$/ },
        'teams': { to: '團隊', check: function (n) {
            if (/(沒有|No)$/.test(prevTextContent(n))) return true;
            var p = n.parentElement;
            return !!(p && p.matches('b,strong'));
        }},
        'roles': { to: '角色', prev: /(沒有|No)$/ },
        // 'Open' only translates when inside a <button> or role=button
        // (walking up via closest() handles Mantine's nested <span> wrappers
        // like .mantine-Button-label / .mantine-Button-inner).
        // <a> deliberately excluded because changelog links like
        // <a href=".../changelog">Open</a> point to "Graylog Open" edition
        // and should keep product naming.
        'Open': { to: '開啟', check: function (n) {
            var p = n.parentElement;
            return !!(p && p.closest('button,[role="button"]'));
        }},
        // "and" only translates when it's the paired opposite of "or" in a
        // radio/toggle group — detected by looking for "或" or "or" anywhere
        // in the nearest group container. Avoids over-translating "and" in
        // ordinary English sentences.
        'and': { to: '且', check: function (n) {
            // Only translate "and" when it's the sole visible text of its
            // immediate parent (e.g. a radio-button <label>). This avoids
            // over-translating "and" inside regular prose sentences.
            var par = n.parentElement;
            if (!par) return false;
            if ((par.textContent || '').trim() !== 'and') return false;
            // Additionally require that an ancestor (small container) also
            // contains "或" / "or" — confirms it's an and/or toggle pair.
            var el = par.parentElement;
            for (var i = 0; i < 6 && el; i++) {
                var t = (el.textContent || '').trim();
                if (t && t.length < 120 && /或|\bor\b/i.test(t)) return true;
                el = el.parentElement;
            }
            return false;
        }}
    };
    // Add every activity verb as a CONDITIONAL whose prev must be "was"/"被"
    _verbEn.forEach(function (en) {
        CONDITIONAL[en] = { to: ACTIVITY_VERBS[en], prev: _wasOrBeiRE };
    });

    // Override `enabled` / `disabled` so they translate when:
    //  1. Prev sibling is "was" / "被" (activity-log case)
    //  2. Text is standalone inside a <label> (checkbox UI)
    //  3. Text is the ONLY visible text of a small status container
    //     (badge / pill / label span — e.g. <span class="badge">enabled</span>)
    ['enabled', 'disabled'].forEach(function (en) {
        CONDITIONAL[en] = { to: ACTIVITY_VERBS[en], check: function (n) {
            if (_wasOrBeiRE.test(prevTextContent(n))) return true;
            var p = n.parentElement;
            if (!p) return false;
            // Inside any button / status badge / label-style container.
            if (p.closest('button,[role="button"],label,dd,td,[class*="label"],[class*="badge"],[class*="Badge"],[class*="Label"],[class*="Pill"]')) {
                return true;
            }
            return false;
        }};
    });

    // Patterns that only fire when the previous sibling text matches `prev`.
    // Handles the trailing " by <username>" fragment after any activity verb.
    var CONDITIONAL_PATTERNS = [
        { match: /^by (\S.*)$/, replace: '由 $1', prev: _verbTailRE }
    ];

    function prevTextContent(textNode) {
        var prev = textNode.previousSibling;
        while (prev) {
            if (prev.nodeType === Node.TEXT_NODE) {
                var t = prev.textContent.trim();
                if (t) return t;
            } else if (prev.nodeType === Node.ELEMENT_NODE) {
                var t2 = (prev.textContent || '').trim();
                if (t2) return t2;
            }
            prev = prev.previousSibling;
        }
        return '';
    }

    function nextTextContent(textNode) {
        var next = textNode.nextSibling;
        while (next) {
            if (next.nodeType === Node.TEXT_NODE) {
                var t = next.textContent.trim();
                if (t) return t;
            } else if (next.nodeType === Node.ELEMENT_NODE) {
                var t2 = (next.textContent || '').trim();
                if (t2) return t2;
            }
            next = next.nextSibling;
        }
        return '';
    }

    function translateTextNode(textNode) {
        var text = textNode.textContent.trim();
        if (!text) return;

        if (CONDITIONAL.hasOwnProperty(text)) {
            var cond = CONDITIONAL[text];
            var passed = true;
            var prevText = '';
            if (cond.prev) {
                prevText = prevTextContent(textNode);
                if (!cond.prev.test(prevText)) passed = false;
            }
            if (passed && cond.next) {
                var nextText = nextTextContent(textNode);
                if (!cond.next.test(nextText)) passed = false;
            }
            if (passed && cond.parent) {
                var par = textNode.parentElement;
                if (!par || !par.matches(cond.parent)) passed = false;
            }
            if (passed && typeof cond.check === 'function') {
                try { if (!cond.check(textNode)) passed = false; } catch (e) { passed = false; }
            }
            if (passed) {
                log('conditional:', text, '->', cond.to, 'ctx prev=', prevText);
                textNode.textContent = textNode.textContent.replace(text, cond.to);
                stats.translated++;
            }
            return;
        }

        for (var cpi = 0; cpi < CONDITIONAL_PATTERNS.length; cpi++) {
            var cp = CONDITIONAL_PATTERNS[cpi];
            if (cp.match.test(text)) {
                var cpPrev = prevTextContent(textNode);
                if (cp.prev && !cp.prev.test(cpPrev)) continue;
                var cpResult = text.replace(cp.match, cp.replace);
                if (cpResult !== text) {
                    log('conditional-pattern:', text, '->', cpResult, 'ctx prev=', cpPrev);
                    textNode.textContent = textNode.textContent.replace(text, cpResult);
                    stats.patterns++;
                }
                return;
            }
        }

        if (text.length < 2) return;

        if (translations.has(text)) {
            var translated = translations.get(text);
            if (textNode.textContent.trim() !== translated) {
                log('translate:', text, '->', translated);
                textNode.textContent = textNode.textContent.replace(text, translated);
                stats.translated++;
            }
            return;
        }

        if (looksLikeDataOrIdentifier(text)) return;

        var normalized = text.replace(/\s+/g, ' ');
        if (normalized !== text && translations.has(normalized)) {
            var translatedN = translations.get(normalized);
            log('translate (normalized):', normalized, '->', translatedN);
            textNode.textContent = textNode.textContent.replace(text, translatedN);
            stats.translated++;
            return;
        }

        var current = text;
        for (var i = 0; i < patterns.length; i++) {
            var p = patterns[i];
            if (p.match.test(current)) {
                current = current.replace(p.match, p.replace);
                break;
            }
        }
        for (var si = 0; si < substringPatterns.length; si++) {
            var sp = substringPatterns[si];
            if (sp.match.test(current)) {
                current = current.replace(sp.match, sp.replace);
            }
        }
        if (current !== text && textNode.textContent.trim() !== current) {
            log('pattern:', text, '->', current);
            textNode.textContent = textNode.textContent.replace(text, current);
            stats.patterns++;
        }
    }

    function processTextNode(textNode) {
        var text = (textNode.nodeValue || '').trim();
        if (ALWAYS_TRANSLATE_TEXTS[text]) {
            translateTextNode(textNode);
            return;
        }
        for (var ai = 0; ai < ALWAYS_TRANSLATE_PATTERNS.length; ai++) {
            if (ALWAYS_TRANSLATE_PATTERNS[ai].test(text)) {
                translateTextNode(textNode);
                return;
            }
        }
        if (isInSkipZone(textNode)) {
            stats.skipped++;
            return;
        }
        translateTextNode(textNode);
    }

    function translateAttribute(el, attr) {
        var val = el.getAttribute(attr);
        if (!val) return;
        var trimmed = val.trim();
        if (trimmed.length < 2) return;
        if (translations.has(trimmed)) {
            var translated = translations.get(trimmed);
            if (trimmed !== translated) {
                el.setAttribute(attr, val.replace(trimmed, translated));
                stats.translated++;
            }
            return;
        }
        for (var i = 0; i < patterns.length; i++) {
            var p = patterns[i];
            if (p.match.test(trimmed)) {
                var result = trimmed.replace(p.match, p.replace);
                if (trimmed !== result) {
                    el.setAttribute(attr, val.replace(trimmed, result));
                    stats.patterns++;
                }
                return;
            }
        }
    }

    function translateAttributesIn(root) {
        var els = root.querySelectorAll('[placeholder], [title], [aria-label]');
        for (var i = 0; i < els.length; i++) {
            var el = els[i];
            if (el.hasAttribute('placeholder')) translateAttribute(el, 'placeholder');
            if (el.hasAttribute('title')) translateAttribute(el, 'title');
            if (el.hasAttribute('aria-label')) translateAttribute(el, 'aria-label');
        }
    }

    function walkAndTranslate(root) {
        var walker = document.createTreeWalker(
            root,
            NodeFilter.SHOW_TEXT,
            null,
            false
        );
        var node;
        while ((node = walker.nextNode())) {
            processTextNode(node);
        }
        if (root.querySelectorAll) translateAttributesIn(root);
    }

    function translateAll() {
        var start = performance.now();
        stats = { translated: 0, skipped: 0, patterns: 0, elapsed: 0 };
        walkAndTranslate(document.body);
        stats.elapsed = (performance.now() - start).toFixed(1);
        log('full scan:', stats);
    }

    function processMutations(mutationsList) {
        var start = performance.now();
        var count = { translated: 0, skipped: 0, patterns: 0 };

        for (var i = 0; i < mutationsList.length; i++) {
            var mutation = mutationsList[i];

            if (mutation.type === 'characterData') {
                processTextNode(mutation.target);
                continue;
            }

            if (mutation.type === 'childList') {
                for (var j = 0; j < mutation.addedNodes.length; j++) {
                    var added = mutation.addedNodes[j];
                    if (added.nodeType === Node.TEXT_NODE) {
                        processTextNode(added);
                    } else if (added.nodeType === Node.ELEMENT_NODE) {
                        if (!added.matches || !added.matches(COMBINED_SKIP)) {
                            walkAndTranslate(added);
                        }
                    }
                }
            }
        }

        var elapsed = (performance.now() - start).toFixed(1);
        log('mutations:', mutationsList.length, 'elapsed:', elapsed + 'ms');
    }

    var pendingMutations = [];

    function startObserver() {
        var observer = new MutationObserver(function (mutations) {
            for (var i = 0; i < mutations.length; i++) {
                pendingMutations.push(mutations[i]);
            }
            if (pendingFrame) return;
            pendingFrame = requestAnimationFrame(function () {
                var batch = pendingMutations;
                pendingMutations = [];
                pendingFrame = null;
                processMutations(batch);
            });
        });

        observer.observe(document.body, {
            childList: true,
            subtree: true,
            characterData: true
        });

        log('MutationObserver started');
    }

    function loadDict(callback) {
        var entry = findLocaleEntry();
        var dictPath = entry && entry.dict ? entry.dict : 'graylog-i18n-dict.json';
        var dictUrl = BASE_URL + dictPath;
        var xhr = new XMLHttpRequest();
        xhr.open('GET', dictUrl, true);
        xhr.onload = function () {
            if (xhr.status === 200) {
                try {
                    var data = JSON.parse(xhr.responseText);

                    if (data.translations) {
                        var keys = Object.keys(data.translations);
                        for (var i = 0; i < keys.length; i++) {
                            translations.set(keys[i], data.translations[keys[i]]);
                        }
                    }

                    if (data.patterns) {
                        for (var j = 0; j < data.patterns.length; j++) {
                            var p = data.patterns[j];
                            var flags = p.flags || '';
                            if (p.substring && flags.indexOf('g') === -1) flags += 'g';
                            var entry = {
                                match: new RegExp(p.match, flags),
                                replace: p.replace
                            };
                            if (p.substring) substringPatterns.push(entry);
                            else patterns.push(entry);
                        }
                    }

                    log('dict loaded:', translations.size, 'translations,', patterns.length, 'patterns');
                    if (data._meta) {
                        log('dict version:', data._meta.version, 'for Graylog', data._meta.graylog_version);
                    }
                    callback(null);
                } catch (e) {
                    console.error('[i18n] failed to parse dict:', e);
                    callback(e);
                }
            } else {
                console.error('[i18n] failed to load dict: HTTP', xhr.status);
                callback(new Error('HTTP ' + xhr.status));
            }
        };
        xhr.onerror = function () {
            console.error('[i18n] failed to load dict: network error');
            callback(new Error('network error'));
        };
        xhr.send();
    }

    function scheduleCatchupPasses() {
        var delays = [100, 300, 800, 1500, 3000, 6000];
        for (var i = 0; i < delays.length; i++) {
            setTimeout(translateAll, delays[i]);
        }
    }

    function startPeriodicCatchup() {
        setInterval(translateAll, 3000);
    }

    function hookRouteChanges() {
        var lastUrl = location.href;
        function onRouteChange() {
            if (location.href === lastUrl) return;
            lastUrl = location.href;
            log('route change ->', lastUrl);
            scheduleCatchupPasses();
        }

        window.addEventListener('popstate', onRouteChange);

        var origPush = history.pushState;
        history.pushState = function () {
            var ret = origPush.apply(this, arguments);
            onRouteChange();
            return ret;
        };

        var origReplace = history.replaceState;
        history.replaceState = function () {
            var ret = origReplace.apply(this, arguments);
            onRouteChange();
            return ret;
        };
    }

    function init() {
        log('initializing locale:', currentLocale);

        loadJSON(LOCALES_URL, function (err, data) {
            if (!err && data) manifest = data;

            loadDict(function (dictErr) {
                if (dictErr) {
                    console.error('[i18n] aborted: could not load dictionary');
                    injectToggle();
                    return;
                }

                function start() {
                    translateAll();
                    startObserver();
                    scheduleCatchupPasses();
                    hookRouteChanges();
                    startPeriodicCatchup();
                    injectToggle();
                }
                if (document.readyState === 'loading') {
                    document.addEventListener('DOMContentLoaded', start);
                } else {
                    start();
                }
            });
        });
    }

    if (DEBUG) {
        window.__graylogI18n = {
            stats: function () { return stats; },
            retranslate: translateAll,
            translations: translations,
            patterns: patterns
        };
        log('debug helpers exposed on window.__graylogI18n');
    }

    init();
})();
