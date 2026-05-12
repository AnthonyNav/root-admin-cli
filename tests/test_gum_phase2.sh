#!/usr/bin/env bash
#
# tests/test_gum_phase2.sh — Pruebas de Fase 2: menús migrados a gum
# Verifica que los menús usan seleccionar_menu, que ya no se invoca
# whiptail --menu y que existen fallbacks no interactivos para pruebas.
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="$SCRIPT_DIR/tests/report_gum_phase2.txt"
UTILS_FILE="$SCRIPT_DIR/src/lib/utils.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0; FAIL=0; TOTAL=0

check() {
    local desc="$1" expected="$2" actual="$3"
    ((TOTAL++))
    if [[ "$actual" -eq "$expected" ]]; then
        echo -e "  ${GREEN}PASS${NC}  $desc" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc" | tee -a "$REPORT_FILE"
        echo -e "        esperado: $expected  |  obtenido: $actual" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

check_contains() {
    local desc="$1" pattern="$2" file="$3"
    ((TOTAL++))
    if grep -qE "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}  $desc" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc" | tee -a "$REPORT_FILE"
        echo -e "        patrón '$pattern' no encontrado en $file" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

check_not_contains() {
    local desc="$1" pattern="$2" file="$3"
    ((TOTAL++))
    if ! grep -qE "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}  $desc" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc" | tee -a "$REPORT_FILE"
        echo -e "        patrón prohibido '$pattern' encontrado en $file" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

check_output_contains() {
    local desc="$1" pattern="$2" output="$3"
    ((TOTAL++))
    if echo "$output" | grep -qE "$pattern"; then
        echo -e "  ${GREEN}PASS${NC}  $desc" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc" | tee -a "$REPORT_FILE"
        echo -e "        patrón '$pattern' no encontrado en output" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

separator() {
    echo "" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}─── $1 ───────────────────────────────────────────${NC}" | tee -a "$REPORT_FILE"
}

> "$REPORT_FILE"
echo -e "${CYAN}${BOLD}" | tee -a "$REPORT_FILE"
echo "╔══════════════════════════════════════════════════════╗" | tee -a "$REPORT_FILE"
echo "  REPORTE — Fase 2 Migración de menús a gum           " | tee -a "$REPORT_FILE"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')                  " | tee -a "$REPORT_FILE"
echo "╚══════════════════════════════════════════════════════╝" | tee -a "$REPORT_FILE"
echo -e "${NC}" | tee -a "$REPORT_FILE"

separator "1. Sintaxis de archivos"

for archivo in main.sh src/lib/utils.sh src/users.sh src/groups.sh src/processes.sh; do
    ((TOTAL++))
    if bash -n "$SCRIPT_DIR/$archivo" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}  bash -n $archivo" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  Errores en $archivo" | tee -a "$REPORT_FILE"
        bash -n "$SCRIPT_DIR/$archivo" 2>&1 | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
done

separator "2. Carga de módulos"

OUTPUT=$(bash -c "
    source '$SCRIPT_DIR/src/lib/utils.sh'
    source '$SCRIPT_DIR/src/users.sh'
    source '$SCRIPT_DIR/src/groups.sh'
    source '$SCRIPT_DIR/src/processes.sh'
    echo 'OK'
" 2>&1)
[[ "$OUTPUT" == *"OK"* ]]
check "utils.sh, users.sh, groups.sh y processes.sh cargan bien" 0 $?

separator "3. Menús ya no usan whiptail"

check_not_contains \
    "main.sh no invoca whiptail --menu" \
    "whiptail[[:space:]]+--menu" \
    "$SCRIPT_DIR/main.sh"

check_not_contains \
    "users.sh no invoca whiptail --menu" \
    "whiptail[[:space:]]+--menu" \
    "$SCRIPT_DIR/src/users.sh"

check_not_contains \
    "groups.sh no invoca whiptail --menu" \
    "whiptail[[:space:]]+--menu" \
    "$SCRIPT_DIR/src/groups.sh"

check_not_contains \
    "processes.sh no invoca whiptail --menu" \
    "whiptail[[:space:]]+--menu" \
    "$SCRIPT_DIR/src/processes.sh"

separator "4. Menús usan seleccionar_menu"

check_contains \
    "utils.sh declara seleccionar_menu()" \
    "^seleccionar_menu\\(\\)" \
    "$UTILS_FILE"

check_contains \
    "seleccionar_menu usa gum choose" \
    "gum choose" \
    "$UTILS_FILE"

check_contains \
    "main.sh usa seleccionar_menu" \
    "seleccionar_menu" \
    "$SCRIPT_DIR/main.sh"

check_contains \
    "users.sh usa seleccionar_menu" \
    "seleccionar_menu" \
    "$SCRIPT_DIR/src/users.sh"

check_contains \
    "groups.sh usa seleccionar_menu" \
    "seleccionar_menu" \
    "$SCRIPT_DIR/src/groups.sh"

check_contains \
    "processes.sh usa seleccionar_menu" \
    "seleccionar_menu" \
    "$SCRIPT_DIR/src/processes.sh"

separator "5. Fallback no interactivo"

OUTPUT=$(printf '2\n' | bash -c "
    source '$UTILS_FILE'
    seleccionar_menu 'Titulo' 'Elige una opción:' '1' 'Uno' '2' 'Dos' '0' 'Salir'
" 2>/dev/null)
check_output_contains \
    "seleccionar_menu retorna la opción escrita con read" \
    "^2$" \
    "$OUTPUT"

OUTPUT=$(printf 'valor_de_prueba\n' | bash -c "
    source '$UTILS_FILE'
    input_campo 'Ingresa algo:'
" 2>/dev/null)
check_output_contains \
    "input_campo usa fallback con read sin TTY" \
    "^valor_de_prueba$" \
    "$OUTPUT"

OUTPUT=$(printf 's\n' | bash -c "
    source '$UTILS_FILE'
    confirmar_whiptail 'Confirmar'
    echo \$?
" 2>/dev/null)
check_output_contains \
    "confirmar_whiptail usa fallback con confirmar_accion" \
    "^0$" \
    "$OUTPUT"

separator "6. Mock de gum para seleccionar_menu"

GUM_MOCK='
gum() { cat | head -1; }
export -f gum
'

OUTPUT=$(bash -c "
    source '$UTILS_FILE'
    $GUM_MOCK
    ui_interactiva() { return 0; }
    seleccionar_menu 'Titulo' 'Elige una opción:' '1' 'Uno' '2' 'Dos'
" 2>/dev/null)
check_output_contains \
    "seleccionar_menu retorna la primera clave con gum mock" \
    "^1$" \
    "$OUTPUT"

echo "" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo -e "  Automáticas: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

[[ $FAIL -eq 0 ]]
exit $?
