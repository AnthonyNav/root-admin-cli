#!/usr/bin/env bash
#
# src/lib/utils.sh — Helpers compartidos del proyecto
# Plataforma: AlmaLinux 9  |  Bash 5.0+
#
# Autor del módulo: Anthony (PR #1 · feat/utils-lib)
#
# NOTA PARA EL EQUIPO:
#   Este archivo es la RUTA CRÍTICA del proyecto. Los módulos
#   users.sh, groups.sh y processes.sh dependen de las funciones
#   aquí definidas. Por favor finaliza tu implementación antes
#   del lunes por la mañana.
#
# Funciones públicas que DEBES implementar (no cambiar los nombres):
#   print_header <título>
#   msg_ok       <mensaje>
#   msg_err      <mensaje>
#   msg_warn     <mensaje>
#   confirmar_accion <pregunta>  → retorna 0 (sí) o 1 (no)
#   usuario_existe   <nombre>    → retorna 0 (existe) o 1 (no)
#   grupo_existe     <nombre>    → retorna 0 (existe) o 1 (no)
#   pausar                       → espera Enter del usuario
#

# ─── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── print_header <título> ────────────────────────────────────────────────────
# Imprime un encabezado visual con bordes redondeados usando gum style.
# Ejemplo de uso: print_header "Gestión de Usuarios"
print_header() {
    local titulo="$1"
    echo ""
    gum style \
        --border rounded \
        --border-foreground 6 \
        --padding "0 2" \
        --bold \
        --foreground 6 \
        "$titulo"
    echo ""
}

# ─── msg_ok <mensaje> ─────────────────────────────────────────────────────────
# Imprime un mensaje de éxito en verde.
msg_ok() {
    echo -e "${GREEN}[OK]${NC} $1"
}

# ─── msg_err <mensaje> ────────────────────────────────────────────────────────
# Imprime un mensaje de error en rojo (a stderr).
msg_err() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

# ─── msg_warn <mensaje> ───────────────────────────────────────────────────────
# Imprime un aviso en amarillo.
msg_warn() {
    echo -e "${YELLOW}[AVISO]${NC} $1"
}

# ─── confirmar_accion <pregunta> ──────────────────────────────────────────────
# Solicita confirmación al usuario.
confirmar_accion() {
    local pregunta="$1"
    local resp
    read -rp "$pregunta [s/N]: " resp
    [[ "$resp" =~ ^[sS]$ ]]
}

# ─── usuario_existe <nombre_usuario> ─────────────────────────────────────────
# Verifica si un usuario existe en el sistema.
usuario_existe() {
    [[ -z "$1" ]] && return 1
    id "$1" &>/dev/null
}

# ─── grupo_existe <nombre_grupo> ─────────────────────────────────────────────
# Verifica si un grupo existe en el sistema.
grupo_existe() {
    [[ -z "$1" ]] && return 1
    if getent group "$1" &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# ─── pausar ───────────────────────────────────────────────────────────────────
# Pausa la ejecución hasta que el usuario presione Enter.
pausar() {
    echo ""
    read -rp "  Presiona Enter para continuar..."
    echo ""
}

# ─── WHIPTAIL HELPERS (Correcciones PR #1) ────────────────────────────────────

# ─── seleccionar_usuario <titulo> ────────────────────────────────────────────
# Lista usuarios con UID >= 1000 usando gum choose.
# Retorna el nombre seleccionado en stdout. Retorna 1 si cancela o no hay usuarios.
seleccionar_usuario() {
    local titulo="${1:-Selecciona un usuario:}"
    local usuarios

    usuarios=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/passwd)

    if [[ -z "$usuarios" ]]; then
        msg_warn "No hay usuarios disponibles (UID >= 1000)."
        return 1
    fi

    echo "$usuarios" | gum choose --header "$titulo" --cursor "▸ "
}

# ─── seleccionar_grupo <titulo> ──────────────────────────────────────────────
# Lista grupos con GID >= 1000 usando gum choose.
# Retorna el nombre seleccionado en stdout. Retorna 1 si cancela o no hay grupos.
seleccionar_grupo() {
    local titulo="${1:-Selecciona un grupo:}"
    local grupos

    grupos=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1}' /etc/group)

    if [[ -z "$grupos" ]]; then
        msg_warn "No hay grupos disponibles (GID >= 1000)."
        return 1
    fi

    echo "$grupos" | gum choose --header "$titulo" --cursor "▸ "
}

# ─── input_campo <placeholder> ───────────────────────────────────────────────
# Campo de entrada de texto con gum input.
# Retorna el texto ingresado en stdout.
input_campo() {
    gum input --placeholder "$1" --width 60
}

# ─── confirmar_whiptail <pregunta> ───────────────────────────────────────────
# Confirmación visual con gum confirm.
# Retorna 0 si confirma (Yes), 1 si cancela (No).
confirmar_whiptail() {
    gum confirm "$1"
}
