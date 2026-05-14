#!/usr/bin/env bash
#
# src/backup.sh - Backup module for archive creation workflows.

# Main menu for the backup module.
menu_respaldo() {
    local opcion

    while true; do
        clear
        print_header "Respaldo de Información"
        opcion=$(gum choose \
            --header "Selecciona una opción:" \
            --cursor "▸ " \
            "Respaldo con Gzip (.tar.gz)" \
            "Respaldo con Bzip2 (.tar.bz2)" \
            "← Volver al menú principal")

        [[ -z "$opcion" || "$opcion" == "← Volver al menú principal" ]] && return

        case "$opcion" in
            "Respaldo con Gzip (.tar.gz)")   respaldar_gzip  ;;
            "Respaldo con Bzip2 (.tar.bz2)") respaldar_bzip2 ;;
        esac
    done
}

# Create a gzip-compressed backup archive.
respaldar_gzip() {
    print_header "Respaldo con Gzip"

    local origen
    local destino

    # Ask for the source directory.
    origen=$(seleccionar_directorio "Selecciona la carpeta a respaldar:")

    if [[ -z "$origen" ]]; then
        msg_err "La ruta de origen no puede estar vacía."
        pausar
        return
    fi

    # Ensure the source directory exists.
    if [[ ! -d "$origen" ]]; then
        msg_err "La carpeta '$origen' no existe."
        pausar
        return
    fi

    # Ask for the destination directory.
    destino=$(seleccionar_directorio "Selecciona la carpeta de destino:")

    if [[ -z "$destino" ]]; then
        msg_err "La ruta de destino no puede estar vacía."
        pausar
        return
    fi

    # Offer to create the destination directory when it is missing.
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

    # Stop early when the destination is not writable.
    if [[ ! -w "$destino" ]]; then
        msg_err "Sin permisos de escritura en '$destino'."
        pausar
        return
    fi

    local nombre
    local tamano

    # Generate a timestamped archive name from the source directory.
    nombre="backup_$(basename "$origen")_$(date +%Y%m%d_%H%M%S).tar.gz"

    # Create the compressed archive in the destination directory.
    tar -czf "$destino/$nombre" -C "$(dirname "$origen")" "$(basename "$origen")"

    # Report tar failures explicitly.
    if [[ $? -ne 0 ]]; then
        msg_err "No se pudo crear el respaldo."
        pausar
        return
    fi

    # Guard against silent failures where the archive was not created.
    if [[ ! -f "$destino/$nombre" ]]; then
        msg_err "El archivo de respaldo no fue creado."
        pausar
        return
    fi

    # Show the final archive size to the operator.
    tamano=$(du -sh "$destino/$nombre" | awk '{print $1}')

    msg_ok "Respaldo creado: $destino/$nombre (tamaño: $tamano)"

    pausar
}

# Create a bzip2-compressed backup archive.
respaldar_bzip2() {
    print_header "Respaldo con Bzip2"

    local origen
    local destino

    # Ask for the source directory.
    origen=$(seleccionar_directorio "Selecciona la carpeta a respaldar:")

    if [[ -z "$origen" ]]; then
        msg_err "La ruta de origen no puede estar vacía."
        pausar
        return
    fi

    # Ensure the source directory exists.
    if [[ ! -d "$origen" ]]; then
        msg_err "La carpeta '$origen' no existe."
        pausar
        return
    fi

    # Ask for the destination directory.
    destino=$(seleccionar_directorio "Selecciona la carpeta de destino:")

    if [[ -z "$destino" ]]; then
        msg_err "La ruta de destino no puede estar vacía."
        pausar
        return
    fi

    # Offer to create the destination directory when it is missing.
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

    # Stop early when the destination is not writable.
    if [[ ! -w "$destino" ]]; then
        msg_err "Sin permisos de escritura en '$destino'."
        pausar
        return
    fi

    local nombre
    local tamano

    # Generate a timestamped archive name from the source directory.
    nombre="backup_$(basename "$origen")_$(date +%Y%m%d_%H%M%S).tar.bz2"

    # Create the compressed archive in the destination directory.
    tar -cjf "$destino/$nombre" -C "$(dirname "$origen")" "$(basename "$origen")"

    # Report tar failures explicitly.
    if [[ $? -ne 0 ]]; then
        msg_err "No se pudo crear el respaldo."
        pausar
        return
    fi

    # Guard against silent failures where the archive was not created.
    if [[ ! -f "$destino/$nombre" ]]; then
        msg_err "El archivo de respaldo no fue creado."
        pausar
        return
    fi

    # Show the final archive size to the operator.
    tamano=$(du -sh "$destino/$nombre" | awk '{print $1}')

    msg_ok "Respaldo creado: $destino/$nombre (tamaño: $tamano)"

    pausar
}
