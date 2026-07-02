# SecureGoDeps

`SecureGoDeps` is a automated security vulnerability scanner and dependency updater for Go modules. It leverages Go's official `govulncheck` tool to analyze your codebase for reachable vulnerabilities, automatically attempts to upgrade vulnerable dependencies, tidies up module configurations, and runs your test suite to ensure system stability.

## Features

- **Automated Tool Management**: Automatically installs or updates `govulncheck` to the latest version.
- **Vulnerability Scanning**: Scans package patterns (`./...`) to identify vulnerabilities reachable by your code.
- **Smart Remediation Pipeline**:
  - If **no vulnerabilities** are found: Runs `go mod tidy` and your test suite (`go test ./...`) as a sanity check.
  - If **vulnerabilities are found**:
    1. Upgrades both direct and indirect dependencies to their latest compatible versions (`go get -u ./...`).
    2. Runs `go mod tidy` to clean up `go.mod` and `go.sum`.
    3. Runs your package test suite (`go test ./...`) to ensure upgrades did not break functionality.
    4. Re-runs `govulncheck` to verify that the upgraded dependencies successfully resolved all vulnerabilities.

---

## Getting Started

### Prerequisites

- Go (version 1.18 or higher recommended; `govulncheck` requires a modern Go version, and will automatically download/switch if required).
- Bash shell environment.

### Installation

No installation required. Simply clone or copy the script to your project and run it.

```bash
git clone https://github.com/your-username/SecureGoDeps.git
cd SecureGoDeps
```

---

## Usage

You can run the script directly from the root of any Go module directory, or point it to a specific directory using the `--path` option.

### Command Syntax

```bash
./scripts/secure-go-deps.sh [options]
```

### Options

- `-p, --path PATH`   : Specify the directory path of the Go module to scan.
- `-d, --dry-run`     : Highlight the changes that would be made without modifying files (dry run).
- `-h, --help`        : Display the help message.

### Examples

**Scan the current Git repository root / working directory:**
```bash
./scripts/secure-go-deps.sh
```

**Run a dry run scan to preview proposed changes:**
```bash
./scripts/secure-go-deps.sh --dry-run
```

**Scan a specific Go project directory:**
```bash
./scripts/secure-go-deps.sh --path ./examples/testing
# or
./scripts/secure-go-deps.sh -p ../my-other-go-service
```

---

## Example Output & Remediation flow

Here is what the script output looks like when it detects and successfully fixes vulnerabilities in a project:

```
==> Using project directory: /home/user/SecureGoDeps/examples/testing
==> Checking this is a Go module repo...
==> Installing/updating govulncheck...
==> Running initial vulnerability scan...
govulncheck: loading packages:
...
==> Vulnerabilities were found.
==> Attempting to upgrade all direct and indirect dependencies...
go: upgraded golang.org/x/text v0.3.5 => v0.38.0
==> Tidying module files...
==> Running tests after dependency upgrades...
ok      secure-go-deps  (cached)
==> Running final vulnerability scan...
No vulnerabilities found.

==> Done. Dependencies were upgraded, tests passed, and govulncheck passed.
```

---

## Testing

A sample project for testing vulnerability scanning and automatic remediation is available in the `examples/testing` directory. See the [Examples README](examples/README.md) for usage instructions.

---

## CI/CD Integration

For details on integrating `SecureGoDeps` into your CI/CD pipelines (such as GitHub Actions), please refer to the [Examples README](examples/README.md).
