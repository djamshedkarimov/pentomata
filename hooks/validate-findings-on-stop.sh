#!/bin/bash
# Hook: Stop — Check that pentest findings are complete before ending
#
# Problem this solves: During past pentests, findings were reported with
# vague repro steps, unverified claims, and missing evidence. This hook checks the
# active report file for completeness before Claude finishes.
#
# How it works: Looks for the active report file in the engagement directory.
# If findings exist, checks each one has: endpoint, evidence, repro steps, severity.
# Warns (but doesn't block) if findings look incomplete.

TOOLKIT_DIR="$(cd "$(dirname "$0")/.." && pwd)"

# Look for active report in common engagement locations
REPORT=""
for path in \
  "$PWD/reports/active-exploitation-results.md" \
  "$PWD/active-exploitation-results.md" \
  "$TOOLKIT_DIR/engagements/*/reports/active-exploitation-results.md"; do
  if [[ -f "$path" ]]; then
    REPORT="$path"
    break
  fi
done

# No report file = not a pentest session, skip
if [[ -z "$REPORT" ]]; then
  exit 0
fi

ISSUES=""

# Count findings (lines starting with ### V followed by a number)
FINDING_COUNT=$(grep -cE '^### V[0-9]+' "$REPORT" 2>/dev/null || echo "0")

if [[ "$FINDING_COUNT" -gt 0 ]]; then
  # Check each finding section for required elements
  while IFS= read -r finding; do
    FINDING_NAME=$(echo "$finding" | sed 's/^### //')

    # Extract the section content (from this heading to next heading or end)
    SECTION=$(sed -n "/^### ${FINDING_NAME//\//\\/}/,/^### V[0-9]/p" "$REPORT" | head -50)

    # Check for required elements
    HAS_ENDPOINT=$(echo "$SECTION" | grep -ciE 'endpoint|url|path|/api/|/dashboard/' || true)
    HAS_EVIDENCE=$(echo "$SECTION" | grep -ciE 'evidence|proof|response|status|confirmed|verified' || true)
    HAS_REPRO=$(echo "$SECTION" | grep -ciE 'reproduc|steps|payload|curl|how to' || true)
    HAS_SEVERITY=$(echo "$SECTION" | grep -ciE 'critical|high|medium|low|severity' || true)

    MISSING=""
    [[ "$HAS_ENDPOINT" -eq 0 ]] && MISSING="${MISSING} endpoint,"
    [[ "$HAS_EVIDENCE" -eq 0 ]] && MISSING="${MISSING} evidence,"
    [[ "$HAS_REPRO" -eq 0 ]] && MISSING="${MISSING} repro-steps,"
    [[ "$HAS_SEVERITY" -eq 0 ]] && MISSING="${MISSING} severity,"

    if [[ -n "$MISSING" ]]; then
      MISSING="${MISSING%,}"  # Remove trailing comma
      ISSUES="${ISSUES}\n- ${FINDING_NAME}: missing${MISSING}"
    fi
  done < <(grep -E '^### V[0-9]+' "$REPORT")
fi

if [[ -n "$ISSUES" ]]; then
  echo -e "FINDINGS QUALITY CHECK — Some findings may be incomplete:${ISSUES}\n\nConsider verifying these before finalizing the report." >&2
  # Exit 0 (warn but don't block) — user may be doing incremental work
  exit 0
fi

exit 0
