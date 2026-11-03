#!/usr/bin/env bash
# Usage: LAWDIVER_TAX_API_KEY=ld_tax_… ./examples/curl.sh [search|retrieve|case|treaty|check]
set -euo pipefail
BASE="${LAWDIVER_TAX_BASE:-https://lawdiver.com/api/v1/tax}"
KEY="${LAWDIVER_TAX_API_KEY:?Set LAWDIVER_TAX_API_KEY}"
CMD="${1:-retrieve}"

hdr=(-H "Authorization: Bearer ${KEY}" -H "Content-Type: application/json")

case "$CMD" in
  search)
    curl -sS "$BASE/search" "${hdr[@]}" -d '{
      "query": "qualified business income",
      "sources": ["irc", "treas_reg", "rev_rul", "rev_proc"],
      "codeSection": "199A",
      "limit": 20
    }' | jq .
    ;;
  retrieve)
    curl -sS "$BASE/retrieve" "${hdr[@]}" -d '{
      "kind": "irc",
      "cite": "61",
      "includeText": true
    }' | jq .
    ;;
  case)
    curl -sS "$BASE/case" "${hdr[@]}" -d '{
      "query": "T.C. Memo. 2019-14",
      "mode": "auto",
      "includeGoodLaw": true,
      "includeCitedBy": true,
      "includeIrsContext": true
    }' | jq .
    ;;
  treaty)
    curl -sS "$BASE/treaty" "${hdr[@]}" -d '{
      "country": "Germany",
      "mode": "auto",
      "topic": "dividends",
      "asOf": "2024-01-01"
    }' | jq .
    ;;
  check)
    curl -sS "$BASE/check" "${hdr[@]}" -d '{
      "cites": ["Rev. Rul. 99-7", "Rev. Proc. 2002-22", "Notice 2014-21"]
    }' | jq .
    ;;
  *)
    echo "Unknown command: $CMD (use search|retrieve|case|treaty|check)" >&2
    exit 1
    ;;
esac
