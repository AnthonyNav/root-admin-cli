#!/usr/bin/env bash
#
# src/backup.sh — Módulo de respaldo de información
# Plataforma: AlmaLinux 9 | Bash 5.0+
#
# Autor del módulo: Imanol (PR P2-2 · feat/backup-module)
#
# Comandos del sistema que utilizarás:
#   tar     → crear respaldos .tar.gz y .tar.bz2
#   du      → mostrar tamaño del archivo generado
#   mkdir   → crear directorios destino
#   basename → obtener nombre de carpeta origen
#   date    → generar timestamp automático
#
# Nota:
# utils.sh ya fue cargado por main.sh.
# Puedes usar directamente:
#   print_header, msg_ok, msg_err, msg_warn,
#   confirmar_accion y pausar
#

# ──────────────────────────────────────────────────────────────────────────────
# menu_respaldo
# Muestra el submenú de respaldos.
# ──────────────────────────────────────────────────────────────────────────────
menu_respaldo() {
    local opcion

    while true; do
        clear
        print_header "Respaldo de Información"

        echo "  1) Respaldo con Gzip (.tar.gz)"
        echo "  2) Respaldo con Bzip2 (.tar.bz2)"
        echo ""
        echo "  0) Volver al menú principal"
        echo ""

        read -rp "  Selecciona una opción: " opcion
        echo ""

        case $opcion in
            1) respaldar_gzip ;;
            2) respaldar_bzip2 ;;
            0) return ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}

# ──────────────────────────────────────────────────────────────────────────────
# respaldar_gzip
# Crea un respaldo comprimido en formato .tar.gz
# ──────────────────────────────────────────────────────────────────────────────
respaldar_gzip() {
    print_header "Respaldo con Gzip"

    local origen
    local destino

    # Solicitar carpeta origen
    read -rp "Carpeta origen: " origen

    # Validar existencia de carpeta origen
    if [[ ! -d "$origen" ]]; then
        msg_err "La carpeta '$origen' no existe."
        pausar
        return
    fi

    # Solicitar carpeta destino
    read -rp "Ruta destino: " destino


    # Verificar si la carpeta destino existe
    if [[ ! -d "$destino" ]]; then
        msg_warn "La carpeta '$destino' no existe."

        if confirmar_accion "¿Deseas crearla?"; then
            mkdir -p "$destino" 2>/dev/null

            if [[ $? -ne 0 ]]; then
                msg_err "No se pudo crear la carpeta '$destino'."
                pausar
                return
            fi

            msg_ok "Carpeta creada correctamente."
        else
            msg_warn "Operación cancelada."
            pausar
            return
        fi
    fi

    # Verificar permisos de escritura
    if [[ ! -w "$destino" ]]; then
        msg_err "Sin permisos de escritura en '$destino'."
        pausar
        return
    fi

    local nombre
    local tamano

    # Generar nombre automático del respaldo
    nombre="backup_$(basename "$origen")_$(date +%Y%m%d_%H%M%S).tar.gz"

    # Crear respaldo comprimido
    tar -czf "$destino/$nombre" -C "$(dirname "$origen")" "$(basename "$origen")"

    # Verificar si tar falló
    if [[ $? -ne 0 ]]; then
        msg_err "No se pudo crear el respaldo."
        pausar
        return
    fi

    # Verificar que el archivo exista
    if [[ ! -f "$destino/$nombre" ]]; then
        msg_err "El archivo de respaldo no fue creado."
        pausar
        return
    fi

    # Obtener tamaño del archivo
    tamano=$(du -sh "$destino/$nombre" | awk '{print $1}')

    msg_ok "Respaldo creado: $destino/$nombre (tamaño: $tamano)"

    pausar




}

# ──────────────────────────────────────────────────────────────────────────────
# respaldar_bzip2
# Crea un respaldo comprimido en formato .tar.bz2
# ──────────────────────────────────────────────────────────────────────────────
respaldar_bzip2() {
    print_header "Respaldo con Bzip2"

    local origen
    local destino

    # Solicitar carpeta origen
    read -rp "Carpeta origen: " origen

    # Validar existencia de carpeta origen
    if [[ ! -d "$origen" ]]; then
        msg_err "La carpeta '$origen' no existe."
        pausar
        return
    fi

    # Solicitar carpeta destino
    read -rp "Ruta destino: " destino

    # Verificar si la carpeta destino existe
    if [[ ! -d "$destino" ]]; then
        msg_warn "La carpeta '$destino' no existe."

        if confirmar_accion "¿Deseas crearla?"; then
            mkdir -p "$destino" 2>/dev/null

            if [[ $? -ne 0 ]]; then
                msg_err "No se pudo crear la carpeta '$destino'."
                pausar
                return
            fi

            msg_ok "Carpeta creada correctamente."
        else
            msg_warn "Operación cancelada."
            pausar
            return
        fi
    fi

    # Verificar permisos de escritura
    if [[ ! -w "$destino" ]]; then
        msg_err "Sin permisos de escritura en '$destino'."
        pausar
        return
    fi

    local nombre
    local tamano

    # Generar nombre automático del respaldo
    nombre="backup_$(basename "$origen")_$(date +%Y%m%d_%H%M%S).tar.bz2"

    # Crear respaldo comprimido
    tar -cjf "$destino/$nombre" -C "$(dirname "$origen")" "$(basename "$origen")"

    # Verificar si tar falló
    if [[ $? -ne 0 ]]; then
        msg_err "No se pudo crear el respaldo."
        pausar
        return
    fi

    # Verificar que el archivo exista
    if [[ ! -f "$destino/$nombre" ]]; then
        msg_err "El archivo de respaldo no fue creado."
        pausar
        return
    fi

    # Obtener tamaño del archivo
    tamano=$(du -sh "$destino/$nombre" | awk '{print $1}')

    msg_ok "Respaldo creado: $destino/$nombre (tamaño: $tamano)"

    pausar
}
