# opencode-configuration

A shareable, installable configuration for [OpenCode](https://opencode.ai/) that bundles custom AI agents, slash commands, skills, MCP integrations, and notification support into a single repository.

## What's Included

- **Model configuration** -- Claude Opus 4 via Google Vertex AI
- **Agents**
  - **Planner** -- read-only agent for decomposing work into parallelizable Jira stories with acceptance criteria and dependency links
  - **TDD** -- strict Red-Green-Refactor agent that enforces phase gating (failing test before implementation, mandatory test runs, auto-commits on green)
- **Slash commands**
  - `/tdd` -- start a TDD session from inline requirements
- **Skills** -- reusable knowledge documents that agents can load at runtime
  - Personal coding standards (fail-fast, immutability, real infrastructure over mocks, etc.)
  - Planning methodology for Jira story creation
- **MCP server** -- Jira/Atlassian integration running via rootless Podman
- **Notifications** -- push notifications via [ntfy.sh](https://ntfy.sh/)

## Prerequisites

- A Google Cloud project with Vertex AI API access
- A Jira MCP environment file at `~/.config/mcp/jira-mcp.env`
- (Optional) An [ntfy.sh](https://ntfy.sh/) topic for push notifications

## Installation

### Quick install (clone + setup)

```sh
curl -fsSL https://raw.githubusercontent.com/lannuttia/opencode-config/main/install.sh | sh
```

Or clone manually and run the installer:

```sh
git clone https://github.com/lannuttia/opencode-config.git
cd opencode-config
sh install.sh --no-clone
```

### What the installer does

1. Installs OpenCode if not already present
2. Installs and configures rootless Podman (needed for the Jira MCP server)
3. Detects the correct config directory for your OS (Linux, macOS, or Windows via MSYS/Cygwin)
4. Backs up any existing OpenCode configuration
5. Places or symlinks this repository into the config directory
6. Supports Fedora, Debian/Ubuntu, Arch, openSUSE, Gentoo, and macOS (Homebrew)

### Post-install

Create a `.env` file in the configuration directory with the following variables:

```sh
OPENCODE_GCP_VERTEX_PROJECT=<your-gcp-project-id>
OPENCODE_NTFY_TOPIC=<your-ntfy-topic>           # optional
```

## License

[MIT](LICENSE)
