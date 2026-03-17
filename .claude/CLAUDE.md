# Pentest Toolkit — Claude Instructions

## Project Overview
This is a penetration testing toolkit for web application security assessments. It contains engagement data, testing scripts, skills, hooks, and report artifacts.

## Directory Structure

### Toolkit (committed to git)
- `scripts/` — Reusable scripts (pentest-runner.js, new-engagement.sh, quick-recon.sh)
- `skills/pentest/` — Pentest skill with methodology, validation gates, and report template
- `hooks/` — Claude Code hooks for quality control
- `templates/` — Report and scope templates for new engagements
- `payloads/` — Payload collections by attack type (xss, ssrf, idor, auth-bypass)
- `wordlists/` — Fuzzing and discovery wordlists
- `config/` — Tool configs (Burp projects, Nuclei custom templates)
- `gaps/` — Tooling capability backlog

### Engagements (gitignored — never committed)
- `engagements/{client}/` — Per-client engagement data

Each engagement follows this structure:
```
engagements/{client}/
├── README.md          ← engagement overview & scope
├── plan.md            ← pentest plan
├── notes/             ← research, setup guides, ideas
├── repo/              ← client source code (if white-box)
├── scans/             ← ALL automated scan output (nuclei, gitleaks, dalfox, ffuf, etc.)
└── reports/           ← human-written findings & final report
    └── evidence/      ← screenshots, PoC files
```

## When Starting a Pentest Engagement
Always use the pentest skill (`skills/pentest/SKILL.md`). It covers the full workflow: reconnaissance, testing, finding validation, report generation, and user validation.

## User Preferences
- Narrate each step during testing — explain what you're doing, why, and what payload you're sending
- Don't stop for approval during active testing — keep momentum
- User is building pentest methodology knowledge — explain decisions as you go
- When updating Linear issues, generate replacement text for the user to paste rather than sending full description updates

## Critical Rules (from past engagement lessons)

### Finding Quality
- **Verify endpoints exist before testing** — GET the base URL with no payload first. If it 404s, don't test it.
- **Validate findings internally before presenting** — every finding must pass all 6 checks in the pentest skill's validation gate
- **Only report what the target team can fix** — vendor/platform limitations (auth providers, hosting platforms, WAF behaviors) are context, not findings
- **Trace attack chains end-to-end** — don't claim vulnerabilities chain together without verifying origins, cookie scope, and data flow
- **Back every claim with evidence** — decode the JWT, fetch the endpoint, show the response. No speculation.
- **Be conservative on severity** — propose one level lower than your gut. Let the user upgrade.

### Reporting
- **Exact repro steps** — copy-pasteable payloads, exact URLs, exact things to look for
- **Fewer verified findings > more findings that get dropped** — quality over quantity
- **Save progress to files frequently** — checkpoint findings to `reports/active-exploitation-results.md` to survive context limits
- See `skills/pentest/references/report-template.md` for the Linear report structure

### Linear Issue Safety
- Never send full description updates when only one section needs changing
- Generate replacement text and let the user paste it
- When asked to change X, change only X — touch nothing else
- The protect-linear-description hook will block updates under 500 characters as a safety net

## Tools

### Primary (proven in engagements)
- **Playwright MCP** — Core testing tool. Authenticated browser sessions, form injection, DOM inspection via `browser_snapshot`, XSS detection via `browser_handle_dialog`, and running bulk tests via `browser_evaluate`. Most tests go through this.
- **pentest-runner.js** (`tooling/pentest-runner.js`) — Custom bulk test script executed inside Playwright's authenticated browser context via `browser_evaluate`. Handles HTTP requests and server action calls with cookies automatically included. Extend per engagement with new payloads.
- **curl** (via Bash) — Header injection tests that browsers block: X-Forwarded-Host, Host poisoning, CRLF injection. Use for any test requiring custom request headers.
- **Linear MCP** — Report delivery. Create pentest report issues, post finding write-ups as comments. Subject to Cloudflare WAF — describe payloads textually, don't include literal XSS in API calls.

### Secondary (partially useful, known limitations)
- **Burp Suite MCP** — Proxy history analysis (`proxy_http_history`) works well for traffic review. Active testing (repeater, intruder) has had connection timeout issues. Collaborator (`collaborator_generate`, `collaborator_poll`) is available for SSRF verification but not yet tested — try it next engagement.

### Worth exploring
- **Playwright Plugin** (agent browser, `mcp__plugin_playwright_playwright__*`) — Same browser capabilities as Playwright MCP but integrated through the plugin system. Not yet tested in a pentest — try it and compare reliability/speed.

## Gap Tracking — Tooling Improvement Backlog

When something in the toolkit doesn't work, is missing, or forces a workaround during an engagement, log it to `gaps/gap-log.md` immediately. These are capability gaps — things to engineer fixes for so future engagements run better.

### What counts as a gap
- A tool that failed or was unreliable (Burp timeouts, MCP connection issues)
- A capability that's missing entirely (no out-of-band SSRF detection, no automated WAF bypass escalation)
- A workflow that required manual workarounds instead of being automated
- Missing test infrastructure (no multi-account setup, no test transaction data)

### When to record
Log to `gaps/gap-log.md` the moment you hit a snag — don't wait until the engagement ends. Include what happened, why it matters, and ideas for a fix.

### After each engagement
Review open gaps. If a gap has a clear fix, build it (update pentest-runner.js, add a new tool, update the skill) and move it to the Resolved section.
