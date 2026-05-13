#!/usr/bin/env bash
#
# setup.sh - Environment validation script.
# Target platform: AlmaLinux 9.
#
# Usage:
#   bash setup.sh
#   sudo bash setup.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEPS_FILE="$SCRIPT_DIR/deps.txt"

# Map required commands to the package that usually provides them.
declare -A CMD_PKG=(
    [useradd]="shadow-utils"
    [userdel]="shadow-utils"
    [usermod]="shadow-utils"
    [groupadd]="shadow-utils"
    [groupdel]="shadow-utils"
    [chage]="shadow-utils"
    [passwd]="shadow-utils"
    [ps]="procps-ng"
    [id]="coreutils"
    [getent]="glibc-common"
)

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

ok()   { echo -e "${GREEN}[OK]${NC}    $1"; }
err()  { echo -e "${RED}[ERROR]${NC} $1"; }
warn() { echo -e "${YELLOW}[AVISO]${NC} $1"; }

ERRORS=0
MISSING_PKGS=()

echo ""
echo -e "${CYAN}=== Verificación de entorno — Admin de Redes ===${NC}"
echo ""

# Check the operating system first.
echo "--- Sistema operativo ---"
if [[ -f /etc/almalinux-release ]]; then
    ALMA_VER=$(cat /etc/almalinux-release)
    ok "AlmaLinux detectado: $ALMA_VER"
    if [[ "$ALMA_VER" != *"9."* ]]; then
        warn "Se recomienda AlmaLinux 9.x. Versión actual: $ALMA_VER"
    fi
else
    warn "No se detectó AlmaLinux. Este proyecto está certificado para AlmaLinux 9."
    warn "En otras distribuciones puede funcionar pero no está garantizado."
fi
echo ""

# Validate the available Bash version.
echo "--- Shell ---"
BASH_MAJOR="${BASH_VERSINFO[0]}"
BASH_MINOR="${BASH_VERSINFO[1]}"
if (( BASH_MAJOR >= 5 )); then
    ok "Bash ${BASH_MAJOR}.${BASH_MINOR}"
else
    err "Se requiere Bash 5.x. Versión actual: ${BASH_MAJOR}.${BASH_MINOR}"
    ((ERRORS++))
fi
echo ""

# Validate the commands expected by the project.
echo "--- Comandos requeridos ---"
for cmd in "${!CMD_PKG[@]}"; do
    if command -v "$cmd" &>/dev/null; then
        ok "$cmd  →  $(command -v "$cmd")"
    else
        err "$cmd no encontrado  (paquete: ${CMD_PKG[$cmd]})"
        MISSING_PKGS+=("${CMD_PKG[$cmd]}")
        ((ERRORS++))
    fi
done
echo ""

# Print the final result and offer package installation if needed.
if (( ERRORS == 0 )); then
    ok "Entorno listo. Ejecuta: sudo bash main.sh"
    echo ""
    exit 0
fi

err "$ERRORS problema(s) encontrado(s)."
echo ""

# Remove duplicates before printing or installing package names.
UNIQUE_PKGS=($(printf '%s\n' "${MISSING_PKGS[@]}" | sort -u))

if [[ $EUID -eq 0 ]]; then
    warn "¿Deseas instalar los paquetes faltantes ahora? [s/N]"
    read -r resp
    if [[ "$resp" =~ ^[sS]$ ]]; then
        dnf install -y "${UNIQUE_PKGS[@]}"
        ok "Instalación completada. Vuelve a ejecutar setup.sh para verificar."
    fi
else
    warn "Para instalar los paquetes faltantes, ejecuta:"
    echo "    sudo dnf install ${UNIQUE_PKGS[*]}"
fi

echo ""
exit 1
