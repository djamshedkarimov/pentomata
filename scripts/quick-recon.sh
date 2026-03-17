#!/usr/bin/env bash
set -euo pipefail

usage() {
  echo "Usage: $0 <target-url> [output-dir]"
  echo ""
  echo "Runs automated recon pipeline against a target."
  echo "Output defaults to ./recon-output/"
  exit 1
}

[[ $# -lt 1 ]] && usage

TARGET="$1"
OUTPUT="${2:-./recon-output}"
mkdir -p "$OUTPUT"

DOMAIN=$(echo "$TARGET" | sed 's|https\?://||' | sed 's|/.*||')

echo "=== Quick Recon: ${TARGET} ==="
echo "Domain: ${DOMAIN}"
echo "Output: ${OUTPUT}"
echo ""

# 1. Nuclei scan
if command -v nuclei &>/dev/null; then
  echo "[*] Running nuclei scan..."
  nuclei -u "$TARGET" -o "${OUTPUT}/nuclei-results.txt" -silent 2>/dev/null || true
  echo "    Results: ${OUTPUT}/nuclei-results.txt"
else
  echo "[!] nuclei not found, skipping"
fi

# 2. ffuf directory bruteforce
if command -v ffuf &>/dev/null; then
  TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
  WORDLIST="${TOOLKIT_DIR}/wordlists/Discovery/Web-Content/common.txt"
  if [[ -f "$WORDLIST" ]]; then
    echo "[*] Running ffuf directory scan..."
    ffuf -u "${TARGET}/FUZZ" -w "$WORDLIST" -mc 200,301,302,403 -o "${OUTPUT}/ffuf-dirs.json" -of json -s 2>/dev/null || true
    echo "    Results: ${OUTPUT}/ffuf-dirs.json"
  else
    echo "[!] Wordlist not found at ${WORDLIST}, skipping ffuf"
  fi
else
  echo "[!] ffuf not found, skipping"
fi

# 3. Dalfox XSS scan
if command -v dalfox &>/dev/null; then
  echo "[*] Running dalfox XSS scan..."
  dalfox url "$TARGET" --silence --output "${OUTPUT}/dalfox-results.txt" 2>/dev/null || true
  echo "    Results: ${OUTPUT}/dalfox-results.txt"
else
  echo "[!] dalfox not found, skipping"
fi

# 4. Gitleaks (if target is a local repo)
if command -v gitleaks &>/dev/null && [[ -d ".git" ]]; then
  echo "[*] Running gitleaks on current repo..."
  gitleaks detect --source . --report-path "${OUTPUT}/gitleaks-report.json" --report-format json 2>/dev/null || true
  echo "    Results: ${OUTPUT}/gitleaks-report.json"
fi

echo ""
echo "=== Recon complete ==="
echo "Results saved to: ${OUTPUT}/"
