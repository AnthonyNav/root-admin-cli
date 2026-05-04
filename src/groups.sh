#!/usr/bin/env bash
#
# src/groups.sh — Módulo de gestión de grupos
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: Imanol (PR #4 · feat/groups-module)
#
# Comandos del sistema que necesitarás:
#   groupadd  → crear grupo
#   groupdel  → eliminar grupo
#   groupmod  → modificar grupo (-n renombrar)
#   gpasswd   → agregar/quitar miembros (-a agregar, -d quitar, -M lista completa)
#   getent    → consultar grupo (wrapper en utils: grupo_existe)
#   groups    → listar grupos de un usuario
#
# Nota: utils.sh ya fue cargado por main.sh — puedes usar directamente
#   msg_ok, msg_err, msg_warn, confirmar_accion, grupo_existe, pausar
#
# ─── menu_grupos ─────────────────────────────────────────────────────────────
# Muestra el submenú de grupos. Llamado desde main.sh.
menu_grupos() {
    local opcion

    while true; do
        clear
        print_header "Gestión de Grupos"
        echo "  1) Alta de grupo"
        echo "  2) Baja de grupo"
        echo "  3) Consulta de grupo"
        echo "  4) Modificaciones de grupo"
        echo ""
        echo "  0) Volver al menú principal"
        echo ""
        read -rp "  Selecciona una opción: " opcion
        echo ""

        case $opcion in
            1) grupo_alta     ;;
            2) grupo_baja     ;;
            3) grupo_consulta ;;
            4) grupo_modificar ;;
            0) return          ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}

# ─── grupo_alta ───────────────────────────────────────────────────────────────
# Da de alta un nuevo grupo en el sistema.
# TODO: implementar
#
# Flujo sugerido:
#   1. Solicitar nombre del grupo
#   2. Verificar que NO existe ya (usar grupo_existe)
#   3. Ejecutar groupadd
#   4. Preguntar si se quieren agregar miembros iniciales (gpasswd -M)
#   5. Confirmar con msg_ok
grupo_alta() {
    print_header "Alta de Grupo"

    local grupo lista

    read -rp "Nombre del nuevo grupo: " grupo

    # Validar vacío
    if [[ -z "$grupo" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    # Verificar si ya existe
    if grupo_existe "$grupo"; then
        msg_err "El grupo '$grupo' ya existe."
        pausar
        return
    fi

    # Confirmar acción
    if ! confirmar_accion "¿Deseas crear el grupo '$grupo'?"; then
        msg_warn "Operación cancelada."
        pausar
        return
    fi

    # Crear grupo
    if groupadd "$grupo"; then
        msg_ok "Grupo '$grupo' creado correctamente."

        # Miembros iniciales
        if confirmar_accion "¿Deseas agregar miembros iniciales?"; then
            read -rp "Lista de usuarios (user1,user2): " lista

            if [[ -z "$lista" ]]; then
                msg_err "Lista inválida."
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
# Elimina un grupo del sistema.
# TODO: implementar
#
# Flujo sugerido:
#   1. Solicitar nombre del grupo
#   2. Verificar que SÍ existe (usar grupo_existe)
#   3. Confirmar la acción con confirmar_accion
#   4. Ejecutar groupdel
#   Nota: no se puede eliminar un grupo que es el grupo primario de algún usuario
grupo_baja() {
    print_header "Baja de Grupo"

    local grupo status

    read -rp "Nombre del grupo a eliminar: " grupo

    if [[ -z "$grupo" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    if ! grupo_existe "$grupo"; then
        msg_err "El grupo '$grupo' no existe."
        pausar
        return
    fi

    if ! confirmar_accion "¿Deseas eliminar el grupo '$grupo'?"; then
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
# Muestra información de un grupo si existe.
# TODO: implementar
#
# Información a mostrar:
#   - GID del grupo (comando: getent group <grupo>)
#   - Lista de miembros (comando: getent group <grupo> | cut -d: -f4)
#   - Si el grupo está vacío, indicarlo claramente
grupo_consulta() {
    print_header "Consulta de Grupo"

    local grupo
    local info
    local gid
    local miembros

    read -rp "Nombre del grupo: " grupo

    # Validar entrada vacía
    if [[ -z "$grupo" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    # Verificar si el grupo existe
    if ! grupo_existe "$grupo"; then
        msg_err "El grupo '$grupo' no existe."
        pausar
        return
    fi

    # Obtener información del grupo
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
# Submenú para modificar atributos de un grupo existente.
# TODO: implementar
#
# Opciones del submenú:
#   a) Renombrar grupo            → groupmod -n <nuevo_nombre> <grupo>
#   b) Agregar miembro al grupo   → gpasswd -a <usuario> <grupo>
#   c) Quitar miembro del grupo   → gpasswd -d <usuario> <grupo>
#   d) Reemplazar lista completa  → gpasswd -M user1,user2 <grupo>
grupo_modificar() {
    local grupo opcion usuario nuevo_nombre lista

    print_header "Modificaciones de Grupo"

    read -rp "Nombre del grupo: " grupo

    # Validaciones
    if [[ -z "$grupo" ]]; then
        msg_err "El nombre no puede estar vacío."
        pausar
        return
    fi

    if ! grupo_existe "$grupo"; then
        msg_err "El grupo '$grupo' no existe."
        pausar
        return
    fi

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
                read -rp "Nuevo nombre: " nuevo_nombre

                if [[ -z "$nuevo_nombre" ]]; then
                    msg_err "Nombre inválido."
                elif grupo_existe "$nuevo_nombre"; then
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
                read -rp "Usuario a agregar: " usuario

                if [[ -z "$usuario" ]]; then
                    msg_err "Usuario inválido."
                elif ! usuario_existe "$usuario"; then
                    msg_err "El usuario '$usuario' no existe en el sistema."
                else
                    if gpasswd -a "$usuario" "$grupo"; then
                        msg_ok "Usuario agregado correctamente."
                    else
                        msg_err "Error al agregar usuario."
                    fi
                fi
                pausar
                ;;
            3)
                read -rp "Usuario a quitar: " usuario

                if [[ -z "$usuario" ]]; then
                    msg_err "Usuario inválido."
                elif ! usuario_existe "$usuario"; then
                    msg_err "El usuario '$usuario' no existe en el sistema."
                else
                    if gpasswd -d "$usuario" "$grupo"; then
                        msg_ok "Usuario eliminado del grupo."
                    else
                        msg_err "Error al quitar usuario."
                    fi
                fi
                pausar
                ;;
            4)
                read -rp "Lista de usuarios (user1,user2): " lista

                if [[ -z "$lista" ]]; then
                    msg_err "Lista inválida."
                else
                    if gpasswd -M "$lista" "$grupo"; then
                        msg_ok "Miembros actualizados."
                    else
                        msg_err "Error al actualizar miembros."
                    fi
                fi
                pausar
                ;;
            0)
                return
                ;;
            *)
                msg_warn "Opción inválida."
                pausar
                ;;
        esac
    done
}
