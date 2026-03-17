# Pre-Engagement Checklist

## Setup
- [ ] Scope document signed
- [ ] Test credentials received
- [ ] VPN / network access confirmed
- [ ] Burp Suite project created
- [ ] Engagement folder scaffolded (`./scripts/new-engagement.sh`)
- [ ] Burp proxy configured for target

## OWASP Testing Guide v4.2

### Information Gathering
- [ ] OTG-INFO-001: Search engine discovery
- [ ] OTG-INFO-002: Web server fingerprinting
- [ ] OTG-INFO-003: Review webserver metafiles (robots.txt, sitemap)
- [ ] OTG-INFO-004: Enumerate applications on web server
- [ ] OTG-INFO-005: Review webpage content for information leakage
- [ ] OTG-INFO-006: Identify application entry points
- [ ] OTG-INFO-007: Map execution paths
- [ ] OTG-INFO-008: Fingerprint web application framework
- [ ] OTG-INFO-009: Fingerprint web application

### Authentication Testing
- [ ] OTG-AUTHN-001: Test credentials over encrypted channel
- [ ] OTG-AUTHN-002: Test for default credentials
- [ ] OTG-AUTHN-003: Test for weak lock-out mechanism
- [ ] OTG-AUTHN-004: Test for bypassing authentication schema
- [ ] OTG-AUTHN-005: Test for vulnerable remember password
- [ ] OTG-AUTHN-006: Test for browser cache weaknesses
- [ ] OTG-AUTHN-007: Test for weak password policy
- [ ] OTG-AUTHN-008: Test for weak security question/answer
- [ ] OTG-AUTHN-009: Test for weak password change/reset
- [ ] OTG-AUTHN-010: Test for weaker authentication in alt channel

### Authorization Testing
- [ ] OTG-AUTHZ-001: Test directory traversal/file include
- [ ] OTG-AUTHZ-002: Test for bypassing authorization schema
- [ ] OTG-AUTHZ-003: Test for privilege escalation
- [ ] OTG-AUTHZ-004: Test for IDOR (Insecure Direct Object Reference)

### Session Management
- [ ] OTG-SESS-001: Test for session management schema
- [ ] OTG-SESS-002: Test for cookie attributes
- [ ] OTG-SESS-003: Test for session fixation
- [ ] OTG-SESS-004: Test for exposed session variables
- [ ] OTG-SESS-005: Test for CSRF
- [ ] OTG-SESS-006: Test for logout functionality
- [ ] OTG-SESS-007: Test session timeout
- [ ] OTG-SESS-008: Test for session puzzling

### Input Validation
- [ ] OTG-INPVAL-001: Test for reflected XSS
- [ ] OTG-INPVAL-002: Test for stored XSS
- [ ] OTG-INPVAL-003: Test for HTTP verb tampering
- [ ] OTG-INPVAL-004: Test for HTTP parameter pollution
- [ ] OTG-INPVAL-005: Test for SQL injection
- [ ] OTG-INPVAL-006: Test for LDAP injection
- [ ] OTG-INPVAL-007: Test for XML injection
- [ ] OTG-INPVAL-008: Test for SSI injection
- [ ] OTG-INPVAL-009: Test for XPath injection
- [ ] OTG-INPVAL-010: Test for IMAP/SMTP injection
- [ ] OTG-INPVAL-011: Test for code injection
- [ ] OTG-INPVAL-012: Test for command injection
- [ ] OTG-INPVAL-013: Test for format string injection
- [ ] OTG-INPVAL-014: Test for incubated vulnerability
- [ ] OTG-INPVAL-015: Test for HTTP splitting/smuggling
- [ ] OTG-INPVAL-016: Test for HTTP incoming requests
- [ ] OTG-INPVAL-017: Test for host header injection
- [ ] OTG-INPVAL-018: Test for SSRF

### Business Logic
- [ ] OTG-BUSLOGIC-001: Test business logic data validation
- [ ] OTG-BUSLOGIC-002: Test ability to forge requests
- [ ] OTG-BUSLOGIC-003: Test integrity checks
- [ ] OTG-BUSLOGIC-004: Test for process timing
- [ ] OTG-BUSLOGIC-005: Test number of times a function can be used
- [ ] OTG-BUSLOGIC-006: Test for circumvention of workflows
- [ ] OTG-BUSLOGIC-007: Test defenses against application misuse
- [ ] OTG-BUSLOGIC-008: Test upload of unexpected file types
- [ ] OTG-BUSLOGIC-009: Test upload of malicious files

### API Security
- [ ] Rate limiting
- [ ] Mass assignment
- [ ] Broken object-level authorization
- [ ] Broken function-level authorization
- [ ] Excessive data exposure
- [ ] Lack of resource throttling

## Wrap-Up
- [ ] All findings documented with evidence
- [ ] Report generated from template
- [ ] Findings reviewed and severity confirmed
- [ ] Client debrief scheduled
