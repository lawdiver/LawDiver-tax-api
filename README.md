# LawDiver Tax API

**Federal tax research over REST** — Internal Revenue Code by year, Treasury regulations, IRS guidance, forms, treaties, tax caselaw search, and IRS cite check.

| | |
|---|---|
| **Product** | [LawDiver for Tax](https://lawdiver.com/products/tax) |
| **API docs** | [LawDiver for Tax API](https://lawdiver.com/products/tax-api) |
| **Free web** | [https://lawdiver.com/tax](https://lawdiver.com/tax) |
| **Base URL** | `https://lawdiver.com/api/v1/tax` |
| **Keys** | `ld_tax_…` from [Account → API Keys](https://lawdiver.com/account?tab=api-keys) |
| **Signup** | [https://lawdiver.com/signup](https://lawdiver.com/signup) |
| **MCP** | `https://lawdiver.com/mcp/tax` (same eight jobs; tool catalog at `/mcp/tax/toolspec.json`) |

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

Eight calls. **Search** to discover. **Law / guidance / form / treaty / case-context** to retrieve. **Check** to verify IRS cites. **What's new** to monitor recent additions.

### `POST /api/v1/tax/search` — find authorities

Discovery search. Pass a research question or a citation. Results are grouped by level of authority: Internal Revenue Code → Treasury regulations → cases → revenue rulings & procedures → treaties → other (notices, PLRs, forms, …).

| Field | Notes |
|------|--------|
| `query` | Required |
| `sources` | Optional: `irc`, `treas_reg`, `caselaw`, `guidance`, `rev_rul`, `rev_proc`, `written_determinations`, `forms_pubs`, `treaties`, `irm`. Default omits `irm`. |
| `authorityTypes` | Narrow IRS / WD / IRM rows (e.g. `notice`, `plr`, `td`) |
| `courtIds` | Caselaw `court_registry` ids (`scotus`, `ca9`, `tax`, `uscfc`, …) |
| `codeSection` | IRC section the guidance interprets |
| `dateFrom` / `dateTo` | `YYYY-MM-DD` |
| `asOf` | Year filter for law / guidance that existed then |
| `perGroup` | Max hits per group (1–25, default 3). Prefer this over `limit`. |
| `limit` | Legacy alias for `perGroup` |

```json
{
  "query": "qualified business income",
  "sources": ["irc", "treas_reg", "caselaw", "rev_rul", "rev_proc"],
  "codeSection": "199A",
  "perGroup": 3,
  "courtIds": ["scotus", "ca9", "tax", "uscfc"]
}
```

### `POST /api/v1/tax/law` — read the Code or a regulation as of a year

Point-in-time statute reader for one IRC or Treas. Reg. section. Editions are held year by year from 1985. `compareTo` returns a word-level redline. Also returns edition history and citing IRS authorities for that section.

| Field | Notes |
|------|--------|
| `kind` | Required: `irc` or `treas_reg` |
| `cite` | Required, e.g. `"163"`, `"163(j)"`, `"1.163(j)-1"` |
| `asOf` | Edition year (at-or-before) |
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

Open a named IRS authority (Rev. Rul., Rev. Proc., notice, PLR, CCA, T.D., IRM, …). Returns Bluebook cite, Bulletin cite, IRS status, Code sections interpreted, optional text and cited-by. Letter rulings carry the IRC § 6110(k)(3) non-precedent notice.

| Field | Notes |
|------|--------|
| `cite` | Required, e.g. `"Rev. Rul. 99-7"` |
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

Batch citator for **IRS guidance only** (up to 50 cites). Not for IRC or Treas. Reg. sections — use `/law` for those. Reports existence, IRS adverse status from Bulletin effect sections / finding lists, separate judicial notes, and whether interpreted Code sections changed after issuance. `"No adverse action found"` is not a guarantee.

| Field | Notes |
|------|--------|
| `cites` | Required array, 1–50 strings |

```json
{
  "cites": ["Rev. Rul. 99-7", "Rev. Proc. 2002-22", "Notice 2014-21"]
}
```

### `POST /api/v1/tax/case-context` — IRS context for an opinion

Given an opinion id, return IRS authorities linked to that opinion and (if `caseName` is set) likely IRS AOD / acquiescence hits. Does **not** return full opinion text — use the [caselaw API](https://lawdiver.com/products/api) or Tax MCP `get_tax_case` for the opinion body.

| Field | Notes |
|------|--------|
| `opinionId` | Required positive integer (LawDiver or corpus opinion id) |
| `caseName` | Optional; improves AOD matching |

```json
{
  "opinionId": 12345678,
  "caseName": "Smith v. Commissioner"
}
```

### `POST /api/v1/tax/treaty` — U.S. tax treaty articles

Find tax treaty instruments with a partner country and return matching articles by number or topic. `asOf` keeps instruments that applied on that date. Technical Explanations are not loaded yet.

| Field | Notes |
|------|--------|
| `country` | Required |
| `article` | Optional article number |
| `topic` | Optional: `dividends`, `interest`, `royalties`, `pe`, `lob`, `pensions`, `residence`, `capital_gains`, `business_profits` |
| `asOf` | `YYYY-MM-DD` |

```json
{
  "country": "Germany",
  "topic": "dividends",
  "asOf": "2024-01-01"
}
```

### `POST /api/v1/tax/form` — form, instructions, or publication

Look up an IRS form / instructions / publication by number. Lists held revisions; `taxYear` picks a year (else latest). Returns PDF URL, optional text, and a short change summary vs the prior revision when available. Roughly the last ten tax years; still filling.

| Field | Notes |
|------|--------|
| `number` | Required, e.g. `"1065"`, `"Pub 535"` |
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

### `POST /api/v1/tax/whats-new` — recent guidance and form changes

Change feed since a date: new guidance rows and form revisions (with a one-line change summary when held). For monitoring, not deep historical research.

| Field | Notes |
|------|--------|
| `since` | Required `YYYY-MM-DD` |
| `codeSections` | Optional IRC sections (max 20) |
| `types` | Optional, e.g. `rev_rul`, `notice`, `plr`, `forms_pubs` (max 20) |
| `limit` | 1–200, default 50 |

```json
{
  "since": "2026-01-01",
  "codeSections": ["163"],
  "types": ["rev_rul", "notice"],
  "limit": 50
}
```

Field-level marketing page: [lawdiver.com/products/tax-api](https://lawdiver.com/products/tax-api).

---

## Quick start

### curl

```bash
curl -s https://lawdiver.com/api/v1/tax/law \
  -H "Authorization: Bearer ld_tax_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"kind":"irc","cite":"61","asOf":2024,"includeText":true}'
```

Or run `examples/curl.sh` with `LAWDIVER_TAX_API_KEY` set.

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
| `/api/v1/tax/case-context` | (IRS half of `get_tax_case`) |
| `/api/v1/tax/treaty` | `get_tax_treaty` |
| `/api/v1/tax/form` | `get_irs_form` |
| `/api/v1/tax/whats-new` | `tax_whats_new` |

---

## Related

- Caselaw API: [LawDiver_api](https://github.com/lawdiver/LawDiver_api) · [lawdiver.com/products/api](https://lawdiver.com/products/api)
- CiteCheck (tax authorities on the main cite-check path): [lawdiver.com/products/citecheck](https://lawdiver.com/products/citecheck)

---

## Keywords

IRS · Internal Revenue Code · IRC API · Treasury regulations · Treas. Reg. · revenue ruling API · Rev. Rul. · Rev. Proc. · tax research API · federal tax database · tax citation check · LawDiver Tax · ld_tax_
