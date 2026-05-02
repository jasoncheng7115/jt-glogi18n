# jt-glogi18n Test Checklist

Run through this list before every deploy. All testing should happen on a
**clean Graylog instance** (or local docker) to avoid contaminating
production. [Chinese version](TESTING_zh-tw.md).

Copy this list into an issue description and tick as you go.

---

## 0. Setup

- [ ] Latest dict / JS / CSS / `install.sh` checked out
- [ ] Test host reachable: `ssh root@<test-host>` (install/update/uninstall testing)
- [ ] Production host reachable: `ssh root@<prod-host>` (dict push only)
- [ ] Browsers: latest Chrome + Firefox with DevTools open
- [ ] Test URL: `https://log4.jason.tools/`
- [ ] Current remote dict version:
  ```bash
  ssh root@<prod-host> \
      'python3 -c "import json;print(json.load(open(\"/opt/jt-glogi18n/static/graylog-i18n-dict.json\"))[\"_meta\"][\"version\"])"'
  ```

---

## 1. Language files (dict + locales + JS)

### 1.1 Format & syntax

- [ ] `python3 -m json.tool static/graylog-i18n-dict.json > /dev/null` (dict is valid JSON)
- [ ] `python3 -m json.tool static/graylog-i18n-locales.json > /dev/null` (locales valid)
- [ ] `node --check static/graylog-i18n-zh-tw.js` (JS syntax OK)
- [ ] `_meta.version` bumped (must differ from the last deployed version)
- [ ] `_meta.last_updated` = today
- [ ] `_meta.locale` = `zh-TW`

### 1.2 Dictionary health

- [ ] No duplicate keys (JSON silently keeps the last; earlier translations vanish):
  ```bash
  grep -oE '"[^"]+"\s*:' static/graylog-i18n-dict.json | sort | uniq -d | head
  ```
- [ ] None of the forbidden short words appear as standalone keys:
  `the`, `not`, `No`, `Open`, `a`, `and`, `Every`, `of`, `in`
  ```bash
  grep -E '"(the|not|No|Open|a|and|Every|of|in)"\s*:' static/graylog-i18n-dict.json
  # expect: no output
  ```
- [ ] Graylog field names are NOT translated: `Domain`, `action`,
  `direction`, `source`, `timestamp`, `DCDomain`, `Active`
- [ ] Role names are NOT translated: `Admin`, `Reader`,
  `Forwarder System (Internal)`
- [ ] `Grok pattern` / `Grok patterns` kept verbatim
- [ ] Product names kept verbatim: `Graylog`, `OpenSearch`,
  `Elasticsearch`, `Sidecar`, `Data Node`, `Marketplace`
- [ ] No dictionary key has trailing whitespace (the engine trims before lookup):
  ```bash
  grep -E '" +":\s*"' static/graylog-i18n-dict.json
  # expect: no output
  ```

### 1.3 Pattern regex

- [ ] Every new pattern validated in `regex101.com` or `python3 -c "import re..."`
- [ ] `^` and `$` anchors present (avoid accidental partial matches)
- [ ] Use `$1`, `$2` (JS style) — not `\1`, `\2` (Python)
- [ ] Double-escape backslashes: in JSON write `\\d+`, at runtime becomes `\d+`

### 1.4 Fragmented DOM coverage

When a sentence is split by `<strong>`, `<span>`, `<em>`, `<a>`, **each
fragment needs its own dictionary entry**:

- [ ] `Welcome to` + `Graylog` → two separate keys
- [ ] `Data. Insights.` + `Answers.` → two separate keys
- [ ] Other split slogans / titles you encounter

### 1.5 Versioning

- [ ] Dict-only change → PATCH bump (`1.1.0` → `1.1.1`)
- [ ] JS engine behaviour change → MINOR bump (`1.1.x` → `1.2.0`)
- [ ] Breaking change → MAJOR bump

---

## 2. Nginx configuration

### 2.1 Prerequisites

- [ ] `nginx -V 2>&1 | grep -q -- '--with-http_sub_module'` returns 0
- [ ] `nginx -t` passes

### 2.2 Required proxy directives

- [ ] `proxy_set_header Accept-Encoding "";` (forces plain-text upstream)
- [ ] `proxy_hide_header Content-Security-Policy;`
- [ ] `add_header Content-Security-Policy "... 'unsafe-eval' 'unsafe-inline' ..."`
- [ ] `proxy_set_header X-Graylog-Server-URL $scheme://$server_name/;`
- [ ] `proxy_set_header Host $host;`
- [ ] `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`
- [ ] `proxy_set_header X-Forwarded-Proto $scheme;`
- [ ] `proxy_http_version 1.1;`
- [ ] `proxy_read_timeout` ≥ 300 (long-running queries)
- [ ] `client_max_body_size` ≥ 50M (Content Pack uploads)

### 2.3 sub_filter directives

- [ ] `sub_filter_types text/html;` (only HTML)
- [ ] `sub_filter_once on;` (prevent double replacement)
- [ ] `sub_filter '</head>' '<link ...><script ...></head>'` present

### 2.4 Static asset location

- [ ] `location /graylog-i18n/ { alias /opt/jt-glogi18n/static/; }`
- [ ] `expires 1h;`
- [ ] `add_header Cache-Control "public, must-revalidate";`

### 2.5 TLS (if enabled)

- [ ] `listen 443 ssl;` and `listen [::]:443 ssl;` (IPv4 + IPv6)
- [ ] `ssl_protocols TLSv1.2 TLSv1.3;`
- [ ] Cert / key files owned by root, mode 0600
- [ ] `http2 on;` (or legacy `listen 443 ssl http2;`)

### 2.6 curl smoke tests

```bash
DOMAIN=log4.jason.tools
```

- [ ] CSP override visible:
  ```bash
  curl -sIk https://$DOMAIN/ | grep -i content-security-policy
  # must include unsafe-eval and unsafe-inline
  ```
- [ ] Script injection confirmed:
  ```bash
  curl -sk https://$DOMAIN/ | grep graylog-i18n-zh-tw.js
  # must emit one <script ...></script> line
  ```
- [ ] Dict downloadable as JSON:
  ```bash
  curl -sIk https://$DOMAIN/graylog-i18n/graylog-i18n-dict.json | head -5
  # Content-Type: application/json (or text/plain; charset=utf-8)
  ```
- [ ] Dict version matches:
  ```bash
  curl -sk https://$DOMAIN/graylog-i18n/graylog-i18n-dict.json \
    | python3 -c "import json,sys;print(json.load(sys.stdin)['_meta']['version'])"
  ```
- [ ] Graylog REST API still functional:
  ```bash
  curl -sk https://$DOMAIN/api/system | head
  ```

---

## 3. install.sh

### 3.1 Basic commands (no root needed)

- [ ] `./install.sh version` prints `jt-glogi18n installer v1.2.x`
- [ ] `./install.sh help` shows the full usage
- [ ] `./install.sh status` prints install state (OS, nginx, deployed files)
- [ ] `./install.sh doctor` runs the full environment diagnostic
- [ ] `sh install.sh version` (non-bash) re-execs as bash and prints version

### 3.2 Syntax & portability

- [ ] `bash -n install.sh` passes
- [ ] `shellcheck install.sh` has no serious warnings (if installed)
- [ ] `doctor` runs under bash 3.2 (macOS default) — validates UTF-8 + `set -u` compatibility
- [ ] Runs under bash 5+ on Linux

### 3.3 Input validation

- [ ] Non-root install aborts: `Must run as root`
- [ ] Missing source files: `Missing source file: ...`
- [ ] Broken dict JSON: `is not valid JSON`, script exits
- [ ] `--domain "foo bar"` rejected: `Invalid DOMAIN format`
- [ ] `--backend "no-port-here"` rejected: `Invalid BACKEND format`
- [ ] `ASSUME_YES=1` without `DOMAIN`: `DOMAIN is required when ASSUME_YES=1`
- [ ] `--ssl-crt=/no/such/file` → `SSL certificate not found`

### 3.4 Install — scenario A (no nginx)

On a clean host:

- [ ] nginx is detected as missing, installer offers to install
- [ ] Correct package manager chosen:
  - [ ] Ubuntu 22.04 / Debian 12 → `apt-get install nginx`
  - [ ] RHEL 9 / Rocky 9 / Alma 9 → `dnf install nginx`
  - [ ] RHEL 7 → `yum install nginx`
  - [ ] openSUSE → `zypper install nginx`
  - [ ] Alpine → `apk add nginx`
  - [ ] Arch → `pacman -S nginx`
- [ ] After install: `nginx -V | grep sub_filter` present
- [ ] Service running: `systemctl is-active nginx` = `active`

### 3.5 Install — scenario B (nginx present, no Graylog proxy)

- [ ] nginx detected, NOT reinstalled
- [ ] `/etc/nginx/conf.d/graylog-i18n.conf` written
- [ ] Existing conf (if any) backed up to `/opt/jt-glogi18n/backups/TIMESTAMP/`
- [ ] Static assets deployed to `/opt/jt-glogi18n/static/` (4 files)
- [ ] Permissions: dir 0755, files 0644
- [ ] `nginx -t` passes
- [ ] `systemctl reload nginx` succeeds
- [ ] Post-install curl check: `graylog-i18n-zh-tw.js` detected in HTML

### 3.6 Install — scenario C (existing Graylog proxy)

Prepare an nginx conf containing `X-Graylog-Server-URL` or
`proxy_pass ...:9000`:

- [ ] Installer detects existing proxy (warn + snippet mode)
- [ ] Existing nginx conf is **NOT** modified
- [ ] Snippet written to `/etc/nginx/snippets/graylog-i18n.conf`
- [ ] Static assets still deployed to `/opt/jt-glogi18n/static/`
- [ ] Manual `include` instructions clearly printed

### 3.7 Flags / environment

- [ ] `--yes` / `-y` / `ASSUME_YES=1` → no prompts at all
- [ ] `--dry-run` / `-n` → every action prefixed `[dry-run]`, no files changed
- [ ] `--no-color` / `NO_COLOR=1` → plain output, no ANSI
- [ ] `--verbose` / `-v` → `exec:`, `os:`, `init:` debug lines visible
- [ ] `--domain=... --backend=... --ssl-crt=... --ssl-key=...` all honoured
- [ ] Fully unattended:
  ```bash
  sudo ASSUME_YES=1 DOMAIN=graylog.test.local \
       SSL_CRT=... SSL_KEY=... ./install.sh
  ```
  completes without any prompt

### 3.8 SELinux (RHEL / Rocky)

- [ ] `getenforce` = `Enforcing` → context auto-applied
- [ ] `ls -Z /opt/jt-glogi18n/static/` — every file shows `httpd_sys_content_t`
- [ ] `getsebool httpd_can_network_connect` = `on`
- [ ] If SELinux disabled → step is silently skipped, no error

### 3.9 Firewall

#### firewalld (RHEL family)

- [ ] `firewall-cmd --state` = `running` → prompts to open port 80
- [ ] HTTPS mode → also prompts for 443
- [ ] Answer yes → `firewall-cmd --list-services` includes `http` / `https`
- [ ] `--open-firewall=no` → no prompt, no change

#### ufw (Ubuntu / Debian)

- [ ] `ufw status` = `active` → prompts
- [ ] Answer yes → `ufw status` shows `80/tcp ALLOW` (and 443 if HTTPS)
- [ ] Inactive ufw → skipped silently

### 3.10 Port conflict detection

- [ ] Pre-occupy port 80: `python3 -m http.server 80 &`
- [ ] Run install → installer warns about port 80 conflict
- [ ] If the occupier is nginx itself (during reinstall) → NOT flagged

### 3.11 Backend reachability

- [ ] Graylog reachable → `ok` shows HTTP 200/302 etc.
- [ ] Graylog stopped → `warn`, install continues
- [ ] Totally wrong backend → `warn`, does not abort

### 3.12 Update

- [ ] `sudo ./install.sh update` only re-copies the 4 static files
- [ ] Does NOT touch `/etc/nginx/conf.d/graylog-i18n.conf`
- [ ] Does NOT reload nginx
- [ ] Dict version on host matches source

### 3.13 Uninstall

- [ ] Prompts per item (can say no to keep)
- [ ] Yes to everything → `/opt/jt-glogi18n/static/` removed
- [ ] `/etc/nginx/conf.d/graylog-i18n.conf` removed
- [ ] `/etc/nginx/snippets/graylog-i18n.conf` removed
- [ ] Backup directory preserved by default (answer `n`)
- [ ] After reload, the UI is back to English
- [ ] Subsequent `./install.sh status` shows `not installed`

### 3.14 Rollback

- [ ] Install twice (two backups exist under `/opt/jt-glogi18n/backups/`)
- [ ] `sudo ./install.sh rollback` restores the previous conf
- [ ] `nginx -t` still passes after rollback
- [ ] Reload and confirm the restored config is live

### 3.15 Failure recovery

- [ ] Corrupt `/etc/nginx/conf.d/graylog-i18n.conf` (insert junk)
- [ ] Re-run `./install.sh install` → `nginx -t` fails
- [ ] Installer offers to restore from backup → answer yes
- [ ] `nginx -t` passes after restore, install resumes

### 3.16 Log

- [ ] After a root run: `/var/log/jt-glogi18n-install.log` exists
- [ ] Permissions 0640
- [ ] Contains `[RUN]`, `[STEP]`, `[OK]`, `[WARN]`, `[ERR]` lines
- [ ] Re-runs append (do not truncate)

---

## 4. Browser end-to-end

### 4.1 Post-deploy verification (hard-reload: Cmd+Shift+R)

- [ ] Top navigation shows: 搜尋 / 串流 / 警報 / 看板 / 系統
- [ ] Bottom-right floating pill shows `中` (when zh-TW active)
- [ ] Clicking the pill shows menu with `English` and `繁體中文`
- [ ] Switch to `English` → reload, UI in English; pill shows `EN`
- [ ] Switch back to `繁體中文` → translations return
- [ ] Drag the pill to the top-left → position persists after reload
- [ ] `localStorage` has `graylog-i18n-locale` and `graylog-i18n-toggle-pos`

### 4.2 SPA navigation

- [ ] Search → Streams → Alerts → every page is Chinese; no English flash lasting > 1 s
- [ ] Browser back / forward → Chinese remains
- [ ] New tab + fresh login → login page is in Chinese

### 4.3 Translation boundaries

#### Must translate

- [ ] Login page: `Welcome to Graylog`, `DATA. INSIGHTS. ANSWERS.`
- [ ] Stream editor title: `編輯串流`
- [ ] Stream hint: `不要將符合此串流的訊息指派到「<any stream name>」。`
- [ ] Search bar placeholder (`Type your search query…`) in Chinese (it lives inside `ace_placeholder` which is force-translated)

#### Must NOT translate

- [ ] Log message bodies in search results stay in the original language
- [ ] All field names in the left sidebar (`action`, `source`, `timestamp`, `direction`, `Domain`, `DCDomain`) stay in English
- [ ] The `<fieldname> = <type>` header in the Mantine right-click menu stays in English
- [ ] Grok pattern definitions in the Grok editor stay untouched
- [ ] Material icons (`<span>warning</span>`) render as glyphs, not the word "warning"

### 4.4 Input behaviour

- [ ] Typing an English query in the search bar — characters appear unchanged
- [ ] Typing in Ace editor (pipelines, Grok rules) — English words not auto-converted
- [ ] `<textarea>` / `<input>` prefilled values stay English

### 4.5 Visualisations

- [ ] Plotly chart hover toolbar (Zoom / Pan / Reset axes / Download plot) in Chinese
- [ ] Chart date / numeric ticks stay original
- [ ] Dashboard widget titles and type labels in Chinese

### 4.6 Debug helpers

```javascript
localStorage.setItem('graylog-i18n-debug', 'true'); location.reload();
```

- [ ] Console shows `[i18n]` log lines
- [ ] `window.__graylogI18n.stats()` returns a sensible `{translated, skipped, patterns, elapsed}` object
- [ ] `window.__graylogI18n.retranslate()` triggers a full rescan
- [ ] `window.__graylogI18n.translations.size` > 2000

---

## 5. Regression (historical bugs)

- [ ] `18 in 11 out` counter — `in` is NOT translated to 於
- [ ] `8 messages in 2 seconds` — `in` IS conditionally translated
- [ ] Editor title `CEF_UDP_32202` — NOT flagged as identifier
- [ ] UI label `User recipient(s)` — translates correctly (function-signature
      detector removed)
- [ ] Text containing `\n` — whitespace normalization still finds the dict key
- [ ] Fast SPA transitions — no lost MutationObserver batches
- [ ] `Welcome to` / `Graylog` split fragments — both translated
- [ ] `Data. Insights.` (dict key has no trailing space, DOM does) — still matches
- [ ] Pipeline stage titles `Stage 0` / `Stage 1` → `階段 0` / `階段 1`
- [ ] `2 years ago` / `3 minutes ago` — time patterns work
- [ ] `Throughput: In 123 / Out 456 msg/s` pattern hits
- [ ] `was` / `shared` / `unshared` — conditional fragment translation
      (requires the prev / next sibling context)
- [ ] Toast ``Request to start input '<name>' was sent successfully.`` — pattern hits
- [ ] `read-only-value-col` form values (user profile start page) ARE translated

---

## 6. Deploy verification (remote)

```bash
DOMAIN=log4.jason.tools
PROD=root@<prod-host>
TEST=root@<test-host>
```

- [ ] File mtime recent on both hosts:
  ```bash
  ssh $PROD 'ls -la /opt/jt-glogi18n/static/'
  ssh $TEST 'ls -la /opt/jt-glogi18n/static/'
  ```
- [ ] Dict version matches on both:
  ```bash
  for H in $PROD $TEST; do
      ssh $H 'python3 -c "import json;print(json.load(open(\"/opt/jt-glogi18n/static/graylog-i18n-dict.json\"))[\"_meta\"][\"version\"])"'
  done
  ```
- [ ] Browser sees new version (bust the 1 h nginx cache if needed):
  ```bash
  curl -sk https://$DOMAIN/graylog-i18n/graylog-i18n-dict.json \
    | python3 -c "import json,sys;print(json.load(sys.stdin)['_meta']['version'])"
  ```
- [ ] nginx config syntax: `ssh $PROD 'nginx -t'` passes
- [ ] Graylog service unaffected: `ssh $PROD 'systemctl is-active graylog-server'` = `active`

---

## 7. Acceptance criteria

**Ready to deploy (every release):**
- Section 1.1, 1.2, 1.5 all pass
- Section 2.1, 2.6 first three items pass
- Section 4.1, 4.3 "must translate" / "must not translate" all pass
- Section 6 all pass

**Ready to ship `install.sh`:**
- Section 3.1, 3.3 all pass
- Section 3.4, 3.5, 3.6 each tested against at least one real OS
- Section 3.12, 3.13 each exercised once

**Major version bump (MINOR+):**
- Everything above passes
