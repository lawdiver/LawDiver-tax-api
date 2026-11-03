# LawDiver Tax API

**Federal tax research over REST** — Internal Revenue Code by year, Treasury regulations, IRS guidance, forms, treaties, and a unified tax caselaw call (search, retrieve, good-law, citing cases, IRS context).

| | |
|---|---|
| **Product** | [LawDiver for Tax](https://lawdiver.com/products/tax) |
| **API docs** | [LawDiver for Tax API](https://lawdiver.com/products/tax-api) |
| **Free web** | [https://lawdiver.com/tax](https://lawdiver.com/tax) |
| **Base URL** | `https://lawdiver.com/api/v1/tax` |
| **Keys** | `ld_tax_…` from [Account → API Keys](https://lawdiver.com/account?tab=api-keys) |
| **Signup** | [https://lawdiver.com/signup](https://lawdiver.com/signup) |
| **MCP** | `https://lawdiver.com/mcp/tax` (same seven jobs; tool catalog at `/mcp/tax/toolspec.json`) |

The **web product is free for now**. An API key needs a regular LawDiver account. Tax keys are separate from caselaw `ld_live_` keys — they only open `/api/v1/tax/*` (and Tax MCP). Caselaw cite-check still resolves tax authorities with your regular key; deep tax search / law / guidance stays on this surface.

Claude.ai and OpenAI **directory** connectors for Tax are coming soon. Tax MCP works today with an `ld_tax_` key (or OAuth once the Tax listing ships).

---

## Authentication

```http
Authorization: Bearer ld_tax_YOUR_KEY
Content-Type: application/json
```

Also accepted: `X-API-Key` or `lawdiver_api_key`.

All methods are `POST` with a JSON body. Responses use the LawDiver `/api/v1` envelope (`ok`, `data`, `requestId`, …).

---

## What each endpoint does

Seven calls. **Search** for Code / regs / IRS. **`/case`** for all tax caselaw work. **Law / guidance / form / treaty** to retrieve. **Check** to verify IRS cites.

### `POST /api/v1/tax/search` — find Code, regs, IRS materials

Discovery for non-case primary sources. Hits are grouped: Internal Revenue Code → Treasury regulations → revenue rulings & procedures → treaties → other. **Default sources omit caselaw** — use `/case` for opinions. You may still pass `"caselaw"` in `sources` for a mixed card.

| Field | Notes |
|------|--------|
| `query` | Required |
| `sources` | Optional: `irc`, `treas_reg`, `caselaw`, `guidance`, `rev_rul`, `rev_proc`, `written_determinations`, `forms_pubs`, `treaties`, `irm` |
| `authorityTypes` | Narrow IRS / WD / IRM rows (e.g. `notice`, `plr`, `td`) |
| `codeSection` | IRC section the guidance interprets |
| `dateFrom` / `dateTo` | `YYYY-MM-DD` |
| `asOf` | Year filter |
| `perGroup` | Max hits per group (1–25, default 3). Prefer over `limit`. |
| `limit` | Legacy alias for `perGroup` |

```json
{
  "query": "qualified business income",
  "sources": ["irc", "treas_reg", "rev_rul", "rev_proc"],
  "codeSection": "199A",
  "perGroup": 3
}
```

### `POST /api/v1/tax/law` — read the Code or a regulation as of a year

Point-in-time statute reader. Editions held year by year from 1985. `compareTo` returns a word-level redline.

| Field | Notes |
|------|--------|
| `kind` | Required: `irc` or `treas_reg` |
| `cite` | Required, e.g. `"163"`, `"1.163(j)-1"` |
| `asOf` | Edition year |
| `compareTo` | Second year for redline |
| `includeText` | Boolean |

```json
{
  "kind": "irc",
  "cite": "163",
  "asOf": 2018,
  "compareTo": 2016,
  "includeText": true
}
```

### `POST /api/v1/tax/guidance` — retrieve one IRS document

Open a named IRS authority (Rev. Rul., Rev. Proc., notice, PLR, CCA, T.D., IRM, …) with status and optional text / cited-by.

| Field | Notes |
|------|--------|
| `cite` | Required |
| `includeText` | Default true |
| `includeCitedBy` | Boolean |

```json
{
  "cite": "Rev. Rul. 99-7",
  "includeText": true,
  "includeCitedBy": true
}
```

### `POST /api/v1/tax/check` — verify IRS guidance cites

Batch citator for **IRS guidance only** (up to 50 cites). Not for IRC or Treas. Reg. sections — use `/law` for those.

| Field | Notes |
|------|--------|
| `cites` | Required array, 1–50 strings |

```json
{
  "cites": ["Rev. Rul. 99-7", "Rev. Proc. 2002-22", "Notice 2014-21"]
}
```

### `POST /api/v1/tax/case` — tax caselaw (search + retrieve + good-law + citing cases + IRS)

**One endpoint for all tax caselaw work.**

| `mode` | Behavior |
|--------|----------|
| `auto` (default) | Resolve a unique cite / `caseId` → retrieve with good-law, citing cases, IRS context. Otherwise search. |
| `search` | Ranked hit list only |
| `retrieve` | One case; ambiguous cites return candidates |

| Field | Notes |
|------|--------|
| `query` | Citation, case name, or search words |
| `caseId` / `opinionId` | Open a known case |
| `courtIds` | Search filter (`scotus`, `ca9`, `tax`, `uscfc`, …) |
| `dateFrom` / `dateTo` | Search date filter |
| `limit` | Search hit cap (default 10) |
| `includeGoodLaw` | Default true on retrieve |
| `includeCitedBy` | Cases that cite this one (default true) |
| `includeIrsContext` | IRS authorities + AOD hits (default true) |
| `citedByLimit` | Default 25 |

```json
{
  "query": "T.C. Memo. 2019-14",
  "mode": "auto",
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
  "courtIds": ["tax", "scotus", "ca9"],
  "limit": 10
}
```

### `POST /api/v1/tax/treaty` — U.S. tax treaty articles

| Field | Notes |
|------|--------|
| `country` | Required |
| `article` | Optional |
| `topic` | `dividends`, `interest`, `royalties`, `pe`, `lob`, `pensions`, `residence`, `capital_gains`, `business_profits` |
| `asOf` | `YYYY-MM-DD` |

```json
{
  "country": "Germany",
  "topic": "dividends",
  "asOf": "2024-01-01"
}
```

### `POST /api/v1/tax/form` — form, instructions, or publication

| Field | Notes |
|------|--------|
| `number` | Required |
| `part` | `form` \| `instructions` \| `publication` |
| `taxYear` | Optional |
| `includeText` | Boolean |

```json
{
  "number": "1065",
  "part": "form",
  "taxYear": 2024,
  "includeText": true
}
```

Field-level marketing page: [lawdiver.com/products/tax-api](https://lawdiver.com/products/tax-api).

---

## Quick start

### curl

```bash
curl -s https://lawdiver.com/api/v1/tax/case \
  -H "Authorization: Bearer ld_tax_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"query":"T.C. Memo. 2019-14","mode":"auto"}'
```

Or run `examples/curl.sh` with `LAWDIVER_TAX_API_KEY` set (`./examples/curl.sh case`).

### TypeScript

```ts
const res = await fetch('https://lawdiver.com/api/v1/tax/guidance', {
  method: 'POST',
  headers: {
    Authorization: `Bearer ${process.env.LAWDIVER_TAX_API_KEY}`,
    'Content-Type': 'application/json',
  },
  body: JSON.stringify({ cite: 'Rev. Rul. 99-7', includeText: true }),
});
console.log(await res.json());
```

### Python

```python
import os, requests

r = requests.post(
    "https://lawdiver.com/api/v1/tax/check",
    headers={"Authorization": f"Bearer {os.environ['LAWDIVER_TAX_API_KEY']}"},
    json={"cites": ["Rev. Rul. 99-7", "Notice 2014-21"]},
)
print(r.json())
```

---

## REST ↔ MCP map

| REST | MCP tool |
|------|----------|
| `/api/v1/tax/search` | `tax_search` |
| `/api/v1/tax/law` | `get_tax_law` |
| `/api/v1/tax/guidance` | `get_irs_guidance` |
| `/api/v1/tax/check` | `check_tax_authority` |
| `/api/v1/tax/case` | `get_tax_case` |
| `/api/v1/tax/treaty` | `get_tax_treaty` |
| `/api/v1/tax/form` | `get_irs_form` |

---

## Related

- Caselaw API: [LawDiver_api](https://github.com/lawdiver/LawDiver_api) · [lawdiver.com/products/api](https://lawdiver.com/products/api)
- CiteCheck (tax authorities on the main cite-check path): [lawdiver.com/products/citecheck](https://lawdiver.com/products/citecheck)

---

## Keywords

IRS · Internal Revenue Code · IRC API · Treasury regulations · Treas. Reg. · revenue ruling API · Rev. Rul. · Rev. Proc. · tax research API · federal tax database · tax citation check · Tax Court API · LawDiver Tax · ld_tax_
