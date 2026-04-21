# 回報 jt-glogi18n 翻譯問題

感謝您協助改進繁體中文與日文翻譯。**本專案不接受外部 pull
request** — 請改為開 GitHub issue,由維護者套用變更。以下規範記錄
維護者採用的慣例,方便您在 issue 中提出合適的建議。

> [English version](CONTRIBUTING.md)

## issue 中請附上的資訊

為方便快速判讀,請在 issue 中提供:

1. **英文原字串**(如它在 Graylog 中顯示的樣子)。
2. **目前的翻譯**(zh-TW 和 / 或 ja)。
3. **您建議的翻譯**,加一句說明理由。
4. **截圖** — 最好是 DevTools → Elements → 選中該文字的畫面,
   維護者才看得出 DOM 是否把句子拆成多個 fragment(「為什麼沒翻
   譯」的最常見原因)。
5. **在哪個 Graylog 頁面 / URL** 看到這個字串。

若問題是 *忽略清單漏洞*(記錄內容或欄位名被誤譯),請一併附上該容器
的 outer HTML — 修正通常需要調整 `graylog-i18n-zh-tw.js` 的選擇器。

## 字典規範(維護者實際套用的規則)

### 保留原文(不可翻譯)

- 產品名:`Graylog`、`Graylog Open`、`Graylog Enterprise`、
  `OpenSearch`、`Elasticsearch`、`Sidecar`、`Data Node`、`Marketplace`
- 角色名:`Admin`、`Reader`、`Forwarder System (Internal)`
- Graylog 欄位名:`action`、`source`、`timestamp`、`direction`、
  `domain`、`Domain`、`Active`、`DCDomain`、`message`、`message_id` 等
- 技術識別碼:`JSON`、`CSV`、`HTTP`、`IP`、`CIDR`、`URL`、
  `JsonPath`、`Shannon Entropy`、`UTF-8` 等
- 資料型別名:`string`、`long`、`double`、`boolean`、`map`、`list`

### 日文字典規範

`graylog-i18n-ja.json` 與 `graylog-i18n-dict.json` 採 **1:1 對應** —
相同的英文 key、相同的 pattern regex,只替換翻譯後的值。若 zh-TW 保留
英文原文,ja 也保留英文;請勿提議 zh-TW 沒有的 ja-only 條目。

### 不可單獨加入 `translations` 的短字

以下短字若放入主 `translations` map 會大量誤觸。引擎已針對每一個
使用 `CONDITIONAL` 守護(`prev` / `next` / `parent` / `check`):

`the`、`not`、`No`、`Open`、`a`、`and`、`Every`、`of`、`in`、`is`、
`after`、`took`、`total`、`indices`、`documents`、`message`、
`messages`、`item`、`items`、`selected`、`details`、`Number`

若您看到這類短字被誤譯,建議新增一條 `CONDITIONAL` 規則(附上守護用
的 DOM 上下文),會比單純提議新增字典條目更有用。

## 回報問題

請直接在 GitHub 開新 issue。**回報未翻譯字串時,請務必附上 Elements
面板的 DOM 截圖** — 看到 `<em>` / `<strong>` 的斷裂邊界是最關鍵的。
