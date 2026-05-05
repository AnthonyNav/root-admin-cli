#!/usr/bin/env bash
#
# src/processes.sh — Módulo de visualización de procesos por usuario
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del modulo: Osvaldo  (PR #5 · feat/processes-module)
#

# menu_procesos 
menu_procesos() {
    local opcion
    while true; do
        clear
        print_header "Procesos por Usuario"
        echo "  1) Ver procesos del usuario (snapshot)"
        echo "  2) Monitor en tiempo real (top)"
        echo ""
        echo "  0) Volver al menú principal"
        echo ""
        read -rp "  Selecciona una opción: " opcion

        case $opcion in
            1) procesos_snapshot ;;
            2) procesos_monitor  ;;
            0) return            ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}

# procesos_snapshot 
procesos_snapshot() {
    local usuario
    print_header "Procesos del Usuario (snapshot)"
    
    read -rp "  Ingresa el nombre de usuario a consultar: " usuario
    echo ""

    # 1. Validar nombre vacío
    if [[ -z "$usuario" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    # 2. Verificar existencia con el helper del proyecto
    if ! usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' no existe en el sistema."
        pausar
        return
    fi

    # 3. Obtener total de procesos
    local total
    total=$(ps -u "$usuario" --no-headers | wc -l)

    if [[ "$total" -eq 0 ]]; then
        # Texto exacto según TASKS.md
        msg_warn "No hay procesos activos para '$usuario'."
    else
        ps aux --user "$usuario"
        echo ""
        msg_ok "Se encontraron $total procesos para '$usuario'."
    fi

    pausar
}

# procesos_monitor 
procesos_monitor() {
    local usuario
    print_header "Monitor en Tiempo Real"
    
    read -rp "  Ingresa el usuario para monitorear: " usuario
    echo ""

    # 1. Validar vacío
    if [[ -z "$usuario" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    # 2. Verificar existencia con helper
    if ! usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' no existe."
        pausar
        return
    fi

    # 3. Aviso exacto según TASKS.md (sin sleep)
    msg_ok "Presiona 'q' para salir del monitor."
    
    top -u "$usuario"

    # 4. Pausar al regresar de top
    pausar
}