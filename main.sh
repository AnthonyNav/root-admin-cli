#!/usr/bin/env bash
#
# main.sh - Entry point for the Admin Redes CLI.
# Target platform: AlmaLinux 9 with Bash 5.0 or newer.
#
# Usage:
#   sudo bash main.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Install the UI tools required by the interactive experience.
instalar_ui() {
    if ! command -v gum &>/dev/null; then
        echo "Instalando gum (primera ejecución)..."
        echo '[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key' | tee /etc/yum.repos.d/charm.repo >/dev/null
        rpm --import https://repo.charm.sh/yum/gpg.key 2>/dev/null
        dnf install -y gum >/dev/null 2>&1 && echo "gum instalado." || echo "Error instalando gum."
    fi
    if ! command -v figlet &>/dev/null; then
        dnf install -y figlet >/dev/null 2>&1
    fi
    if ! command -v fzf &>/dev/null; then
        dnf install -y fzf >/dev/null 2>&1 && \
            echo "fzf instalado." || echo "Error instalando fzf."
    fi
}

# Return success when the current terminal is likely to support the resize escape.
soporta_zoom_terminal() {
    [[ -t 1 ]] || return 1

    case "${TERM:-}" in
        xterm*|vte*|screen*|tmux*|rxvt*)
            return 0
            ;;
        *)
            return 1
            ;;
    esac
}

# Render the application title and attempt to maximize the terminal window.
show_titulo() {
    # Resize only on terminals that typically honor the xterm-compatible escape.
    if soporta_zoom_terminal; then
        printf '\e[9;1t'
        sleep 0.1
    fi

    clear
    echo ""
    # Color figlet output with ANSI directly so multiline alignment stays intact.
    echo -e "\033[0;36m$(figlet -f slant 'Admin Redes')\033[0m"
    echo -e "\033[0;37m  Administración de Redes · AlmaLinux 9 · BUAP\033[0m"
    echo ""
}

# Load project modules.
source "$SCRIPT_DIR/src/lib/utils.sh"
source "$SCRIPT_DIR/src/users.sh"
source "$SCRIPT_DIR/src/groups.sh"
source "$SCRIPT_DIR/src/processes.sh"
source "$SCRIPT_DIR/src/automation.sh"
source "$SCRIPT_DIR/src/backup.sh"
source "$SCRIPT_DIR/src/security.sh"

# Install UI tools before entering the interactive flow.
instalar_ui

# Require root privileges for all administrative actions.
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo -e "\033[0;31m[ERROR]\033[0m Acceso denegado: este script debe ejecutarse como root."
    echo "Usa: sudo bash main.sh"
    echo ""
    exit 1
fi

# Main application loop.
main() {
    local opcion

    while true; do
        show_titulo
        opcion=$(seleccionar_menu \
            "Administración de Redes — Menú Principal" \
            "Selecciona un módulo a gestionar:" \
            "1" "Usuarios" \
            "2" "Grupos" \
            "3" "Procesos de usuario" \
            "4" "Automatización de tareas" \
            "5" "Respaldo de información" \
            "6" "Seguridad / Monitoreo" \
            "0" "Salir")

        # Exit cleanly when the user cancels or selects the exit option.
        if [[ -z "$opcion" || "$opcion" == "0" ]]; then
            clear
            msg_ok "Saliendo del sistema. ¡Hasta luego!"
            exit 0
        fi

        case $opcion in
            1) menu_usuarios       ;;
            2) menu_grupos         ;;
            3) menu_procesos       ;;
            4) menu_automatizacion ;;
            5) menu_respaldo       ;;
            6) menu_seguridad      ;;
            *)
                msg_warn "Opción inválida. Intenta de nuevo."
                pausar
                ;;
        esac
    done
}

main
