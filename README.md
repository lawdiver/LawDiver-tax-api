# LawDiver Tax API

**Federal tax research over REST** — five calls: search (non-case), retrieve (non-case), case, treaty, check.

| | |
|---|---|
| **Product** | [LawDiver for Tax](https://lawdiver.com/products/tax) |
| **API docs** | [LawDiver for Tax API](https://lawdiver.com/products/tax-api) |
| **Free web** | [https://lawdiver.com/tax](https://lawdiver.com/tax) |
| **Base URL** | `https://lawdiver.com/api/v1/tax` |
| **Keys** | `ld_tax_…` from [Account → API Keys](https://lawdiver.com/account?tab=api-keys) |
| **Signup** | [https://lawdiver.com/signup](https://lawdiver.com/signup) |
| **MCP** | `https://lawdiver.com/mcp/tax` (same five tools; catalog at `/mcp/tax/toolspec.json`) |

The **web product is free for now**. An API key needs a regular LawDiver account. Tax keys (`ld_tax_`) only open `/api/v1/tax/*` and Tax MCP. Caselaw `ld_live_` keys do not.

---

## Authentication

```http
Authorization: Bearer ld_tax_YOUR_KEY
Content-Type: application/json
```

Also accepted: `X-API-Key` or `lawdiver_api_key`.

All methods are `POST` with a JSON body. Responses use the LawDiver `/api/v1` envelope (`ok`, `data`, `requestId`, …).

---

## Surface at a glance

| REST | MCP tool | Job |
|------|----------|-----|
| `POST /search` | `tax_search` | Discover Code, regs, IRS guidance, forms, IRM (**not** cases, **not** treaties) |
| `POST /retrieve` | `tax_retrieve` | Open one non-case item (IRC / Treas. Reg. / IRS doc / form / IRM) |
| `POST /case` | `get_tax_case` | Tax caselaw: search + retrieve + good-law + citing cases |
| `POST /treaty` | `get_tax_treaty` | Tax treaty search + retrieve (+ implementing legislation) |
| `POST /check` | `check_tax_authority` | Batch IRS-guidance citator |

There is **no** separate `/law`, `/guidance`, `/form`, or `/whats-new` on the public API. Use `/retrieve` for point lookup; What’s New stays on the free web / admin tRPC.

---

## `POST /api/v1/tax/search`

Search **everything except cases and treaties**. Default sources = all of the list below. Flat hit list with a **blurb** per item; short Code/reg sections may include **full text** in `text`.

| Field | Required | Default | Notes |
|------|:--------:|---------|--------|
| `query` | yes | — | 1–500 chars |
| `sources` | no | **all** of: `irc`, `treas_reg`, `guidance`, `rev_rul`, `rev_proc`, `written_determinations`, `forms_pubs`, `irm` | Omit for everything non-case. Pass a subset to narrow. |
| `authorityTypes` | no | — | Narrow IRS / WD / IRM rows (e.g. `notice`, `plr`, `td`, `cca`) |
| `codeSection` | no | — | IRC section the guidance interprets (e.g. `"199A"`) |
| `dateFrom` / `dateTo` | no | — | `YYYY-MM-DD` |
| `asOf` | no | — | Year filter (integer) |
| `limit` | no | **20** | 1–**200** |

```json
{
  "query": "qualified business income",
  "sources": ["irc", "treas_reg", "rev_rul", "rev_proc"],
  "codeSection": "199A",
  "limit": 20
}
```

---

## `POST /api/v1/tax/retrieve`

Retrieve **one non-case item**. For IRC / Treas. Reg., omit `asOf` → **latest held edition (current)**. For forms, set `includeInstructions` to also get the matching instructions revision.

| Field | Required | Default | Notes |
|------|:--------:|---------|--------|
| `kind` | yes | — | `irc` \| `treas_reg` \| `irs_guidance` \| `form` \| `irm` |
| `cite` | one of cite/number | — | Section (`"163(j)"`), Rev. Rul. cite, form number, IRM cite, … |
| `number` | one of cite/number | — | Alias for form number when `kind=form` |
| `asOf` | no | **latest held** | Code / reg edition year |
| `compareTo` | no | — | Second year for redline (statutes only) |
| `taxYear` | no | **latest held** | Forms |
| `includeInstructions` | no | false | Forms: also return instructions in the same response |
| `includeText` | no | true (guidance) | Body text |
| `includeCitedBy` | no | false | Guidance: cases / authorities that cite it |

```json
{
  "kind": "irc",
  "cite": "163(j)",
  "asOf": 2024,
  "compareTo": 2017,
  "includeText": true
}
```

Form + instructions:

```json
{
  "kind": "form",
  "number": "1065",
  "taxYear": 2024,
  "includeInstructions": true,
  "includeText": true
}
```

---

## `POST /api/v1/tax/case`

Tax caselaw — same search family as the main LawDiver caselaw API (auto / citation / boolean / semantic / hybrid / case_name). Retrieve adds good-law, citing cases, and IRS context.

| `mode` | Behavior |
|--------|----------|
| `auto` (default) | Unique cite / `caseId` → retrieve. Otherwise search. |
| `search` | Ranked hit list only |
| `retrieve` | One case; ambiguous cites return candidates |

| Field | Required | Default | Notes |
|------|:--------:|---------|--------|
| `query` | one of query/caseId/opinionId | — | Citation, case name, or search words |
| `caseId` | ″ | — | Open a known case |
| `opinionId` | ″ | — | Numeric opinion id |
| `mode` | no | `auto` | See above |
| `searchType` | no | `auto` | `auto` \| `citation` \| `case_name` \| `boolean` \| `semantic` \| `hybrid` \| `keyword` (→ boolean) |
| `courtIds` | no | — | e.g. `tax`, `scotus`, `ca9`, `uscfc` |
| `dateFrom` / `dateTo` | no | — | `YYYY-MM-DD` |
| `publishedOnly` | no | — | Published opinions only |
| `includeUnpublished` | no | — | Include unpublished |
| `goodLawOnly` | no | — | Search filter: good-law opinions only |
| `limit` | no | **10** (search) | 1–200 |
| `includeGoodLaw` | no | **true** (retrieve) | Good-law status on the case card |
| `includeCitedBy` | no | **true** (retrieve) | Cases that cite this one |
| `includeIrsContext` | no | **true** (retrieve) | IRS authorities + AOD hits |
| `citedByLimit` | no | 25 | Cap citing cases (1–100) |

```json
{
  "query": "T.C. Memo. 2019-14",
  "mode": "auto",
  "searchType": "auto",
  "includeGoodLaw": true,
  "includeCitedBy": true,
  "includeIrsContext": true
}
```

Search example:

```json
{
  "query": "like-kind exchange related party",
  "mode": "search",
  "searchType": "semantic",
  "courtIds": ["tax", "scotus", "ca9"],
  "limit": 20
}
```

---

## `POST /api/v1/tax/treaty`

Own search + retrieve. Retrieve returns the instrument **and** `implementingLegislation` (enabling-law labels + statute links when held).

| Field | Required | Default | Notes |
|------|:--------:|---------|--------|
| `mode` | no | `auto` | `auto` \| `search` \| `retrieve` |
| `query` | one of query/country/ldId | — | Free-text search |
| `country` | ″ | — | Party country |
| `ldId` | ″ | — | Retrieve by id |
| `article` | no | — | Article label filter |
| `topic` | no | — | `dividends` \| `interest` \| `royalties` \| `pe` \| `lob` \| `pensions` \| `residence` \| `capital_gains` \| `business_profits` |
| `asOf` | no | — | `YYYY-MM-DD` — instrument in force on that date |
| `limit` | no | 20 | 1–50 (search) |
| `includeArticles` | no | true | Article list / text |
| `includeBody` | no | true | Full body on retrieve |

```json
{
  "country": "Germany",
  "mode": "auto",
  "topic": "dividends",
  "asOf": "2024-01-01"
}
```

---

## `POST /api/v1/tax/check`

Batch citator for **IRS guidance only** (not IRC / Treas. Reg. sections — use `/retrieve` for those).

| Field | Required | Default | Notes |
|------|:--------:|---------|--------|
| `cites` | yes | — | Array of 1–50 cite strings |

```json
{
  "cites": ["Rev. Rul. 99-7", "Rev. Proc. 2002-22", "Notice 2014-21"]
}
```

---

## Quick start

```bash
curl -s https://lawdiver.com/api/v1/tax/retrieve \
  -H "Authorization: Bearer ld_tax_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"kind":"irc","cite":"61","includeText":true}'
```

Or run `examples/curl.sh` with `LAWDIVER_TAX_API_KEY` set.

---

## Related

- Caselaw API: [LawDiver_api](https://github.com/lawdiver/LawDiver_api) · [lawdiver.com/products/api](https://lawdiver.com/products/api)
- CiteCheck: [lawdiver.com/products/citecheck](https://lawdiver.com/products/citecheck)

---

## Keywords

IRS · Internal Revenue Code · IRC API · Treasury regulations · Treas. Reg. · revenue ruling API · Rev. Rul. · Rev. Proc. · tax research API · federal tax database · tax citation check · Tax Court API · LawDiver Tax · ld_tax_
