#!/usr/bin/env bash
# src/users.sh - Modulo de gestion de usuarios
# Rama: feat/part1-corrections

# -----------------------------------------------------------------------------
# Fallbacks por si el archivo se prueba de forma aislada.
# -----------------------------------------------------------------------------
if ! declare -F print_header >/dev/null 2>&1; then
    print_header() {
        echo "========================================"
        echo " $1"
        echo "========================================"
    }
fi
if ! declare -F msg_ok >/dev/null 2>&1; then msg_ok() { echo "[OK] $*"; }; fi
if ! declare -F msg_err >/dev/null 2>&1; then msg_err() { echo "[ERROR] $*"; }; fi
if ! declare -F msg_warn >/dev/null 2>&1; then msg_warn() { echo "[AVISO] $*"; }; fi
if ! declare -F pausar >/dev/null 2>&1; then pausar() { echo ""; read -rp "Presiona Enter para continuar..."; }; fi
if ! declare -F confirmar_accion >/dev/null 2>&1; then confirmar_accion() { local resp; read -rp "$1 [s/N]: " resp; [[ "$resp" =~ ^[sS]$ ]]; }; fi
if ! declare -F usuario_existe >/dev/null 2>&1; then usuario_existe() { getent passwd "$1" >/dev/null 2>&1; }; fi

# Fallbacks de whiptail aislados
if ! declare -F seleccionar_usuario >/dev/null 2>&1; then seleccionar_usuario() { read -rp "$1 " usr; echo "$usr"; }; fi
if ! declare -F input_campo >/dev/null 2>&1; then input_campo() { read -rp "$1 " input; echo "$input"; }; fi
if ! declare -F confirmar_whiptail >/dev/null 2>&1; then confirmar_whiptail() { confirmar_accion "$1"; }; fi

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
    if [[ "$fecha" == "-1" ]]; then return 0; fi
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
        if ! confirmar_whiptail "Deseas usarla de todos modos?"; then
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
        opcion=$(whiptail --title "Gestión de Usuarios" \
            --menu "Selecciona una opción:" 16 60 5 \
            "1" "Alta de usuario" \
            "2" "Baja de usuario" \
            "3" "Consulta de usuario" \
            "4" "Modificaciones de usuario" \
            "0" "Volver al menú principal" \
            3>&1 1>&2 2>&3)

        [[ -z "$opcion" || "$opcion" == "0" ]] && return

        case "$opcion" in
            1) usuario_alta ;;
            2) usuario_baja ;;
            3) usuario_consulta ;;
            4) usuario_modificar ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}
# -----------------------------------------------------------------------------
# usuario_alta
# -----------------------------------------------------------------------------
usuario_alta() {
    local usuario

    clear
    print_header "Alta de Usuario"

    asegurar_root || { pausar; return 1; }
    comando_requerido useradd || { pausar; return 1; }
    comando_requerido passwd || { pausar; return 1; }

    usuario=$(input_campo "Nombre del nuevo usuario:")
    [[ -z "$usuario" ]] && return 0 # Usuario canceló o dejó en blanco

    if ! validar_nombre_usuario "$usuario"; then
        pausar
        return 1
    fi

    if usuario_existe "$usuario"; then
        msg_err "El usuario '$usuario' ya existe."
        pausar
        return 1
    fi

    if ! confirmar_whiptail "¿Deseas crear el usuario '$usuario'?"; then
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
        fi
        pausar
        return 1
    fi

    pausar
}

# -----------------------------------------------------------------------------
# usuario_baja
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

    usuario=$(seleccionar_usuario "Selecciona el usuario a eliminar:")
    [[ -z "$usuario" ]] && return 0

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

    if confirmar_whiptail "¿Deseas eliminar también el directorio home de '$usuario'?"; then
        eliminar_home="si"
    fi

    msg_warn "Esta accion eliminara el usuario '$usuario'."
    if [[ "$eliminar_home" == "si" ]]; then
        msg_warn "Tambien se eliminara su directorio home."
    else
        msg_warn "No se eliminara su directorio home."
    fi

    if ! confirmar_whiptail "¿Confirmas la eliminación del usuario '$usuario'?"; then
        msg_warn "Operacion cancelada."
        pausar
        return 0
    fi

    if [[ "$eliminar_home" == "si" ]]; then
        err=$(userdel -r "$usuario" 2>&1)
        status=$?
    else
        err=$(userdel "$usuario" 2>&1)
        status=$?
    fi

    if [[ $status -ne 0 ]]; then
        msg_err "No se pudo eliminar el usuario: $err"
        pausar
        return 1
    fi

    msg_ok "Usuario '$usuario' eliminado exitosamente."
    pausar
}

# -----------------------------------------------------------------------------
# usuario_consulta
# -----------------------------------------------------------------------------
usuario_consulta() {
    local usuario
    local passwd_info
    local uid gid home_dir shell_usuario

    clear
    print_header "Consulta de Usuario"

    comando_requerido id || { pausar; return 1; }
    comando_requerido getent || { pausar; return 1; }
    comando_requerido chage || { pausar; return 1; }

    usuario=$(seleccionar_usuario "Selecciona el usuario a consultar:")
    [[ -z "$usuario" ]] && return 0

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
# -----------------------------------------------------------------------------
usuario_modificar() {
    local usuario opcion nueva_shell nuevo_home comentario fecha

    clear
    print_header "Modificaciones de Usuario"

    asegurar_root || { pausar; return 1; }
    comando_requerido usermod || { pausar; return 1; }

    usuario=$(seleccionar_usuario "Selecciona el usuario a modificar:")
    [[ -z "$usuario" ]] && return 0

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
                fecha=$(input_campo "Nueva fecha de caducidad YYYY-MM-DD, o -1 para quitar caducidad:")
                [[ -z "$fecha" ]] && { pausar; continue; }

                if validar_fecha_caducidad "$fecha"; then
                    if chage -E "$fecha" "$usuario"; then
                        msg_ok "Fecha de caducidad actualizada para '$usuario'."
                    else
                        msg_err "No se pudo actualizar la fecha de caducidad."
                    fi
                fi
                pausar
                ;;
            2)
                nuevo_home=$(input_campo "Nuevo directorio home (Ejemplo: /home/$usuario):")
                [[ -z "$nuevo_home" ]] && { pausar; continue; }

                if [[ "$nuevo_home" != /* ]]; then
                    msg_err "Debes escribir una ruta absoluta. Ejemplo: /home/$usuario"
                elif [[ "$nuevo_home" == "/" ]]; then
                    msg_err "No puedes usar / como directorio home."
                else
                    if confirmar_whiptail "¿Mover contenido actual al nuevo home?"; then
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
                if confirmar_whiptail "¿Deseas bloquear la cuenta '$usuario'?"; then
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
                if confirmar_whiptail "¿Deseas desbloquear la cuenta '$usuario'?"; then
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
                nueva_shell=$(input_campo "Nueva shell absoluta (Ej: /bin/bash):")
                [[ -z "$nueva_shell" ]] && { pausar; continue; }

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
                comentario=$(input_campo "Nuevo comentario / nombre completo:")
                [[ -z "$comentario" ]] && { pausar; continue; }

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
                if confirmar_whiptail "¿Forzar cambio de contrasena para '$usuario' en el proximo inicio?"; then
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
            0) return ;;
            *) msg_warn "Opcion invalida."; pausar ;;
        esac
    done
}