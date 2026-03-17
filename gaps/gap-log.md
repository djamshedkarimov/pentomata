# Tooling Gap Log

Capability gaps in the pentest toolkit — things we couldn't do, tools that didn't work, or workflows that are missing. Each gap is something to fix or build so the next engagement runs smoother.

When a gap is hit during an engagement, log it here immediately with context on why it blocked us and what the fix might be. When the fix is built, move it to the Resolved section.

---

## Open Gaps

### GAP-001: Burp Suite MCP active testing unreliable
- **First seen:** Initial engagement
- **What happened:** Repeater and Intruder requests timed out consistently. Could not use Burp for active HTTP testing.
- **Workaround used:** curl via Bash for header injection, Playwright `browser_evaluate` + fetch() for everything else
- **Why this matters:** No reliable tool for raw HTTP request manipulation with full header control beyond curl. Curl works but lacks Burp's response diffing, intruder automation, and session handling.
- **Possible fix:** Debug MCP connection settings (timeout config, proxy settings). Test if the Playwright Plugin can serve as an alternative for raw HTTP. Consider building a lightweight HTTP request tool into pentest-runner.js.

### GAP-002: No SSRF out-of-band verification workflow
- **First seen:** Initial engagement
- **What happened:** Burp Collaborator (`collaborator_generate`, `collaborator_poll`) was available but never integrated into the testing workflow. SSRF testing relied only on response content — if the server fetches an internal URL but doesn't return the content, we'd miss it.
- **Why this matters:** Blind SSRF is undetectable without out-of-band callbacks. This is a fundamental detection gap.
- **Possible fix:** Build a Collaborator workflow into the pentest skill — generate callback URL at start of SSRF tests, submit as payload, poll for hits after. Alternatively, set up a lightweight callback server (e.g., interactsh) if Burp Collaborator remains unreliable.

### GAP-003: No timing-based SSRF detection
- **First seen:** Initial engagement
- **What happened:** Planned to compare response times (internal IPs resolve faster than external) to detect blind SSRF. Never built.
- **Why this matters:** Even without Collaborator, response time differences can reveal whether the server is making outbound connections.
- **Possible fix:** Add a timing comparison function to pentest-runner.js — send same request with internal vs external URL, compare response times, flag significant differences.

### GAP-004: No multi-account test data setup
- **First seen:** Initial engagement
- **What happened:** IDOR tests used fake UUIDs instead of real cross-user resource IDs. Only had 2 test accounts with no shared resources between them. Payment and booking actions needed real transaction data (Stripe sessions, completed bookings) that didn't exist.
- **Why this matters:** IDOR and business logic tests are only valid with real cross-user data. Testing with fake IDs only proves the app handles non-existent resources — not that it enforces ownership.
- **Possible fix:** Build an engagement setup checklist in the pentest skill — request 2+ test accounts with pre-seeded data (existing bookings, sessions, reviews, invitations) before testing begins. Add a "test data requirements" section to Phase 1.

### GAP-005: No automated WAF bypass escalation
- **First seen:** Initial engagement
- **What happened:** WAF bypass encoding ladder (L0-L8 + WAF-specific payloads) was executed manually — writing each variant, sending it, checking the response, moving to next level.
- **Why this matters:** 17 bypass variants × multiple endpoints = tedious manual work. Easy to miss a combination.
- **Possible fix:** Build a WAF bypass function into pentest-runner.js that takes a base payload and automatically sends all encoding variants, returning a results table. One function call instead of 17 manual tests per endpoint.

---

## Resolved

| ID | Gap | Resolution | Date |
|----|-----|-----------|------|
| — | Tested non-existent endpoints | Pentest skill validation gate Check 1 (pre-flight GET) | 2026-03-17 |
| — | Impossible attack chains claimed | Pentest skill validation gate Check 3 (trace full chain) | 2026-03-17 |
| — | Platform limitations reported as findings | Pentest skill validation gate Check 2 ("can they fix it?") | 2026-03-17 |
| — | Overwrote user's Linear edits | CLAUDE.md rules + protect-linear-description hook | 2026-03-17 |
| — | Vague reproduction steps | Pentest skill validation gate Check 5 (copy-pasteable steps) | 2026-03-17 |
| — | Inflated severity ratings | Pentest skill validation gate Check 6 (conservative default) | 2026-03-17 |
