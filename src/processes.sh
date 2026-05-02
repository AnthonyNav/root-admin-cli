#!/usr/bin/env bash
#
# src/processes.sh — Módulo de visualización de procesos por usuario
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: [Nombre] (PR #5 · feat/processes-module)
#
# Comandos del sistema que necesitarás:
#   ps     → listar procesos  (ps aux --user <usuario>  o  ps -u <usuario>)
#   top    → monitor en vivo  (top -u <usuario>  — presionar q para salir)
#   pgrep  → buscar por nombre (opcional, para enriquecer la salida)
#
# Nota: utils.sh ya fue cargado por main.sh — puedes usar directamente
#   msg_ok, msg_err, msg_warn, confirmar_accion, usuario_existe, pausar
#

# ─── menu_procesos ────────────────────────────────────────────────────────────
# Muestra el submenú de procesos. Llamado desde main.sh.
menu_procesos() {
    local opcion

    while true; do
        clear
        print_header "Procesos por Usuario"
        echo "  1) Ver procesos del usuario (snapshot)"
        echo "  2) Monitor en tiempo real (top)"
        echo ""
        echo "  0) Volver al menú principal"
        echo ""
        read -rp "  Selecciona una opción: " opcion
        echo ""

        case $opcion in
            1) procesos_snapshot ;;
            2) procesos_monitor  ;;
            0) return            ;;
            *) msg_warn "Opción inválida."; pausar ;;
        esac
    done
}

# ─── procesos_snapshot ───────────────────────────────────────────────────────
# Muestra una foto instantánea de los procesos de un usuario específico.
# TODO: implementar
#
# Flujo sugerido:
#   1. Solicitar nombre de usuario
#   2. Verificar que SÍ existe (usar usuario_existe)
#   3. Verificar que el usuario tiene procesos activos
#   4. Ejecutar: ps aux --user <usuario>
#   5. Mostrar número de procesos encontrados
#   6. Si no hay procesos, indicarlo claramente con msg_warn
procesos_snapshot() {
    print_header "Procesos del Usuario (snapshot)"
    msg_warn "TODO: función procesos_snapshot no implementada aún."
    pausar
}

# ─── procesos_monitor ────────────────────────────────────────────────────────
# Abre top filtrado por usuario para monitoreo en tiempo real.
# TODO: implementar
#
# Flujo sugerido:
#   1. Solicitar nombre de usuario
#   2. Verificar que SÍ existe (usar usuario_existe)
#   3. Advertir al usuario que presione 'q' para salir de top
#   4. Ejecutar: top -u <usuario>
procesos_monitor() {
    print_header "Monitor en Tiempo Real"
    msg_warn "TODO: función procesos_monitor no implementada aún."
    pausar
}