#!/usr/bin/env bash
# src/users.sh - Modulo de gestion de usuarios
# Rama: feat/users-module

# -----------------------------------------------------------------------------
# Fallbacks por si el archivo se prueba de forma aislada.
# Si el proyecto ya define estas funciones en src/lib, no se sobrescriben.
# -----------------------------------------------------------------------------
if ! declare -F print_header >/dev/null 2>&1; then
    print_header() {
        echo "========================================"
        echo " $1"
        echo "========================================"
    }
fi

if ! declare -F msg_ok >/dev/null 2>&1; then
    msg_ok() { echo "[OK] $*"; }
fi

if ! declare -F msg_err >/dev/null 2>&1; then
    msg_err() { echo "[ERROR] $*"; }
fi

if ! declare -F msg_warn >/dev/null 2>&1; then
    msg_warn() { echo "[AVISO] $*"; }
fi

if ! declare -F pausar >/dev/null 2>&1; then
    pausar() {
        echo ""
        read -rp "Presiona Enter para continuar..."
    }
fi

if ! declare -F confirmar_accion >/dev/null 2>&1; then
    confirmar_accion() {
        local pregunta="$1"
        local respuesta

        read -rp "$pregunta [s/N]: " respuesta
        [[ "$respuesta" =~ ^[sS]$ ]]
    }
fi

if ! declare -F usuario_existe >/dev/null 2>&1; then
    usuario_existe() {
        getent passwd "$1" >/dev/null 2>&1
    }
fi

# -----------------------------------------------------------------------------
# Utilidades internas del modulo
# -----------------------------------------------------------------------------
asegurar_root() {
    if [[ "$EUID" -ne 0 ]]; then
        msg_err "Esta opcion debe ejecutarse con permisos de root."
        msg_warn "Ejecuta el programa con: sudo bash main.sh"
        return 1
    fi

    return 0
}

comando_requerido() {
    local comando="$1"

    if ! command -v "$comando" >/dev/null 2>&1; then
        msg_err "El comando '$comando' no esta disponible en este sistema."
        return 1
    fi

    return 0
}

validar_nombre_usuario() {
    local usuario="$1"

    if [[ -z "$usuario" ]]; then
        msg_err "El nombre de usuario no puede estar vacio."
        return 1
    fi

    if (( ${#usuario} > 32 )); then
        msg_err "El nombre de usuario no debe superar 32 caracteres."
        return 1
    fi

    if [[ "$usuario" == "root" ]]; then
        msg_err "No se permite crear, eliminar o modificar el usuario root desde este modulo."
        return 1
    fi

    if [[ "$usuario" =~ [[:space:]] ]]; then
        msg_err "El nombre de usuario no debe contener espacios."
        return 1
    fi

    if [[ ! "$usuario" =~ ^[a-z_][a-z0-9_-]*[$]?$ ]]; then
        msg_err "Nombre de usuario invalido."
        msg_warn "Debe iniciar con letra minuscula o guion bajo."
        msg_warn "Solo puede contener minusculas, numeros, guion y guion bajo."
        return 1
    fi

    return 0
}

uid_de_usuario() {
    id -u "$1" 2>/dev/null
}

es_usuario_sistema() {
    local usuario="$1"
    local uid

    uid="$(uid_de_usuario "$usuario")"
    [[ -n "$uid" && "$uid" -lt 1000 ]]
}

validar_fecha_caducidad() {
    local fecha="$1"

    if [[ "$fecha" == "-1" ]]; then
        return 0
    fi

    if [[ ! "$fecha" =~ ^[0-9]{4}-[0-9]{2}-[0-9]{2}$ ]]; then
        msg_err "Formato invalido. Usa YYYY-MM-DD o -1 para quitar caducidad."
        return 1
    fi

    if ! date -d "$fecha" >/dev/null 2>&1; then
        msg_err "La fecha '$fecha' no es valida."
        return 1
    fi

    return 0
}

validar_shell() {
    local shell_usuario="$1"

    if [[ -z "$shell_usuario" ]]; then
        msg_err "La shell no puede estar vacia."
        return 1
    fi

    if [[ "$shell_usuario" != /* ]]; then
        msg_err "La shell debe ser una ruta absoluta. Ejemplo: /bin/bash"
        return 1
    fi

    if [[ ! -x "$shell_usuario" ]]; then
        msg_err "La shell '$shell_usuario' no existe o no es ejecutable."
        return 1
    fi

    if [[ -f /etc/shells ]] && ! grep -qxF "$shell_usuario" /etc/shells; then
        msg_warn "La shell '$shell_usuario' no aparece en /etc/shells."
        if ! confirmar_accion "Deseas usarla de todos modos?"; then
            return 1
        fi
    fi

    return 0
}

# -----------------------------------------------------------------------------
# menu_usuarios
# -----------------------------------------------------------------------------
menu_usuarios() {
    local opcion

    while true; do
        clear
        print_header "Gestion de Usuarios"

        echo " 1) Alta de usuario"
        echo " 2) Baja de usuario"
        echo " 3) Consulta de usuario"
        echo " 4) Modificaciones de usuario"
        echo ""
        echo " 0) Volver al menu principal"
        echo ""

        read -rp " Selecciona una opcion: " opcion
        echo ""

        case "$opcion" in
            1) usuario_alta ;;
            2) usuario_baja ;;
            3) usuario_consulta ;;
            4) usuario_modificar ;;
            0) return ;;
            *)
                msg_warn "Opcion invalida."
                pausar
                ;;
        esac
    done
}

# -----------------------------------------------------------------------------
# usuario_alta
# Crea un usuario usando useradd y asigna contrasena con passwd.
# -----------------------------------------------------------------------------
usuario_alta() {
    local usuario

    clear
    print_header "Alta de Usuario"

    asegurar_root || { pausar; return 1; }
    comando_requerido useradd || { pausar; return 1; }
    comando_requerido passwd || { pausar; return 1; }

    read -rp " Nombre del nuevo usuario: " usuario

    if ! validar_nombre_usuario "$usuario"; then
        pausar
        return 1
    fi

    if usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' ya existe."
        pausar
        return 1
    fi

    if ! confirmar_accion "Deseas crear el usuario '$usuario'?"; then
        msg_warn "Operacion cancelada."
        pausar
        return 0
    fi

    if ! useradd -m -s /bin/bash "$usuario"; then
        msg_err "No se pudo crear el usuario '$usuario'."
        pausar
        return 1
    fi

    msg_warn "Usuario creado. Ahora asigna una contrasena para '$usuario'."

    if passwd "$usuario"; then
        msg_ok "Usuario '$usuario' creado correctamente."
        id "$usuario"
    else
        msg_err "Usuario creado pero fallo al asignar contrasena."
        msg_warn "Se intentara eliminar el usuario para no dejarlo incompleto."

        if userdel -r "$usuario" >/dev/null 2>&1; then
            msg_ok "Usuario '$usuario' eliminado correctamente despues del fallo."
        else
            msg_err "No se pudo eliminar automaticamente el usuario '$usuario'."
            msg_warn "Puedes eliminarlo manualmente con: sudo userdel -r $usuario"
        fi

        pausar
        return 1
    fi

    pausar
}

# -----------------------------------------------------------------------------
# usuario_baja
# Elimina un usuario usando userdel o userdel -r.
# -----------------------------------------------------------------------------
usuario_baja() {
    local usuario
    local eliminar_home="no"
    local err
    local status

    clear
    print_header "Baja de Usuario"

    asegurar_root || { pausar; return 1; }
    comando_requerido userdel || { pausar; return 1; }

    read -rp " Nombre del usuario a eliminar: " usuario

    if ! validar_nombre_usuario "$usuario"; then
        pausar
        return 1
    fi

    if ! usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' no existe."
        pausar
        return 1
    fi

    if es_usuario_sistema "$usuario"; then
        msg_err "No se permite eliminar usuarios del sistema con UID menor a 1000."
        pausar
        return 1
    fi

    if [[ -n "${SUDO_USER:-}" && "$usuario" == "$SUDO_USER" ]]; then
        msg_err "No se recomienda eliminar el usuario que ejecuto sudo: '$SUDO_USER'."
        pausar
        return 1
    fi

    if command -v pgrep >/dev/null 2>&1 && pgrep -u "$usuario" >/dev/null 2>&1; then
        msg_warn "El usuario '$usuario' tiene procesos en ejecucion. userdel puede fallar."
    fi

    if confirmar_accion "Deseas eliminar tambien el directorio home de '$usuario'?"; then
        eliminar_home="si"
    fi

    msg_warn "Esta accion eliminara el usuario '$usuario'."

    if [[ "$eliminar_home" == "si" ]]; then
        msg_warn "Tambien se eliminara su directorio home."
    else
        msg_warn "No se eliminara su directorio home."
    fi

    if ! confirmar_accion "Confirmas la eliminacion del usuario '$usuario'?"; then
        msg_warn "Operacion cancelada."
        pausar
        return 0
    fi

    if [[ "$eliminar_home" == "si" ]]; then
        err=$(userdel -r "$usuario" 2>&1)
        status=$?

        if [[ $status -ne 0 ]]; then
            msg_err "No se pudo eliminar el usuario: $err"
            pausar
            return 1
        fi

        msg_ok "Usuario '$usuario' eliminado junto con su home."
    else
        err=$(userdel "$usuario" 2>&1)
        status=$?

        if [[ $status -ne 0 ]]; then
            msg_err "No se pudo eliminar el usuario: $err"
            pausar
            return 1
        fi

        msg_ok "Usuario '$usuario' eliminado sin borrar su home."
    fi

    pausar
}

# -----------------------------------------------------------------------------
# usuario_consulta
# Consulta informacion de usuario con id, getent, chage y lastlog.
# -----------------------------------------------------------------------------
usuario_consulta() {
    local usuario
    local passwd_info
    local uid
    local gid
    local home_dir
    local shell_usuario

    clear
    print_header "Consulta de Usuario"

    comando_requerido id || { pausar; return 1; }
    comando_requerido getent || { pausar; return 1; }
    comando_requerido chage || { pausar; return 1; }

    read -rp " Nombre del usuario a consultar: " usuario

    if [[ -z "$usuario" ]]; then
        msg_err "El nombre de usuario no puede estar vacio."
        pausar
        return 1
    fi

    if ! usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' no existe."
        pausar
        return 1
    fi

    passwd_info="$(getent passwd "$usuario")"
    uid="$(echo "$passwd_info" | cut -d: -f3)"
    gid="$(echo "$passwd_info" | cut -d: -f4)"
    home_dir="$(echo "$passwd_info" | cut -d: -f6)"
    shell_usuario="$(echo "$passwd_info" | cut -d: -f7)"

    echo "Informacion general:"
    id "$usuario"
    echo ""

    echo "UID: $uid"
    echo "GID: $gid"
    echo "Home: $home_dir"
    echo "Shell: $shell_usuario"
    echo ""

    echo "Grupos:"
    id -Gn "$usuario"
    echo ""

    echo "Registro en /etc/passwd:"
    echo "$passwd_info"
    echo ""

    echo "Informacion de caducidad de contrasena:"
    chage -l "$usuario"
    echo ""

    echo "--- Ultimo login ---"
    lastlog -u "$usuario" 2>/dev/null || echo "(sin informacion de login)"
    echo ""

    pausar
}

# -----------------------------------------------------------------------------
# usuario_modificar
# Submenu de modificacion. Las opciones 1-5 cumplen TASKS.md.
# -----------------------------------------------------------------------------
usuario_modificar() {
    local usuario
    local opcion
    local nueva_shell
    local nuevo_home
    local comentario
    local fecha

    clear
    print_header "Modificaciones de Usuario"

    asegurar_root || { pausar; return 1; }
    comando_requerido usermod || { pausar; return 1; }

    read -rp " Nombre del usuario a modificar: " usuario

    if ! validar_nombre_usuario "$usuario"; then
        pausar
        return 1
    fi

    if ! usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' no existe."
        pausar
        return 1
    fi

    if es_usuario_sistema "$usuario"; then
        msg_err "No se permite modificar usuarios del sistema con UID menor a 1000."
        pausar
        return 1
    fi

    while true; do
        clear
        print_header "Modificar Usuario: $usuario"

        echo " 1) Cambiar fecha de caducidad de cuenta"
        echo " 2) Cambiar directorio home"
        echo " 3) Bloquear cuenta"
        echo " 4) Desbloquear cuenta"
        echo " 5) Cambiar shell"
        echo " 6) Cambiar contrasena"
        echo " 7) Cambiar comentario / nombre completo"
        echo " 8) Forzar cambio de contrasena en el proximo inicio"
        echo ""
        echo " 0) Volver al menu de usuarios"
        echo ""

        read -rp " Selecciona una opcion: " opcion
        echo ""

        case "$opcion" in
            1)
                comando_requerido chage || { pausar; continue; }

                read -rp " Nueva fecha de caducidad YYYY-MM-DD, o -1 para quitar caducidad: " fecha

                if validar_fecha_caducidad "$fecha"; then
                    if chage -E "$fecha" "$usuario"; then
                        msg_ok "Fecha de caducidad actualizada para '$usuario'."
                        chage -l "$usuario" 2>/dev/null || true
                    else
                        msg_err "No se pudo actualizar la fecha de caducidad."
                    fi
                fi

                pausar
                ;;

            2)
                read -rp " Nuevo directorio home, ejemplo /home/$usuario: " nuevo_home

                if [[ -z "$nuevo_home" ]]; then
                    msg_err "El directorio home no puede estar vacio."
                elif [[ "$nuevo_home" != /* ]]; then
                    msg_err "Debes escribir una ruta absoluta. Ejemplo: /home/$usuario"
                elif [[ "$nuevo_home" == "/" ]]; then
                    msg_err "No puedes usar / como directorio home."
                else
                    if confirmar_accion "Mover contenido actual al nuevo home?"; then
                        if usermod -d "$nuevo_home" -m "$usuario"; then
                            msg_ok "Home cambiado y contenido movido a '$nuevo_home'."
                        else
                            msg_err "No se pudo cambiar el home."
                        fi
                    else
                        if usermod -d "$nuevo_home" "$usuario"; then
                            msg_ok "Home cambiado a '$nuevo_home' sin mover contenido."
                        else
                            msg_err "No se pudo cambiar el home."
                        fi
                    fi
                fi

                pausar
                ;;

            3)
                if confirmar_accion "Deseas bloquear la cuenta '$usuario'?"; then
                    if usermod -L "$usuario"; then
                        msg_ok "Cuenta '$usuario' bloqueada."
                    else
                        msg_err "No se pudo bloquear la cuenta."
                    fi
                else
                    msg_warn "Operacion cancelada."
                fi

                pausar
                ;;

            4)
                if confirmar_accion "Deseas desbloquear la cuenta '$usuario'?"; then
                    if usermod -U "$usuario"; then
                        msg_ok "Cuenta '$usuario' desbloqueada."
                    else
                        msg_err "No se pudo desbloquear la cuenta."
                    fi
                else
                    msg_warn "Operacion cancelada."
                fi

                pausar
                ;;

            5)
                echo "Shells comunes:"
                echo " /bin/bash"
                echo " /bin/sh"
                echo " /usr/sbin/nologin"
                echo ""

                read -rp " Nueva shell: " nueva_shell

                if validar_shell "$nueva_shell"; then
                    if usermod -s "$nueva_shell" "$usuario"; then
                        msg_ok "Shell de '$usuario' cambiada a '$nueva_shell'."
                    else
                        msg_err "No se pudo cambiar la shell."
                    fi
                fi

                pausar
                ;;

            6)
                comando_requerido passwd || { pausar; continue; }

                if passwd "$usuario"; then
                    msg_ok "Contrasena actualizada para '$usuario'."
                else
                    msg_err "No se pudo actualizar la contrasena."
                fi

                pausar
                ;;

            7)
                read -rp " Nuevo comentario / nombre completo: " comentario

                if [[ "$comentario" == *:* ]]; then
                    msg_err "El comentario no debe contener dos puntos (:)."
                elif [[ "$comentario" == *$'\n'* ]]; then
                    msg_err "El comentario no debe contener saltos de linea."
                elif usermod -c "$comentario" "$usuario"; then
                    msg_ok "Comentario actualizado para '$usuario'."
                else
                    msg_err "No se pudo actualizar el comentario."
                fi

                pausar
                ;;

            8)
                comando_requerido chage || { pausar; continue; }

                if confirmar_accion "Forzar cambio de contrasena para '$usuario' en el proximo inicio?"; then
                    if chage -d 0 "$usuario"; then
                        msg_ok "Se forzara cambio de contrasena en el proximo inicio de sesion."
                    else
                        msg_err "No se pudo aplicar el cambio."
                    fi
                else
                    msg_warn "Operacion cancelada."
                fi

                pausar
                ;;

            0)
                return
                ;;

            *)
                msg_warn "Opcion invalida."
                pausar
                ;;
        esac
    done
}
