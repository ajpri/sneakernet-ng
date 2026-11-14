#!/usr/bin/env bash
# SPDX-License-Identifier: GPL-3.0-only
set -euo pipefail

ensure_python() {
    if python3 -c 'import tomllib' 2>/dev/null; then
        return
    fi

    printf 'SneakerNet needs Python 3.11 or later.\n' >&2
    . /etc/os-release
    local manager response
    case "$ID" in
        fedora) manager=dnf ;;
        debian|ubuntu) manager=apt-get ;;
        *) return 1 ;;
    esac
    printf 'The installer can run sudo %s install python3.\n' "$manager"
    if [[ ! -t 0 ]]; then
        return 1
    fi
    read -r -p 'Install Python 3? [y/N] ' response
    case "${response,,}" in
        y|yes) sudo "$manager" install python3 ;;
        *) return 1 ;;
    esac
    if ! python3 -c 'import tomllib' 2>/dev/null; then
        printf 'Python 3.11 or later is required.\n' >&2
        return 1
    fi
}

install_sneakernet() {
    local source_path="$1" action="$2" download_dir
    if [[ "$action" == uninstall ]]; then
        if [[ -z "$source_path" || ! -f "$source_path" ]]; then
            source_path="$HOME/.local/bin/sneakernet"
        fi
        if [[ ! -f "$source_path" ]]; then
            printf 'SneakerNet is not installed for this user.\n'
            return
        fi
    elif [[ -z "$source_path" || ! -f "$source_path" ]]; then
        if ! command -v curl >/dev/null; then
            printf 'Install curl or run installLinux.sh from a full checkout.\n' >&2
            return 1
        fi
        download_dir="$(mktemp -d)"
        trap "$(printf 'rm -rf -- %q' "$download_dir")" EXIT
        source_path="$download_dir/sneakernet"
        if ! curl -fsSL --proto '=https' --output "$source_path" \
            https://raw.githubusercontent.com/ajpri/sneakernet-ng/main/sneakernet; then
            printf 'Could not download SneakerNet from GitHub.\n' >&2
            return 1
        fi
        ensure_python
        python3 "$source_path" "$action"
        return
    fi

    ensure_python
    python3 "$source_path" "$action"
}

main() {
    local script_path="$1" source_path="" action=install terminal
    shift
    case "${1:-}" in
        "") ;;
        --uninstall) action=uninstall ;;
        -h|--help) printf 'Usage: %s [--uninstall]\n' "${script_path:-installLinux.sh}"; return ;;
        *) printf 'Usage: %s [--uninstall]\n' "${script_path:-installLinux.sh}" >&2; return 2 ;;
    esac
    if (( $# > 1 )); then
        printf 'Usage: %s [--uninstall]\n' "${script_path:-installLinux.sh}" >&2
        return 2
    fi
    if (( EUID == 0 )); then
        printf 'Run this installer as your desktop user. It asks for sudo if needed.\n' >&2
        return 1
    fi

    if [[ -n "$script_path" ]]; then
        source_path="$(cd -- "$(dirname -- "$script_path")" && pwd)/sneakernet"
    fi
    if [[ -t 0 ]]; then
        install_sneakernet "$source_path" "$action"
    elif { exec {terminal}</dev/tty; } 2>/dev/null; then
        install_sneakernet "$source_path" "$action" <&"$terminal"
    else
        install_sneakernet "$source_path" "$action" </dev/null
    fi
}

main "${BASH_SOURCE[0]:-}" "$@"
