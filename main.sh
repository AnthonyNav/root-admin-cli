#!/usr/bin/env bash
#
# main.sh — Administración de Redes: Parte 1
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: [Nombre] (PR #2 · feat/core-entrypoint)
#
# Uso: sudo bash main.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# ─── Cargar módulos ───────────────────────────────────────────────────────────
source "$SCRIPT_DIR/src/lib/utils.sh"
source "$SCRIPT_DIR/src/users.sh"
source "$SCRIPT_DIR/src/groups.sh"
source "$SCRIPT_DIR/src/processes.sh"

# ─── Verificación de root ─────────────────────────────────────────────────────
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "Acceso denegado: este script debe ejecutarse como root."
    echo "Usa: sudo bash main.sh"
    echo ""
    exit 1
fi

# ─── Menú principal ───────────────────────────────────────────────────────────
main() {
    local opcion

    while true; do
        clear
        print_header "Administración de Redes — Menú Principal"
        echo "  1) Usuarios"
        echo "  2) Grupos"
        echo "  3) Procesos de usuario"
        echo ""
        echo "  0) Salir"
        echo ""
        read -rp "  Selecciona una opción: " opcion
        echo ""

        case $opcion in
            1) menu_usuarios ;;
            2) menu_grupos   ;;
            3) menu_procesos ;;
            0)
                echo "Saliendo. Hasta luego."
                echo ""
                exit 0
                ;;
            *)
                msg_warn "Opción inválida. Intenta de nuevo."
                pausar
                ;;
        esac
    done
}

main