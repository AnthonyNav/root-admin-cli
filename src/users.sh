#!/usr/bin/env bash
#
# src/users.sh — Módulo de gestión de usuarios
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: [Nombre] (PR #3 · feat/users-module)
#
# Comandos del sistema que necesitarás:
#   useradd  → crear usuario
#   userdel  → eliminar usuario
#   usermod  → modificar usuario (-d home, -L lock, -U unlock, -e expiración)
#   chage    → gestionar caducidad de contraseña (-l listar, -E fecha expiración)
#   passwd   → cambiar contraseña
#   id       → información del usuario (wrapper en utils: usuario_existe)
#
# Nota: utils.sh ya fue cargado por main.sh — puedes usar directamente
#   msg_ok, msg_err, msg_warn, confirmar_accion, usuario_existe, pausar
#

# ─── menu_usuarios ────────────────────────────────────────────────────────────
# Muestra el submenú de usuarios. Llamado desde main.sh.
menu_usuarios() {
    local opcion

    while true; do
        clear
        print_header "Gestión de Usuarios"
        echo "  1) Alta de usuario"
        echo "  2) Baja de usuario"
        echo "  3) Consulta de usuario"
        echo "  4) Modificaciones de usuario"
        echo ""
        echo "  0) Volver al menú principal"
        echo ""
        read -rp "  Selecciona una opción: " opcion
        echo ""

        case $opcion in
            1) usuario_alta     ;;
            2) usuario_baja     ;;
            3) usuario_consulta ;;
            4) usuario_modificar ;;
            0) return           ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}

# ─── usuario_alta ─────────────────────────────────────────────────────────────
# Da de alta un nuevo usuario en el sistema.
# TODO: implementar
#
# Flujo sugerido:
#   1. Solicitar nombre de usuario
#   2. Verificar que NO existe ya (usar usuario_existe)
#   3. Solicitar contraseña
#   4. Ejecutar useradd (con home directory y shell /bin/bash)
#   5. Asignar contraseña con passwd o chpasswd
#   6. Confirmar con msg_ok
usuario_alta() {
    print_header "Alta de Usuario"
    msg_warn "TODO: función usuario_alta no implementada aún."
    pausar
}

# ─── usuario_baja ─────────────────────────────────────────────────────────────
# Elimina un usuario del sistema.
# TODO: implementar
#
# Flujo sugerido:
#   1. Solicitar nombre de usuario
#   2. Verificar que SÍ existe (usar usuario_existe)
#   3. Preguntar si se elimina también el directorio home (userdel -r)
#   4. Confirmar la acción con confirmar_accion antes de ejecutar
#   5. Ejecutar userdel o userdel -r
usuario_baja() {
    print_header "Baja de Usuario"
    msg_warn "TODO: función usuario_baja no implementada aún."
    pausar
}

# ─── usuario_consulta ────────────────────────────────────────────────────────
# Muestra información de un usuario si existe, o avisa si no.
# TODO: implementar
#
# Información a mostrar:
#   - UID y GID principal (comando: id)
#   - Grupos secundarios (comando: id -Gn)
#   - Directorio home y shell (comando: getent passwd <usuario>)
#   - Estado de contraseña y caducidad (comando: chage -l)
usuario_consulta() {
    print_header "Consulta de Usuario"
    msg_warn "TODO: función usuario_consulta no implementada aún."
    pausar
}

# ─── usuario_modificar ───────────────────────────────────────────────────────
# Submenú para modificar atributos de un usuario existente.
# TODO: implementar
#
# Opciones del submenú:
#   a) Fecha de caducidad de cuenta    → chage -E YYYY-MM-DD <usuario>
#   b) Cambiar directorio home          → usermod -d /nuevo/home <usuario>
#   c) Bloquear cuenta                  → usermod -L <usuario>
#   d) Desbloquear cuenta               → usermod -U <usuario>
#   e) Cambiar shell                    → usermod -s /bin/bash <usuario>
usuario_modificar() {
    print_header "Modificaciones de Usuario"
    msg_warn "TODO: función usuario_modificar no implementada aún."
    pausar
}