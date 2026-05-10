#!/bin/bash
# src/automation.sh - Módulo interactivo para gestionar tareas programadas (cron y at)
# Autor: Administrador de Sistemas Linux

# ==========================================
# Definición de Colores para la Interfaz
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[1;34m'
CYAN='\033[1;36m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# ==========================================
# 2. Función: automatizar_cron
# ==========================================
automatizar_cron() {
    echo -e "\n${CYAN}--- Programar nueva tarea recurrente (CRON) ---${NC}"
    read -r -p "Introduce el comando o script a ejecutar: " comando
    if [ -z "$comando" ]; then
        echo -e "${RED}Error: El comando no puede estar vacío.${NC}"
        return
    fi
    
    echo -e "Ejemplo de formato: '* * * * *' (minuto hora día mes día_semana)"
    read -r -p "Introduce la frecuencia en formato cron: " frecuencia
    if [ -z "$frecuencia" ]; then
        echo -e "${RED}Error: La frecuencia no puede estar vacía.${NC}"
        return
    fi

    # Se utiliza un archivo temporal para no sobreescribir las tareas previas
    local temp_cron
    temp_cron=$(mktemp)
    
    # Exportamos el crontab actual al archivo temporal, ignorando errores si el usuario no tiene crontab previo
    crontab -l > "$temp_cron" 2>/dev/null || true
    
    # Agregamos la nueva tarea al final del archivo temporal
    echo "$frecuencia $comando" >> "$temp_cron"
    
    # Cargamos el nuevo crontab en el sistema
    if crontab "$temp_cron" 2>/dev/null; then
        echo -e "${GREEN}¡Tarea cron agregada exitosamente!${NC}"
    else
        echo -e "${RED}Error al agregar la tarea cron. Revisa la sintaxis de la frecuencia.${NC}"
    fi
    
    # Limpieza
    rm -f "$temp_cron"
}

# ==========================================
# 3. Función: automatizar_at
# ==========================================
automatizar_at() {
    echo -e "\n${CYAN}--- Programar nueva tarea puntual (AT) ---${NC}"
    read -r -p "Introduce el comando a ejecutar: " comando
    if [ -z "$comando" ]; then
        echo -e "${RED}Error: El comando no puede estar vacío.${NC}"
        return
    fi
    
    echo -e "Ejemplos de formato: 'now + 1 minute', '5:00 PM', 'tomorrow', '23:00 05/10/2026'"
    read -r -p "Introduce la fecha/hora: " tiempo
    if [ -z "$tiempo" ]; then
        echo -e "${RED}Error: La fecha/hora no puede estar vacía.${NC}"
        return
    fi

    # Programar la tarea enviando el comando por tubería (pipe) al comando 'at'
    if echo "$comando" | at "$tiempo" 2>/dev/null; then
        echo -e "${GREEN}¡Tarea 'at' programada exitosamente!${NC}"
    else
        echo -e "${RED}Error al programar la tarea puntual. Revisa que el formato de hora/fecha sea válido.${NC}"
    fi
}

# ==========================================
# 4. Función: listar_cron
# ==========================================
listar_cron() {
    echo -e "\n${BLUE}--- Tareas Cron Actuales ---${NC}"
    
    # Si crontab -l devuelve un código distinto de 0, significa que no hay crontab para el usuario
    if crontab -l >/dev/null 2>&1; then
        local output
        output=$(crontab -l)
        if [ -z "$output" ]; then
            echo -e "${YELLOW}El crontab está vacío. No hay tareas recurrentes configuradas.${NC}"
        else
            echo -e "${GREEN}$output${NC}"
        fi
    else
        echo -e "${YELLOW}No hay tareas recurrentes configuradas (no existe un crontab para este usuario).${NC}"
    fi
}

# ==========================================
# 5. Función: listar_at
# ==========================================
listar_at() {
    echo -e "\n${BLUE}--- Tareas Puntuales Programadas (AT) ---${NC}"
    
    # El comando atq lista la cola de trabajos programados
    local output
    output=$(atq 2>/dev/null)
    
    if [ -z "$output" ]; then
        echo -e "${YELLOW}La cola de tareas puntuales está vacía.${NC}"
    else
        echo -e "${GREEN}$output${NC}"
    fi
}

# ==========================================
# 1. Función: menu_automatizacion
# ==========================================
menu_automatizacion() {
    local opcion
    # Ciclo infinito del menú
    while true; do
        echo -e "\n${BLUE}================================================${NC}"
        echo -e "${CYAN}      MENÚ DE GESTIÓN DE AUTOMATIZACIÓN         ${NC}"
        echo -e "${BLUE}================================================${NC}"
        echo -e " 1) Programar tarea recurrente (cron)"
        echo -e " 2) Programar tarea puntual (at)"
        echo -e " 3) Listar tareas recurrentes (cron)"
        echo -e " 4) Listar tareas puntuales (at)"
        echo -e " 5) Salir"
        echo -e "${BLUE}================================================${NC}"
        read -r -p "Selecciona una opción [1-5]: " opcion
        
        # Manejo de la selección del usuario
        case $opcion in
            1) automatizar_cron ;;
            2) automatizar_at ;;
            3) listar_cron ;;
            4) listar_at ;;
            5) 
                echo -e "\n${GREEN}Saliendo del módulo de automatización... ¡Hasta luego!${NC}"
                break
                ;;
            *) 
                # Gestión amigable de opciones inválidas
                echo -e "\n${RED}Opción inválida '$opcion'. Por favor, selecciona un número del 1 al 5.${NC}"
                ;;
        esac
    done
}

# ==========================================
# Ejecución Principal
# ==========================================
menu_automatizacion
