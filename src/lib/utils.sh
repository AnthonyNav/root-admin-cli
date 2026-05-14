#!/usr/bin/env bash
#
# src/lib/utils.sh - Shared UI and validation helpers.
# Target platform: AlmaLinux 9 with Bash 5.0 or newer.
#

# ANSI color constants used by text-based status messages.
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# Print a consistent section header with gum styling.
print_header() {
    local titulo="$1"
    echo ""
    gum style \
        --border rounded \
        --border-foreground 6 \
        --padding "0 2" \
        --bold \
        --foreground 6 \
        "$titulo"
    echo ""
}

# Print a success message.
msg_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# Print an error message to stderr.
msg_err() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# Print a warning message.
msg_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# Ask for a simple yes/no confirmation using standard input.
confirmar_accion() {
    local pregunta="$1"
    local resp
    read -rp "$pregunta [s/N]: " resp
    [[ "$resp" =~ ^[sS]$ ]]
}

# Return success when the given user exists on the system.
usuario_existe() {
    [[ -z "$1" ]] && return 1
    id "$1" &>/dev/null
}

# Return success when the given group exists on the system.
grupo_existe() {
    [[ -z "$1" ]] && return 1
    if getent group "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Pause execution until the operator presses Enter.
pausar() {
    echo ""
    read -rp "  Presiona Enter para continuar..."
    echo ""
}

# Return success when gum can safely open interactive prompts.
ui_interactiva() {
    command -v gum &>/dev/null &&
        [[ -r /dev/tty && -w /dev/tty ]] &&
        [[ -t 0 || -t 1 || -t 2 ]]
}

# Render a menu and return the selected key on stdout.
# In interactive mode gum only shows labels, while this helper maps the label
# back to its key so existing case statements remain unchanged.
# In non-interactive mode it falls back to a plain read-based prompt.
seleccionar_menu() {
    local titulo="$1"
    local prompt="$2"
    local seleccion opcion i
    local -a claves descripciones
    shift 2 || return 1

    if (( $# == 0 || $# % 2 != 0 )); then
        return 1
    fi

    while (( $# >= 2 )); do
        claves+=("$1")
        descripciones+=("$2")
        shift 2
    done

    if ui_interactiva; then
        seleccion=$(printf '%s\n' "${descripciones[@]}" | \
            gum choose --header "$titulo"$'\n'"$prompt" --cursor "▸ ") || return 1

        for i in "${!descripciones[@]}"; do
            if [[ "${descripciones[$i]}" == "$seleccion" ]]; then
                printf '%s\n' "${claves[$i]}"
                return 0
            fi
        done

        return 1
    fi

    echo "$titulo" >&2
    echo "$prompt" >&2
    for i in "${!claves[@]}"; do
        printf '  [%s] %s\n' "${claves[$i]}" "${descripciones[$i]}" >&2
    done
    read -rp "Opción: " opcion || return 1
    printf '%s\n' "$opcion"
}

# List non-system users and return the selected username.
# Return 1 when the list is empty or the selection is cancelled.
seleccionar_usuario() {
    local titulo="${1:-Selecciona un usuario:}"
    local usuarios seleccion

    usuarios=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)

    if [[ -z "$usuarios" ]]; then
        msg_warn "No hay usuarios disponibles (UID >= 1000)."
        return 1
    fi

    if ui_interactiva; then
        echo "$usuarios" | gum choose --header "$titulo" --cursor "▸ "
        return $?
    fi

    read -rp "$titulo " seleccion || return 1
    [[ -n "$seleccion" ]] || return 1
    printf '%s\n' "$seleccion"
}

# List non-system groups and return the selected group name.
# Return 1 when the list is empty or the selection is cancelled.
seleccionar_grupo() {
    local titulo="${1:-Selecciona un grupo:}"
    local grupos seleccion

    grupos=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/group)

    if [[ -z "$grupos" ]]; then
        msg_warn "No hay grupos disponibles (GID >= 1000)."
        return 1
    fi

    if ui_interactiva; then
        echo "$grupos" | gum choose --header "$titulo" --cursor "▸ "
        return $?
    fi

    read -rp "$titulo " seleccion || return 1
    [[ -n "$seleccion" ]] || return 1
    printf '%s\n' "$seleccion"
}

# Read a free-form text value and print it to stdout.
input_campo() {
    local valor

    if ui_interactiva; then
        gum input --placeholder "$1" --width 60
        return $?
    fi

    read -rp "$1 " valor || return 1
    printf '%s\n' "$valor"
}

# Ask for UI confirmation using gum when available.
confirm_ui() {
    if ui_interactiva; then
        gum confirm "$1"
    else
        confirmar_accion "$1"
    fi
}

# Backward-compatible alias kept for legacy callers and tests.
confirmar_whiptail() {
    confirm_ui "$1"
}

# Select a directory with either an fzf browser or manual input.
# Return the chosen path on stdout and 1 on cancellation.
seleccionar_directorio() {
    local titulo="${1:-Selecciona un directorio:}"
    local modo

    if ! ui_interactiva; then
        input_campo "$titulo"
        return $?
    fi

    modo=$(gum choose \
        --header "¿Cómo deseas seleccionar la ruta?" \
        --cursor "▸ " \
        "Explorar directorios visualmente (fzf)" \
        "Escribir la ruta manualmente")

    [[ -z "$modo" ]] && return 1

    case "$modo" in
        "Explorar directorios visualmente (fzf)")
            if ! command -v fzf &>/dev/null; then
                msg_err "fzf no instalado. Usa la opción manual o: sudo dnf install fzf"
                return 1
            fi
            find /home /root /etc /var /tmp /srv /opt \
                 -maxdepth 5 -type d 2>/dev/null | \
            fzf --header "$titulo" \
                --preview 'echo "Contenido:" && ls -la {} 2>/dev/null | head -20' \
                --preview-window=right:50% \
                --prompt "▸ " \
                --pointer "▸" \
                --border rounded
            ;;
        "Escribir la ruta manualmente")
            input_campo "$titulo"
            ;;
    esac
}
