# 版本紀錄

本檔記錄本專案所有重要變更。格式沿用
[Keep a Changelog](https://keepachangelog.com/zh-TW/1.1.0/)，版本採鬆散
[SemVer](https://semver.org/lang/zh-TW/)：工具 / 架構變更提升 MINOR，
字典 only 變更提升 PATCH。

> [English version](CHANGELOG.md)

## [3.1.4] — 2026-05-02

### Changed
- **README 安裝指令改為「clone 或 pull」自癒寫法**:單一行
  `git clone … 2>/dev/null || git -C jt-glogi18n pull --ff-only`
  同時涵蓋初次安裝與後續升級 — 不會再因為「destination path already
  exists」而誤跑到本機留下的舊版 `install.sh`。

---

## [3.1.3] — 2026-05-02

### Added
- **版本 banner**:每次 `install.sh` 執行(除 `help` / `version` 外),
  最開頭會印出 `jt-glogi18n installer vX.Y.Z` 一行,跑任何動作前
  就能直接看到這台機跑的是哪一版。

### Installer
- `install.sh` v1.3.2 → **v1.3.3**。

---

## [3.1.2] — 2026-05-02

**主題:乾淨 Graylog 主機上的安裝程式 UX 改善。**

### Added
- **`Site domain` 改為選填**:直接按 Enter 留空,會自動使用 Nginx 的
  catch-all `server_name _`(單機 Graylog、純 IP 存取的情境本來就不需要
  domain)。
- **Pre-flight 失敗時自動 self-sign 修補**:若既有 nginx 設定引用的
  `ssl_certificate` / `ssl_certificate_key` 檔案不存在(常見於 Let's
  Encrypt 沒裝、cert 路徑筆誤等),安裝程式現在會列出所有缺檔的
  cert/key 對,**詢問**是否在原路徑直接產生 10 年期的 RSA-2048 自簽
  憑證來修補(完全不動使用者的 nginx 設定)。CN 預設用 `$DOMAIN`,
  catch-all 模式下退回主機 FQDN。
- **`--skip-preflight` 旗標**(與 `SKIP_PREFLIGHT=1` 環境變數):
  跳過 pre-flight 的 `nginx -t`。僅供使用者明確知道有無關的既有
  broken state、暫時無法修復時使用,不建議常駐。

### Fixed
- `verify_deployment` 在 catch-all 模式下不再硬塞 `Host: _` header
  (catch-all server 本來就接受任何 Host)。

### Installer
- `install.sh` v1.3.1 → **v1.3.2**。

---

## [3.1.1] — 2026-05-02

**主題:安裝程式強化 + 公開 repo 的文件修整。**

### Fixed
- **`install.sh` 在 `/opt/jt-glogi18n` 路徑下「are the same file」中斷**:
  README 提供的快速安裝路徑(`git clone … && cd … && sudo bash install.sh`)
  讓 source 與 install 目錄落在同路徑,內部 `install -m 0644 src dst`
  會以
  `'…/static/graylog-i18n-zh-tw.js' and '…/static/graylog-i18n-zh-tw.js' are the same file`
  失敗。`install_static()` 現在偵測 same-inode(`-ef`),已在原位則跳過
  複製、僅 `chmod 0644`。
- **README 安裝指令改用 `sudo bash install.sh`**,不再依賴 `git clone`
  後 `install.sh` 的執行權限位。
- 移除公開 mirror 中殘留的 `nginx/install.sh` —— `nginx/` 現在只有
  `graylog-i18n.conf` 一檔(文件原本就只描述這一檔)。
- `README_zh-TW.md` 標點正規化為全形(符合中文行文慣例);Markdown
  image 語法 `![alt](url)` 已保護不被誤轉。
- 在 zh-TW README 中,跨 CJK 的 `**X**` 粗體標記前後加空格,讓 GitHub
  CommonMark parser 正確判定為強調。

### Security
- 公開檔案的內網 IP 全數清除:`CHANGELOG*.md` 與 `TESTING*.md` 中
  `<prod-host>/127/83` 替換為 `<prod-host>` / `<test-host>` /
  `<lab-host>`;JSON 字典裡 RFC 1918 的範例 IP 是翻譯文件本身的內容,
  保留。
- 刪除 `.DS_Store`;新增 `.gitignore` 防止未來再混進來。

### Translations
- 字典 `2.9.5` / 日文 `0.5.5`:
  - **`Optimizing index <name>.`** 純名稱版 pattern(Graylog 7 把
    System Job 列移除了角括號)。
  - 片段 **`failed indexing attempts in the last 24 hours.`** 對應拆碎的
    「Total N _failed indexing attempts in the last 24 hours._」一行。
  - **`index set field types`** 對應欄位型別管理空狀態列。

### Installer
- `install.sh` v1.3.0 → **v1.3.1**。

---

## [3.0.0] — 2026-04-20

**主題：加入日文（ja）語系、與繁中 1:1 同步；修復 Material icon 被強制翻譯的 bug。**

### 新語系

- 新增 **日文（ja）** 字典 `static/graylog-i18n-ja.json`（`_meta.version` 0.4.0）：
  - **4,987 條 translations** + **576 條 patterns**，與 `graylog-i18n-dict.json`（繁中 2.9.2）**逐條 1:1 對應** — 每個 zh-TW 的 key／match 在 ja 中都有對應條目；ja 不會多出任何 zh-TW 沒有的項目。
  - 產品名、Graylog 欄位名、技術識別碼：zh-TW 保留原文的，ja 同樣保留。
  - 日文使用日本 IT 業界慣用術語：入力器 / 出力器 / 抽出器 / 参照テーブル / パイプライン / インデックスセット / ダッシュボード / ストリーム / 通知 / イベント定義 / 認証サービス。
- `graylog-i18n-locales.json` 加入 `{ code: 'ja', native: '日本語', dict: 'graylog-i18n-ja.json' }`。
- 懸浮按鈕改為三段切換：**English / 繁體中文 / 日本語**；首次載入 `detectPreferredLocale()` 依 `navigator.languages` 選擇（`/^ja(?:-|$)/i` → ja；`zh-Hant` → zh-TW；其餘 → 英文）。
- `CLAUDE.md` 加入「日文字典規則」— ja 必須與 zh-TW 逐條 1:1，禁止新增 zh-TW 沒有的條目；新增翻譯流程：先加 zh-TW → 再同步加 ja。

### 機制變更（JS）

- **`HARD_SKIP_SELECTORS`（新）**：放在 `FORCE_TRANSLATE_SELECTORS` 上層、`isInSkipZone` 最先檢查的 hard skip。收錄 `[class*="material-symbols"]` / `[class*="material-icons"]`。
  - **原因**：先前把 `.mantine-Button-inner` / `.mantine-Button-label` 加進 FORCE_TRANSLATE（為了翻譯抽取器下拉選單），導致按鈕內的 icon glyph `<span class="material-symbols-rounded">search</span>` 被誤翻為「搜尋」/「検索」並破壞圖示渲染。
  - **修法**：HARD_SKIP 優先級高於 FORCE_TRANSLATE，即使 node 在強制翻譯範圍內，只要其祖先含 icon 字型 class 就略過。

### 部署

- 同步部署三台：`root@<prod-host>`（正式）、`root@<test-host>`（測試）、`root@<lab-host>`（Lab）。
- `github/static/` 目錄一併更新。

### 文件

- `README.md` / `README_zh-TW.md`：標題改為「Localization Pack (zh-TW / ja)」；覆蓋範圍改為「4,987 翻譯 + 576 patterns」；語系切換改為三段；檔案結構列出 `graylog-i18n-ja.json`；「翻譯機制」補充 HARD_SKIP 說明。

## [2.9.2] — 2026-04-19

延伸長走訪：對照表管理（快取 / 資料配接器建立精靈、WHOIS / Spamhaus / DNS / GreyNoise 配接器）、內建角色權限敘述、Input Diagnosis 說明、錯誤頁、看板 / 角色 / 資料配接器 / 共用項目 / 通知搜尋語法對話框、Threat Intelligence 外掛設定、URL 允許清單設定、MCP 伺服器設定、Markdown 小工具內容 skip、強調規則 modal。

### 機制變更

- **首次載入自動偵測語系**：讀取 `navigator.languages`，符合 zh-TW / zh-HK / zh-MO / zh-Hant 時自動套繁中；其他（包含 zh-CN）退回英文（不翻譯）。使用者手動切換後仍以 `localStorage` 紀錄為準。
- **懸浮按鈕位置 viewport clamp**：`graylog-i18n-toggle-pos` 還原時若超出當前視窗 (換螢幕 / 縮視窗) 自動夾回可視範圍，不會再消失。
- **`ALWAYS_TRANSLATE_TEXTS` 白名單**：精確文字比對即跳過 SKIP zone 翻譯。目前收錄 `(Empty Value)` — 小工具值欄位內的 placeholder 仍可在地化，而周邊使用者資料維持不翻。
- **DOM 拆碎的 "No <noun>." CONDITIONAL**：為 `events` / `dashboards` / `streams` / `searches` / `alerts` / `notifications` / `pipelines` / `rules` / `users` / `teams` / `roles` 加上守衛條件，僅在前段以「沒有」或「No」結尾時觸發。
- **`<th>` 限定的 CONDITIONAL 表頭**：`Filename` / `Size` 只在 `<th>` 內翻譯，避開訊息欄位值與小工具儲存格。
- **Markdown 小工具內容整塊 skip**：`SKIP_SELECTORS` 新增 `[class*="Markdown"]` / `[class*="markdown"]`；同時移除先前誤加的 6 條 placeholder 字典項，避免使用者 markdown 內容被翻。
- **`disabled` CONDITIONAL 的容器清單擴充**：新增 `dd` / `td`，讓定義列 / 表格儲存格內的狀態標籤可被翻譯。

### 術語

- 全域：儀表板 → 看板 (2026-04-19 反轉 — 使用者要求)。
- Surrounding (前後文時間範圍) → 前後文 (取代先前的「周邊」)。
- 資料轉接器 → 資料配接器 (對照表 UI 全面對齊)。
- Grok pattern 相關文案一律改用「規則」。

### 字典

- 對照表精靈 (建立快取 / 建立資料配接器流程、快取類型選單、Time Based Expiration、DSV/CSV/HTTP JSONPath/DNS/TXT 記錄/WHOIS IP/GreyNoise Quick IP/HTTP JSONPath 資料配接器敘述含 IPv4/IPv6/混合查詢、連線與讀取逾時、API 權杖、URL 允許清單項目、「URL <x> is not allowlisted.」pattern、Add to URL allowlist 按鈕、資料配接器 / 快取 / 對照表 / 共用項目 / 角色 / 通知 / 看板 搜尋語法說明表)。
- 內建角色權限敘述 (封存 Manager / Viewer、Assets Manager / Viewer、Dashboard Creator、Data Node Cluster Manager、Event Definition / Notification creator、External Actions、Forwarder Admin、Graylog Investigations Admin / Viewer、MCP Server、Processing Pipelines、Report Admin / User、Security Admin / Security Event Admin / Viewer、Sidecars、Sigma 規則、Summary Templates、Teams Reader、Theme Overrides、Users Reader、Views Manager、Watchlist Editor、Anomaly Detection full/read)。
- 錯誤頁 (Something went wrong. / Sorry! / Need help? / Community support / Issue tracker / Professional support / Show more / Show less，以及「Do not hesitate to consult ...」這段含 `<a>說明文件</a>` 的 fragment)。
- Input Diagnosis 說明 (連線檢查 / 格式不符 / 訊息錯誤排錯與失敗處理)。
- 系統指標頁 (Process-buffer dump of node / Thread dump of node / Metrics of node / Type a metric name to filter... / most recent system logs fragment / Taken at / pause / resume 對話框 fragment)。
- 小工具與圖表：Related values / Groupings / Show line thresholds / Specify threshold name / line thresholds / Zoom / Latitude / Longitude / Stretch width (+ Sretch 拼寫變體) / Highlighting Rule (+ Remove this / Edit this) / Coloring / Static Color / Gradient / Pick a color。
- 內容套件敘述 (Spamhaus / WHOIS / Tor Exit Node / Open Threat Exchange 對照表說明、Graylog 預設 Grok 規則、顯示所有來源統計的預設看板、監視清單內部對照表)。
- Threat Intel 外掛設定 (Tor Exit Node / Spamhaus 啟用切換、Allow Spamhaus DROP/EDROP lookups?、Update Threat Intelligence plugin Configuration)。
- URL 允許清單設定頁 (完整前言含 `<em>Graylog</em>` 的 fragment、Allowlist URLs、Disable Allowlist 切換與警告)。
- MCP Server 設定頁 (Beta 頁面說明、Remote MCP access、Output schema、啟用切換、更新按鈕)。
- Markdown 設定頁 (Allow images from all sources (comma-separated)、Update Markdown Configuration 等)。
- 自動重新整理間隔選項頁 (標籤 + 「Configure the available options for the auto-refresh interval selector as ISO8601 duration」DOM fragment + 最低間隔警告 fragment)。
- 查詢時間範圍上限欄位與 P30D / PT24H 範例 (兩種 P30D / PT30D 變體)。
- 對照表列表：Search for lookup tables / Search for caches / Search for data adapter(s) / Data Adapter(s) (required) / Create Cache / Create Data Adapter / Create Lookup Table / Lookup Table Details / Cache Details / Data Adapter Details / No title set / No name set (required) / Back to list / Cache Size / Hit Rate / Data Adapters for Lookup Tables。
- 欄位型別變更 modal DOM fragment (粗體欄位名兩側的 Change + Field Type；Select Targeted Index Sets 標題與「By default the ... field type will be set for the ... field in all index sets of the current message/search.」fragment 鏈)。
- 事件動作 (View event details / Toggle event actions / Open following page)。
- 我的最愛 (Favorite / Favorites / Add to favorites / Remove from favorites)。
- 其他：Active Authentication Service (DOM fragment)、Import extractors to ... (`<em>INPUT</em>` 兩側 fragment)、Edit extractor ... for input ... (DOM fragment)、The cache is local to each Graylog server (fragment 鏈)、The file is accessible using the same URL by (fragment)、Latest Version:、Url allowlist entry、Time shown in UTC、Time zone of the Palo Alto device、Store the full original Palo Alto message as full_message?、TTL Syntax Examples (P30D 版本)、Select a Condition Type、Direct Collaborators、The grantee is required.、Convert to list、collections、No data available.、No description.、Cache (required)、Stores Graylog events.、The Graylog default index set. ...、This pipeline is system managed、type is not defined、Index Set Title / Stream Titles / Current Types、Title * / Name *、Multi-value lookup / Multi Value Example / Single Value Example / Value columns、Multi value JSONPath: / Single value JSONPath:、Syslog Severity Mapper (補上實際翻譯)、Search filter / Search Filter。
- 通知寄送失敗 pattern：「Notification has email recipients and is triggered, but sending emails failed. Sending the email to the following server failed : IP:PORT」(IP:PORT 動態保留)。
- 伺服器無法連線警告的 DOM fragment (`We are experiencing problems connecting to the <em>Graylog</em> server running on <i>URL</i>`)。

## [2.8.1] — 2026-04-19

第二輪長 UI 走訪：Inputs、擷取器、AMQP / Kafka / AWS / Kinesis 輸入器設定、資料節點遷移、憑證機構建置、索引集管理、Input Setup Wizard、Input Diagnosis 面板、通知 email 的 lookup 欄位、Change Field Type / Set Profile modal、鍵盤快速鍵對話框與各類錯誤訊息。

### 字典（約 4,057 → 4,353 條翻譯；505 → 522 條 pattern）

- **AMQP 輸入器**：Broker hostname / virtual host / port、Prefetch count、Queue、Exchange、Routing key、Number of consumers/queues、Passive queue declaration、Bind to exchange、Heartbeat timeout、Enable TLS?、Re-queue invalid messages?、Connection recovery interval、Username / Password。
- **Kafka 輸入器**：Legacy mode、Bootstrap Servers、ZooKeeper address、Topic filter regex、Fetch minimum bytes、Fetch maximum wait time、Processor threads、Auto offset reset 及三種策略、Consumer group id、Custom Kafka properties。
- **AWS / Kinesis**：AWS Integrations 總標題、Kinesis Authorize / Setup / Review 分頁、CloudWatch Health Check、AWS Authentication Type (Automatic)、六個 credential-provider 項目、Assume Role ARN、Region 選單、Optional AWS VPC Endpoints 與全部六個 endpoint 覆寫 (CloudWatch / IAM / DynamoDB / Kinesis / S3 / SQS / STS)、SQS / S3 Region、AWS access/secret key、CloudTrail queue、Authorize & Choose Stream。
- **JSON path HTTP 輸入器**：URI of JSON resource、Interval time unit、JSON path of data to extract、Message source、Allow throttling this input (含完整說明)、HTTP method / body / content type / additional / sensitive headers、Flatten JSON、Launch Input、Select Node、On which node should this input start。
- **Syslog 輸入器**：Force rDNS?、Allow overriding date?、Store full message?、Expand structured data?、Time Zone (optional)、Not configured。
- **擷取器 (Extractor) 設定**：Extractor preview、`checkRouting set up!` / `checkInput started successfully!` toast (含圖示前綴)、Setting up Input...、Routing set up!、`Input already in use – Message Duplication Risk!`、相關管線規則警告、擷取器 converter 選單（Anonymize IPv4 Addresses、Syslog Level/Facility From PRI、Key = Value Pairs To Fields、CSV To Fields、Lowercase、Uppercase、Flexible Date → 自動解析日期、Numeric、Date、Hash）、CSV 參數、Split-and-count 轉換器說明、Date 轉換器參數 (Convert to date type / Format string / Time Zone / Locale / Pick a locale)、hash 轉換器描述、`The regular expression used for extraction. Learn more in the` 變體。
- **Input Setup Wizard**：Routing / Launch / Diagnosis 分頁、`Select a destination Stream` / `We recommend creating a new stream for each new input.` bullets、Route to a new / existing Stream、Create Stream / Select Stream、Recommended!、Choose an existing Stream、`Route messages from this input to an existing stream is selected.`、`Pipeline Rules will be created when the … button is pressed.`、Create new Stream / new pipeline for this stream、Select(et) Index Set、Default Index Set selected 整段警告、`Messages that match this stream will be written to the configured Index Set …` 段落、Create a new Index Set、Set up and start the Input …
- **憑證機構建置**：Configure Certificate Authority 區塊、reuse-certificates 警告、Create new CA / Upload CA 分頁、`Click on the "Create CA" button …`（直 + 彎引號兩版）、Organization Name、Create CA、"Creating CA..." / "Uploading CA..." 進度 toast、Upload-CA 完整說明 (PEM / PKCS#12)、Drag CA here or click to select file、Certificate Authority、Configure certificate renewal policy、Certificate Renewal Policy Configuration (title 與 title-case 變體)、`These settings will be used when detecting expiration …` + `Please create a certificate renewal policy before proceeding.`
- **資料節點遷移**：`Data Nodes offer a better integration with Graylog …`、`Data Node is a management component designed to configure and optimize OpenSearch for use with Graylog …`、`You can get more information on the Data Node migration`、`Please start at least a Data Node to continue the migration process. …`、`Graylog Data Node – Getting Started`（含 en-dash 與 ASCII hyphen 變體）、Data Nodes Migration。
- **索引集管理**：Create Index Set、每串流分區完整說明、Select Template、Index Analyzer / Shards / Replica / Max Segments / Optimization after Rotation / Field Type Refresh Interval、Index Message Count、Index Time Size Optimizing（含輪替策略說明）、Lifetime in days、Rotate empty index set（長警告）、保留策略預設（`7 Days Hot, 90 Days Total` / `14 Days Hot, 90 Days Total` / `30 days Hot, 90 Days Total` 加對應三段 `Use case: …`）、Rotation period (ISO8601 Duration)、Close / Open / Delete Index、`Multiple indices are used to store documents …`、retention-strategy placeholder、Update template、Select / Set Profile、`To see and use the selected field type as a field type for … you have to rotate indices …`、Rotate affected indices after change。
- **Change Field Type / 覆寫 modal**：完整說明 (Changing the type of the field … + Failure Processing 連結 + Processing and Indexing Failures + Enterprise Plugin `required`)、Select Rotation Strategy、Select Field Type For `<name>` (pattern)、Change `<name>` Field Type (pattern)、Configure `<name>` Field Types (pattern)、Origin explanation、「Field type `<String (aggregatable)>` comes from the …」fragment、Overridden index / indices、Remove Field Type Overrides 對話框、欄位型別選單（Boolean / Date / Geo Point / IP / Number / Number (Floating Point) / String (aggregatable) / String (full-text searchable) / Binary Data）。
- **系統工作 / 索引器 log pattern**：`SystemJob <UUID> […] finished in <N>ms`、`Optimizing index <…>`、`Flushed and set <…> to read-only`、`Cycled index alias <…> from <…> to <…>`、`Input […] is in state X` / `is now X`、`Added/Deleted/Updated extractor <…> of type […] …`、`Started up.` / `Graceful shutdown initiated.` / `SIGNAL received. Shutting down.` / `There is no index target to point to. Creating one now.`。
- **狀態徽章 / 計數**：Paused / Resumed (及全大寫)、Event / Events、read only / Read only / READ ONLY、`(\d+) (RUNNING|STARTING|STOPPING|FAILED|FAILING|STOPPED)` 與常見組合、`(\d+) (index|indices), (\d+) documents?, (size)` — 支援 `1 index, 0 documents, 208.0B` 單數版。
- **Email 通知表單**：CC / BCC / Recipients / Reply To / Sender 各 Lookup Table Name + Key + helper 說明、Select Lookup Table、`No users will (be cc'd / bcc'd / receive this notification / be notified)`、`No email addresses are configured to be cc'd / bcc'd on this notification`、Email HTML Body / Body / Subject / Reply To、`Validation failed, please correct any errors in the form before continuing.`。
- **Input Diagnosis 面板**：`Input Diagnosis: <type>` pattern、`Input Diagnosis can be used to test inputs and parsing …`、Information 與欄位列、所有 Troubleshooting bullets (port-privilege / external-API / TCP-cert)、Received Traffic / Message Errors 區塊、完整 Number-of-nodes 說明、`Graceful shutdown initiated.` / `SIGNAL received. Shutting down.` / `Started up.`。
- **伺服器無法連線對話框**：Server currently unavailable、`We are experiencing problems connecting to the Graylog server running on`、`. Please verify that the server is healthy and working correctly.`、`You will be automatically redirected …`、Do you need a hand?、`We can help you`（加句點與不加兩版）、More details、`This is the last response we received from the server:`、Error message。
- **便條紙說明**：完整 `You can use this space to store personal notes …` 段、Clear 按鈕。
- **鍵盤快速鍵對話框（小與完整版）**：所有面板標題 (General / 看板 / Query Input / Scratchpad / 搜尋)、Show available keyboard shortcuts、Show scratchpad、Submit form、Close modal、Undo/Redo last action、Save dashboard (as)、Save search as、Execute the search、Create a new line、Create search filter based on current query、Show suggestions…、View your search query history、View all keyboard shortcuts、Clear / Copy scratchpad。
- **使用者搜尋語法說明**：full_name / username / email 欄位列、`Find users with a email containing example.com:`、Logged in / Logged out、Last activity:、Client address:、`The address of the client used to initially establish the session, not necessarily its current address.`、User is enabled / disabled。
- **搜尋頁**：Load a previously saved search、Save / Save as new search、Perform Search、Start / Stop Refresh、`No Date/Time Override chosen.`、`Use the tabs above to choose a Date & Time Range to Search.`、Export message table search results 與引導文字、`When you've finished the configuration, click on` + `"開始下載"` / Export to CSV。
- **串流**：Pause / Resume / Edit / Delete stream、Paused 徽章。
- **雜項**：Select a new column / row / field、Select a template、Update template、Select Field Type、Set Profile、`Create new from revision`、`Lastest Value` (源碼錯字) / Latest Value、Sleep time + 說明、Source name for generator、IPFIX field definitions、Load Balancers、Journal metrics unavailable / Loading journal metrics / throughput / node metrics / heap usage information（皆含 `…` 與 `...` 變體）、Certificate Renewal Policy、`Overrides the default AWS API endpoint URL that Graylog communicates with.` + 全部 6 個 VPC endpoint 覆寫、WHOIS 的 `Pattern` / `Prefix for results`、`Enter Setup Mode` / `Exit Setup Mode` / Setup Mode、`Change vhost_city_name Field Type` 透過 pattern 支援任意欄位名、`Deleted after` + CONDITIONAL `after` → `於`。

### JS 引擎
- `ACTIVITY_VERBS` 中的 `enabled` / `disabled` 特別 override：仍支援 `was enabled/disabled` 活動記錄，也會在文字是 `<label>` 內獨立字（checkbox UI）時翻譯。
- `.` （句點）CONDITIONAL 改用 `check` 函式：當前段以 CJK / 全形標點結尾 **或** 父元素 textContent 含 CJK 時轉成 `。`。處理像 `<span>已設定的存取權杖總數：</span><strong>Graylog</strong><span>.</span>` 這種情境。
- `Open` CONDITIONAL 從固定 `parent:` 選擇器改為 `check` 函式呼叫 `closest('button,[role="button"]')` — 能穿透 Mantine 巢狀 `<span>` 包裝 (`mantine-Button-label` 等) 正確翻譯，但 `<a>Graylog Open</a>` changelog 連結仍不翻。
- 新 CONDITIONAL 計數詞：`took` → `耗時`（prev 為 `(`）；`messages` / `message` → `則訊息`（prev 為數字）；`item` / `items` → `個項目已選取` + `selected` → 空（合併拆碎 "1 item selected"）；`after` → `於`（prev 為 `Deleted` / `刪除`）；`indices` → `個索引`、`documents` → `筆文件`（prev 為數字）；`total` → `筆`（prev 為數字）；`Every` → `每`（next 為數字開頭）；`details` → `詳細資訊`（prev 為 `Show`/`Hide`/`顯示`/`隱藏`）。

### 政策變更（全域字典掃）
- `輸入來源` → `輸入器`（148 translations + 42 patterns 更新）。
- `輸出目標` → `輸出器`。
- `Data Node(s)` / `data node(s)` → `資料節點`（33 translations + 11 patterns）。
- `映射` → `map`（英文）— 13 處。
- `Default index set` 從翻譯移除（是使用者可重命名的索引集「名稱」，不該翻）。
- `Grok pattern` → `Grok 規則`（先前保留原文，政策反轉；8 translations + 5 patterns）。
- 所有字典值內殘餘的全形括號 `（ ）` 改為半形 `()` + 前後空格（依 CLAUDE.md 台灣用語規範，97 處）。

### Nginx 手動接線（<test-host>）
- `install.sh` snippet 模式偵測到既有 Graylog 反向代理後從不自動動客戶設定。127 上手動把 `include /etc/nginx/snippets/graylog-i18n.conf;` + `location /graylog-i18n/ { alias /opt/jt-glogi18n/static/; }` 加進 `/etc/nginx/sites-available/default`（443 HTTPS）與 `/etc/nginx/sites-enabled/l9000`（8080 HTTP）。備份在 `/opt/jt-glogi18n/backups/manual-wire-*/`。
- 發現 127 原有一個 `access_log … graylog_audit;` 引用未定義的 log_format（與本專案無關），暫時註解掉並加註解說明。

### 備註
- 依 2026-04-18 規則，deploy 仍雙推 `<prod-host>` 與 `<test-host>`。
- 字典 `_meta.version` 於本輪多次 bump，逐版細節見 git 歷史。
- 待辦（未實作）：`install.sh --auto-wire` opt-in 旗標，自動把 snippet include + static location 套入既有 Graylog nginx 設定（含備份與 `nginx -t` 失敗時自動還原）。

## [2.1.5] — 2026-04-18

這一輪實機走一遍 UI 所累積的字典與引擎擴充總整理。

### 新增（字典）
- **+1100 條翻譯**（約 2,960 → **4,070**），**+60 條 pattern**（約 445 → **505**）。涵蓋：
  - **Pipeline Rule Builder**：所有內建 condition（`Field <= / >= / == / !=`、`Field is bool/collection/date/double/ip/list/long/map/null/not_null/number/string/url`、`Has field`、`Field matches CIDR/grok`、`Lookup table string list contains`、`Lookup value check` 等），含標題與描述。
  - **Pipeline 函數**：94 個 `AbstractFunction` 類別 + 165 條參數描述，從 `graylog2-server` Java 源碼挖出，兩批共 271 條 + 補的 46 條。
  - **Toast 與 pattern**：Input 啟停（stop/start/restart × will be shortly / Request to ... was sent successfully）、`Input [...] has failed to start on node ...`、`Loading ... failed with status: FetchError ...`、`Updating pipeline failed with status: FetchError ...`、`Details: FetchError ...`、`no lookup result for (.+)`、`New extractor for input (.+)`、`Change (.+) Field Type`、`Select Field Type For (.+)`、`Configure (.+) Field Types`、`Launch new (.+) input`、`Input Diagnosis: (.+)`、`(\d+) (RUNNING|FAILED|STARTING|FAILING|STOPPED)` 與組合、`(\d+) items? selected`、`The data represents field types from (\d+) last indices ...`、`Remove matches from '...'`（直 / 彎引號兩種）、`Don't assign messages that match this stream to the '...'.`（直 / 彎引號兩種）。
  - **每個聚合函式**：`Field is required for function <name>.` 的 min/max/avg/sum/count/latest/stddev/variance/percentile/percentage/cardinality/median/mean 都有專屬 pattern（輸出已翻譯函式名）。
  - **大段落**：索引集管理（保留 / 輪替 / Data Tiering profile / hot-cold 預設 / 7、14、30 Days Hot）、Change Field Type modal、Set Profile modal、欄位型別覆寫、Origin explanation、擷取器測試 UI、Input Setup Wizard、憑證機構設定 / 上傳 CA / 續簽政策、Data Node 遷移說明、Input Diagnosis 面板（資訊 / 狀態 / 疑難排解 / 已接收流量 / 訊息錯誤 / 各項 bullet）、CSV-to-map 轉換器參數、Split-and-count 轉換器說明、Substring 轉換器參數、base16/32/64 編碼 / 解碼、雜湊函式（CRC32C / MD5 / MURMUR3 / SHA1/256/512）、日期解析（flex / pattern / period）、Tor / Spamhaus / abuse.ch / OTX 威脅情資查詢、聚合標籤（Maximum / Minimum / Percentage / Sum of Squares / Mean / Median / Range / Cardinality）、對照表轉換。

### 新增（JS 引擎）
- 從 `SKIP_SELECTORS` 移除過寬的 `[class*="value-col"]` — 先前誤擋使用者個人頁「起始頁」與其他表單值。
- `FORCE_TRANSLATE_SELECTORS` 新增 `option[disabled]`，讓 `<option disabled>Select ...</option>` 的 placeholder 可翻譯，但一般 `<option>` 值仍保持英文（避免影響表單送出）。
- `CONDITIONAL` 除既有 `prev` 外，新增 `next`、`parent`（選擇器檢查）、`check`（自訂函式）。新 `check` 允許呼叫者自行走 DOM 判斷，例如 `and` 只在附近 sibling 含 `或` / `or` 時觸發。
- 新 `CONDITIONAL_PATTERNS` 陣列：regex pattern 僅在 `prev` 符合條件時觸發。用來處理活動記錄尾段 ` by <user>` 而不誤觸一般 `by` 用法。
- **活動記錄動詞 CONDITIONAL 批次**：`was` → `被`（加 `next` 檢查），`shared / unshared / created / updated / deleted / removed / added / modified / changed / started / stopped / restarted / renamed / enabled / disabled / imported / exported / saved / archived / restored / moved` 都僅在前段為 `was` / `被` 時觸發。讓「X was shared by Y」這種活動記錄可讀，同時不破壞這些常見英文字在別處的使用。
- **計數 CONDITIONAL**：`total` / `indices` / `documents` / `messages` / `message` → 對應中文，僅在前段為數字時觸發。`took` → `耗時`（前段為 `(`）；`after` → `於`（前段為 `Deleted` / `刪除`）；`details` → `詳細資訊`（前段為 `Show` / `Hide` / `顯示` / `隱藏`）；`Every` → `每`（下一段以數字開頭）；`Open` → `開啟`（僅限 `<button>` / `[role="button"]`，避免誤譯 `<a>Graylog Open</a>`）；`item` / `items` → `個項目已選取` 與 `selected` → 空（合併拆碎的 "1 item selected" UI）；`is` → 空（Enterprise 產品名與狀態標籤之間，如 "Graylog Plugin Enterprise is not installed"）。

### 修正
- 多次挖掘過程誤譯：`"message"` → `"則訊息"` 會誤擋 Graylog 欄位名（已從 translations 移除，改為需要數字前綴的 CONDITIONAL）。
- `"Substring"` → `"子字串"` 為名詞，與其他動詞式函式選單不一致；改為 `"擷取子字串"`。
- `"Flexibly parse date"` / `"Flexible Date"` 先前直譯 `"彈性…"` 讀來彆扭；改為 `"自動解析日期"` 符合功能實際行為（natty 自然語言解析）。
- `"Letter ID"` → `"訊息 ID"`（Graylog 自身錯字，此處依語意糾正而不變動 dict key）。
- 全域用語：`映射`（中國用語偏好）→ `map`（英文，與其他型別名一致），全文 13 處皆替換。
- 全域標點：字典 values 裡 95 條、patterns 裡 2 條的全形 `（` `）` 改為半形 `()` 加前後空格，符合 CLAUDE.md 台灣用語規範。
- 引擎：`CONDITIONAL` 的 `prev` 與 `next` 檢查可並存；`to: ''`（空字串）為有效值（對應的 fragment 會從顯示中消失），處理「翻譯後該字應該拿掉」的情境。

### 備註
- 部署目標：**兩台**（`root@<prod-host>` 正式、`root@<test-host>` 測試）。
- 字典 `_meta.version` 於此輪大量 bump（1.2.0 → 1.2.9 → 1.3.0–1.3.4 → 1.4.0–1.4.9 → 1.5.0–1.5.11 → 1.6.0–1.6.9 → 1.7.0–1.7.9 → 1.8.0–1.8.9 → 1.9.0–1.9.9 → 2.0.0–2.1.5）。
- Grok pattern 政策翻轉：**翻譯**為 `Grok 規則`（先前保留原文）。

## [1.2.2] — 2026-04-18
### 修正
- `install.sh` 讀取 `/etc/os-release` 時與自身 `VERSION` 常數衝突（os-release 內 `VERSION=...` 無法覆寫 `readonly VERSION`）→ 改名為 `INSTALLER_VERSION`。Ubuntu/Debian 上 doctor / install 不再因此失敗。

### 字典 1.2.0（同批部署）
- **新增 227 條 toast 字面翻譯**，從 Graylog 前端源碼 434 個 `UserNotification.{success,error,warning,info}(...)` call site（131 檔）挖出。
- **新增 260 條 pattern**，覆蓋含變數的 toast 訊息（如 ``Request to start input '<名稱>' was sent successfully.``）。review 剔除 15 條過寬 pattern。
- **重譯 16 條**符合台灣用語：對照表 / 記錄 / 警報 / 串流 / 檢視 / 前置字串 / 規則 / 說明文件 / 綠|黃|紅燈狀態 / 半形 `()`。
- 新增 `Editing Stream`、`Welcome to`、`Data. Insights.`、`Answers.` 等 DOM 拆碎 fragment。
- 新增 `^Remove matches from '(.+)'$` 與 `^Don't assign messages that match this stream to the '(.+)'\.?$`（取代寫死的 Default Stream）。

### 字典 1.1.0（JS 引擎擴充）
- `CONDITIONAL` 每項可選 `next` 正規式（除 `prev` 外）。
- 新增 `CONDITIONAL_PATTERNS` 陣列：full regex pattern 僅在前一 sibling 文字符合條件時觸發。
- 新 conditional：`was` → `被`（next 為 shared/unshared 時）、`shared` → `分享`、`unshared` → `取消分享`（皆於 prev 為 `was` / `被` 時觸發）。修復「… was shared by Administrator」拆三段的活動記錄翻譯。
- 新 conditional pattern `^by (\S.*)$` → `由 $1`（僅於前段為 shared / unshared / 分享 / 取消分享 時）。

### Skip list 修正
- 移除 `[class*="value-col"]` — 誤擋使用者個人頁面的「起始頁」欄位（`class="read-only-value-col col-sm-9"`）。訊息欄位值已有 `[class*="MessageField*"]` 系列保護。

## [1.2.0] — 2026-04-18

重點：讓 `install.sh` 在客戶環境中更穩。

### 新增
- `install.sh doctor` — 完整環境診斷（OS / init / PM / nginx flavor + `http_sub_module` / SELinux / firewall / port 衝突 / 後端可達性 / 既有 proxy 偵測）。
- `install.sh rollback` — 還原 `/opt/jt-glogi18n/backups/` 最新備份。
- CLI flags：`--domain`、`--backend`、`--ssl-crt`、`--ssl-key`、`--open-firewall`、`--dry-run`、`--verbose`、`--no-color`、`--version`。
- 安裝日誌 `/var/log/jt-glogi18n-install.log`（0640）。
- `sh install.sh` 自動 re-exec 為 bash。
- 安裝後驗證：`curl` 檢查靜態檔 200 與注入確認。
- 擴充套件管理器：apt / dnf / yum / zypper / apk / pacman。
- Init：systemd / OpenRC / sysvinit，加上 `nginx -s reload` fallback。
- Nginx flavor：原生 nginx / OpenResty / Tengine。
- SELinux：偵測 Enforcing → 自動套 `httpd_sys_content_t` 與 `httpd_can_network_connect`。
- Firewall：偵測 firewalld / ufw → 詢問開 80（HTTPS 模式含 443），支援 `OPEN_FIREWALL=yes|no|ask`。
- Port 衝突偵測（80 / 443）；若佔用者是 nginx 自己則忽略。
- 後端可達性（`curl` → `nc` fallback）。
- 覆蓋 `nginx.conf` 前自動備份；`nginx -t` 失敗時詢問還原。
- Domain / backend 格式驗證；錯誤訊息明確。
- HTTPS 區塊含 `http2 on;` + `TLSv1.2 TLSv1.3` + cipher 偏好。

### 調整
- `README.md` / `README_zh-TW.md` 擴充：平台相容表、完整 flag/env、三種安裝模式、SELinux / firewall 說明、升級 / 回滾 / 移除、驗證食譜。
- `install.sh` 版本釘 1.2.0；`--version` 顯示。
- 結構化日誌（`INFO` / `OK` / `WARN` / `ERR` / `STEP` / `DBG`）同步寫入日誌檔。
- 新文件：`TESTING.md` / `TESTING_zh-tw.md` — 完整測試清單。

### 修正
- Bash 3.2 / UTF-8 parser 在 `set -u` 下把 `$VAR：` 當作變數名的 edge case — 全面改用 `${VAR}`。
- `curl ... || echo 000` 失敗時會產生 `"000\n000"` 的 bug — 改為 `code="$(curl ...)" || code="000"`。
- `reload_nginx` 現在 reload 失敗會再試 restart 作為 fallback。

## [1.1.0] — 2026-04-18
### 新增
- `install.sh`：一行指令完成 安裝 / 更新 / 移除 / 狀態檢查。
  - 自動偵測三種情境：未裝 nginx、有 nginx 但未反向代理 Graylog、已反向代理 Graylog。
  - 支援非互動模式（`ASSUME_YES=1` 搭配 `DOMAIN` / `BACKEND` / `SSL_CRT` / `SSL_KEY` 環境變數），適合 CI / 自動化。
  - **安全 snippet 模式**：偵測到使用者已有 Graylog 反向代理設定時，腳本絕不動你的 nginx 設定，只產生一個 snippet 檔並列印手動 `include` 指令。
  - `update` 子指令只刷新靜態檔，不 reload nginx — 日常升級字典用。
  - `status` 子指令顯示安裝狀態、字典版本、`nginx -t` 結果。
- 新增 `README.md`（英文版）作為主要 README。
- 新增 `README_zh-TW.md`（繁體中文版）。
- 新增 `CHANGELOG.md` / `CHANGELOG_zh-tw.md`。

### 調整
- 文件重構：安裝說明改為推薦使用 `install.sh`，取代先前多步驟手動 `cp` / `nginx -t` 流程。

### 備註
- 字典內容維持 `_meta.version` = **1.0.69**，本版未動字典。
- `nginx/graylog-i18n.conf` 保留作為範本參考；建議客戶安裝一律走 `install.sh`。

## [1.0.69] — 2026-04-17
自白名單改黑名單後快速迭代的總結版本。1.0.1 → 1.0.69 的亮點：

### 新增
- **黑名單策略**：任何不在 `SKIP_SELECTORS` 內的 text node 都會送去精確比對 + 正規式（舊白名單漏譯太多）。
- 大幅擴充字典覆蓋：頂部導覽、System 子選單全集、告警 / 事件定義精靈、管線、叢集 / 節點詳情、輸入來源 / 擷取器、索引、內容套件、看板、對照表。
- `MutationObserver` + `requestAnimationFrame` 批次；`history.pushState` / `replaceState` / `popstate` 路由 hook；追趕掃描 `[100, 300, 800, 1500, 3000, 6000]` ms + 每 3 秒週期重掃。
- 屬性翻譯：`placeholder` / `title` / `aria-label`。
- **CONDITIONAL 條件式翻譯**：高風險短詞（`in`、`of`、`.`）依前一個 sibling 是否符合上下文 pattern 決定翻不翻。
- **空白字元正規化**：含 `\n` / `\t` / 多個空格的文字仍能命中單一空格的字典 key。
- **FORCE_TRANSLATE_SELECTORS**：即使在 skip zone 內也強制翻譯（目前只有 `.ace_placeholder`）。
- **欄位名保護**：`[class*="field-element"]`、`FieldName`、`FieldList`、`FieldItem`、`FieldSelect`、`FieldGroup`、`FieldTypes`、`FieldType`、`SidebarField`、`FieldsList`、`TypeIcon`、`TypeListItem`、`.mantine-Menu-dropdown > li`；`looksLikeDataOrIdentifier()` 新增 `欄位名 = 型別` 偵測。
- **Material icons 保護**：`[class*="material-symbols"]` / `[class*="material-icons"]`。

### 調整
- 全域套用台灣繁體用語：查詢表→對照表、日誌→記錄、告警→警報、資料串流→串流、查看→檢視、前綴→前置字串、接收者→接收器、便條板→便條紙、跳過→忽略、企業版→Enterprise、樣式→規則、文件→說明文件、綠 / 黃 / 紅色狀態→綠 / 黃 / 紅燈狀態，全形括號 `（）` → 半形 `()` 且前後加空格。
- Grok pattern 一律維持原文（中文描述中也寫 Grok pattern）。
- 產品名維持原文：Graylog、Graylog Open、Graylog Enterprise、OpenSearch、Elasticsearch、Sidecar、Data Node、Marketplace。
- 角色名維持原文：Admin、Reader、Forwarder System (Internal) 等。

### 移除
- 白名單 `TRANSLATE_SELECTORS`（黑名單策略下已多餘）。
- `svg` 從 skip list 移除（讓 plotly 圖表 UI 文字可被翻譯）。
- `[data-rbd-draggable-id]` / `[data-rbd-droppable-id]` 從 skip list 移除 — 曾把 widget 編輯器的 Direction / Fields / Limit 表單標籤一併擋住。
- 會誤觸的短詞：`the`、`not`、`No`、`Open`、`a`、`and`、`Every`、`of`、`in`。
- `^[A-Za-z0-9 .:+/-]+\([^)]*\)$` 函式簽名偵測 — 誤擋 「User recipient(s)」這類 UI 標籤。
- `"Domain": "網域"` — `Domain` 是 Graylog 欄位名。

### 修正
- 快速 DOM 變化時 MutationObserver 批次遺失 — `pendingMutations` 陣列跨 frame 累積後再處理。
- 收緊 `looksLikeDataOrIdentifier()`：IP / 路徑 / URL regex 改為完整行匹配；底線識別字規則不再誤擋 `CEF_UDP_32202` 這類編輯標題。

## [1.0.0] — 2026-04-17
- 初版。白名單策略，涵蓋頂部導覽、常用按鈕、System 選單。
