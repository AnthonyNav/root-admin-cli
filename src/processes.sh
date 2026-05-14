#!/usr/bin/env bash
#
# src/processes.sh - Process inspection module.

# Main menu for process-related actions.
menu_procesos() {
    local opcion
    while true; do
        clear
        print_header "Procesos por Usuario"
        opcion=$(seleccionar_menu \
            "Procesos por Usuario" \
            "Selecciona una opción:" \
            "1" "Ver procesos del usuario (snapshot)" \
            "2" "Monitor en tiempo real (top)" \
            "3" "Ver procesos de root" \
            "0" "Volver al menú principal")

        [[ -z "$opcion" || "$opcion" == "0" ]] && return

        case "$opcion" in
            1) procesos_snapshot ;;
            2) procesos_monitor  ;;
            3) procesos_root     ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}

# Show a static snapshot of the selected user's processes.
procesos_snapshot() {
    local usuario
    print_header "Procesos del Usuario (snapshot)"
    
    usuario=$(seleccionar_usuario "Selecciona el usuario a consultar:")
    [[ -z "$usuario" ]] && return 0
    echo ""

    # Guard against empty values when the selector falls back to plain input.
    if [[ -z "$usuario" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    # Confirm the selected user still exists before calling ps.
    if ! usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' no existe en el sistema."
        pausar
        return
    fi

    # Count processes first so the summary message matches the output.
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

# Run top filtered by the selected user.
procesos_monitor() {
    local usuario
    print_header "Monitor en Tiempo Real"
    
    usuario=$(seleccionar_usuario "Selecciona el usuario para monitorear:")
    [[ -z "$usuario" ]] && return 0
    echo ""

    # Guard against empty values when the selector falls back to plain input.
    if [[ -z "$usuario" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    # Confirm the selected user still exists before opening top.
    if ! usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' no existe."
        pausar
        return
    fi

    # Remind the operator how to leave top.
    msg_warn "Presiona 'q' para salir del monitor."
    
    top -u "$usuario"

    # Pause after top returns so the user can read the summary line.
    pausar
}

# Show current processes owned by root.
procesos_root() {
    print_header "Procesos de root"
    
    ps aux --user root
    
    echo ""
    msg_ok "Mostrando procesos actuales del usuario 'root'."
    pausar
}
