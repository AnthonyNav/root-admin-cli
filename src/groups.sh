#!/usr/bin/env bash
#
# src/groups.sh — Módulo de gestión de grupos
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: [Nombre] (PR #4 · feat/groups-module)
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
    msg_warn "TODO: función grupo_alta no implementada aún."
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
    msg_warn "TODO: función grupo_baja no implementada aún."
    pausar
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
    msg_warn "TODO: función grupo_consulta no implementada aún."
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
    print_header "Modificaciones de Grupo"
    msg_warn "TODO: función grupo_modificar no implementada aún."
    pausar
}