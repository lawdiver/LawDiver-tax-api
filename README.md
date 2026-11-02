# LawDiver Tax API

**Federal tax research over REST** — Internal Revenue Code by year, Treasury regulations, IRS revenue rulings and procedures, notices, written determinations, forms, treaties, and cite check.

| | |
|---|---|
| **Product** | [LawDiver for Tax](https://lawdiver.com/products/tax) |
| **API docs** | [LawDiver for Tax API](https://lawdiver.com/products/tax-api) |
| **Free web** | [https://lawdiver.com/tax](https://lawdiver.com/tax) |
| **Base URL** | `https://lawdiver.com/api/v1/tax` |
| **Keys** | `ld_tax_…` from [Account → API Keys](https://lawdiver.com/account?tab=api-keys) |
| **Signup** | [https://lawdiver.com/signup](https://lawdiver.com/signup) |

The **web product is free for now**. An API key needs a regular LawDiver account. Tax keys are separate from caselaw `ld_live_` keys — they only open `/api/v1/tax/*` (and Tax MCP at `/mcp/tax`). Caselaw cite-check still resolves tax authorities with your regular key; deep tax search/law/guidance stays on this surface.

Claude.ai and OpenAI directory connectors for Tax are **coming soon**. Tax MCP works today with an `ld_tax_` key.

---

## Authentication

```http
Authorization: Bearer ld_tax_YOUR_KEY
Content-Type: application/json
```

Also accepted: `X-API-Key` or `lawdiver_api_key`.

---

## Endpoints

All methods are `POST` with a JSON body. Responses use the LawDiver `/api/v1` envelope (`ok`, `data`, `requestId`, …).

| Path | Purpose |
|------|---------|
| `/api/v1/tax/search` | Search IRC, regs, guidance, forms, treaties, IRM |
| `/api/v1/tax/law` | IRC or Treas. Reg. section by year (+ optional redline) |
| `/api/v1/tax/guidance` | Rev. Rul. / Proc. / notice / PLR / etc. |
| `/api/v1/tax/check` | Verify up to 50 tax cites |
| `/api/v1/tax/case-context` | IRS context for an opinion id |
| `/api/v1/tax/treaty` | Income-tax treaty article |
| `/api/v1/tax/form` | Form / instructions / publication revision |
| `/api/v1/tax/whats-new` | Guidance and forms since a date |

Full field-level examples: [lawdiver.com/products/tax-api](https://lawdiver.com/products/tax-api).

---

## Quick start

### curl

```bash
curl -s https://lawdiver.com/api/v1/tax/law \
  -H "Authorization: Bearer ld_tax_YOUR_KEY" \
  -H "Content-Type: application/json" \
  -d '{"kind":"irc","cite":"61","asOf":2024,"includeText":true}'
```

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
    json={"cites": ["I.R.C. § 61", "Rev. Rul. 99-7"]},
)
print(r.json())
```

---

## Example bodies

**Search**

```json
{
  "query": "qualified business income",
  "sources": ["irc", "guidance"],
  "codeSection": "199A",
  "limit": 10
}
```

**Law**

```json
{
  "kind": "irc",
  "cite": "163",
  "asOf": 2018,
  "compareTo": 2016,
  "includeText": true
}
```

**What's new**

```json
{
  "since": "2026-01-01",
  "codeSections": ["163"],
  "limit": 50
}
```

---

## Related

- Caselaw API: [LawDiver_api](https://github.com/lawdiver/LawDiver_api) · [lawdiver.com/products/api](https://lawdiver.com/products/api)
- CiteCheck (tax authorities on the main cite-check path): [lawdiver.com/products/citecheck](https://lawdiver.com/products/citecheck)

---

## Keywords

IRS · Internal Revenue Code · IRC API · Treasury regulations · Treas. Reg. · revenue ruling API · Rev. Rul. · Rev. Proc. · tax research API · federal tax database · tax citation check · LawDiver Tax · ld_tax_
