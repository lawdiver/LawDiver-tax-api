#!/usr/bin/env bash
# Requires LAWDIVER_TAX_API_KEY (ld_tax_…)
# Usage: ./examples/curl.sh [law|search|guidance|check|case|form|treaty]
set -euo pipefail
BASE="${LAWDIVER_API_BASE:-https://lawdiver.com}"
KEY="${LAWDIVER_TAX_API_KEY:?Set LAWDIVER_TAX_API_KEY to an ld_tax_ key}"
CMD="${1:-case}"

hdr=(-H "Authorization: Bearer $KEY" -H "Content-Type: application/json")

case "$CMD" in
  law)
    curl -sS "$BASE/api/v1/tax/law" "${hdr[@]}" \
      -d '{"kind":"irc","cite":"61","asOf":2024,"includeText":true}'
    ;;
  search)
    curl -sS "$BASE/api/v1/tax/search" "${hdr[@]}" \
      -d '{"query":"qualified business income","codeSection":"199A","perGroup":3}'
    ;;
  guidance)
    curl -sS "$BASE/api/v1/tax/guidance" "${hdr[@]}" \
      -d '{"cite":"Rev. Rul. 99-7","includeText":true}'
    ;;
  check)
    curl -sS "$BASE/api/v1/tax/check" "${hdr[@]}" \
      -d '{"cites":["Rev. Rul. 99-7","Notice 2014-21"]}'
    ;;
  case)
    curl -sS "$BASE/api/v1/tax/case" "${hdr[@]}" \
      -d '{"query":"T.C. Memo. 2019-14","mode":"auto"}'
    ;;
  form)
    curl -sS "$BASE/api/v1/tax/form" "${hdr[@]}" \
      -d '{"number":"1065","part":"form","taxYear":2024,"includeText":false}'
    ;;
  treaty)
    curl -sS "$BASE/api/v1/tax/treaty" "${hdr[@]}" \
      -d '{"country":"Germany","topic":"dividends","asOf":"2024-01-01"}'
    ;;
  *)
    echo "Unknown command: $CMD (law|search|guidance|check|case|form|treaty)" >&2
    exit 1
    ;;
esac
echo
