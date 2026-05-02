# jt-glogi18n — Graylog Localization Pack (zh-TW / ja)  `v3.1.6`

Localizes the Graylog Web UI into **Traditional Chinese (zh-TW)** and
**Japanese (ja)** via an Nginx `sub_filter` that injects a small translation
script + CSS into every HTML response. Does **not** patch Graylog itself, no
browser extension required.

> [繁體中文說明](README_zh-TW.md)

## Screenshots

### Runtime locale switching — English / 繁體中文 / 日本語

A floating pill at the bottom-right of every page lets each user switch
locale on the fly without reloading Graylog. The initial locale is
auto-detected from `navigator.languages` (zh-Hant → zh-TW, `ja*` → ja,
anything else stays in English) and the choice persists in `localStorage`.

| | |
|---|---|
| **Language toggle on Search page** — floating pill at bottom-right | **Japanese (日本語) — dashboard widget** |
| ![search](images/search_switch_language.png) | ![ja widget](images/jp_widget_language.png) |
| **Japanese (日本語) — pipeline rule editor** | **Traditional Chinese (繁體中文) — same page** |
| ![ja pipeline rule](images/jp_pipeline_rule.png) | ![zh-TW pipeline rule](images/pipeline_rule.png) |

### Other pages

| | |
|---|---|
| **Authentication providers page** | **Pipeline list with rules** |
| ![auth](images/authen.png) | ![pipeline](images/pipeline.png) |
| **Event definition configuration** | **Input configuration editor** |
| ![event definition](images/eventdefinition.png) | ![input edit](images/input_edit.png) |
| **Extractor list for an input** | **Lookup table creation wizard** |
| ![extractor](images/extractor.png) | ![lookup table](images/lookuptable_create.png) |
| **Dashboard widget date-range picker** | |
| ![date picker](images/widget_date_picker.png) | |
| **Extractor list for an input** | **Input configuration editor** |
| ![extractor](images/extractor.png) | ![input edit](images/input_edit.png) |
| **Lookup table creation wizard** | **Dashboard widget date-range picker** |
| ![lookup table](images/lookuptable_create.png) | ![date picker](images/widget_date_picker.png) |

- Target Graylog: **6.0 / 6.1 / 6.2 / 6.3 / 7.0** (tested on 6.3.9 and 7.0.6)
- Approach: Nginx reverse proxy + `sub_filter` injection + client-side DOM translation
- Runtime locale toggle: a floating pill at bottom-right lets users switch between **English / 繁體中文 / 日本語**; the initial locale is auto-detected from `navigator.languages` (zh-Hant → zh-TW, `ja*` → ja, anything else stays in English)
- Coverage (dict 2.9.2 / ja 0.4.1): **4,987 exact-match translations** + **576 regex patterns** in each locale (zh-TW is the source; ja mirrors zh-TW 1:1 — every key present in one locale exists in the other). Covers the full Graylog Open UI plus most Enterprise toast messages, pipeline functions, rule builder, extractor / converter forms (AMQP / Kafka / AWS Kinesis / Syslog / JSON path HTTP), index set management, Data Node migration, certificate authority setup, input setup wizard, Input Diagnosis panel, Change Field Type / Set Profile modals, email notification forms, user search syntax, keyboard shortcuts dialog, server-unavailable dialog, and system log patterns.

### Note on the Japanese translation

The author does **not** read Japanese. The Japanese dictionary was produced
with LLM assistance and then revised against a community style-guide
contributed by Japanese-speaking reviewers. Current conventions:

- Product entities: **入力** (Input) / **出力** (Output) / **エクストラクター** (Extractor) / **ストリーム** (Stream) / **パイプライン** (Pipeline) / **インデックスセット** (Index Set) / **ダッシュボード** (Dashboard) / **ウィジェット** (Widget) / **通知** (Notification) / **イベント定義** (Event definition) / **認証サービス** (Authentication service)
- UI labels are concise noun forms; action prompts use `〜してください`.
- Avoid English-literal phrasings (e.g. `空の場合` → `未選択の場合`, `役立つ説明` → `説明`, `ロールアップ列` → `集計列`).
- Prefer `期間` over `時間範囲` for UI time-range labels.
- Katakana uses long-mark style (`サーバー`, `ユーザー`, `コレクター`, `フィルター`) except `クラスタ` (no mark, per project convention).

Corrections are welcome — please open an issue with the awkward string
and a suggested replacement. See the [reporting guide](CONTRIBUTING.md).

## Quick install

Clone (or refresh) the repo, then run the installer with `bash` (works
regardless of the file's executable bit after `git clone`):

```bash
# Clone fresh, or fast-forward-pull an existing clone — always lands on latest
git clone https://github.com/jasoncheng7115/jt-glogi18n.git 2>/dev/null \
  || git -C jt-glogi18n pull --ff-only
cd jt-glogi18n
sudo bash install.sh
```

Re-running these three lines on the same host is also how you upgrade —
you'll never accidentally install an old cached copy.

The installer auto-detects your environment and chooses the right mode:

| Scenario | What the installer does |
|---|---|
| Nginx not installed | Offers to install via `apt` / `dnf` / `yum` |
| Nginx installed, no Graylog reverse proxy | Writes `/etc/nginx/conf.d/graylog-i18n.conf` for you |
| Nginx installed, Graylog already reverse-proxied | Does **not** touch your config; prints a snippet for you to `include` into your existing `server` block |

Non-interactive (for automation) — either via env vars:

```bash
sudo ASSUME_YES=1 \
     DOMAIN=graylog.example.com \
     BACKEND=127.0.0.1:9000 \
     SSL_CRT=/etc/ssl/certs/graylog.crt \
     SSL_KEY=/etc/ssl/private/graylog.key \
     ./install.sh
```

…or equivalently via CLI flags:

```bash
sudo ./install.sh -y \
     --domain=graylog.example.com \
     --backend=127.0.0.1:9000 \
     --ssl-crt=/etc/ssl/certs/graylog.crt \
     --ssl-key=/etc/ssl/private/graylog.key
```

Other flags: `-v/--verbose`, `-n/--dry-run` (print actions without touching
anything), `--no-color`, `--open-firewall=yes|no` (defaults to `ask`).

### Snippet mode (when you already have a reverse proxy)

If you already front Graylog with Nginx, the installer does **not** touch
your server block. It only:

1. Deploys the static assets to `/opt/jt-glogi18n/static/`
2. Writes a snippet to `/etc/nginx/snippets/graylog-i18n.conf`
3. Prints two manual steps you need to apply:
   - Add `include /etc/nginx/snippets/graylog-i18n.conf;` inside your
     existing Graylog `location / { ... }` block.
   - Add a second location for the static assets:
     ```nginx
     location /graylog-i18n/ {
         alias /opt/jt-glogi18n/static/;
         expires 1h;
         add_header Cache-Control "public, must-revalidate";
     }
     ```
4. Then reload: `sudo nginx -t && sudo systemctl reload nginx`

A complete reference server block lives at `nginx/graylog-i18n.conf`.

## Everyday commands

```bash
sudo ./install.sh              # Install (interactive)
sudo ./install.sh update       # Refresh the dictionary/JS/CSS — no nginx changes
sudo ./install.sh uninstall    # Remove files (asks for confirmation)
sudo ./install.sh rollback     # Restore the previous nginx.conf backup
     ./install.sh status       # Show install state + dict version (nginx -t needs root)
     ./install.sh doctor       # Full environment diagnostic — run this first on a new host
     ./install.sh help         # Usage
```

`update` is the command you run after pulling a new dictionary release —
it only re-copies the static files; `nginx` does not need reloading.
Tell users to hard-reload (Cmd+Shift+R / Ctrl+Shift+R) to skip the 1 h cache.

`doctor` is the fastest way to surface environmental issues before a real
install: it reports OS, init system, Nginx flavor, `http_sub_module`
availability, SELinux state, firewall status, port 80/443 usage, whether
the backend answers, and whether an existing proxy is detected.

## Requirements

- Graylog reachable on `127.0.0.1:9000` (or wherever `BACKEND` points)
- Nginx with `http_sub_module` — either compiled in (official nginx.org,
  Debian `nginx-full` / `nginx-extras`, RHEL family) or as a dynamic
  module at `/usr/share/nginx/modules/ngx_http_sub_filter_module.so`
  (some Debian/Ubuntu splits). The installer detects both.
- Root privileges for install / update / uninstall / rollback
- One of `apt-get` / `dnf` / `yum` / `zypper` / `apk` / `pacman` if you
  want the installer to install Nginx for you
- Optional: `policycoreutils-python-utils` on SELinux-enforcing RHEL-family
  systems so the installer can apply a persistent `httpd_sys_content_t`
  label via `semanage fcontext` (it falls back to `chcon` otherwise)

## File layout

```
jt-glogi18n/
├── install.sh                          # installer / updater / uninstaller
├── nginx/graylog-i18n.conf             # reference server block (for review only)
├── static/
│   ├── graylog-i18n-zh-tw.js           # translation engine + locale toggle
│   ├── graylog-i18n-dict.json          # zh-TW dictionary (source of truth)
│   ├── graylog-i18n-ja.json            # ja dictionary — mirrors zh-TW 1:1
│   ├── graylog-i18n-locales.json       # available locales manifest (en / zh-TW / ja)
│   └── graylog-i18n-patch.css          # font + layout fixes
└── tools/extract-strings.sh            # helper to mine candidate strings from graylog.jar
```

## How the translation works

1. Nginx replaces `</head>` with `<link>` + `<script>` tags pointing at `/graylog-i18n/*`.
2. The JS loads the dictionary for the selected locale (`graylog-i18n-dict.json` for zh-TW or `graylog-i18n-ja.json` for ja), walks every text node, translates by exact match, then regex pattern.
3. A `MutationObserver` keeps new DOM (SPA route changes, async data) translated.
4. Log content, field names, identifiers, JSON payloads, code blocks, search inputs, and Material icon font containers (`material-symbols*` / `material-icons*` — whose text content *is* the glyph) are **excluded** via a two-tier skip list. A `HARD_SKIP_SELECTORS` layer sits above `FORCE_TRANSLATE_SELECTORS` so that icon glyphs inside force-translated Mantine buttons stay untouched.

## Debug

```javascript
localStorage.setItem('graylog-i18n-debug', 'true');
location.reload();

window.__graylogI18n.stats();        // counters
window.__graylogI18n.retranslate();  // manual full-page re-scan
window.__graylogI18n.translations;   // dictionary
window.__graylogI18n.patterns;       // pattern list
```

## Troubleshooting

| Symptom | Likely cause | Fix |
|---|---|---|
| Dictionary edited but UI unchanged | 1 h static cache / browser cache | Cmd+Shift+R |
| Script not injected | Backend responding gzip | Check `proxy_set_header Accept-Encoding "";` |
| Script blocked (401/CSP) | Graylog CSP not overridden | Check `proxy_hide_header Content-Security-Policy` + new `add_header` |
| Specific string not translated | Not in dict or text node is split | Open an issue with an Elements screenshot |
| Log content was translated | Skip-list gap | Open an issue with the container's outer HTML |
| Installer aborts with "nginx -t already fails" | Pre-existing broken `nginx.conf` (undefined `log_format`, missing `include`, etc.) | Fix the existing config first, then re-run |
| `HTTP 403` on `/graylog-i18n/*` on RHEL/Rocky | SELinux blocking file reads | `getenforce` → if Enforcing: `sudo restorecon -Rv /opt/jt-glogi18n/`; installer handles this when `policycoreutils-python-utils` is available |
| Browser can't reach the server | firewalld / ufw / nftables dropping 80/443 | Re-run with `--open-firewall=yes`, or add rules manually |
| Installer says `http_sub_module: NO` | Wrong Nginx package | Debian: `nginx-full` or `nginx-extras`; RHEL: use the nginx.org repo |
| `502 Bad Gateway` | Backend (`$BACKEND`) not listening | `./install.sh doctor` — backend reachability is checked there |
| Installer ran but UI still English | `server_name` in our config doesn't match the URL you're visiting | Check `/etc/nginx/conf.d/graylog-i18n.conf` — the `server_name` must match the browser's URL host |

## Uninstall

```bash
sudo ./install.sh uninstall
```

Removes `/opt/jt-glogi18n/`, `/etc/nginx/conf.d/graylog-i18n.conf` and the
snippet file (if present). Nginx is reloaded **only when `nginx -t` passes**
after the removal — if it doesn't, the installer prints a warning and
leaves Nginx alone for you to inspect. If you used snippet-mode, remove
the `include` line from your existing server block before uninstalling,
otherwise `nginx -t` will fail on the dangling include.

## Companion project: jt-glogarch

For a complete Traditional-Chinese Graylog experience, pair this UI pack
with **[jt-glogarch](../jt-glogarch/)** — our Graylog Open archive &
restore tool. jt-glogarch adds long-term log archival, on-disk integrity
verification, and one-click restore back into Graylog, with its own
localised web UI. Together they give Graylog Open deployments two
features that are otherwise Enterprise-only: Traditional-Chinese UI
(this project) and compliant log archival (jt-glogarch).

## License

Licensed under the **Apache License, Version 2.0**. See [LICENSE](LICENSE).

Copyright (c) Jason Cheng ([Jason Tools](https://jason.tools)).

Upstream repository: <https://github.com/jasoncheng7115/jt-glogi18n> — see
the [changelog](CHANGELOG.md) for release history.
