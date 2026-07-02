# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.1.0] - 2026-07-02

### Added
- `secure-go-deps.sh` utility script for scanning Go modules with `govulncheck` and automatically applying updates.
- `-d` / `--dry-run` flag in the script to simulate dependency upgrades and output the resulting `go.mod` diff without writing changes to the disk.
- `-p` / `--path` flag in the script to target specific Go module directories.
- Colored console output support with automated TTY detection in the script.
- `examples/testing/` folder containing a sample Go project with vulnerable dependencies for scan testing.
- `examples/github/` containing a template GitHub Actions workflow (`go-security-check.yml`), issue templates (`bug_report.md`, `feature_request.md`), and a pull request template (`PULL_REQUEST_TEMPLATE.md`).
- Repository documentation including a polished root `README.md`, `examples/README.md`, `LICENSE.md`, `SUPPORT.md`, and this `CHANGELOG.md`.
