# Admin Redes

Admin Redes is a Bash-based administration toolkit for AlmaLinux 9. It provides
interactive flows for user management, group management, process inspection,
task scheduling, backups, and security tooling through a terminal-first UI.

## Quick Start

Check the environment:

```bash
bash setup.sh
```

Start the application:

```bash
sudo bash main.sh
```

## What It Includes

- User management: create, inspect, update, and delete local users
- Group management: create, inspect, update, and delete local groups
- Process tools: snapshots, live monitoring, and root process inspection
- Scheduling: cron and at workflows with guided prompts
- Backups: gzip and bzip2 archive creation with directory selection
- Security tools: Nagios, Wireshark, Nmap, and iftop entry points

## UI Stack

- `gum` for menus, prompts, confirmations, and styled headers
- `figlet` for the main banner
- `fzf` for directory browsing in backup workflows

`main.sh` installs `gum`, `figlet`, and `fzf` automatically when missing.

## Automatic Dependency Flow

When you start the application with:

```bash
sudo bash main.sh
```

the script runs `instalar_ui()` before entering the main menu.

That startup step does the following:

- checks whether `gum`, `figlet`, and `fzf` are already available
- installs `gum` from the Charm repository when it is missing
- installs `figlet` and `fzf` with `dnf` when they are missing

Important notes:

- this automatic installation only covers the UI layer dependencies
- the script should be started with `sudo`, otherwise package installation will fail
- base project dependencies are still managed through `setup.sh` and `deps.txt`

## Repository Layout

```text
.
├── main.sh
├── setup.sh
├── deps.txt
├── src/
│   ├── lib/utils.sh
│   ├── users.sh
│   ├── groups.sh
│   ├── processes.sh
│   ├── automation.sh
│   ├── backup.sh
│   └── security.sh
├── scripts/
│   └── install_security.sh
├── tests/
│   ├── test_utils.sh
│   ├── test_users.sh
│   ├── test_groups.sh
│   ├── test_processes.sh
│   ├── test_gum_phase1.sh
│   ├── test_gum_phase2.sh
│   └── test_gum_phase3.sh
└── docs/
    ├── TECHNICAL_HANDOFF.md
    ├── COLLABORATION_RULES.md
    ├── PLANNING.md
    ├── RESPONSIBILITIES.md
    └── TASKS.md
```

## Main Commands

Run the most useful checks during development:

```bash
bash -n main.sh src/lib/utils.sh src/users.sh src/groups.sh \
       src/processes.sh src/automation.sh src/backup.sh src/security.sh

bash tests/test_gum_phase1.sh
bash tests/test_gum_phase2.sh
bash tests/test_gum_phase3.sh
bash tests/test_utils.sh
```

## Dependencies

Base dependencies are listed in `deps.txt`.

Notable runtime requirements:

- `gum` comes from the Charm repository and is installed by `instalar_ui()`
- `figlet` and `fzf` are installed through `dnf`
- security tooling is installed by `scripts/install_security.sh`

## Documentation

- Quick project overview: this `README.md`
- Technical handoff: [docs/TECHNICAL_HANDOFF.md](docs/TECHNICAL_HANDOFF.md)
- Historical planning and coordination docs:
  - [docs/PLANNING.md](docs/PLANNING.md)
  - [docs/RESPONSIBILITIES.md](docs/RESPONSIBILITIES.md)
  - [docs/TASKS.md](docs/TASKS.md)
  - [docs/COLLABORATION_RULES.md](docs/COLLABORATION_RULES.md)

## Collaborators

Fill these links with the final profiles, repository pages, or portfolio links.

- Project lead: `<add link here>`
- Contributor 1: `<add link here>`
- Contributor 2: `<add link here>`
- Contributor 3: `<add link here>`
- Contributor 4: `<add link here>`

## Handoff Note

If someone needs to resume the project later, start with:

1. `README.md` for the workflow and entry points
2. `docs/TECHNICAL_HANDOFF.md` for architecture, dependencies, and test strategy
3. `src/lib/utils.sh` to understand shared UI and validation helpers
