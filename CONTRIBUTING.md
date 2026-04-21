# Reporting translation issues in jt-glogi18n

Thanks for helping improve the Traditional Chinese and Japanese
translations. **This project does not accept external pull requests** —
please open a GitHub issue instead and the maintainer will apply the
change. The rules below document the conventions the maintainer follows
so you know what to suggest.

> [繁體中文版](CONTRIBUTING_zh-tw.md)

## What to include in an issue

To help triage quickly, please include:

1. **The English string** as it appears in Graylog.
2. **The current translation** (zh-TW and/or ja).
3. **Your proposed translation**, with a one-line reason.
4. **A screenshot** — ideally with DevTools → Elements → the text
   highlighted, so the maintainer can see whether the DOM has split the
   phrase into multiple fragments (common cause of "why isn't it
   translated?").
5. **Which Graylog page / URL** you saw the string on.

If the problem is a *skip-list gap* (log contents or field names are
being mistranslated), please also include the outer HTML of the
container — the fix usually requires a selector update in
`graylog-i18n-zh-tw.js`.

## Dictionary conventions (what the maintainer applies)

### Keep in original English (do NOT translate)

- Product names: `Graylog`, `Graylog Open`, `Graylog Enterprise`,
  `OpenSearch`, `Elasticsearch`, `Sidecar`, `Data Node`, `Marketplace`.
- Role names: `Admin`, `Reader`, `Forwarder System (Internal)`.
- Graylog field names: `action`, `source`, `timestamp`, `direction`,
  `domain`, `Domain`, `Active`, `DCDomain`, `message`, `message_id`, etc.
- Technical identifiers: `JSON`, `CSV`, `HTTP`, `IP`, `CIDR`, `URL`,
  `JsonPath`, `Shannon Entropy`, `UTF-8`, etc.
- Data type names: `string`, `long`, `double`, `boolean`, `map`, `list`.

### Japanese dictionary rule

`graylog-i18n-ja.json` mirrors `graylog-i18n-dict.json` **1:1** — same
English keys, same pattern regexes; only the translated value is
replaced. If zh-TW keeps a term in English, ja keeps it in English too.
Don't suggest ja-only additions that have no zh-TW counterpart.

### Short words that must NOT become standalone entries

These words over-translate disastrously when added to the main
`translations` map. The engine uses `CONDITIONAL` guards (`prev` /
`next` / `parent` / `check`) for each of them:

`the`, `not`, `No`, `Open`, `a`, `and`, `Every`, `of`, `in`, `is`,
`after`, `took`, `total`, `indices`, `documents`, `message`, `messages`,
`item`, `items`, `selected`, `details`, `Number`.

If you see one of these words mistranslated, suggesting a new
`CONDITIONAL` rule (with the DOM context that guards it) is more useful
than just proposing a new dictionary entry.

## Reporting issues

Open a new issue on GitHub. For missing translations, **please include
an Elements-panel screenshot of the DOM** — seeing the split `<em>` /
`<strong>` boundaries is essential.
