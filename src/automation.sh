#!/bin/bash
# src/automation.sh - Módulo interactivo para gestionar tareas programadas (cron y at)
# Autor: Administrador de Sistemas Linux

# ==========================================
# 2. Función: automatizar_cron
# ==========================================
automatizar_cron() {
    echo -e "\n${CYAN}--- Programar nueva tarea recurrente (CRON) ---${NC}"
    comando=$(input_campo "Introduce el comando o script a ejecutar:")
    if [ -z "$comando" ]; then
        msg_err "El comando no puede estar vacío."
        pausar
        return
    fi
    
    echo -e "Ejemplo de formato: '* * * * *' (minuto hora día mes día_semana)"
    frecuencia=$(input_campo "Introduce la frecuencia en formato cron:")
    if [ -z "$frecuencia" ]; then
        msg_err "La frecuencia no puede estar vacía."
        pausar
        return
    fi

    local temp_cron
    temp_cron=$(mktemp)
    
    # Exportamos el crontab actual al archivo temporal, ignorando errores si no existe crontab
    crontab -l > "$temp_cron" 2>/dev/null || true
    
    # Agregamos la nueva tarea al final del archivo temporal
    echo "$frecuencia $comando" >> "$temp_cron"
    
    if confirmar_whiptail "¿Confirmas la tarea cron?"; then
        # Cargamos el nuevo crontab en el sistema
        if crontab "$temp_cron" 2>/dev/null; then
            msg_ok "¡Tarea cron agregada exitosamente!"
        else
            msg_err "Error al agregar la tarea cron. Revisa la sintaxis de la frecuencia."
        fi
    else
        msg_warn "Tarea cron cancelada."
    fi
    
    # Limpieza
    rm -f "$temp_cron"
    pausar
}

# ==========================================
# 3. Función: automatizar_at
# ==========================================
automatizar_at() {
    echo -e "\n${CYAN}--- Programar nueva tarea puntual (AT) ---${NC}"
    comando=$(input_campo "Introduce el comando a ejecutar:")
    if [ -z "$comando" ]; then
        msg_err "El comando no puede estar vacío."
        pausar
        return
    fi
    
    echo -e "Ejemplos de formato: 'now + 1 minute', '5:00 PM', 'tomorrow', '23:00 05/10/2026'"
    tiempo=$(input_campo "Introduce la fecha/hora:")
    if [ -z "$tiempo" ]; then
        msg_err "La fecha/hora no puede estar vacía."
        pausar
        return
    fi

    if confirmar_whiptail "¿Confirmas la tarea puntual?"; then
        # Programar la tarea enviando el comando por tubería (pipe) al comando 'at'
        if echo "$comando" | at "$tiempo" 2>/dev/null; then
            msg_ok "¡Tarea 'at' programada exitosamente!"
        else
            msg_err "Error al programar la tarea puntual. Revisa que el formato de hora/fecha sea válido."
        fi
    else
        msg_warn "Tarea puntual cancelada."
    fi
    pausar
}

# ==========================================
# 4. Función: listar_cron
# ==========================================
listar_cron() {
    echo -e "\n${CYAN}--- Tareas Cron Actuales ---${NC}"
    
    # Si crontab -l devuelve un código distinto de 0, significa que no hay crontab para el usuario
    if crontab -l >/dev/null 2>&1; then
        local output
        output=$(crontab -l)
        if [ -z "$output" ]; then
            msg_warn "El crontab está vacío. No hay tareas recurrentes configuradas."
        else
            msg_ok "$output"
        fi
    else
        msg_warn "No hay tareas recurrentes configuradas (no existe un crontab para este usuario)."
    fi
    pausar
}

# ==========================================
# 5. Función: listar_at
# ==========================================
listar_at() {
    echo -e "\n${CYAN}--- Tareas Puntuales Programadas (AT) ---${NC}"
    
    # El comando atq lista la cola de trabajos programados
    local output
    output=$(atq 2>/dev/null)
    
    if [ -z "$output" ]; then
        msg_warn "La cola de tareas puntuales está vacía."
    else
        msg_ok "$output"
    fi
    pausar
}

# ==========================================
# 1. Función: menu_automatizacion
# ==========================================
menu_automatizacion() {
    local opcion
    # Ciclo infinito del menú
    while true; do
        print_header "Gestión de Automatización"
        echo -e " 1) Programar tarea recurrente (cron)"
        echo -e " 2) Programar tarea puntual (at)"
        echo -e " 3) Listar tareas recurrentes (cron)"
        echo -e " 4) Listar tareas puntuales (at)"
        echo -e " 0) Volver al menú principal"
        echo -e "${CYAN}================================================${NC}"
        opcion=$(input_campo "Selecciona una opción [0-4]:")
        
        # Manejo de la selección del usuario
        case $opcion in
            1) automatizar_cron ;;
            2) automatizar_at ;;
            3) listar_cron ;;
            4) listar_at ;;
            0) return ;;
            *) 
                # Gestión amigable de opciones inválidas
                msg_err "Opción inválida '$opcion'. Por favor, selecciona un número del 0 al 4."
                pausar
                ;;
        esac
    done
}
