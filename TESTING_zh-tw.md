# jt-glogi18n 測試清單

新版部署前請逐項檢查。所有測試建議在 **乾淨的 Graylog 實例**（或本機 docker）做，
避免污染正式環境。[英文版](TESTING.md)。

使用建議:把本清單複製到 issue 敘述,邊測邊打勾。

---

## 0. 測試前準備

- [ ] 取得新字典 / JS / CSS / install.sh 最新版
- [ ] 測試主機：`ssh root@<prod-host>` 可連線（或 staging 機）
- [ ] 瀏覽器：Chrome 最新版、Firefox 最新版；DevTools 開啟
- [ ] 測試 URL：`https://log4.jason.tools/`
- [ ] 已知遠端目前字典版本：
  ```bash
  ssh root@<prod-host> \
      'python3 -c "import json;print(json.load(open(\"/opt/jt-glogi18n/static/graylog-i18n-dict.json\"))[\"_meta\"][\"version\"])"'
  ```

---

## 1. 語言檔（dict + locales + JS）

### 1.1 格式與語法

- [ ] `python3 -m json.tool static/graylog-i18n-dict.json > /dev/null`（dict JSON 合法）
- [ ] `python3 -m json.tool static/graylog-i18n-locales.json > /dev/null`（locales JSON 合法）
- [ ] `node --check static/graylog-i18n-zh-tw.js` 或 `bash -n` 對應檢查（JS 語法 OK）
- [ ] `_meta.version` 已 bump（不能和上次部署同一版本）
- [ ] `_meta.last_updated` = 今日
- [ ] `_meta.locale` = `zh-TW`

### 1.2 字典健康度

- [ ] 沒有重複 key（JSON 允許但後蓋前，會靜默丟翻譯）：
  ```bash
  python3 -c "
  import json, collections
  d=json.load(open('static/graylog-i18n-dict.json'))
  raw=open('static/graylog-i18n-dict.json').read()
  # 自己寫一個簡單 duplicate detector 或用 dict 解析
  "
  ```
  或 `grep -oE '"[^"]+"\s*:' static/graylog-i18n-dict.json | sort | uniq -d | head`
- [ ] 禁用短詞**未**出現為獨立 translations key：`the`, `not`, `No`, `Open`, `a`, `and`, `Every`, `of`, `in`
  ```bash
  grep -E '"(the|not|No|Open|a|and|Every|of|in)"\s*:' static/graylog-i18n-dict.json
  # 應無輸出
  ```
- [ ] Graylog 欄位名**未**被翻譯：`Domain`, `action`, `direction`, `source`, `timestamp`, `DCDomain`, `Active`
- [ ] 角色名**未**被翻譯：`Admin`, `Reader`, `Forwarder System (Internal)`
- [ ] `Grok pattern` / `Grok patterns` 維持原文
- [ ] 產品名維持原文：`Graylog`, `OpenSearch`, `Elasticsearch`, `Sidecar`, `Data Node`, `Marketplace`
- [ ] 字典 key 不含**尾端空白**（`translateTextNode` 會先 `trim()`）：
  ```bash
  grep -E '" +":\s*"' static/graylog-i18n-dict.json
  # 應無輸出
  ```

### 1.3 Pattern 正規式

- [ ] 每個新 pattern 在 `regex101.com` 或 `python3 -c "import re; print(re.match(...))"` 驗過
- [ ] `^` 與 `$` 有用（避免部分比對造成誤譯）
- [ ] 使用 `$1`, `$2` 取代 Python 的 `\1`（JS 格式）
- [ ] 雙斜線正確跳脫：JSON 裡 `\\d+`，JS 拿到後變 `\d+`

### 1.4 拆碎 DOM fragment 覆蓋

常見被 `<strong>`, `<span>`, `<em>`, `<a>` 拆開的句子，**兩段都要翻**：

- [ ] `Welcome to` + `Graylog` → 兩段獨立 key
- [ ] `Data. Insights.` + `Answers.` → 兩段獨立 key
- [ ] 其他登入頁 slogan 或標題有拆 span 的情況

### 1.5 版本升版規則

- [ ] 只改字典 → PATCH（1.0.71 → 1.0.72）
- [ ] 改 JS 引擎邏輯 → MINOR（1.0.x → 1.1.0）
- [ ] 重大 breaking → MAJOR

---

## 2. Nginx 設定

### 2.1 前置

- [ ] `nginx -V 2>&1 | grep -q -- '--with-http_sub_module'` → 0（有 sub_filter 模組）
- [ ] `nginx -t` 通過

### 2.2 反向代理必備

- [ ] `proxy_set_header Accept-Encoding "";`（清 gzip 讓後端回明文）
- [ ] `proxy_hide_header Content-Security-Policy;`
- [ ] `add_header Content-Security-Policy "... 'unsafe-eval' 'unsafe-inline' ..."`
- [ ] `proxy_set_header X-Graylog-Server-URL $scheme://$server_name/;`
- [ ] `proxy_set_header Host $host;`
- [ ] `proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;`
- [ ] `proxy_set_header X-Forwarded-Proto $scheme;`
- [ ] `proxy_http_version 1.1;`
- [ ] `proxy_read_timeout` ≥ 300（長查詢不會斷）
- [ ] `client_max_body_size` ≥ 50M（Content Pack 上傳）

### 2.3 sub_filter 設定

- [ ] `sub_filter_types text/html;`（只對 HTML 做替換）
- [ ] `sub_filter_once on;`（避免多次替換）
- [ ] sub_filter 替換 `</head>` 插入 `<link>` + `<script>`

### 2.4 靜態資源 location

- [ ] `location /graylog-i18n/ { alias /opt/jt-glogi18n/static/; }` 存在
- [ ] `expires 1h`
- [ ] `add_header Cache-Control "public, must-revalidate"`

### 2.5 TLS（若啟用）

- [ ] `listen 443 ssl;` + `listen [::]:443 ssl;`（IPv4 + IPv6）
- [ ] `ssl_protocols TLSv1.2 TLSv1.3;`
- [ ] 憑證與私鑰檔權限正確（root:root 0600）
- [ ] `http2 on;` 或舊語法 `listen 443 ssl http2;`

### 2.6 curl 實測

```bash
DOMAIN=log4.jason.tools
```

- [ ] CSP 覆蓋：
  ```bash
  curl -sIk https://$DOMAIN/ | grep -i content-security-policy
  # 應出現 unsafe-eval / unsafe-inline
  ```
- [ ] 腳本注入：
  ```bash
  curl -sk https://$DOMAIN/ | grep graylog-i18n-zh-tw.js
  # 應回傳 1 行 <script ...></script>
  ```
- [ ] 字典可下載且為 JSON：
  ```bash
  curl -sIk https://$DOMAIN/graylog-i18n/graylog-i18n-dict.json | head -5
  # Content-Type: application/json（或 text/plain; charset=utf-8 也可）
  ```
- [ ] 字典版本符合：
  ```bash
  curl -sk https://$DOMAIN/graylog-i18n/graylog-i18n-dict.json \
    | python3 -c "import json,sys;print(json.load(sys.stdin)['_meta']['version'])"
  ```
- [ ] Graylog REST API 仍可用（沒壞）：
  ```bash
  curl -sk https://$DOMAIN/api/system | head
  ```

---

## 3. install.sh

### 3.1 基本指令（不需 root）

- [ ] `./install.sh version` → 顯示 `jt-glogi18n installer v1.2.x`
- [ ] `./install.sh help` → 顯示完整 usage
- [ ] `./install.sh status` → 顯示狀態（OS、nginx、已安裝檔）
- [ ] `./install.sh doctor` → 顯示環境診斷
- [ ] `sh install.sh version`（非 bash）→ 自動 re-exec 為 bash 後顯示版本

### 3.2 語法與可攜性

- [ ] `bash -n install.sh` 通過
- [ ] `shellcheck install.sh` 無重大警告（若有安裝）
- [ ] 在 bash 3.2（macOS 內建）可跑 doctor（驗證 UTF-8 / set -u 相容）
- [ ] 在 bash 5+（Linux）亦可跑

### 3.3 輸入驗證

- [ ] 非 root 執行 install → `Must run as root`
- [ ] 來源目錄缺檔 → `Missing source file: ...`
- [ ] dict JSON 壞掉 → `is not valid JSON`，中止
- [ ] `--domain "foo bar"` → `Invalid DOMAIN format`
- [ ] `--backend "no-port-here"` → `Invalid BACKEND format`
- [ ] `ASSUME_YES=1` 未給 DOMAIN → `DOMAIN is required when ASSUME_YES=1`
- [ ] `--ssl-crt=/no/such/file` → `SSL certificate not found`

### 3.4 Install — 情境 A（無 nginx）

在乾淨 OS 上：

- [ ] 偵測到無 nginx，詢問是否自動安裝
- [ ] 依套件管理器選擇：
  - [ ] Ubuntu 22.04 / Debian 12 → `apt-get install nginx`
  - [ ] RHEL 9 / Rocky 9 / Alma 9 → `dnf install nginx`
  - [ ] RHEL 7 → `yum install nginx`
  - [ ] openSUSE → `zypper install nginx`
  - [ ] Alpine → `apk add nginx`
  - [ ] Arch → `pacman -S nginx`
- [ ] 安裝完成後 `nginx -V | grep sub_filter` 有
- [ ] 服務已啟動：`systemctl is-active nginx` = active

### 3.5 Install — 情境 B（有 nginx、無 Graylog proxy）

- [ ] 偵測到 nginx 存在，不重裝
- [ ] 寫入 `/etc/nginx/conf.d/graylog-i18n.conf`
- [ ] 寫入前先備份（若已存在）到 `/opt/jt-glogi18n/backups/TIMESTAMP/`
- [ ] 靜態檔部署到 `/opt/jt-glogi18n/static/`（4 個檔）
- [ ] 檔案權限：目錄 0755、檔案 0644
- [ ] `nginx -t` 通過
- [ ] `reload` 成功（`systemctl reload nginx`）
- [ ] 安裝後 curl 驗證：注入偵測到 `graylog-i18n-zh-tw.js`

### 3.6 Install — 情境 C（已有 Graylog proxy）

預先建立一個既有 nginx conf 包含 `X-Graylog-Server-URL` 或 `proxy_pass ...:9000`：

- [ ] 偵測到既有 proxy（warn + snippet 模式）
- [ ] **不修改**既有 nginx conf
- [ ] snippet 寫入 `/etc/nginx/snippets/graylog-i18n.conf`
- [ ] 靜態檔仍部署到 `/opt/jt-glogi18n/static/`
- [ ] 列印清楚的手動 `include` 指示

### 3.7 Flags / 環境變數

- [ ] `--yes` / `-y` / `ASSUME_YES=1` → 無任何提示
- [ ] `--dry-run` / `-n` → 所有 `[dry-run]` 前綴，檔案未實際建立
- [ ] `--no-color` / `NO_COLOR=1` → 輸出無 ANSI 碼
- [ ] `--verbose` / `-v` → 顯示 `exec:` / `os:` / `init:` 等除錯
- [ ] `--domain=foo --backend=host:port --ssl-crt=... --ssl-key=...` 全部生效
- [ ] 非互動一次到位：
  ```bash
  sudo ASSUME_YES=1 DOMAIN=graylog.test.local \
       SSL_CRT=... SSL_KEY=... ./install.sh
  ```
  完整無需任何輸入

### 3.8 SELinux（RHEL / Rocky）

- [ ] `getenforce` = `Enforcing` → 安裝時自動套 context
- [ ] `ls -Z /opt/jt-glogi18n/static/` 每個檔含 `httpd_sys_content_t`
- [ ] `getsebool httpd_can_network_connect` = `on`
- [ ] 未啟用 SELinux 時略過不中斷

### 3.9 Firewall

#### firewalld（RHEL 系）

- [ ] `firewall-cmd --state` = running → 詢問是否開 80
- [ ] HTTPS 模式 → 也詢問 443
- [ ] 答 yes → `firewall-cmd --list-services` 含 `http` / `https`
- [ ] `--open-firewall=no` → 不詢問不開

#### ufw（Ubuntu / Debian）

- [ ] `ufw status` = active → 詢問
- [ ] 答 yes → `ufw status` 顯示 `80/tcp ALLOW`（與 443 若有）
- [ ] 未啟用 ufw → 略過

### 3.10 Port 衝突偵測

- [ ] 安裝前先跑 `python3 -m http.server 80`（佔用 80）
- [ ] 執行 install → 偵測到衝突 + warn
- [ ] 若 port 80 是 nginx 自己持有（重跑安裝） → 忽略不 warn

### 3.11 後端可達性

- [ ] Graylog 可連線 → `ok` 顯示 HTTP 200/302 等
- [ ] 關閉 Graylog → `warn` 但安裝繼續
- [ ] 完全錯誤的 backend → `warn`，不中斷

### 3.12 Update

- [ ] `sudo ./install.sh update` 只複製 4 個靜態檔
- [ ] **不動** `/etc/nginx/conf.d/graylog-i18n.conf`
- [ ] **不 reload** nginx
- [ ] 遠端字典版本與來源一致

### 3.13 Uninstall

- [ ] 逐項詢問（可拒絕保留）
- [ ] 全 yes → `/opt/jt-glogi18n/static/` 消失
- [ ] `/etc/nginx/conf.d/graylog-i18n.conf` 消失
- [ ] `/etc/nginx/snippets/graylog-i18n.conf` 消失
- [ ] 備份目錄預設保留（預設 no）
- [ ] nginx reload 後頁面回英文
- [ ] 再跑 `./install.sh status` → `not installed`

### 3.14 Rollback

- [ ] 先安裝兩次（產生 `/opt/jt-glogi18n/backups/TIMESTAMP/`）
- [ ] `sudo ./install.sh rollback` → 還原上一份
- [ ] 還原後 `nginx -t` 通過
- [ ] 重新 reload 後設定生效

### 3.15 失敗復原

- [ ] 手動破壞 `/etc/nginx/conf.d/graylog-i18n.conf`（加進一個亂字）
- [ ] 重跑 `./install.sh install` → `nginx -t` 失敗
- [ ] 提示還原備份 → 答 yes
- [ ] 還原後 `nginx -t` 通過，安裝繼續

### 3.16 Log

- [ ] 以 root 執行後 `/var/log/jt-glogi18n-install.log` 存在
- [ ] 權限 0640
- [ ] 內容含 `[RUN]`, `[STEP]`, `[OK]`, `[WARN]`, `[ERR]` 行
- [ ] 多次執行會 append 不會覆蓋

---

## 4. 瀏覽器 end-to-end

### 4.1 部署後驗證（Cmd+Shift+R 強制重整）

- [ ] 頂部導覽顯示：搜尋 / 串流 / 警報 / 看板 / 系統
- [ ] 右下角懸浮按鈕顯示「中」（繁中狀態）
- [ ] 點懸浮按鈕 → 選單顯示「English」+「繁體中文」
- [ ] 切 English → 重載後顯示英文；懸浮按鈕變「EN」
- [ ] 切回繁體中文 → 翻譯復原
- [ ] 拖曳懸浮按鈕到左上 → 重載後位置仍在
- [ ] `localStorage` 有 `graylog-i18n-locale` / `graylog-i18n-toggle-pos`

### 4.2 SPA 路由切換

- [ ] 從 Search 切到 Streams 切到 Alerts → 每頁都是中文，無英文閃現持續 > 1s
- [ ] 瀏覽器返回 / 前進 → 中文維持
- [ ] 開新分頁重登入 → 登入頁即為中文

### 4.3 翻譯邊界

#### 必須翻譯

- [ ] 登入頁：`Welcome to Graylog`, `DATA. INSIGHTS. ANSWERS.`
- [ ] Stream 編輯頁標題：`編輯串流`
- [ ] Stream 說明：`不要將符合此串流的訊息指派到「<任意名稱>」。`
- [ ] 搜尋列 placeholder：`Type your search query…` → 中文（位於 ace_placeholder 白名單）

#### 必須**不**翻譯

- [ ] Search 結果的 log 訊息內容保留原文
- [ ] 左側 Field list 所有欄位名（`action`, `source`, `timestamp`, `direction`, `Domain`, `DCDomain`）保留英文
- [ ] Mantine 右鍵欄位選單頂端的「`欄位名 = 型別`」列保留原文
- [ ] Grok pattern 編輯器中的 pattern 原文不動
- [ ] Material icons（`<span>warning</span>`）顯示為圖示而非「warning」文字

### 4.4 輸入行為

- [ ] 搜尋欄輸入查詢句子 → 每個字元正確出現、不被替換
- [ ] Ace editor（pipeline 編輯、Grok 編輯）輸入英文單字 → 不會中途變中文
- [ ] `<textarea>` / `<input>` 預填值維持英文

### 4.5 視覺化

- [ ] plotly 圖表 hover 工具列（Zoom / Pan / Reset axes / Download plot）顯示中文
- [ ] 圖表中的日期 / 數字刻度保留原文
- [ ] Dashboard widget 標題與類型標籤中文

### 4.6 Debug 工具

```javascript
localStorage.setItem('graylog-i18n-debug', 'true'); location.reload();
```

- [ ] Console 出現 `[i18n]` 訊息
- [ ] `window.__graylogI18n.stats()` → `{translated, skipped, patterns, elapsed}` 合理
- [ ] `window.__graylogI18n.retranslate()` 可手動重跑
- [ ] `window.__graylogI18n.translations.size` > 2000

---

## 5. 歷史回歸（已修過的 bug）

- [ ] `18 in 11 out` 計數器 → 不把 `in` 翻成「於」
- [ ] 數字的 `in` 上下文 `8 messages in 2 seconds` → 會翻成「...於...」（CONDITIONAL）
- [ ] `CEF_UDP_32202` 編輯標題 → 不被視為 identifier 誤擋
- [ ] `User recipient(s)` UI 標籤 → 正常翻譯（不被簽名偵測誤擋）
- [ ] 含 `\n` 的多行文字 → whitespace 正規化後仍能查字典
- [ ] 快速切頁下，`MutationObserver` 批次不遺失
- [ ] `Welcome to` / `Graylog` 拆碎片 → 兩段都翻
- [ ] `Data. Insights.`（尾端空格在 DOM，但字典 key 無） → 仍命中
- [ ] Pipeline Stage 標題 `Stage 0` / `Stage 1` → `階段 0` / `階段 1`
- [ ] `2 years ago` / `3 minutes ago` → 時間 pattern 正確
- [ ] `Throughput: In 123 / Out 456 msg/s` → pattern 命中
- [ ] 短詞 `dashboard` / `stream` / `notification` 在標籤 badge 中翻譯，但整段英文句子中的 `dashboard` 若未整句翻則保持英文

---

## 6. 部署驗證（遠端）

```bash
DOMAIN=log4.jason.tools
REMOTE=root@<prod-host>
```

- [ ] 檔案時間：
  ```bash
  ssh $REMOTE 'ls -la /opt/jt-glogi18n/static/'
  # mtime 應為剛才 scp 的時間
  ```
- [ ] 字典版本符合：
  ```bash
  ssh $REMOTE 'python3 -c "import json;print(json.load(open(\"/opt/jt-glogi18n/static/graylog-i18n-dict.json\"))[\"_meta\"][\"version\"])"'
  ```
- [ ] 瀏覽器實際拿到新版（避開 nginx 1h cache）：
  ```bash
  curl -sk https://$DOMAIN/graylog-i18n/graylog-i18n-dict.json \
    | python3 -c "import json,sys;print(json.load(sys.stdin)['_meta']['version'])"
  ```
  若版本仍舊，等最多 1 小時或 `systemctl reload nginx`
- [ ] Nginx 設定語法：`ssh $REMOTE 'nginx -t'` 通過
- [ ] Graylog 服務未被影響：`ssh $REMOTE 'systemctl is-active graylog-server'` = active

---

## 7. 驗收標準

**可部署**（所有項目）：
- Section 1.1、1.2、1.5 全通過
- Section 2.1、2.6 前三項通過
- Section 4.1、4.3 必翻 / 必不翻全通過
- Section 6 全通過

**install.sh 正式發佈**：
- Section 3.1、3.3 全通過
- Section 3.4、3.5、3.6 至少各跑過一個真實 OS
- Section 3.12、3.13 至少各跑過一次

**重大版本升級**（MINOR+）：
- 全部項目通過
