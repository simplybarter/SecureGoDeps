# 🛠️ SecureGoDeps Examples & Integrations

This directory contains example configurations, test modules, and CI/CD pipelines to help you integrate `SecureGoDeps` into your projects.

---

## 📂 Directory Layout

```
examples/
├── github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.md          # Sample bug report template
│   │   └── feature_request.md     # Sample feature request template
│   ├── PULL_REQUEST_TEMPLATE.md   # Sample PR template
│   └── workflows/
│       └── go-security-check.yml  # Sample GitHub Actions workflow
└── testing/
    ├── go.mod                     # Vulnerable test Go module
    ├── go.sum                     # Vulnerable test Go checksums
    └── main.go                    # Entrypoint importing vulnerable package
```

---

## 🧪 Local Testing / Verification

To verify that the automatic scanning and remediation works as intended, you can run `secure-go-deps.sh` against the pre-configured `testing` folder.

This test module includes an outdated, vulnerable dependency (`golang.org/x/text` version `v0.35.0` or similar) to trigger `govulncheck`.

### Run Test Scan

From the root of the repository, execute:
```bash
./scripts/secure-go-deps.sh --path ./examples/testing
```

> [!TIP]
> Run with the `--dry-run` flag first to preview proposed dependency updates without writing changes:
> ```bash
> ./scripts/secure-go-deps.sh --path ./examples/testing --dry-run
> ```

---

## 🤖 GitHub Actions CI/CD Integration

Automate vulnerability detection and remediation by setting up a scheduled run or pull-request gate in your target repository.

### Workflow Configuration

The sample workflow is located in [`github/workflows/go-security-check.yml`](github/workflows/go-security-check.yml):

```yaml
name: Go Security Check

on:
  push:
    branches: [main]
  pull_request:
  schedule:
    - cron: "0 6 * * *" # Runs daily at 06:00 UTC

jobs:
  security:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-go@v5
        with:
          go-version-file: go.mod # Path to your go.mod file

      - name: Run security dependency script
        run: |
          chmod +x scripts/secure-go-deps.sh
          ./scripts/secure-go-deps.sh
```

### Setup Steps for Your Repository

1. **Stash the workflow**: Copy `go-security-check.yml` into your target repository's `.github/workflows/` folder.
2. **Include the script**: Copy `secure-go-deps.sh` to `scripts/secure-go-deps.sh` in your target repository.
3. **Verify paths**:
    * If your `go.mod` is in a subdirectory (e.g. `src/` or `backend/`), modify the `go-version-file` input:
      ```yaml
      go-version-file: backend/go.mod
      ```
    * Update the execution script step in the workflow to pass the corresponding directory:
      ```yaml
      ./scripts/secure-go-deps.sh --path ./backend
      ```
