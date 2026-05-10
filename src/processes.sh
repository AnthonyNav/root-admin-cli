#!/usr/bin/env bash
#
# src/processes.sh — Módulo de visualización de procesos por usuario
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del modulo: Osvaldo  (PR #5 · feat/part1-corrections)
#

# menu_procesos 
menu_procesos() {
    local opcion
    while true; do
        opcion=$(whiptail --title "Procesos por Usuario" \
            --menu "Selecciona una opción:" 14 60 4 \
            "1" "Ver procesos del usuario (snapshot)" \
            "2" "Monitor en tiempo real (top)" \
            "3" "Ver procesos de root" \
            "0" "Volver al menú principal" \
            3>&1 1>&2 2>&3)

        [[ -z "$opcion" || "$opcion" == "0" ]] && return

        case "$opcion" in
            1) procesos_snapshot ;;
            2) procesos_monitor  ;;
            3) procesos_root     ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}
# procesos_snapshot 
procesos_snapshot() {
    local usuario
    print_header "Procesos del Usuario (snapshot)"
    
    usuario=$(seleccionar_usuario "Selecciona el usuario a consultar:")
    [[ -z "$usuario" ]] && return 0
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
    
    usuario=$(seleccionar_usuario "Selecciona el usuario para monitorear:")
    [[ -z "$usuario" ]] && return 0
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
    msg_warn "Presiona 'q' para salir del monitor."
    
    top -u "$usuario"

    # 4. Pausar al regresar de top
    pausar
}

# procesos_root (Nueva funcionalidad solicitada)
procesos_root() {
    print_header "Procesos de root"
    
    ps aux --user root
    
    echo ""
    msg_ok "Mostrando procesos actuales del usuario 'root'."
    pausar
}
