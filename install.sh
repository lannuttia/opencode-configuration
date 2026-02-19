#!/bin/sh

set -e

repo=${repo:-lannuttia/opencode-config}
remote=${remote:-https://github.com/${repo}.git}
branch=${branch:-main}

error() {
    echo "${RED}Error: $@${RESET}" >&2
}

command_exists() {
    command -v "$@" >/dev/null 2>&1
}

detect_os() {
    if [ -f /etc/os-release ] || [ -f /usr/lib/os-release ] || [ -f /etc/openwrt_release ] || [ -f /etc/lsb_release ]; then
        for file in /etc/os-release /usr/lib/os-release /etc/openwrt_release /etc/lsb_release; do
            [ -f "$file" ] && . "$file" && break
        done
    else
        error "Failed to detect OS environment"
        exit 1
    fi

    if [ "${ID_LIKE}" ]; then
        OS_FAMILY="${ID_LIKE}"
    else
        OS_FAMILY="${ID}"
    fi
}

run_as_root() {
    if [ "$(id -u)" = 0 ]; then
        eval "$*"
    elif command_exists sudo; then
        sudo -v
        if [ $? -eq 0 ]; then
            eval "sudo sh -c '$*'"
        else
            su -c "$*"
        fi
    elif command_exists doas; then
        doas sh -c "$*"
    else
        su -c "$*"
    fi
}

install_packages() {
    echo "${BLUE}Installing packages: $@${RESET}"

    case "${OS_FAMILY}" in
        fedora)
            run_as_root dnf install -y "$@"
            ;;
        debian|ubuntu)
            run_as_root apt-get update
            run_as_root apt-get install -y "$@"
            ;;
        arch)
            run_as_root pacman -S --noconfirm "$@"
            ;;
        suse|opensuse*)
            run_as_root zypper install -y "$@"
            ;;
        gentoo)
            run_as_root emerge "$@"
            ;;
        *)
            case "$(uname -s)" in
                Darwin)
                    if command_exists brew; then
                        brew install "$@"
                    else
                        error "Homebrew is not installed. Install packages manually: $@"
                        exit 1
                    fi
                    ;;
                *)
                    error "Unsupported OS family: ${OS_FAMILY}. Install packages manually: $@"
                    exit 1
                    ;;
            esac
            ;;
    esac

    echo
}

ensure_rootless_podman() {
    if ! command_exists podman; then
        install_packages podman
    fi

    # Rootless networking requires pasta (Podman 5+) or slirp4netns
    if ! command_exists pasta && ! command_exists slirp4netns; then
        echo "${BLUE}Installing pasta for rootless podman networking...${RESET}"
        install_packages passt
    fi

    # Rootless podman requires subordinate UID/GID ranges
    if ! grep -q "^$(whoami):" /etc/subuid 2>/dev/null; then
        echo "${BLUE}Configuring subordinate UID/GID ranges for $(whoami)...${RESET}"
        run_as_root usermod --add-subuids 100000-165535 --add-subgids 100000-165535 "$(whoami)"
    fi

    # Verify rootless podman works
    echo "${BLUE}Verifying rootless podman...${RESET}"
    if podman info --format '{{.Host.Security.Rootless}}' 2>/dev/null | grep -q "true"; then
        echo "${GREEN}Rootless podman is working.${RESET}"
    else
        echo "${YELLOW}Warning: Could not verify rootless podman. You may need to log out and back in.${RESET}"
    fi

    echo
}

setup_color() {
    if [ -t 1 ]; then
        RED=$(printf '\033[31m')
        GREEN=$(printf '\033[32m')
        YELLOW=$(printf '\033[33m')
        BLUE=$(printf '\033[34m')
        BOLD=$(printf '\033[1m')
        RESET=$(printf '\033[m')
    else
        RED=""
        GREEN=""
        YELLOW=""
        BLUE=""
        BOLD=""
        RESET=""
    fi
}

detect_config_dir() {
    case "$(uname -s)" in
        Linux|FreeBSD|DragonFly|NetBSD|OpenBSD)
            echo "${XDG_CONFIG_HOME:-${HOME}/.config}/opencode"
            ;;
        Darwin)
            echo "${HOME}/Library/Application Support/opencode"
            ;;
        MINGW*|MSYS*|CYGWIN*)
            echo "${APPDATA}/opencode"
            ;;
        *)
            error "Unsupported platform: $(uname -s)"
            exit 1
            ;;
    esac
}

detect_source_dir() {
    # Resolve the directory containing this script
    script_path="$0"

    # Follow symlinks to find the real path
    while [ -L "${script_path}" ]; do
        script_dir="$(cd "$(dirname "${script_path}")" && pwd)"
        script_path="$(readlink "${script_path}")"
        # Handle relative symlink targets
        case "${script_path}" in
            /*) ;;
            *) script_path="${script_dir}/${script_path}" ;;
        esac
    done

    cd "$(dirname "${script_path}")" && pwd
}

backup_existing() {
    target="$1"

    if [ ! -e "${target}" ]; then
        return
    fi

    # If it's already a symlink, just remove it
    if [ -L "${target}" ]; then
        echo "${YELLOW}Removing existing symlink: ${target}${RESET}"
        rm "${target}"
        return
    fi

    backup="${target}.bak"

    if [ -e "${backup}" ]; then
        n=1
        while [ -e "${backup}.${n}" ]; do
            n=$((n + 1))
        done
        backup="${backup}.${n}"
    fi

    echo "${YELLOW}Backing up existing config: ${target} -> ${backup}${RESET}"
    mv "${target}" "${backup}"
}

clone_repo() {
    echo "${BLUE}Cloning opencode-config...${RESET}"

    command_exists git || {
        error "git is not installed"
        exit 1
    }

    git clone -c core.eol=lf \
        --branch "${branch}" "${remote}" "${SOURCE_DIR}" || {
        error "git clone of opencode-config failed"
        exit 1
    }

    echo
}

link_config() {
    config_dir="$1"
    source_dir="$2"

    # Ensure the parent directory exists
    parent_dir="$(dirname "${config_dir}")"
    if [ ! -d "${parent_dir}" ]; then
        mkdir -p "${parent_dir}"
    fi

    backup_existing "${config_dir}"

    echo "${BLUE}Linking: ${source_dir} -> ${config_dir}${RESET}"
    ln -s "${source_dir}" "${config_dir}"
}

usage() {
    echo "Usage: $0 [OPTIONS]"
    echo
    echo "OPTIONS:"
    echo "  --help          Display this help menu"
    echo "  --no-clone      Skip cloning; use the directory containing this script"
}

main() {
    clone=true

    while [ $# -gt 0 ]; do
        case $1 in
            --help) usage; exit 0 ;;
            --no-clone) clone=false ;;
            *) usage >&2; exit 1 ;;
        esac
        shift
    done

    setup_color
    detect_os

    if ! command_exists opencode; then
        echo "${BLUE}Installing OpenCode...${RESET}"
        curl -fsSL https://opencode.ai/install | bash || {
            error "OpenCode installation failed"
            exit 1
        }
        echo
    fi

    ensure_rootless_podman

    CONFIG_DIR="$(detect_config_dir)"

    if [ "${clone}" = true ]; then
        SOURCE_DIR="${CONFIG_DIR}"
        # When cloning, we need to back up first, then clone into the target
        backup_existing "${CONFIG_DIR}"
        clone_repo
    else
        SOURCE_DIR="$(detect_source_dir)"
        link_config "${CONFIG_DIR}" "${SOURCE_DIR}"
    fi

    printf "$GREEN"
	cat <<-'EOF'
	  ___        _   _                         _                             _   _   _ _       _____                  _____           _        _____              __ _                       _   _
	 / _ \      | | | |                       | |                           | | | | (_| )     |  _  |                /  __ \         | |      /  __ \            / _(_)                     | | (_)
	/ /_\ \_ __ | |_| |__   ___  _ __  _   _  | |     __ _ _ __  _ __  _   _| |_| |_ _|/ ___  | | | |_ __   ___ _ __ | /  \/ ___   __| | ___  | /  \/ ___  _ __ | |_ _  __ _ _   _ _ __ __ _| |_ _  ___  _ __
	|  _  | '_ \| __| '_ \ / _ \| '_ \| | | | | |    / _` | '_ \| '_ \| | | | __| __| | / __| | | | | '_ \ / _ \ '_ \| |    / _ \ / _` |/ _ \ | |    / _ \| '_ \|  _| |/ _` | | | | '__/ _` | __| |/ _ \| '_ \
	| | | | | | | |_| | | | (_) | | | | |_| | | |___| (_| | | | | | | | |_| | |_| |_| | \__ \ \ \_/ / |_) |  __/ | | | \__/\ (_) | (_| |  __/ | \__/\ (_) | | | | | | | (_| | |_| | | | (_| | |_| | (_) | | | |
	\_| |_/_| |_|\__|_| |_|\___/|_| |_|\__, | \_____/\__,_|_| |_|_| |_|\__,_|\__|\__|_| |___/  \___/| .__/ \___|_| |_|\____/\___/ \__,_|\___|  \____/\___/|_| |_|_| |_|\__, |\__,_|_|  \__,_|\__|_|\___/|_| |_|
	                                    __/ |                                                       | |                                                                 __/ |
	                                   |___/                                                        |_|                                                                |___/
	EOF
    printf "$RESET"
}

main "$@"
