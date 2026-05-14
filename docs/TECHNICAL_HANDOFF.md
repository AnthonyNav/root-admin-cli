# Technical Handoff

This document is the maintenance reference for anyone resuming work on
Admin Redes after the original implementation phase.

## 1. Project Purpose

Admin Redes is a terminal-based administration tool for AlmaLinux 9. It wraps
common Linux administration tasks in guided Bash workflows so operators can
navigate tasks from menus instead of memorizing every command.

The project currently covers:

- local user administration
- local group administration
- process inspection and monitoring
- recurring and one-off task scheduling
- compressed backup creation
- security and monitoring tool launchers

## 2. Runtime Model

### Entry point

- `main.sh` is the only supported application entry point
- it loads every module with `source`
- it installs the required UI tools before entering the menu flow
- it requires root privileges for the operational workflows

### Shared helper layer

- `src/lib/utils.sh` is the central dependency for interactive behavior
- UI helpers live there:
  - `print_header`
  - `seleccionar_menu`
  - `seleccionar_usuario`
  - `seleccionar_grupo`
  - `input_campo`
  - `confirm_ui`
  - `seleccionar_directorio`
- legacy compatibility is preserved through `confirmar_whiptail()`, which now
  delegates to `confirm_ui()`

### Module loading order

`main.sh` loads modules in this order:

1. `src/lib/utils.sh`
2. `src/users.sh`
3. `src/groups.sh`
4. `src/processes.sh`
5. `src/automation.sh`
6. `src/backup.sh`
7. `src/security.sh`

This order matters because all modules rely on functions from `utils.sh`.

## 3. UI Design Stack

The project no longer uses `whiptail` for its active workflows.

Current UI stack:

- `gum` for menus, confirm dialogs, input fields, and styled headers
- `figlet` for the startup banner
- `fzf` for directory browsing in backup flows

Implementation notes:

- menu flows based on numeric keys are normalized through `seleccionar_menu()`
- `gum` displays only labels, but the helper maps the selected label back to
  the original numeric key so existing `case` blocks do not need to change
- when no interactive TTY is available, helpers fall back to `read`

## 4. File-by-File Responsibilities

### `main.sh`

Responsibilities:

- install UI dependencies through `instalar_ui()`
- render the banner with `show_titulo()`
- enforce root execution
- drive the top-level application loop

Important detail:

- `show_titulo()` only sends the terminal resize escape when the current
  terminal looks compatible with xterm-style window control

### `src/lib/utils.sh`

Responsibilities:

- shared status messages
- existence checks for users and groups
- interactive menus and prompts
- TTY detection
- backup directory selection helper

Maintenance rule:

- prefer extending helpers here instead of duplicating UI logic in modules

### `src/users.sh`

Responsibilities:

- create users
- inspect users
- delete users
- modify account properties

Important safeguards:

- blocks direct destructive operations against `root`
- prevents modification of system users with UID below 1000 in the relevant flows
- validates shell paths and account expiration formats

### `src/groups.sh`

Responsibilities:

- create groups
- inspect groups
- delete groups
- rename groups
- manage membership lists

### `src/processes.sh`

Responsibilities:

- static process snapshots by user
- filtered `top` monitoring
- direct root process listing

### `src/automation.sh`

Responsibilities:

- create cron jobs
- create at jobs
- list cron entries
- list at queue entries

Important detail:

- the cron creation flow includes guided frequency presets plus a manual mode

### `src/backup.sh`

Responsibilities:

- create `.tar.gz` backups
- create `.tar.bz2` backups
- validate source and destination directories
- create destination directories when approved by the operator

Important detail:

- directory selection supports both interactive browsing with `fzf` and manual
  path entry

### `src/security.sh`

Responsibilities:

- open Nagios
- launch Wireshark
- run Nmap
- run iftop

Important detail:

- Nagios browser launch uses `SUDO_USER` when available so GUI sessions opened
  from `sudo` still work correctly

### `scripts/install_security.sh`

Responsibilities:

- enable repositories
- install security packages
- configure Nagios access
- enable services
- verify the post-install state

## 5. Dependency Strategy

### Base package list

The baseline package list lives in `deps.txt`.

### Special-case dependencies

#### `gum`

- not installed from the base AlmaLinux repositories
- installed from the Charm repository
- managed at runtime by `instalar_ui()` in `main.sh`

#### Security tooling

- installed through `scripts/install_security.sh`
- includes Nagios, Wireshark, Nmap, iftop, cron-related tools, and HTTP support

## 6. Testing Strategy

### Syntax checks

Use:

```bash
bash -n main.sh src/lib/utils.sh src/users.sh src/groups.sh \
       src/processes.sh src/automation.sh src/backup.sh src/security.sh
```

### Migration and regression suites

Key suites:

- `tests/test_gum_phase1.sh`
- `tests/test_gum_phase2.sh`
- `tests/test_gum_phase3.sh`
- `tests/test_utils.sh`

Recommended regression run:

```bash
bash tests/test_gum_phase1.sh
bash tests/test_gum_phase2.sh
bash tests/test_gum_phase3.sh
bash tests/test_utils.sh
```

### Module-level suites

Also available:

- `tests/test_users.sh`
- `tests/test_groups.sh`
- `tests/test_processes.sh`

Important note:

- these legacy module suites are more environment-sensitive than the gum phase
  suites
- several checks assume real root privileges, live system accounts, or direct
  command side effects
- when they fail in a constrained environment, compare the failure against the
  gum phase suites before assuming the module logic regressed

## 7. Common Change Patterns

### Add a new menu option

1. add the label and key in the relevant `seleccionar_menu()` call
2. add the matching branch in the `case`
3. keep labels user-friendly and keys stable
4. rerun the phase tests if the menu is part of the gum migration

### Add a new prompt

Prefer:

- `input_campo` for free text
- `confirm_ui` for confirmation
- `seleccionar_menu` for numeric menu flows
- `seleccionar_directorio` for paths

### Add a new module

1. create `src/<module>.sh`
2. keep module functions return-based, not `exit`-based
3. source the module in `main.sh`
4. add the new top-level menu option
5. document dependencies in `deps.txt` or in an installer script
6. add at least one validation path in tests if the module changes shared UX

## 8. Known Compatibility Decisions

- `confirmar_whiptail()` remains available as a compatibility alias
- `seleccionar_menu()` keeps numeric keys internally even though gum shows only
  descriptive labels
- fallback `read` behavior remains important for tests and non-interactive runs
- some historical tests still reference old naming or root-dependent behaviors
- historical planning files under `docs/` still mention `whiptail`; they should
  be treated as historical coordination artifacts, not as the current UI design

## 9. Recovery Checklist for a New Maintainer

When resuming the project:

1. read `README.md`
2. read this file completely
3. run `bash setup.sh`
4. run the syntax checks
5. run the regression suites
6. inspect `src/lib/utils.sh` before changing any menu or prompt behavior
7. inspect `main.sh` before changing module loading or application startup

## 10. Suggested Next Improvements

These are optional, not blockers:

- unify user-facing language across all modules
- add automated tests for backup and security flows with mocks
- expand `setup.sh` to verify `gum`, `figlet`, and `fzf` explicitly
- add a release checklist for demo or classroom delivery
