# Changelog

All notable changes to easy-command are documented here.

## 2.0.9 - 2026-09-20

- Added a bundled changelog and linked it from both README files.

## 2.0.8 - 2026-09-20

- `ec update` now upgrades the global npm CLI to `easy-command@latest` before updating managed repositories and shell configuration.
- Added `ec -v` and `ec --version`.
- Added npm Trusted Publishing through GitHub Actions, including provenance attestations.

## 2.0.7 - 2026-09-20

- Directories are recorded only through explicit `ec add` / `ec a` or `z add` / `z a`.
- `ec <keyword>` and `z <keyword>` now only search and jump; they do not record a local matching directory implicitly.

## 2.0.6 - 2026-09-20

- Added default Git aliases, including `st`, `br`, `sw`, `ci`, `cam`, `lg`, `la`, and `lb`.
- Existing user-defined Git aliases are never overwritten.

## 2.0.5 - 2026-09-19

- Added global npm installation support.
- Added the `ec` unified directory and maintenance command interface.

## 2.0.3 - 2026-09-18

- Added explicit zoxide directory registration shortcuts.

## 2.0.2 - 2026-09-18

- Improved macOS installation compatibility.

## 2.0.1 - 2026-09-18

- Released the 2.x installer improvements.

## 1.0.4 - 2026-09-18

- Added the npm CLI entry point.
