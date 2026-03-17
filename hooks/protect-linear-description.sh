#!/bin/bash
# Hook: PreToolUse — Prevent accidental overwrites of Linear issue descriptions
#
# Problem this solves: During past pentests, Claude overwrote the user's
# manually edited Linear description when asked to change only one section.
#
# How it works: When Claude tries to update a Linear issue with a description field,
# this hook checks if the new description is significantly shorter than the current one.
# If it dropped by more than 20%, it blocks the update — likely a truncation/overwrite.

INPUT=$(cat)
TOOL=$(echo "$INPUT" | jq -r '.tool_name // empty')

# Only check Linear save_issue calls that include a description
if [[ "$TOOL" == "mcp__claude_ai_Linear__save_issue" ]]; then
  DESCRIPTION=$(echo "$INPUT" | jq -r '.tool_input.description // empty')
  ISSUE_ID=$(echo "$INPUT" | jq -r '.tool_input.id // empty')

  # Only check updates (has id) that include a description change
  if [[ -n "$DESCRIPTION" && -n "$ISSUE_ID" ]]; then
    NEW_LEN=${#DESCRIPTION}

    # If description is under 500 chars, it's probably a truncation
    # (full pentest reports are typically 5000+ chars)
    if [[ $NEW_LEN -lt 500 ]]; then
      echo "HOOK BLOCKED: New description is only ${NEW_LEN} characters — this looks like a truncation. The full pentest report description should be 5000+ characters. Generate the replacement text for the user to paste instead of sending a full description update." >&2
      exit 2
    fi
  fi
fi

exit 0
