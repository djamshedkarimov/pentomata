#!/usr/bin/env bash
set -euo pipefail

TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

usage() {
  echo "Usage: $0 <client-name> [target-url]"
  echo ""
  echo "Creates a new engagement directory under ${TOOLKIT_DIR}/engagements/"
  echo ""
  echo "Example:"
  echo "  $0 acme-corp https://app.acme.com"
  exit 1
}

[[ $# -lt 1 ]] && usage

CLIENT="$1"
TARGET="${2:-}"
ENGAGEMENT_DIR="${TOOLKIT_DIR}/engagements/${CLIENT}"

if [[ -d "$ENGAGEMENT_DIR" ]]; then
  echo "Error: Engagement '${CLIENT}' already exists at ${ENGAGEMENT_DIR}"
  exit 1
fi

echo "Creating engagement: ${CLIENT}"

mkdir -p "${ENGAGEMENT_DIR}"/{reports/evidence,notes,scans}

# README with engagement overview
cat > "${ENGAGEMENT_DIR}/README.md" << EOF
# Engagement: ${CLIENT}

## Target
${TARGET:-TBD}

## Type
- [ ] White-box (source access)
- [ ] Black-box

## In Scope
- [ ] Web application
- [ ] API endpoints
- [ ] Authentication flows
- [ ] Authorization / IDOR
- [ ] File upload
- [ ] Admin panel
- [ ] Webhooks
- [ ] Embed / widget endpoints

## Out of Scope
- [ ] Infrastructure / network
- [ ] Social engineering
- [ ] DoS / DDoS

## Test Accounts
<!-- Add test account credentials here -->

## Tech Stack
<!-- Framework, auth provider, hosting, WAF, ORM -->

## Notes
Created: $(date +%Y-%m-%d)
EOF

# Pentest plan placeholder
cat > "${ENGAGEMENT_DIR}/plan.md" << EOF
# Pentest Plan: ${CLIENT}

## Target
${TARGET:-TBD}

## Attack Surface
<!-- Map all testable surfaces during recon:
- User-facing pages, forms, input fields
- API endpoints and webhook handlers
- Server actions / mutation endpoints
- Embed/widget endpoints
- Auth flows (login, signup, OAuth, OTP, password reset)
-->

## Test Groups
<!-- Define test groups based on the attack surface.
See skills/pentest/SKILL.md Phase 2 for test categories. -->

## Tools
<!-- Which tools for which tests:
- Playwright MCP: form injection, DOM inspection, authenticated sessions
- pentest-runner.js: bulk HTTP tests (customize scripts/pentest-runner.js for this target)
- curl: header injection (X-Forwarded-Host, Host, CRLF)
- Burp Suite MCP: traffic analysis, Collaborator for SSRF
-->
EOF

# Findings notes
cat > "${ENGAGEMENT_DIR}/notes/findings.md" << EOF
# Findings: ${CLIENT}

<!-- Log findings as you go. Move validated findings to reports/. -->

## Critical

## High

## Medium

## Low

## Informational

## Dropped During Validation
<!-- Findings that didn't pass the validation gate. Include reason. -->
EOF

echo ""
echo "Engagement created at: ${ENGAGEMENT_DIR}"
echo ""
echo "Structure:"
find "${ENGAGEMENT_DIR}" -type f -o -type d | sort | sed "s|${TOOLKIT_DIR}/||"
echo ""
echo "Next steps:"
echo "  1. Fill in README.md with scope, credentials, and tech stack"
echo "  2. Copy and customize scripts/pentest-runner.js for this target"
echo "  3. Start Claude Code: cd ${TOOLKIT_DIR} && claude"
echo "  4. Tell Claude: 'Start a pentest engagement against ${TARGET:-<target-url>}'"
