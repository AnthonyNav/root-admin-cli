#!/usr/bin/env bash
#
# src/groups.sh — Módulo de gestión de grupos
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: Imanol (PR #4 · feat/part1-corrections)
#

# ─── menu_grupos ─────────────────────────────────────────────────────────────
menu_grupos() {
    local opcion
    while true; do
        opcion=$(whiptail --title "Gestión de Grupos" \
            --menu "Selecciona una opción:" 16 60 5 \
            "1" "Alta de grupo" \
            "2" "Baja de grupo" \
            "3" "Consulta de grupo" \
            "4" "Modificaciones de grupo" \
            "0" "Volver al menú principal" \
            3>&1 1>&2 2>&3)

        [[ -z "$opcion" || "$opcion" == "0" ]] && return

        case "$opcion" in
            1) grupo_alta     ;;
            2) grupo_baja     ;;
            3) grupo_consulta ;;
            4) grupo_modificar ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}

# ─── grupo_alta ───────────────────────────────────────────────────────────────
grupo_alta() {
    print_header "Alta de Grupo"

    local grupo lista

    grupo=$(input_campo "Nombre del nuevo grupo:")
    [[ -z "$grupo" ]] && return 0

    # Verificar si ya existe
    if grupo_existe "$grupo"; then
        msg_err "El grupo '$grupo' ya existe."
        pausar
        return
    fi

    # Confirmar acción
    if ! confirmar_whiptail "¿Deseas crear el grupo '$grupo'?"; then
        msg_warn "Operación cancelada."
        pausar
        return
    fi

    # Crear grupo
    if groupadd "$grupo"; then
        msg_ok "Grupo '$grupo' creado correctamente."

        # Miembros iniciales
        if confirmar_whiptail "¿Deseas agregar miembros iniciales?"; then
            lista=$(input_campo "Lista de usuarios separados por comas (user1,user2):")
            if [[ -z "$lista" ]]; then
                msg_err "Lista inválida o vacía."
            else
                if gpasswd -M "$lista" "$grupo"; then
                    msg_ok "Miembros agregados correctamente."
                else
                    msg_err "Error al agregar miembros."
                fi
            fi
        fi
    else
        msg_err "Error al crear el grupo."
    fi
    pausar
}

# ─── grupo_baja ───────────────────────────────────────────────────────────────
grupo_baja() {
    print_header "Baja de Grupo"

    local grupo status

    grupo=$(seleccionar_grupo "Selecciona el grupo a eliminar:")
    [[ -z "$grupo" ]] && return 0

    if ! confirmar_whiptail "¿Deseas eliminar el grupo '$grupo'?"; then
        msg_warn "Operación cancelada."
        pausar
        return
    fi

    groupdel "$grupo"
    status=$?

    if [[ $status -eq 8 ]]; then
        msg_err "No se puede eliminar: es grupo primario de algún usuario."
        pausar
        return 1
    elif [[ $status -eq 0 ]]; then
        msg_ok "Grupo '$grupo' eliminado correctamente."
        pausar
        return 0
    else
        msg_err "No se pudo eliminar el grupo."
        pausar
        return 1
    fi
}

# ─── grupo_consulta ──────────────────────────────────────────────────────────
grupo_consulta() {
    print_header "Consulta de Grupo"

    local grupo info gid miembros

    grupo=$(seleccionar_grupo "Selecciona el grupo a consultar:")
    [[ -z "$grupo" ]] && return 0

    info=$(getent group "$grupo")
    gid=$(echo "$info" | cut -d: -f3)
    miembros=$(echo "$info" | cut -d: -f4)

    echo ""
    echo "Grupo:    $grupo"
    echo "GID:      $gid"

    if [[ -z "$miembros" ]]; then
        echo "Miembros: (sin miembros)"
    else
        echo "Miembros: $miembros"
    fi

    echo ""
    pausar
}

# ─── grupo_modificar ─────────────────────────────────────────────────────────
grupo_modificar() {
    local grupo opcion usuario nuevo_nombre lista

    print_header "Modificaciones de Grupo"

    grupo=$(seleccionar_grupo "Selecciona el grupo a modificar:")
    [[ -z "$grupo" ]] && return 0

    while true; do
        clear
        print_header "Modificar Grupo: $grupo"

        echo "1) Renombrar grupo"
        echo "2) Agregar miembro al grupo"
        echo "3) Quitar miembro del grupo"
        echo "4) Reemplazar lista completa"
        echo ""
        echo "0) Volver"
        echo ""

        read -rp "Selecciona una opción: " opcion

        case $opcion in
            1)
                nuevo_nombre=$(input_campo "Nuevo nombre para el grupo:")
                [[ -z "$nuevo_nombre" ]] && { pausar; continue; }

                if grupo_existe "$nuevo_nombre"; then
                    msg_err "El grupo ya existe."
                else
                    if groupmod -n "$nuevo_nombre" "$grupo"; then
                        msg_ok "Grupo renombrado correctamente."
                        grupo="$nuevo_nombre"
                    else
                        msg_err "Error al renombrar grupo."
                    fi
                fi
                pausar
                ;;
            2)
                usuario=$(seleccionar_usuario "Selecciona el usuario a AGREGAR al grupo:")
                [[ -z "$usuario" ]] && { pausar; continue; }

                if gpasswd -a "$usuario" "$grupo"; then
                    msg_ok "Usuario agregado correctamente."
                else
                    msg_err "Error al agregar usuario."
                fi
                pausar
                ;;
            3)
                usuario=$(seleccionar_usuario "Selecciona el usuario a QUITAR del grupo:")
                [[ -z "$usuario" ]] && { pausar; continue; }

                if gpasswd -d "$usuario" "$grupo"; then
                    msg_ok "Usuario eliminado del grupo."
                else
                    msg_err "Error al quitar usuario."
                fi
                pausar
                ;;
            4)
                lista=$(input_campo "Nueva lista de usuarios (user1,user2):")
                [[ -z "$lista" ]] && { pausar; continue; }

                if gpasswd -M "$lista" "$grupo"; then
                    msg_ok "Miembros actualizados."
                else
                    msg_err "Error al actualizar miembros."
                fi
                pausar
                ;;
            0) return ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}