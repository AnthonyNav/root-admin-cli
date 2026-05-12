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
    
    local opcion_freq
    opcion_freq=$(gum choose \
        --header "¿Con qué frecuencia se ejecutará la tarea?" \
        --cursor "▸ " \
        "Cada minuto          →  * * * * *" \
        "Cada hora            →  0 * * * *" \
        "Diariamente (00:00)  →  0 0 * * *" \
        "Semanalmente (lunes) →  0 0 * * 1" \
        "Mensualmente (día 1) →  0 0 1 * *" \
        "Personalizado        →  escribir expresión")

    [[ -z "$opcion_freq" ]] && return

    case "$opcion_freq" in
        "Cada minuto"*)          frecuencia="* * * * *" ;;
        "Cada hora"*)            frecuencia="0 * * * *" ;;
        "Diariamente"*)          frecuencia="0 0 * * *" ;;
        "Semanalmente"*)         frecuencia="0 0 * * 1" ;;
        "Mensualmente"*)         frecuencia="0 0 1 * *" ;;
        "Personalizado"*)
            echo ""
            gum style --foreground 8 \
                "Formato: MIN HORA DÍA MES DÍA_SEMANA"
            gum style --foreground 8 \
                "Ejemplo: 30 8 * * 1-5  (lun-vie a las 8:30)"
            echo ""
            frecuencia=$(input_campo "Escribe la expresión cron:")
            if [[ -z "$frecuencia" ]]; then
                msg_err "La frecuencia no puede estar vacía."
                pausar
                return
            fi
            ;;
    esac

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

# ─── Interpretación básica de frecuencia cron ─────────────────────────────────
# Convierte una expresión cron a lenguaje natural básico.
interpretar_frecuencia() {
    local expr="$1"
    case "$expr" in
        "* * * * *")    echo "Cada minuto" ;;
        "0 * * * *")    echo "Cada hora (al minuto 0)" ;;
        "0 0 * * *")    echo "Diariamente a medianoche" ;;
        "0 0 * * 0")    echo "Semanalmente (domingos a medianoche)" ;;
        "0 0 * * 1")    echo "Semanalmente (lunes a medianoche)" ;;
        "0 0 1 * *")    echo "El 1ro de cada mes a medianoche" ;;
        "0 8 * * 1-5")  echo "Lunes a viernes a las 08:00" ;;
        *)               echo "Personalizado" ;;
    esac
}

# ==========================================
# 4. Función: listar_cron
# ==========================================
listar_cron() {
    print_header "Tareas Cron Actuales"

    if ! crontab -l >/dev/null 2>&1; then
        msg_warn "No hay tareas recurrentes configuradas."
        pausar
        return
    fi

    local output
    output=$(crontab -l 2>/dev/null | grep -v '^#' | grep -v '^$')

    if [[ -z "$output" ]]; then
        msg_warn "El crontab está vacío. No hay tareas recurrentes configuradas."
        pausar
        return
    fi

    echo ""
    # Encabezado de columnas
    gum style --bold --foreground 6 \
        "  MIN    HORA   DÍA    MES    D.SEM  COMANDO"
    echo -e "\033[0;36m  ─────────────────────────────────────────────────────\033[0m"

    # Mostrar cada tarea con interpretación
    while IFS= read -r linea; do
        local min hora dia mes dsem
        read min hora dia mes dsem resto <<< "$linea"
        local expresion="$min $hora $dia $mes $dsem"
        local interpretacion
        interpretacion=$(interpretar_frecuencia "$expresion")

        printf "  %-6s %-6s %-6s %-6s %-6s %s\n" \
            "$min" "$hora" "$dia" "$mes" "$dsem" "$resto"
        gum style --foreground 8 "          ↳ $interpretacion"
        echo ""
    done <<< "$output"

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
        echo ""
        echo "$output"
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
        clear
        print_header "Gestión de Automatización"
        opcion=$(gum choose \
            --header "Selecciona una opción:" \
            --cursor "▸ " \
            "Programar tarea recurrente (cron)" \
            "Programar tarea puntual (at)" \
            "Listar tareas recurrentes (cron)" \
            "Listar tareas puntuales (at)" \
            "← Volver al menú principal")

        [[ -z "$opcion" || "$opcion" == "← Volver al menú principal" ]] && return

        case "$opcion" in
            "Programar tarea recurrente (cron)") automatizar_cron ;;
            "Programar tarea puntual (at)")      automatizar_at   ;;
            "Listar tareas recurrentes (cron)")  listar_cron      ;;
            "Listar tareas puntuales (at)")      listar_at        ;;
        esac
    done
}
