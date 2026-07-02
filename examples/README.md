# SecureGoDeps Integration Examples

This directory contains integration examples for utilizing the `SecureGoDeps` scanning tool within your CI/CD pipelines.

## Contents

- [`testing/`](testing/): A test Go module containing an older, vulnerable dependency configuration to demonstrate vulnerability identification and resolution.
- [`github/workflows/go-security-check.yml`](github/workflows/go-security-check.yml): A complete GitHub Actions workflow configured to run the dependency vulnerability scanner.
---

## Local Testing / Verification

This directory includes a `testing/` folder containing a simple Go module pre-configured with a vulnerable dependency (`golang.org/x/text` version `v0.3.5` or `v0.35.0`).

To run a test scan (from the root of the repository):
```bash
./scripts/secure-go-deps.sh --path ./examples/testing
```

---

## GitHub Actions CI/CD Integration

The provided GitHub Actions workflow automates the process of checking your Go codebase for reachable vulnerabilities, automatically upgrading dependencies if any are detected, and validating module integrity.

### Workflow Configuration

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

1. **Copy the workflow file**: Copy the `go-security-check.yml` workflow into your target repository at `.github/workflows/go-security-check.yml`.
2. **Add the script**: Copy the `secure-go-deps.sh` script to your repository under `scripts/secure-go-deps.sh` (or update the path in the workflow file accordingly).
3. **Verify Go module path**:
   - If your `go.mod` is in the repository root, `go-version-file: go.mod` works out of the box.
   - If your Go code/module is in a subdirectory (e.g. `src/` or `backend/`), update the `setup-go` action's configuration:
     ```yaml
     - uses: actions/setup-go@v5
       with:
         go-version-file: backend/go.mod
     ```
   - Also, update the runner script call to pass the target directory path using the `-p` or `--path` option:
     ```yaml
     run: |
       chmod +x scripts/secure-go-deps.sh
       ./scripts/secure-go-deps.sh --path ./backend
     ```
