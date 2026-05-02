# Changelog

All notable changes are documented here. This project follows
[Keep a Changelog](https://keepachangelog.com/en/1.1.0/) and loose
[SemVer](https://semver.org/) — MINOR bumps for tooling / structure, PATCH
bumps for dictionary-only changes.

> [繁體中文版](CHANGELOG_zh-tw.md)

## [3.1.6] — 2026-05-02

### Fixed
- **Self-sign auto-fix actually fires now (round 2).** v3.1.5 wired the
  detection up to a file scan, but the function still aborted on
  `set -u` because it declared `local n=… m=… max=$((n>m?m:n))` on one
  line — bash evaluated the arithmetic before the inline `local`
  bindings landed and tripped "unbound variable: n". Tested on
  Ubuntu 22.04 / nginx 1.18 with a missing Let's Encrypt cert path —
  now correctly enumerates broken pairs and prompts for self-sign.

### Installer
- `install.sh` v1.3.4 → **v1.3.5**.

---

## [3.1.5] — 2026-05-02

### Fixed
- **Self-sign auto-fix now actually triggers when the existing cert is
  missing.** v3.1.2's `detect_broken_ssl_in_existing_conf` parsed
  `nginx -T` — but when the existing config already fails (e.g. the
  `ssl_certificate` path doesn't exist on disk), `nginx -T` emits nothing
  to stdout, so detection returned 0 missing pairs and the prompt never
  appeared. Replaced with a direct file walk under `/etc/nginx`
  (following symlinks via `find -L`) that scans every regular file for
  `ssl_certificate` / `ssl_certificate_key` directives — comments
  stripped — and pairs them in occurrence order.

### Installer
- `install.sh` v1.3.3 → **v1.3.4**.

---

## [3.1.4] — 2026-05-02

### Changed
- **Install command in README is now self-healing**: a single
  `git clone … 2>/dev/null || git -C jt-glogi18n pull --ff-only` line
  works for both first-time install and upgrade — no more "destination
  path already exists" then accidentally running the previous-day's copy
  of `install.sh`.

---

## [3.1.3] — 2026-05-02

### Added
- **Version banner**: every `install.sh` invocation (except `help` /
  `version`) now prints `jt-glogi18n installer vX.Y.Z` as the first line,
  so it's obvious which version is actually running before any work
  starts.

### Installer
- `install.sh` v1.3.2 → **v1.3.3**.

---

## [3.1.2] — 2026-05-02

**Theme: better installer UX for fresh Graylog hosts.**

### Added
- **`Site domain` is now optional**: blank input is accepted and falls back
  to Nginx catch-all `server_name _` (works fine for single-Graylog hosts
  where users just want IP-based access).
- **Self-signed cert auto-fix on pre-flight failure**: when `nginx -t`
  fails because the existing config references missing
  `ssl_certificate` / `ssl_certificate_key` files, the installer now
  offers to generate a 10-year self-signed RSA-2048 cert at those exact
  paths (no edit to the user's nginx config). CN defaults to `$DOMAIN`,
  falling back to the host's FQDN when the catch-all is in use.
- **`--skip-preflight` flag** (and `SKIP_PREFLIGHT=1` env): bypass the
  pre-flight `nginx -t` check for the rare case the user knowingly has
  unrelated broken state they can't fix right now. Not recommended.

### Fixed
- `verify_deployment` no longer pins `Host: _` when running in catch-all
  mode (the catch-all server matches any Host header anyway).

### Installer
- `install.sh` v1.3.1 → **v1.3.2**.

---

## [3.1.1] — 2026-05-02

**Theme: installer robustness + documentation polish for the public repo.**

### Fixed
- **`install.sh` "are the same file" abort when cloned to `/opt/jt-glogi18n`**:
  the documented quick-install path (`git clone … && cd … && sudo bash install.sh`)
  put the script's source dir at the same path as the install dir, so the
  internal `install -m 0644 src dst` failed with
  `'…/static/graylog-i18n-zh-tw.js' and '…/static/graylog-i18n-zh-tw.js' are the same file`.
  `install_static()` now detects same-inode (`-ef`) and skips the copy
  (files are already in place); `chmod 0644` still applied.
- **README install instructions now use `sudo bash install.sh`** so the
  executable bit on `install.sh` after `git clone` is irrelevant.
- Removed a stray duplicate `nginx/install.sh` from the public mirror —
  `nginx/` now only contains `graylog-i18n.conf` as documented.
- `README_zh-TW.md` punctuation normalised to full-width per zh-TW prose
  conventions; markdown image syntax `![alt](url)` preserved.
- Spaces added around `**X**` bold markers that flank CJK characters in
  the zh-TW README so GitHub's CommonMark parser recognises the emphasis.

### Security
- Internal-host IPs scrubbed from `CHANGELOG*.md` and `TESTING*.md`
  (replaced with `<prod-host>` / `<test-host>` / `<lab-host>`); RFC 1918
  example IPs inside the JSON dictionaries are translated documentation
  and intentionally retained.
- `.DS_Store` removed; `.gitignore` added to keep it out going forward.

### Translations
- Dict `2.9.5` / ja `0.5.5`:
  - Bare-name **`Optimizing index <name>.`** pattern (Graylog 7 dropped
    the `<…>` brackets in System Job rows).
  - Fragment **`failed indexing attempts in the last 24 hours.`** for the
    DOM-split "Total N _failed indexing attempts in the last 24 hours._"
    line.
  - **`index set field types`** fragment for the empty-state row in field
    type management.

### Installer
- `install.sh` v1.3.0 → **v1.3.1**.

---

## [3.0.0] — 2026-04-20

**Theme: add Japanese (ja) locale with 1:1 parity to zh-TW; fix Material icon glyphs being force-translated.**

### New locale

- Added **Japanese (ja)** dictionary `static/graylog-i18n-ja.json` (`_meta.version` 0.4.0):
  - **4,987 translations** + **576 patterns**, **1:1 with `graylog-i18n-dict.json` (zh-TW 2.9.2)** — every key / match in the zh-TW dict has a Japanese counterpart; ja never adds entries zh-TW lacks.
  - Product names, Graylog field names, and technical identifiers that zh-TW leaves in English stay in English in ja too.
  - Japanese terminology follows Japan IT industry conventions: 入力器 / 出力器 / 抽出器 / 参照テーブル / パイプライン / インデックスセット / ダッシュボード / ストリーム / 通知 / イベント定義 / 認証サービス.
- `graylog-i18n-locales.json` now includes `{ code: 'ja', native: '日本語', dict: 'graylog-i18n-ja.json' }`.
- Floating toggle cycles three states: **English / 繁體中文 / 日本語**. First-visit `detectPreferredLocale()` maps `navigator.languages` → `/^ja(?:-|$)/i` → ja; `zh-Hant` → zh-TW; otherwise stays English.
- `CLAUDE.md` gained a "Japanese dict rules" section enforcing 1:1 parity (add zh-TW first, then ja).

### Mechanism change (JS)

- **`HARD_SKIP_SELECTORS` (new)**: sits above `FORCE_TRANSLATE_SELECTORS` and is the first check in `isInSkipZone`. Covers `[class*="material-symbols"]` and `[class*="material-icons"]`.
  - **Why**: `.mantine-Button-inner` / `.mantine-Button-label` were previously added to `FORCE_TRANSLATE_SELECTORS` (to localize extractor dropdown items). Those selectors also wrap the icon-font span `<span class="material-symbols-rounded">search</span>` inside buttons, which caused the icon glyph literal "search" to be translated to 搜尋 / 検索 — breaking the icon rendering.
  - **Fix**: HARD_SKIP beats FORCE_TRANSLATE, so even inside a force-translated ancestor, any descendant that lives under a Material icon font class is skipped.

### Deploy

- Pushed to all three hosts: `root@<prod-host>` (prod), `root@<test-host>` (test), `root@<lab-host>` (lab).
- `github/static/` mirrored.

### Docs

- `README.md` / `README_zh-TW.md`: retitled "Localization Pack (zh-TW / ja)"; coverage updated to 4,987 translations + 576 patterns; toggle listed as three-state; file layout lists `graylog-i18n-ja.json`; the translation-mechanism section explains `HARD_SKIP_SELECTORS`.

## [2.9.2] — 2026-04-19

Extended session covering lookup-table management (cache / data-adapter
creation wizard, WHOIS / Spamhaus / DNS / GreyNoise adapters), permission
descriptions (roles list), input diagnosis help, error page, dashboard
/ role / data-adapter / shared-entity / notification search syntax
dialogs, threat-intel plugin settings, URL allowlist configuration,
MCP server settings, Markdown widget body skip, and highlighting rule
modal. Key mechanism changes:

- **Auto-detect locale** on first visit via `navigator.languages`: zh-TW
  / zh-HK / zh-MO / zh-Hant → apply Traditional Chinese; anything else
  (incl. zh-CN) falls through to English (no translation). Users who
  explicitly pick a language via the floating toggle continue to have
  their choice remembered in `localStorage`.
- **Toggle position viewport clamp**: a saved `graylog-i18n-toggle-pos`
  that lands outside the current viewport (window resize / smaller
  screen) is clamped back in on restore; the button no longer goes
  missing after moving between monitors.
- **`ALWAYS_TRANSLATE_TEXTS` whitelist**: exact-text matches that
  bypass the SKIP zone. Populated with `(Empty Value)` so widget-value
  cells still localise the placeholder while leaving surrounding field
  data alone.
- **CONDITIONAL for DOM-split "No <noun>." fragments**: adds guarded
  translations for `events` / `dashboards` / `streams` / `searches` /
  `alerts` / `notifications` / `pipelines` / `rules` / `users` /
  `teams` / `roles` that only fire when the previous sibling ends with
  `沒有` / `No`.
- **CONDITIONAL for `<th>`-only headers**: `Filename` / `Size` translate
  only inside `<th>`; keeps message-field values and widget cells
  untouched.
- **Markdown widget body skipped**: added `[class*="Markdown"]` /
  `[class*="markdown"]` to `SKIP_SELECTORS` so user markdown content
  never gets translated; removed the 6 placeholder-body dict entries
  that rendered the sample widget text.
- **`disabled` CONDITIONAL parent list expanded** to include `dd` and
  `td` so definition-list / table-cell badges get picked up.

### Terminology

- Global: 儀表板 → 看板 (2026-04-19 reversal — request from user).
- Surrounding (time-range context) → 前後文 (replacing earlier "周邊").
- 資料轉接器 → 資料配接器 (consistency across lookup-table UI).
- Grok pattern rendering normalized to 規則 throughout.

### Dictionary

- Lookup-table wizard (Create Cache / Create Data Adapter flow, Cache
  Type selector, Time Based Expiration, DSV/CSV/HTTP JSONPath/DNS/TXT
  record/WHOIS IP/GreyNoise Quick IP/HTTP JSONPath data-adapter
  descriptions incl. IPv4/IPv6/mixed lookups, connect/read timeouts,
  API token, URL allowlist entry, "URL <x> is not allowlisted."
  pattern, Add to URL allowlist button, search-syntax help tables for
  data-adapter / cache / lookup-table / shared-entity / role /
  notification / dashboard queries).
- Permission descriptions for built-in roles (Archive Manager / Viewer,
  Assets Manager / Viewer, Dashboard Creator, Data Node Cluster
  Manager, Event Definition / Notification creators, External Actions,
  Forwarder Admin, Graylog Investigations Admin / Viewer, MCP Server,
  Processing Pipelines, Report Admin / User, Security Admin / Security
  Event Admin / Viewer, Sidecars, Sigma Rules, Summary Templates,
  Teams Reader, Theme Overrides, Users Reader, Views Manager, Watchlist
  Editor, Anomaly Detection full/read).
- Error page (Something went wrong. / Sorry! / Need help? / Community
  support / Issue tracker / Professional support / Show more / Show
  less + the "Do not hesitate to consult ..." text-node fragment that
  sits around the `<a>說明文件</a>`).
- Input Diagnosis help (connectivity checks / format mismatch / Message
  Errors troubleshooting with Failure Processing).
- System metrics page (Process-buffer dump of node / Thread dump of
  node / Metrics of node / Type a metric name to filter... / most
  recent system logs fragment / Taken at / pause / resume dialog
  fragments).
- Widget & chart: Related values / Groupings / Show line thresholds /
  Specify threshold name / line thresholds / Zoom / Latitude /
  Longitude / Stretch width (+ Sretch misspelling) / Highlighting Rule
  (+ Remove this / Edit this) / Coloring / Static Color / Gradient /
  Pick a color.
- Content-pack descriptions (Spamhaus / WHOIS / Tor Exit Node / Open
  Threat Exchange lookup-table descriptions, Graylog default Grok
  patterns, default dashboard showing statistics of all sources,
  internal watchlist lookup table).
- Threat Intel plugin settings (Tor Exit Node / Spamhaus enable
  toggles, Allow Spamhaus DROP/EDROP lookups?, Update Threat
  Intelligence plugin Configuration).
- URL Allowlist Configuration page (full preamble text-node fragments
  around `<em>Graylog</em>`, Allowlist URLs, Disable Allowlist
  toggle + warning).
- MCP Server Configuration page (Beta page text, Remote MCP access,
  Output schema, Enable toggles, Update button).
- Markdown Configuration page (Allow images from all sources
  (comma-separated), Update Markdown Configuration, etc.).
- Auto-Refresh Interval Options page (label + "Configure the
  available options for the auto-refresh interval selector as ISO8601
  duration" DOM fragments + minimum interval warning fragments).
- Query time range limit field + "P30D / PT24H" examples (both P30D
  and PT30D variants).
- Lookup-table listing: Search for lookup tables / Search for caches /
  Search for data adapter(s) / Data Adapter(s) (required) / Create
  Cache / Create Data Adapter / Create Lookup Table / Lookup Table
  Details / Cache Details / Data Adapter Details / No title set /
  No name set (required) / Back to list / Cache Size / Hit Rate /
  Data Adapters for Lookup Tables.
- Field-type change modal DOM fragments (Change + Field Type around
  a bold field name; Select Targeted Index Sets header and
  "By default the ... field type will be set for the ... field in
  all index sets of the current message/search." fragment chain).
- Event actions (View event details / Toggle event actions / Open
  following page).
- Favorites (Favorite / Favorites / Add to favorites / Remove from
  favorites).
- Misc: Active Authentication Service (DOM fragment), Import
  extractors to ... (DOM fragments around `<em>INPUT</em>`), Edit
  extractor ... for input ... (DOM fragments), The cache is local to
  each Graylog server (fragment chain), The file is accessible using
  the same URL by (fragment), Latest Version:, Url allowlist entry,
  Time shown in UTC, Time zone of the Palo Alto device, Store the
  full original Palo Alto message as full_message?, TTL Syntax
  Examples (P30D variant), Select a Condition Type, Direct
  Collaborators, The grantee is required., Convert to list,
  collections, No data available., No description., Cache (required),
  Stores Graylog events., The Graylog default index set. ... , This
  pipeline is system managed, type is not defined, Index Set Title /
  Stream Titles / Current Types, Title * / Name *, Multi-value
  lookup / Multi Value Example / Single Value Example / Value
  columns, Multi value JSONPath: / Single value JSONPath:, Syslog
  Severity Mapper (real translation), Search filter / Search Filter.

## [2.8.1] — 2026-04-19

Second long UI-walk session focused on Inputs, Extractors, AMQP / Kafka /
AWS / Kinesis input configuration, Data Node migration, certificate
authority setup, Index Set management, Input Setup Wizard, Input
Diagnosis panel, notification email lookup fields, Change Field Type /
Set Profile modals, Keyboard Shortcuts dialog, and various error
messages.

### Dictionary (roughly 4,057 → 4,353 translations; 505 → 522 patterns)

- **AMQP input**: Broker hostname / virtual host / port, Prefetch count,
  Queue, Exchange, Routing key, Number of consumers/queues, Passive
  queue declaration, Bind to exchange, Heartbeat timeout, Enable TLS?,
  Re-queue invalid messages?, Connection recovery interval, Username /
  Password.
- **Kafka input**: Legacy mode, Bootstrap Servers, ZooKeeper address,
  Topic filter regex, Fetch minimum bytes, Fetch maximum wait time,
  Processor threads, Auto offset reset (+ each strategy option),
  Consumer group id, Custom Kafka properties.
- **AWS / Kinesis**: AWS Integrations header, Kinesis Authorize / Setup
  / Review tabs, CloudWatch Health Check, AWS Authentication Type
  (Automatic), all six credential-providers rows, Assume Role ARN,
  Region picker, Optional AWS VPC Endpoints with every endpoint override
  (CloudWatch / IAM / DynamoDB / Kinesis / S3 / SQS / STS), SQS / S3
  Region, AWS access/secret key, CloudTrail queue, Authorize & Choose
  Stream.
- **JSON path HTTP input**: URI of JSON resource, Interval time unit,
  JSON path of data to extract, Message source, Allow throttling this
  input (+ full explanation), HTTP method / body / content type /
  additional / sensitive headers, Flatten JSON, Launch Input, Select
  Node, On which node should this input start.
- **Syslog input**: Force rDNS?, Allow overriding date?, Store full
  message?, Expand structured data?, Time Zone (optional),
  Not configured.
- **Extractor configuration**: Extractor preview, `checkRouting set up!`
  / `checkInput started successfully!` toasts (with icon prefix),
  Setting up Input..., Routing set up!, `Input already in use – Message
  Duplication Risk!`, related pipeline-rule warning, Extractor converter
  catalog (Anonymize IPv4 Addresses, Syslog Level/Facility From PRI,
  Key = Value Pairs To Fields, CSV To Fields, Lowercase, Uppercase,
  Flexible Date → 自動解析日期, Numeric, Date, Hash), CSV parameters
  (Field names, Separator character, Escape character, Use strict quotes,
  Trim leading whitespace), Split-and-count converter help, Date
  converter parameters (Convert to date type, Format string, Time Zone,
  Locale, Pick a locale), hash converter descriptions, "The regular
  expression used for extraction. Learn more in the" variants.
- **Input Setup Wizard**: Routing / Launch / Diagnosis tabs, `Select a
  destination Stream` / `We recommend creating a new stream for each
  new input.` bullets, Route to a new / existing Stream, Create Stream,
  Select Stream, Recommended!, Choose an existing Stream,
  `Route messages from this input to an existing stream is selected.`,
  `Pipeline Rules will be created when the … button is pressed.`,
  Create new Stream / new pipeline for this stream, Select(et) Index
  Set, Default Index Set selected long warning prose, `Messages that
  match this stream will be written to the configured Index Set …`
  paragraph, Create a new Index Set, Set up and start the Input …
- **Certificate authority setup**: Configure Certificate Authority
  panel, reuse-certificates warning, Create new CA / Upload CA tabs,
  `Click on the "Create CA" button …` (straight + curly quote variants),
  Organization Name, Create CA, "Creating CA...", "Uploading CA..."
  progress toasts, full Upload-CA helper text (PEM / PKCS#12), Drag CA
  here or click to select file, Certificate Authority, Configure
  certificate renewal policy, Certificate Renewal Policy Configuration
  (title + title-case variant), `These settings will be used when
  detecting expiration …` + `Please create a certificate renewal
  policy before proceeding.`
- **Data Node migration**: `Data Nodes offer a better integration with
  Graylog …`, `Data Node is a management component designed to configure
  and optimize OpenSearch for use with Graylog …`, `You can get more
  information on the Data Node migration`, `Please start at least a Data
  Node to continue the migration process. …`, `Graylog Data Node – Getting
  Started` (with en-dash + ascii hyphen variants), Data Nodes Migration.
- **Index Set management**: Create Index Set, full description of
  per-stream partitioning, Select Template, Index Analyzer / Shards /
  Replica / Max Segments / Optimization after Rotation / Field Type
  Refresh Interval, Index Message Count, Index Time Size Optimizing
  (with rotation-policy prose), Lifetime in days,
  Rotate empty index set (+ long warning), retention presets
  (`7 Days Hot, 90 Days Total`, `14 Days Hot, 90 Days Total`,
  `30 days Hot, 90 Days Total` plus the three `Use case: …` paragraphs),
  Rotation period (ISO8601 Duration), Close / Open / Delete Index,
  `Multiple indices are used to store documents …`, retention-strategy
  placeholder `This retention strategy is not configurable …`, Update
  template, Select Profile / Set Profile, `To see and use the selected
  field type as a field type for … you have to rotate indices …`,
  Rotate affected indices after change.
- **Change Field Type / Overrides modal**: entire prose (Changing the
  type of the field … + Failure Processing link + Processing and
  Indexing Failures + Enterprise Plugin `required`), Select Rotation
  Strategy, Select Field Type For `<name>` (pattern),
  Change `<name>` Field Type (pattern), Configure `<name>` Field Types
  (pattern), Origin explanation, "Field type `<String (aggregatable)>`
  comes from the …" fragment, Overridden index / indices, Remove Field
  Type Overrides modal ("After removing the overridden field type for
  … `<field>` … in `<index set>`, the settings of your search engine
  will be applied for fields: …"), all "Field type picker" type names
  (Boolean, Date, Geo Point, IP, Number, Number (Floating Point), String
  (aggregatable), String (full-text searchable), Binary Data).
- **System job / indexer log patterns**: `SystemJob <UUID> […] finished
  in <N>ms`, `Optimizing index <…>`, `Flushed and set <…> to read-only`,
  `Cycled index alias <…> from <…> to <…>`, `Input […] is in state X`,
  `Input […] is now X`, `Added extractor <…> of type […] to input <…>`,
  `Deleted extractor <…> of type […] from input <…>`,
  `Updated extractor <…> of type […] in input <…>`, `Started up.`,
  `Graceful shutdown initiated.`, `SIGNAL received. Shutting down.`,
  `There is no index target to point to. Creating one now.`.
- **Status badges & counters**: Paused, Resumed (+ all-caps), Event /
  Events, read only / Read only / READ ONLY, `(\d+) (RUNNING|STARTING|
  STOPPING|FAILED|FAILING|STOPPED)` and common pair combos, `(\d+)
  (index|indices), (\d+) documents?, (size)` — handles `1 index, 0
  documents, 208.0B` singular case.
- **Email notification form**: CC / BCC / Recipients / Reply To / Sender
  — Lookup Table Name + Lookup Table Key for each + helper prose
  (`Select the Lookup Table which should be used to get the value.` /
  `Event Field name whose value will be used as Lookup Table Key.`),
  Select Lookup Table, No users will (be cc'd / bcc'd / receive this
  notification / be notified), No email addresses are configured to be
  cc'd / bcc'd on this notification, Email HTML Body, Email Body,
  Email Subject, Email Reply To, `Validation failed, please correct any
  errors in the form before continuing.`.
- **Input Diagnosis panel**: `Input Diagnosis: <type>` pattern, `Input
  Diagnosis can be used to test inputs and parsing …`, Information +
  field rows (`Input Title:` / `Input Type:` / `This Input is running
  on` / `This Input is listening on` / `This Input is listening for`),
  all Troubleshooting bullets (`When an Input fails on one or more
  Graylog nodes …`, port-privilege bullet, external-API bullet,
  TCP-cert bullet), Received Traffic / Message Errors sections, entire
  Number-of-nodes prose, `Graceful shutdown initiated.`,
  `SIGNAL received. Shutting down.`, `Started up.`.
- **Server unavailable dialog**: Server currently unavailable,
  `We are experiencing problems connecting to the Graylog server running
  on`, `. Please verify that the server is healthy and working
  correctly.`, `You will be automatically redirected to the previous
  page once we can connect to the server.`, Do you need a hand?,
  `We can help you` (.+ variant), More details, `This is the last
  response we received from the server:`, Error message.
- **Sticky-notes help**: full `You can use this space to store personal
  notes …` paragraph, Clear button.
- **Keyboard Shortcuts dialog (both small and full versions)**: all
  panel titles (General / Dashboard / Query Input / Scratchpad /
  Search), Show available keyboard shortcuts, Show scratchpad, Submit
  form, Close modal, Undo/Redo last action, Save dashboard (as),
  Save search as, Execute the search, Create a new line, Create search
  filter based on current query, Show suggestions…, View your search
  query history, View all keyboard shortcuts, Clear / Copy scratchpad.
- **User search syntax help**: full_name / username / email field rows,
  `Find users with a email containing example.com:`, Logged in /
  Logged out, Last activity:, Client address:,
  `The address of the client used to initially establish the session,
  not necessarily its current address.`, User is enabled / disabled.
- **Search page**: Load a previously saved search, Save / Save as new
  search, Perform Search, Start / Stop Refresh,
  `No Date/Time Override chosen.`, `Use the tabs above to choose a
  Date & Time Range to Search.`, Export message table search results
  with instructions ("Please select the message table …"),
  `When you've finished the configuration, click on` +
  `"開始下載"` / Export to CSV.
- **Streams**: Pause / Resume / Edit / Delete stream, Paused badge.
- **Misc**: Select a new column / row / field, Select a template,
  Update template, Select Field Type, Set Profile, Set profile / Select
  profile / `Select index set profile`,
  `Create new from revision`, `Lastest Value` (typo in source) / Latest
  Value, `Sleep time` + prose, `Source name` for generator, IPFIX field
  definitions, Load Balancers, Journal metrics unavailable / Loading
  journal metrics / throughput / node metrics / heap usage information
  (all with `…` and `...` variants), Certificate Renewal Policy
  (title / title-case),
  `Overrides the default AWS API endpoint URL that Graylog communicates
  with.` + all six VPC-endpoint overrides, `Pattern` / `Prefix for
  results` for WHOIS, `Enter Setup Mode` / `Exit Setup Mode` / Setup
  Mode, `Change vhost_city_name Field Type` via pattern (works for any
  field name), `Deleted after` + CONDITIONAL `after` → `於` when prev
  is `Deleted` / `刪除`.

### JS engine
- `ACTIVITY_VERBS` CONDITIONAL now overrides `enabled` / `disabled`
  specifically: still fires for "was enabled/disabled" activity-log
  case, AND now also fires when the text is a standalone word inside a
  `<label>` (checkbox UI).
- `.` (period) CONDITIONAL now uses a `check` function: converts to
  `。` when the previous sibling ends with CJK/full-width punctuation
  OR when the surrounding parent element contains any CJK character.
  Catches cases like `<span>已設定的存取權杖總數：</span><strong>Graylog</strong><span>.</span>`.
- `Open` CONDITIONAL switched from `parent:` static selector to a
  `check` function using `closest('button,[role="button"]')` — now
  correctly translates inside Mantine nested `<span>` wrappers
  (`mantine-Button-label`, etc.) while still **not** translating
  `<a>Graylog Open</a>` changelog links.
- New sibling-counter CONDITIONAL: `took` → `耗時` when prev ends with
  `(`; `messages` / `message` → `則訊息` when prev is digit; `item` /
  `items` → `個項目已選取` + `selected` → `` (empty) for split
  "1 item selected" UI; `after` → `於` when prev is `Deleted`/`刪除`;
  `indices` → `個索引`, `documents` → `筆文件` when prev is digit;
  `total` → `筆` when prev is digit; `Every` → `每` when next starts
  with digit; `details` → `詳細資訊` when prev is
  `Show`/`Hide`/`顯示`/`隱藏`.

### Policy changes (global dict pass)
- `輸入來源` → `輸入器` (148 translations + 42 patterns updated).
- `輸出目標` → `輸出器`.
- `Data Node(s)` / `data node(s)` → `資料節點` (33 translations + 11
  patterns).
- `映射` → `map` (English) — 13 occurrences.
- `Default index set` translation removed (it's a user-renamable
  index-set *name*, not a label).
- `Grok pattern` → `Grok 規則` (policy flipped from earlier "keep
  verbatim"; 8 translations + 5 patterns).
- All remaining full-width parens `（ ）` inside dict values converted
  to half-width `()` + surrounding spaces (per CLAUDE.md Taiwan style
  rules, 97 entries total).

### Nginx wire-up (manual, on <test-host>)
- `install.sh` in snippet mode detects an existing Graylog reverse
  proxy and never auto-modifies the customer's config.  For 127 we
  manually wired `include /etc/nginx/snippets/graylog-i18n.conf;` +
  `location /graylog-i18n/ { alias /opt/jt-glogi18n/static/; }` into
  both `/etc/nginx/sites-available/default` (443 HTTPS) and
  `/etc/nginx/sites-enabled/l9000` (8080 HTTP). Backup kept under
  `/opt/jt-glogi18n/backups/manual-wire-*/`.
- Discovered a pre-existing broken `access_log … graylog_audit;`
  reference (undefined log_format) on 127 and disabled that line with
  a note; unrelated to jt-glogi18n.

### Notes
- Deploy continues to target **both** <prod-host> and <test-host>
  per user rule from 2026-04-18.
- Dict `_meta.version` bumped many times this session — see the commit
  log or `git blame` on the dict file for the per-increment detail.
- TODO flagged but not implemented: `install.sh --auto-wire` opt-in
  flag that automates the snippet-include + static-location surgery
  on existing Graylog nginx configs (with pre-backup and
  nginx-t-fail rollback).

## [2.1.5] — 2026-04-18

Cumulative dictionary + engine growth during an intensive UI-walk session.

### Added (dictionary)
- **+1100 translations** (≈ 2,960 → **4,070**) and **+60 patterns**
  (≈ 445 → **505**) covering:
  - Pipeline Rule Builder: every builtin condition (`Field <= / >= / == / !=`,
    `Field is bool/collection/date/double/ip/list/long/map/null/not_null/
    number/string/url`, `Has field`, `Field matches CIDR/grok`, `Lookup
    table string list contains`, `Lookup value check`, etc.) with title +
    description.
  - Pipeline functions: 94 AbstractFunction classes + 165 parameter
    descriptions mined from `graylog2-server` Java source. Split across
    two mining passes (271 unique + 46 more).
  - Toast body / dynamic patterns:
    `^Input '(.+)' will be (stopped|started|restarted) shortly$`,
    `^Request to (stop|start|restart) input '(.+)' was sent successfully$`,
    `^Input \[...\] has failed to start on node ... for this reason ...$`,
    `^Loading ... failed with status: FetchError ...$`,
    `^Updating pipeline failed with status: FetchError ...$`,
    `^Details: FetchError ...$`, `^no lookup result for (.+)$`,
    `^New extractor for input (.+)$`, `^Change (.+) Field Type$`,
    `^Select Field Type For (.+)$`, `^Configure (.+) Field Types$`,
    `^Launch new (.+) input$`, `^Input Diagnosis: (.+)$`,
    `^(\d+) (RUNNING|FAILED|STARTING|FAILING|STOPPED)$` + pair combos,
    `^(\d+) items? selected$`,
    `^The data represents field types from (\d+) last indices ...$`,
    `^Remove matches from '(.+)'$` and curly-quote variant,
    `^Don't assign messages that match this stream to the '(.+)'\.$`
    and curly-quote variant.
  - Per-function `Field is required for function <name>.` patterns for
    min / max / avg / sum / count / latest / stddev / variance /
    percentile / percentage / cardinality / median / mean (with
    translated function name in output).
  - Large sections: Index set management (retention, rotation, Data
    Tiering profiles, hot/cold retention presets, "7/14/30 Days Hot"),
    Change Field Type modal, Set Profile modal, Field Type Overrides,
    Origin explanation, Extractor test UI, Input Setup Wizard,
    Configure Certificate Authority / Upload CA / Certificate renewal,
    Data Node Migration prose, Input Diagnosis panel (Information /
    State / Troubleshooting / Received Traffic / Message Errors / bullet
    points), CSV-to-map converter parameters, Split-and-count
    converter help text, Substring converter parameters, base16/32/64
    encoding functions, hash functions (CRC32C / MD5 / MURMUR3 /
    SHA1/256/512), date parsing (flex / pattern / period), Tor /
    Spamhaus / abuse.ch / OTX threat-intel lookups, aggregation
    function labels (Maximum / Minimum / Percentage / Sum of Squares /
    Mean / Median / Range / Cardinality), Lookup table conversions.

### Added (JS engine)
- Removed over-broad `[class*="value-col"]` from `SKIP_SELECTORS` —
  was blocking user profile "Start page" and other form values.
- `FORCE_TRANSLATE_SELECTORS` extended with `option[disabled]` so
  placeholder `<option disabled>Select ...</option>` translates while
  real option values stay in English for form-submission safety.
- `CONDITIONAL` now supports `next`, `parent`, and a user-defined
  `check` function (alongside the existing `prev`). New `check` lets
  callers walk the DOM to decide contextually (e.g. `and` only fires
  when a nearby sibling contains `或` / `or`).
- `CONDITIONAL_PATTERNS` array — regex patterns gated on a `prev`
  context check. Handles fragments like ` by <username>` after an
  activity verb, without over-triggering generic `by` uses.
- Activity-verb CONDITIONAL batch: `was` → `被` (+ `next` check),
  `shared / unshared / created / updated / deleted / removed / added /
  modified / changed / started / stopped / restarted / renamed /
  enabled / disabled / imported / exported / saved / archived /
  restored / moved` all translate **only** when prev sibling is
  `was`/`被`. Makes "X was shared by Y" style activity log entries
  readable without hurting these common English words elsewhere.
- Counter CONDITIONALs: `total` / `indices` / `documents` / `messages`
  / `message` → Chinese, fires only when preceding text ends in a
  digit. `took` → `耗時` when prev is `(`. `after` → `於` when prev
  is `Deleted` / `刪除`. `details` → `詳細資訊` when prev is
  `Show` / `Hide` / `顯示` / `隱藏`. `Every` → `每` when next starts
  with a digit. `Open` → `開啟` only inside `<button>` or
  `[role="button"]` (keeps `Graylog Open` untouched in `<a>`).
  `item` / `items` → `個項目已選取` and `selected` → `` (empty) for
  split "1 item selected" UI. `is` → `` (empty) between product
  names and status labels ("Graylog Plugin Enterprise is not
  installed").

### Fixed
- Multi-batch mining mistakes: `"message"` → `"則訊息"` was
  over-matching Graylog field names in reserved-field lists (removed
  from translations, moved to CONDITIONAL requiring digit prev).
- `"Substring"` → `"子字串"` was noun-form in a verb-phrased menu;
  changed to `"擷取子字串"` for consistency with other pipeline-function
  titles.
- `"Flexibly parse date"` / `"Flexible Date"` — previous literal
  translation `"彈性…"` read oddly; now `"自動解析日期"` which matches
  the feature's actual behaviour (natty natural-language parsing).
- `"Letter ID"` → `"訊息 ID"` (Graylog's own typo for "Message ID";
  contextually corrected without changing the dict key).
- Global terminology pass: `映射` (Mainland usage) → `map` (English,
  Taiwan-friendly, consistent with other type names) in all 13
  occurrences.
- Global punctuation pass: all full-width `（` `）` in dict values
  replaced with half-width `()` + surrounding spaces, per CLAUDE.md
  Taiwan style rules (95 translations + 2 patterns adjusted).
- Engine: `CONDITIONAL` no longer clashes between `prev` and `next`
  checks — both are evaluated when present; empty `to` is now an
  allowed value (deletes the matching text) for cases where a
  fragment should disappear in translation.

### Notes
- Deploy targets: **both** `root@<prod-host>` (production) and
  `root@<test-host>` (install.sh / nginx testing).
- Dict `_meta.version` tracking: patches bumped many times during
  this run (1.2.0 → 1.2.9 → 1.3.0-1.3.4 → 1.4.0-1.4.9 → 1.5.0-1.5.11
  → 1.6.0-1.6.9 → 1.7.0-1.7.9 → 1.8.0-1.8.9 → 1.9.0-1.9.9 → 2.0.0-2.1.5).
- Grok pattern policy reversed: **translate** as `Grok 規則`
  (previously kept as `Grok pattern` verbatim).

## [1.2.2] — 2026-04-18
### Fixed
- `install.sh` re-read of `/etc/os-release` clashed with its own
  `VERSION` constant — renamed to `INSTALLER_VERSION` so sourcing OS
  metadata no longer errors out as `VERSION: readonly variable`.

### Dictionary 1.2.0 (matching deploy)
- **+227 new toast literals** mined from the Graylog web-interface
  source tree (434 `UserNotification.{success,error,warning,info}(...)`
  call sites across 131 files).
- **+260 new patterns** for variable-laden toast messages (e.g.
  ``Request to start input '<name>' was sent successfully.``).
  15 over-broad candidates were pruned during review.
- **16 entries re-translated** to Taiwan vocabulary standard
  (對照表 / 記錄 / 警報 / 串流 / 檢視 / 前置字串 / 規則 / 說明文件 /
  綠|黃|紅燈狀態 / half-width parens).
- Added `Editing Stream`, `Welcome to`, `Data. Insights.`, `Answers.`
  as individual fragments to cover DOM-split login / stream pages.
- Added `^Remove matches from '(.+)'$` and
  `^Don't assign messages that match this stream to the '(.+)'\.?$`
  patterns (replacing the previous hard-coded "Default Stream"
  variants — now work for any stream name).

### Dictionary 1.1.0
- JS engine extended: `CONDITIONAL` entries accept an optional `next`
  regex in addition to `prev`; new `CONDITIONAL_PATTERNS` array runs
  full regex patterns only when the previous-sibling text matches
  a context predicate.
- New conditional fragments: `was` → `被` (when next is
  shared/unshared), `shared` → `分享`, `unshared` → `取消分享`
  (both gated on `prev` being `was` / `被`). Handles activity-log
  entries like "… was shared by Administrator" that split across
  three text nodes.
- New conditional pattern `^by (\S.*)$` → `由 $1` (fires only after
  shared/unshared/分享/取消分享) — translates the trailing "by <user>"
  fragment without over-triggering generic `by` uses.

### Skip-list fix
- Removed `[class*="value-col"]` — it was over-skipping the user
  profile "Start page" field (matched
  `class="read-only-value-col col-sm-9"`). Messages values are
  already protected by dedicated `[class*="MessageField*"]` selectors.

## [1.2.0] — 2026-04-18

Focus: make `install.sh` bullet-proof across customer environments.

### Added
- `install.sh doctor` — full environment diagnostic (OS, init, package
  manager, nginx flavor + `http_sub_module`, SELinux, firewall, port
  conflicts, backend reachability, existing-proxy detection).
- `install.sh rollback` — restore the previous `nginx.conf` backup
  kept under `/opt/jt-glogi18n/backups/`.
- CLI flags `--domain`, `--backend`, `--ssl-crt`, `--ssl-key`,
  `--open-firewall`, `--dry-run`, `--verbose`, `--no-color`,
  `--version`.
- Install log at `/var/log/jt-glogi18n-install.log` (mode 0640).
- Automatic bash re-exec when invoked via `sh install.sh`.
- Post-install verification: `curl` checks for static-file 200 and
  confirms the `<script>` was injected into the proxied HTML.
- Expanded package-manager support: `apt`, `dnf`, `yum`, `zypper`,
  `apk`, `pacman`.
- Init-system support: `systemd`, `OpenRC`, `sysvinit`, plus
  `nginx -s reload` fallback.
- Nginx flavor detection: vanilla nginx, OpenResty, Tengine.
- SELinux handling: detect `Enforcing` state, apply
  `httpd_sys_content_t` on `/opt/jt-glogi18n/static`, toggle
  `httpd_can_network_connect`.
- Firewall handling: detect `firewalld` / `ufw`, offer to open
  80/tcp (and 443/tcp if HTTPS) with `OPEN_FIREWALL=yes|no|ask`.
- Port-conflict detection on 80/443 (ignores when occupying process is
  nginx itself).
- Backend reachability check (`curl` → `nc` fallback) before writing
  config.
- Automatic backup on every `nginx.conf` overwrite, with restore
  offered on `nginx -t` failure.
- Domain / backend format validation with helpful error messages.
- HTTPS block now includes `http2 on;` and `TLSv1.2 TLSv1.3` + cipher
  preference.
- New docs:
  - `TROUBLESHOOTING.md` / `TROUBLESHOOTING_zh-tw.md` — expanded FAQ
    and recovery procedures.

### Changed
- `README.md` / `README_zh-TW.md` expanded with: platform matrix,
  full flag/env reference, three-mode explanation, SELinux / firewall
  notes, upgrade path, rollback, uninstall steps, verification recipe.
- `install.sh` version pinned at 1.2.0; printed via `--version`.
- Structured logging (`INFO`/`OK`/`WARN`/`ERR`/`STEP`/`DBG`) mirrored
  into the install log for post-mortem.

### Fixed
- Bash 3.2 / UTF-8 parser edge case where `$VAR：` was parsed as part of
  the variable name under `set -u` — all such sites now use `${VAR}`.
- `curl ... || echo 000` pattern that produced `"000\n000"` on
  failure — now uses `code="$(curl ...)" || code="000"`.
- `reload_nginx` now tries `restart` as fallback when `reload` fails.

### Notes
- Dictionary content unchanged at `_meta.version` = **1.0.69**.
- `nginx/graylog-i18n.conf` kept as a reference template; prefer
  `install.sh` for deployments.

## [1.1.0] — 2026-04-18
### Added
- `install.sh` — one-command installer / updater / uninstaller / status tool.
  - Auto-detects three scenarios: nginx missing, nginx present (no
    Graylog proxy), nginx already proxying Graylog.
  - Non-interactive mode via `ASSUME_YES=1` and `DOMAIN` / `BACKEND` /
    `SSL_CRT` / `SSL_KEY` env vars.
  - Safe snippet mode: when an existing Graylog reverse proxy is
    detected, never mutates the user's nginx config — emits a snippet
    file and printed instructions for manual `include`.
  - `update` subcommand refreshes only the static assets.
  - `status` subcommand shows install state, dictionary version.
- `README.md` (English) — primary project README.
- `README_zh-TW.md` — 繁體中文版 README.
- `CHANGELOG.md` / `CHANGELOG_zh-tw.md`.

## [1.0.69] — 2026-04-17
Dictionary-only release capping the rapid iteration that followed the
black-list rewrite. Highlights across the 1.0.1 → 1.0.69 run:

### Added
- Black-list translation strategy: any text node outside `SKIP_SELECTORS`
  is sent through exact-match then pattern lookup (previous white-list
  approach missed too many legitimate strings).
- Large dictionary coverage: top nav, System submenus, Alerts / event
  definition wizard, pipelines, cluster / node detail, inputs /
  extractors, indices, content packs, dashboards, lookup tables.
- `MutationObserver` with `requestAnimationFrame` batching; route-change
  hook (`history.pushState` / `replaceState` / `popstate`); catch-up
  scans at `[100, 300, 800, 1500, 3000, 6000]` ms plus a 3 s periodic
  safety net.
- Attribute translation for `placeholder` / `title` / `aria-label`.
- Conditional translation (`CONDITIONAL` map) for high-risk short words
  (`in`, `of`, `.`) that only fires when the preceding sibling matches
  a context pattern.
- Whitespace normalization so text containing `\n` / `\t` / multiple
  spaces still matches single-spaced dictionary keys.
- `FORCE_TRANSLATE_SELECTORS` override (currently `.ace_placeholder`).
- Field-name / Material-icon protection via extended skip list.

### Changed
- Taiwan localization pass across the dictionary: 查詢表→對照表,
  日誌→記錄, 告警→警報, 資料串流→串流, 查看→檢視, 前綴→前置字串,
  接收者→接收器, 便條板→便條紙, 跳過→忽略, 企業版→Enterprise,
  樣式→規則, 文件→說明文件, 綠/黃/紅色狀態→綠/黃/紅燈狀態,
  全形括號 `（）` → 半形 `()` 含前後空格.
- Grok pattern / Grok patterns kept untranslated.
- Product / role names kept in original form.

### Removed
- White-list `TRANSLATE_SELECTORS`.
- `svg` from skip list (plotly charts now translatable).
- `[data-rbd-draggable-id]` from skip list (over-skipped widget
  editor form labels).
- Short words known to over-trigger: `the`, `not`, `No`, `Open`,
  `a`, `and`, `Every`, `of`, `in`.

### Fixed
- MutationObserver batch loss under rapid DOM changes.
- `looksLikeDataOrIdentifier()` tightened: IP/path/URL regex anchored
  to full line only.

## [1.0.0] — 2026-04-17
- Initial release. White-list translation strategy, baseline dictionary
  covering top navigation, common buttons, and System menu.
