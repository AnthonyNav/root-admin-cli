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
# Imprime un encabezado visual con separador.
# Ejemplo de uso: print_header "Gestión de Usuarios"
print_header() {
    local titulo="$1"
    echo ""
    echo -e "${CYAN}${BOLD}╔══════════════════════════════════════════╗${NC}"
    echo -e "${CYAN}${BOLD}  $titulo${NC}"
    echo -e "${CYAN}${BOLD}╚══════════════════════════════════════════╝${NC}"
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

# ─── seleccionar_usuario <titulo_ventana> ─────────────────────────────────────
seleccionar_usuario() {
    local lista arr
    # Filtra usuarios con UID >= 1000 y < 65534 (ignora nobody)
    lista=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3}' /etc/passwd)
    
    if [[ -z "$lista" ]]; then
        whiptail --title "Aviso" --msgbox "No hay usuarios disponibles (UID >= 1000)." 8 50
        return 1
    fi
    
    arr=($lista)
    # 3>&1 1>&2 2>&3 intercambia los descriptores para capturar la salida
    whiptail --title "Seleccionar Usuario" --menu "$1" 15 50 8 "${arr[@]}" 3>&1 1>&2 2>&3
}

# ─── seleccionar_grupo <titulo_ventana> ───────────────────────────────────────
seleccionar_grupo() {
    local lista arr
    # Filtra grupos con GID >= 1000 y < 65534
    lista=$(awk -F: '$3 >= 1000 && $3 < 65534 {print $1, $3}' /etc/group)
    
    if [[ -z "$lista" ]]; then
        whiptail --title "Aviso" --msgbox "No hay grupos disponibles (GID >= 1000)." 8 50
        return 1
    fi
    
    arr=($lista)
    whiptail --title "Seleccionar Grupo" --menu "$1" 15 50 8 "${arr[@]}" 3>&1 1>&2 2>&3
}

# ─── input_campo <mensaje> ────────────────────────────────────────────────────
input_campo() {
    whiptail --title "Entrada requerida" --inputbox "$1" 8 50 3>&1 1>&2 2>&3
}

# ─── confirmar_whiptail <pregunta> ────────────────────────────────────────────
confirmar_whiptail() {
    whiptail --title "Confirmación" --yesno "$1" 8 50
}