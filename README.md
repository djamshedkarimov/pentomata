# Pentest Toolkit

AI-assisted penetration testing toolkit that connects Claude Code to professional security tools via MCP. Codifies methodology, validation gates, and reporting so engagements are repeatable and findings are solid.

Built from real engagement lessons — the methodology exists because past pentests revealed that the biggest risks aren't missed vulnerabilities, they're false positives, inflated severity, and wasted time on non-issues.

---

## Quick Start

### 1. Prerequisites

| Requirement | Check | Install |
|---|---|---|
| macOS with Homebrew | `brew --version` | [brew.sh](https://brew.sh) |
| Node.js (v18+) | `node --version` | `brew install node` |
| Claude Code CLI | `claude --version` | `npm install -g @anthropic-ai/claude-code` |
| Burp Suite Pro | Open Burp | [portswigger.net/burp/pro](https://portswigger.net/burp/pro) |

### 2. Clone the repo

```bash
git clone --recurse-submodules https://github.com/djamshedkarimov/pentomata.git ~/pentomata
cd ~/pentomata
```

This clones the toolkit along with [SecLists](https://github.com/danielmiessler/SecLists) wordlists as a submodule.

If you already cloned without `--recurse-submodules`, pull the wordlists separately:

```bash
git submodule update --init --depth 1
```

### 3. Install security tools

```bash
# Core tools (required)
brew install nuclei        # Vulnerability scanner
brew install ffuf          # Web fuzzer
brew install dalfox        # XSS scanner
brew install gitleaks      # Secret detection in git repos
brew install trufflehog    # Deep secret scanning across git history

# Optional — for source code review
brew install semgrep       # Static analysis (SAST)
brew install osv-scanner   # Dependency vulnerability check (SCA)
```

### 4. Configure MCP servers

These let Claude Code talk to security tools directly.

```bash
# Burp Suite MCP — connects Claude Code to Burp Suite Pro
claude mcp add --scope user burp-ai-agent -- npx -y supergateway --sse http://127.0.0.1:9876/sse

# Playwright MCP — browser automation for interactive testing
claude mcp add --scope user playwright -- npx -y @playwright/mcp@latest
```

Verify: `claude mcp list` should show both servers.

### 5. Set up Burp Suite extension

1. Download the latest `.jar` from [burp-ai-agent releases](https://github.com/six2dez/burp-ai-agent/releases)
2. In Burp: **Extensions** > **Installed** > **Add** > select the `.jar`
3. In the **burp-ai-agent** tab: **Settings** > **MCP Server** > **Enable** on port **9876**
4. Restart Claude Code

### 6. Verify everything works

```bash
# Tools installed
nuclei -version && ffuf -V && dalfox version && gitleaks version && trufflehog --version

# MCP servers registered
claude mcp list

# Start Claude Code from the toolkit directory
cd ~/pentomata
claude
```

Inside Claude Code, test the connections:
- `List the Burp proxy history` (requires Burp running)
- `Use Playwright to navigate to https://example.com and take a snapshot`

---

## Starting a Pentest Engagement

### Step 1: Create the engagement

```bash
cd ~/pentomata
./scripts/new-engagement.sh "client-name" "https://target.example.com"
```

This creates the engagement folder with scope template, plan template, and notes.

### Step 2: Fill in the scope

Edit `engagements/client-name/README.md` with:
- Target URL
- Test account credentials
- Tech stack (framework, auth provider, hosting, WAF)
- What's in scope and out of scope

### Step 3: Customize the test runner (optional)

Copy and edit `scripts/pentest-runner.js` for the target. The script has placeholder endpoints marked with `{curly-braces}` — replace them with the target's actual URLs:

```
{other-user-slug}      → the slug of another test account's profile
{own-slug}             → your test account's profile slug
{other-user-profile-id} → another user's resource ID (for IDOR tests)
{service}              → the webhook service name (e.g., clerk, stripe)
/api/upload/images     → the target's actual upload endpoint
/auth/callback         → the target's auth callback URL
/search                → the target's search endpoint
```

Remove tests that don't apply to the target and add new ones for target-specific endpoints.

### Step 4: Start Claude Code

```bash
cd ~/pentomata
claude
```

Claude Code automatically loads the project instructions and the pentest skill. Tell it what to do:

```
Start a pentest engagement against https://target.example.com
```

Or be more specific:

```
Run the pentest test plan for the acme-corp engagement. Target is https://app.acme.com,
test account is test@example.com / password123. It's a Next.js app on Vercel with
Clerk auth and Cloudflare WAF.
```

The pentest skill guides the full workflow:

1. **Reconnaissance** — gather scope, credentials, tech stack, map attack surface
2. **Testing** — systematic tests across XSS, SQLi, SSRF, IDOR, CSRF, parameter tampering, header injection, webhook forgery
3. **Validation** — every finding passes 6 checks before reporting (endpoint exists? team can fix it? attack chain possible? evidence? repro steps? conservative severity?)
4. **Reporting** — findings saved locally, then published to Linear with structured write-ups
5. **User validation** — findings presented one at a time, user decides keep/drop/severity

### Engagement folder structure

```
engagements/{client}/
├── README.md          # Engagement overview & scope
├── plan.md            # Pentest plan
├── notes/             # Research, setup guides, ideas
├── repo/              # Client source code (if white-box)
├── scans/             # ALL automated scan output (nuclei, gitleaks, dalfox, ffuf, etc.)
└── reports/           # Human-written findings & final report
    └── evidence/      # Screenshots, PoC files
```

Engagement data is gitignored — it never leaves your machine.

---

## Running Scans

All scanning goes through `scripts/run-module.sh`:

```bash
TOOLKIT=~/pentomata

# Source code scans (need --source)
$TOOLKIT/scripts/run-module.sh sast --source /path/to/app
$TOOLKIT/scripts/run-module.sh sca --source /path/to/app
$TOOLKIT/scripts/run-module.sh secrets --source /path/to/app

# Live target scans (need URL)
$TOOLKIT/scripts/run-module.sh dast https://target.com
$TOOLKIT/scripts/run-module.sh xss "https://target.com/search?q=test"
$TOOLKIT/scripts/run-module.sh fuzz https://target.com

# Everything at once
$TOOLKIT/scripts/run-module.sh all https://target.com --source /path/to/app
```

| Module | Tool | What it does |
|---|---|---|
| `sast` | semgrep | Static code analysis |
| `sca` | osv-scanner, npm audit | Dependency vulnerability check |
| `secrets` | gitleaks, trufflehog | Find leaked secrets in code |
| `dast` | nuclei | Dynamic vulnerability scanning |
| `xss` | dalfox | XSS vulnerability scanning |
| `fuzz` | ffuf | Directory and parameter brute-forcing |
| `recon` | multiple | Full recon pipeline (dast + fuzz + xss) |
| `all` | multiple | sast + sca + secrets + dast combined |

---

## Directory Structure

```
pentomata/
├── .claude/
│   ├── CLAUDE.md                  # Project instructions for Claude Code
│   └── settings.json              # Hooks configuration
│
├── scripts/
│   ├── new-engagement.sh          # Create a new engagement folder
│   ├── run-module.sh              # Modular scanner
│   ├── quick-recon.sh             # Automated recon pipeline
│   └── pentest-runner.js          # Bulk HTTP test script (runs inside Playwright)
│
├── skills/
│   └── pentest/
│       ├── SKILL.md               # Pentest methodology, validation gates, common mistakes
│       └── references/
│           └── report-template.md # Linear report structure template
│
├── hooks/
│   ├── protect-linear-description.sh  # Blocks accidental Linear description overwrites
│   └── validate-findings-on-stop.sh   # Warns about incomplete findings on session end
│
├── gaps/
│   └── gap-log.md                 # Tooling capability backlog
│
├── templates/                     # Report and scope templates
├── payloads/                      # Payload collections (xss, ssrf, idor, auth-bypass)
├── wordlists/                     # SecLists (git submodule)
├── config/                        # Burp projects, custom Nuclei templates
│
└── engagements/                   # Per-client data (gitignored)
```

---

## Tools

### Used during testing (via Claude Code)

| Tool | How | What for |
|---|---|---|
| **Playwright MCP** | `browser_navigate`, `browser_evaluate`, `browser_snapshot`, `browser_handle_dialog` | Core testing — authenticated sessions, form injection, DOM inspection, XSS detection, bulk tests via `browser_evaluate` |
| **pentest-runner.js** | Executed inside Playwright via `browser_evaluate` | Bulk HTTP requests and server action calls with session cookies included automatically |
| **curl** | Via Bash | Header injection (X-Forwarded-Host, Host poisoning, CRLF) — things browsers block |
| **Burp Suite MCP** | `proxy_http_history`, `collaborator_generate` | Traffic analysis, out-of-band SSRF verification |
| **Linear MCP** | `save_issue`, `save_comment` | Report delivery — pentest report issues and finding write-ups |

### Used for scanning (via CLI)

| Tool | Command | What for |
|---|---|---|
| nuclei | `run-module.sh dast` | CVE and misconfiguration scanning |
| ffuf | `run-module.sh fuzz` | Directory and parameter brute-forcing |
| dalfox | `run-module.sh xss` | Automated XSS detection |
| gitleaks | `run-module.sh secrets` | Secret detection in git repos |
| trufflehog | `run-module.sh secrets` | Deep secret scanning across git history |
| semgrep | `run-module.sh sast` | Static analysis |
| osv-scanner | `run-module.sh sca` | Dependency vulnerability check |

---

## Hooks

Two hooks fire automatically during pentest sessions:

**`protect-linear-description.sh`** (PreToolUse)
- Triggers when Claude updates a Linear issue description
- Blocks the update if the new description is under 500 characters — likely a truncation
- Prevents accidental overwrites of manually edited reports

**`validate-findings-on-stop.sh`** (Stop)
- Triggers when a session ends
- Scans the active report file for findings missing endpoint, evidence, repro steps, or severity
- Warns but doesn't block — you may be doing incremental work

---

## Gap Tracking

When a tool fails, a capability is missing, or a workaround is needed during an engagement, it gets logged to `gaps/gap-log.md`. This is the backlog for improving the toolkit between engagements.

Current open gaps and resolved items are tracked there with context on what happened, why it matters, and ideas for fixes.

---

## Troubleshooting

**"command not found" for any tool** — Re-run `brew install <tool>` from the install section.

**MCP servers not in Claude Code** — Run `claude mcp list`. If missing, re-add with the commands from step 3 and restart Claude Code.

**Burp MCP not connecting** — Burp Suite Pro must be running with the burp-ai-agent extension enabled on port 9876. Test: `curl http://127.0.0.1:9876/sse`

**Playwright not working** — Run `npx -y playwright install chromium` to install the browser.

**ffuf says "wordlist not found"** — Wordlists not initialized. Run: `git submodule update --init --depth 1`

**Scan produces empty results** — Normal. Means no findings for that scan type. The output file exists but may be empty.
