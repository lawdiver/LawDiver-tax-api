#!/usr/bin/env bash
# Requires LAWDIVER_TAX_API_KEY (ld_tax_…)
set -euo pipefail
BASE="${LAWDIVER_API_BASE:-https://lawdiver.com}"
KEY="${LAWDIVER_TAX_API_KEY:?Set LAWDIVER_TAX_API_KEY to an ld_tax_ key}"

curl -sS "$BASE/api/v1/tax/law" \
  -H "Authorization: Bearer $KEY" \
  -H "Content-Type: application/json" \
  -d '{"kind":"irc","cite":"61","asOf":2024,"includeText":true}'
echo
