#!/usr/bin/env bash
#
# main.sh — Administración de Redes: Parte 1
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: [Tu Nombre] (PR #2 · feat/core-entrypoint)
#
# Uso: sudo bash main.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Cargar módulos ───────────────────────────────────────────────────────────
source "$SCRIPT_DIR/src/lib/utils.sh"
source "$SCRIPT_DIR/src/users.sh"
source "$SCRIPT_DIR/src/groups.sh"
source "$SCRIPT_DIR/src/processes.sh"
source "$SCRIPT_DIR/src/automation.sh"
source "$SCRIPT_DIR/src/backup.sh"
source "$SCRIPT_DIR/src/security.sh"

# ─── Verificación de root ─────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo -e "\033[0;31m[ERROR]\033[0m Acceso denegado: este script debe ejecutarse como root."
    echo "Usa: sudo bash main.sh"
    echo ""
    exit 1
fi

# ─── Menú principal ───────────────────────────────────────────────────────────
main() {
    local opcion

    while true; do
        opcion=$(whiptail --title "Administración de Redes — Menú Principal" \
            --menu "Selecciona un módulo a gestionar:" 20 60 7 \
            "1" "Usuarios" \
            "2" "Grupos" \
            "3" "Procesos de usuario" \
            "4" "Automatización de tareas" \
            "5" "Respaldo de información" \
            "6" "Seguridad / Monitoreo" \
            "0" "Salir" \
            3>&1 1>&2 2>&3)

        # Si el usuario presiona ESC o Cancelar, salimos limpiamente
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
