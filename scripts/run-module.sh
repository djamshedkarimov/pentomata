#!/usr/bin/env bash
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  cat <<EOF
Usage: $0 <module> <target> [options...]

Optional security scanning modules. Run what you need, skip what you don't.

Modules:
  sast          Static analysis (semgrep)
  sca           Software composition analysis (osv-scanner, npm audit)
  secrets       Secret detection (gitleaks + trufflehog)
  dast          Dynamic scanning (nuclei)
  xss           XSS scanning (dalfox)
  fuzz          Directory/param fuzzing (ffuf)
  recon         Full recon pipeline (quick-recon.sh)
  all           Run sast + sca + secrets + dast

Options:
  --source DIR  Source code directory (for sast/sca/secrets)
  --output DIR  Output directory (default: ./scan-results)
  --wordlist F  Custom wordlist for fuzz module
  --templates D Custom nuclei templates directory

Examples:
  $0 sast --source ./app
  $0 dast https://target.com
  $0 secrets --source ./repo
  $0 all https://target.com --source ./app
  $0 xss "https://target.com/search?q=test"
EOF
  exit 1
}

[[ $# -lt 1 ]] && usage

MODULE="$1"; shift
TARGET="${1:-}"; [[ -n "$TARGET" && "$TARGET" != --* ]] && shift || TARGET=""

# Parse options
SOURCE_DIR=""
OUTPUT_DIR="./scan-results"
WORDLIST=""
CUSTOM_TEMPLATES=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --source)  SOURCE_DIR="$2"; shift 2 ;;
    --output)  OUTPUT_DIR="$2"; shift 2 ;;
    --wordlist) WORDLIST="$2"; shift 2 ;;
    --templates) CUSTOM_TEMPLATES="$2"; shift 2 ;;
    *) echo "Unknown option: $1"; usage ;;
  esac
done

mkdir -p "$OUTPUT_DIR"
TIMESTAMP=$(date +%Y%m%d-%H%M%S)

check_tool() {
  if ! command -v "$1" &>/dev/null; then
    echo "[!] $1 not found. Install with: $2"
    return 1
  fi
  return 0
}

run_sast() {
  echo "=== SAST: Static Analysis ==="
  if [[ -z "$SOURCE_DIR" ]]; then
    echo "[!] --source required for SAST. Skipping."
    return 1
  fi
  if check_tool semgrep "pip install semgrep"; then
    echo "[*] Running semgrep..."
    semgrep scan --config auto "$SOURCE_DIR" \
      --json --output "${OUTPUT_DIR}/semgrep-${TIMESTAMP}.json" 2>/dev/null || true
    semgrep scan --config auto "$SOURCE_DIR" \
      --text --output "${OUTPUT_DIR}/semgrep-${TIMESTAMP}.txt" 2>/dev/null || true
    echo "    Results: ${OUTPUT_DIR}/semgrep-${TIMESTAMP}.json"
  fi
}

run_sca() {
  echo "=== SCA: Software Composition Analysis ==="
  if [[ -z "$SOURCE_DIR" ]]; then
    echo "[!] --source required for SCA. Skipping."
    return 1
  fi

  # osv-scanner (Google's vulnerability scanner)
  if check_tool osv-scanner "brew install osv-scanner"; then
    echo "[*] Running osv-scanner..."
    osv-scanner scan --recursive "$SOURCE_DIR" \
      --format json > "${OUTPUT_DIR}/osv-scanner-${TIMESTAMP}.json" 2>/dev/null || true
    echo "    Results: ${OUTPUT_DIR}/osv-scanner-${TIMESTAMP}.json"
  fi

  # npm audit (if package.json exists)
  if [[ -f "${SOURCE_DIR}/package.json" ]]; then
    echo "[*] Running npm audit..."
    (cd "$SOURCE_DIR" && npm audit --json > "${OUTPUT_DIR}/npm-audit-${TIMESTAMP}.json" 2>/dev/null) || true
    echo "    Results: ${OUTPUT_DIR}/npm-audit-${TIMESTAMP}.json"
  fi

  # pip-audit (if requirements.txt exists)
  if [[ -f "${SOURCE_DIR}/requirements.txt" ]]; then
    if check_tool pip-audit "pip install pip-audit"; then
      echo "[*] Running pip-audit..."
      pip-audit -r "${SOURCE_DIR}/requirements.txt" \
        --format json --output "${OUTPUT_DIR}/pip-audit-${TIMESTAMP}.json" 2>/dev/null || true
      echo "    Results: ${OUTPUT_DIR}/pip-audit-${TIMESTAMP}.json"
    fi
  fi
}

run_secrets() {
  echo "=== Secrets: Secret Detection ==="
  if [[ -z "$SOURCE_DIR" ]]; then
    echo "[!] --source required for secrets scan. Skipping."
    return 1
  fi

  if check_tool gitleaks "brew install gitleaks"; then
    echo "[*] Running gitleaks..."
    gitleaks detect --source "$SOURCE_DIR" \
      --report-path "${OUTPUT_DIR}/gitleaks-${TIMESTAMP}.json" \
      --report-format json 2>/dev/null || true
    echo "    Results: ${OUTPUT_DIR}/gitleaks-${TIMESTAMP}.json"
  fi

  if check_tool trufflehog "brew install trufflehog"; then
    echo "[*] Running trufflehog..."
    trufflehog filesystem "$SOURCE_DIR" \
      --json > "${OUTPUT_DIR}/trufflehog-${TIMESTAMP}.json" 2>/dev/null || true
    echo "    Results: ${OUTPUT_DIR}/trufflehog-${TIMESTAMP}.json"
  fi
}

run_dast() {
  echo "=== DAST: Dynamic Scanning ==="
  if [[ -z "$TARGET" ]]; then
    echo "[!] Target URL required for DAST. Skipping."
    return 1
  fi

  if check_tool nuclei "brew install nuclei"; then
    echo "[*] Running nuclei..."
    TEMPLATE_FLAG=""
    if [[ -n "$CUSTOM_TEMPLATES" ]]; then
      TEMPLATE_FLAG="-t ${CUSTOM_TEMPLATES}"
    fi
    nuclei -u "$TARGET" $TEMPLATE_FLAG \
      -jsonl -output "${OUTPUT_DIR}/nuclei-${TIMESTAMP}.jsonl" \
      -silent 2>/dev/null || true
    echo "    Results: ${OUTPUT_DIR}/nuclei-${TIMESTAMP}.jsonl"
  fi
}

run_xss() {
  echo "=== XSS: Cross-Site Scripting Scan ==="
  if [[ -z "$TARGET" ]]; then
    echo "[!] Target URL required for XSS scan. Skipping."
    return 1
  fi

  if check_tool dalfox "brew install dalfox"; then
    echo "[*] Running dalfox..."
    dalfox url "$TARGET" \
      --silence --output "${OUTPUT_DIR}/dalfox-${TIMESTAMP}.txt" 2>/dev/null || true
    echo "    Results: ${OUTPUT_DIR}/dalfox-${TIMESTAMP}.txt"
  fi
}

run_fuzz() {
  echo "=== Fuzz: Directory/Parameter Fuzzing ==="
  if [[ -z "$TARGET" ]]; then
    echo "[!] Target URL required for fuzzing. Skipping."
    return 1
  fi

  if check_tool ffuf "brew install ffuf"; then
    WL="${WORDLIST:-${TOOLKIT_DIR}/wordlists/Discovery/Web-Content/common.txt}"
    if [[ ! -f "$WL" ]]; then
      echo "[!] Wordlist not found: $WL"
      return 1
    fi
    echo "[*] Running ffuf..."
    ffuf -u "${TARGET}/FUZZ" -w "$WL" \
      -mc 200,301,302,403 \
      -o "${OUTPUT_DIR}/ffuf-${TIMESTAMP}.json" -of json -s 2>/dev/null || true
    echo "    Results: ${OUTPUT_DIR}/ffuf-${TIMESTAMP}.json"
  fi
}

# Dispatch
case "$MODULE" in
  sast)    run_sast ;;
  sca)     run_sca ;;
  secrets) run_secrets ;;
  dast)    run_dast ;;
  xss)     run_xss ;;
  fuzz)    run_fuzz ;;
  recon)   exec "${TOOLKIT_DIR}/scripts/quick-recon.sh" "$TARGET" "$OUTPUT_DIR" ;;
  all)
    run_sast
    echo ""
    run_sca
    echo ""
    run_secrets
    echo ""
    run_dast
    ;;
  *)
    echo "Unknown module: $MODULE"
    usage
    ;;
esac

echo ""
echo "=== Scan complete. Results in: ${OUTPUT_DIR}/ ==="
ls -la "$OUTPUT_DIR"/*-${TIMESTAMP}* 2>/dev/null || echo "(no output files generated)"
