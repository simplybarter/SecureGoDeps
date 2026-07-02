#!/usr/bin/env bash
set -euo pipefail

# secure-go-deps.sh
#
# Scans a Go repo with govulncheck, attempts to upgrade vulnerable modules,
# tidies dependencies, runs tests, and verifies the vulnerability scan again.
#
# Usage:
#   ./secure-go-deps.sh
#   ./secure-go-deps.sh --path ./my-go-project
#   ./secure-go-deps.sh -p ./my-go-project
#   ./secure-go-deps.sh --dry-run

TARGET_PATH=""
DRY_RUN=false

usage() {
  cat <<EOF
Usage:
  $0 [--path PATH] [--dry-run]

Options:
  -p, --path PATH   Path to the Go project/repo to scan
  -d, --dry-run     Highlight the changes that would be made without modifying files
  -h, --help        Show this help message

Examples:
  $0
  $0 --path ./vulnerable-go-test
  $0 -p ../some-go-repo
  $0 --dry-run
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    -p|--path)
      if [[ $# -lt 2 ]]; then
        echo "ERROR: --path requires a value."
        usage
        exit 1
      fi
      TARGET_PATH="$2"
      shift 2
      ;;
    -d|--dry-run|--dryrun)
      DRY_RUN=true
      shift 1
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    *)
      echo "ERROR: Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -n "$TARGET_PATH" ]]; then
  if [[ ! -d "$TARGET_PATH" ]]; then
    echo "ERROR: Path does not exist or is not a directory: $TARGET_PATH"
    exit 1
  fi

  cd "$TARGET_PATH"
  ROOT_DIR="$(pwd)"
else
  ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$ROOT_DIR"
fi

echo "==> Using project directory: $(pwd)"
echo "==> Checking this is a Go module repo..."

if [[ ! -f "go.mod" ]]; then
  echo "ERROR: go.mod not found in $(pwd)."
  echo "Run this from the root of a Go module repo or pass --path."
  exit 1
fi

echo "==> Installing/updating govulncheck..."

go install golang.org/x/vuln/cmd/govulncheck@latest

GOVULNCHECK="$(go env GOPATH)/bin/govulncheck"

if [[ ! -x "$GOVULNCHECK" ]]; then
  echo "ERROR: govulncheck was not found at $GOVULNCHECK"
  exit 1
fi

echo "==> Running initial vulnerability scan..."

set +e
"$GOVULNCHECK" ./...
INITIAL_STATUS=$?
set -e

if [[ "$INITIAL_STATUS" -eq 0 ]]; then
  echo "==> No known reachable vulnerabilities found."
  if [[ "$DRY_RUN" = true ]]; then
    echo "==> Done. [DRY RUN] No changes needed."
    exit 0
  fi
  echo "==> Running go mod tidy and tests anyway..."

  go mod tidy
  go test ./...

  echo "==> Done. Repo passed vulnerability scan and tests."
  exit 0
fi

echo
echo "==> Vulnerabilities were found."

if [[ "$DRY_RUN" = true ]]; then
  echo "==> [DRY RUN] Simulating dependency upgrades..."
  echo

  # Create backups
  cp go.mod go.mod.tmp
  HAS_SUM=false
  if [[ -f go.sum ]]; then
    cp go.sum go.sum.tmp
    HAS_SUM=true
  fi

  restore_backups() {
    mv go.mod.tmp go.mod
    if [[ "$HAS_SUM" = true ]]; then
      mv go.sum.tmp go.sum
    else
      rm -f go.sum
    fi
  }

  trap restore_backups EXIT INT TERM

  set +e
  # Run the upgrades silently in-place to get the simulated result
  go get -u ./... >/dev/null 2>&1
  go mod tidy >/dev/null 2>&1

  echo "==> Proposed changes to go.mod:"
  echo "------------------------------------------------------------"
  diff -u go.mod.tmp go.mod || true
  echo "------------------------------------------------------------"

  # Restore backups
  restore_backups
  # Clear trap so it doesn't run again on normal exit
  trap - EXIT INT TERM
  set -e

  echo
  echo "==> [DRY RUN] Simulation complete. No files were modified."
  exit 0
fi

echo "==> Attempting to upgrade all direct and indirect dependencies..."
echo

go get -u ./...

echo "==> Tidying module files..."

go mod tidy

echo "==> Running tests after dependency upgrades..."

go test ./...

echo "==> Running final vulnerability scan..."

"$GOVULNCHECK" ./...

echo
echo "==> Done. Dependencies were upgraded, tests passed, and govulncheck passed."