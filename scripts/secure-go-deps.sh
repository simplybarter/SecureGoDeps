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

# Color support setup
if [[ -t 1 ]]; then
  NC='\033[0m'
  RED='\033[0;31m'
  GREEN='\033[0;32m'
  YELLOW='\033[0;33m'
  BLUE='\033[0;34m'
  CYAN='\033[0;36m'
  BOLD='\033[1m'
else
  NC=''
  RED=''
  GREEN=''
  YELLOW=''
  BLUE=''
  CYAN=''
  BOLD=''
fi

log_info() {
  echo -e "${BLUE}==>${NC} ${BOLD}$1${NC}"
}

log_success() {
  echo -e "${GREEN}==>${NC} ${BOLD}$1${NC}"
}

log_warn() {
  echo -e "${YELLOW}==>${NC} ${BOLD}$1${NC}"
}

log_error() {
  echo -e "${RED}ERROR:${NC} $1" >&2
}

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
        log_error "--path requires a value."
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
      log_error "Unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if [[ -n "$TARGET_PATH" ]]; then
  if [[ ! -d "$TARGET_PATH" ]]; then
    log_error "Path does not exist or is not a directory: $TARGET_PATH"
    exit 1
  fi

  cd "$TARGET_PATH"
  ROOT_DIR="$(pwd)"
else
  ROOT_DIR="$(git rev-parse --show-toplevel 2>/dev/null || pwd)"
  cd "$ROOT_DIR"
fi

log_info "Using project directory: $(pwd)"
log_info "Checking this is a Go module repo..."

if [[ ! -f "go.mod" ]]; then
  log_error "go.mod not found in $(pwd)."
  log_error "Run this from the root of a Go module repo or pass --path."
  exit 1
fi

log_info "Installing/updating govulncheck..."

go install golang.org/x/vuln/cmd/govulncheck@latest

GOVULNCHECK="$(go env GOPATH)/bin/govulncheck"

if [[ ! -x "$GOVULNCHECK" ]]; then
  log_error "govulncheck was not found at $GOVULNCHECK"
  exit 1
fi

log_info "Running initial vulnerability scan..."

set +e
"$GOVULNCHECK" ./...
INITIAL_STATUS=$?
set -e

if [[ "$INITIAL_STATUS" -eq 0 ]]; then
  log_success "No known reachable vulnerabilities found."
  if [[ "$DRY_RUN" = true ]]; then
    log_success "Done. [DRY RUN] No changes needed."
    exit 0
  fi
  log_info "Running go mod tidy and tests anyway..."

  go mod tidy
  go test ./...

  log_success "Done. Repo passed vulnerability scan and tests."
  exit 0
fi

echo
log_warn "Vulnerabilities were found."

if [[ "$DRY_RUN" = true ]]; then
  log_warn "[DRY RUN] Simulating dependency upgrades..."
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

  log_info "Proposed changes to go.mod:"
  echo "------------------------------------------------------------"
  diff -u go.mod.tmp go.mod || true
  echo "------------------------------------------------------------"

  # Restore backups
  restore_backups
  # Clear trap so it doesn't run again on normal exit
  trap - EXIT INT TERM
  set -e

  echo
  log_success "[DRY RUN] Simulation complete. No files were modified."
  exit 0
fi

log_info "Attempting to upgrade all direct and indirect dependencies..."
echo

go get -u ./...

log_info "Tidying module files..."

go mod tidy

log_info "Running tests after dependency upgrades..."

go test ./...

log_info "Running final vulnerability scan..."

"$GOVULNCHECK" ./...

echo
log_success "Done. Dependencies were upgraded, tests passed, and govulncheck passed."