#!/usr/bin/env bash
#
# tests/test_gum_phase3.sh — Pruebas de Fase 3: migración de menús y inputs
# Verifica que automation.sh, backup.sh y security.sh usan gum.
# Uso: bash tests/test_gum_phase3.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="$SCRIPT_DIR/tests/report_gum_phase3.txt"

RED='\033[0;31m'
GREEN='\033[0;32m'
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
        echo -e "        patrón '$pattern' no encontrado" | tee -a "$REPORT_FILE"
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
        echo -e "        patrón '$pattern' aún presente" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

check_count() {
    local desc="$1" expected="$2" actual="$3"
    ((TOTAL++))
    if [[ "$actual" -eq "$expected" ]]; then
        echo -e "  ${GREEN}PASS${NC}  $desc (count: $actual)" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc" | tee -a "$REPORT_FILE"
        echo -e "        esperado: $expected  |  obtenido: $actual" | tee -a "$REPORT_FILE"
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
echo "  REPORTE — Fase 3 Migración a gum                     " | tee -a "$REPORT_FILE"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')                  " | tee -a "$REPORT_FILE"
echo "╚══════════════════════════════════════════════════════╝" | tee -a "$REPORT_FILE"
echo -e "${NC}" | tee -a "$REPORT_FILE"

separator "1. Sintaxis de archivos migrados"
for f in src/automation.sh src/backup.sh src/security.sh; do
    ((TOTAL++))
    if bash -n "$SCRIPT_DIR/$f" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}  bash -n $f" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  Errores en $f" | tee -a "$REPORT_FILE"
        bash -n "$SCRIPT_DIR/$f" 2>&1 | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
done

separator "2. Source de todos los módulos"
OUTPUT=$(bash -c "
    source '$SCRIPT_DIR/src/lib/utils.sh'
    source '$SCRIPT_DIR/src/users.sh'
    source '$SCRIPT_DIR/src/groups.sh'
    source '$SCRIPT_DIR/src/processes.sh'
    source '$SCRIPT_DIR/src/automation.sh'
    source '$SCRIPT_DIR/src/backup.sh'
    source '$SCRIPT_DIR/src/security.sh'
    echo 'OK'
" 2>&1)
[[ "$OUTPUT" == *"OK"* ]]
check "todos los módulos cargan sin errores" 0 $?

separator "3. automation.sh — migración completa"
check_not_contains \
    "sin echo numerado en menu" \
    'echo.*[[:space:]][0-9]\)' \
    "$SCRIPT_DIR/src/automation.sh"
check_not_contains \
    "sin read -rp en menu principal" \
    'read -rp.*opcion' \
    "$SCRIPT_DIR/src/automation.sh"
COUNT=$(grep -c "gum choose" "$SCRIPT_DIR/src/automation.sh" 2>/dev/null || true)
check_count "1 menú gum choose en automation.sh" 1 "$COUNT"

separator "4. backup.sh — migración completa"
check_not_contains \
    "sin echo numerado en menu" \
    'echo.*[[:space:]][0-9]\)' \
    "$SCRIPT_DIR/src/backup.sh"
COUNT=$(grep -c "read -rp" "$SCRIPT_DIR/src/backup.sh" 2>/dev/null || true)
check_count "0 read -rp restantes en backup.sh" 0 "$COUNT"
COUNT=$(grep -c "gum choose" "$SCRIPT_DIR/src/backup.sh" 2>/dev/null || true)
check_count "1 menú gum choose en backup.sh" 1 "$COUNT"
COUNT=$(grep -c "input_campo" "$SCRIPT_DIR/src/backup.sh" 2>/dev/null || true)
check_count "4 input_campo en backup.sh (origen+destino × 2 func)" 4 "$COUNT"

separator "5. security.sh — migración completa"
check_not_contains \
    "sin echo numerado en menus" \
    'echo.*[[:space:]][0-9]\)' \
    "$SCRIPT_DIR/src/security.sh"
COUNT=$(grep -c "read -rp" "$SCRIPT_DIR/src/security.sh" 2>/dev/null || true)
check_count "0 read -rp restantes en security.sh" 0 "$COUNT"
COUNT=$(grep -c "gum choose" "$SCRIPT_DIR/src/security.sh" 2>/dev/null || true)
check_count "3 menús gum choose en security.sh" 3 "$COUNT"
COUNT=$(grep -c "input_campo" "$SCRIPT_DIR/src/security.sh" 2>/dev/null || true)
check_count "1 input_campo en security.sh (objetivo nmap)" 1 "$COUNT"

separator "6. Inventario global — sin whiptail ni read -rp en módulos"
ARCHIVOS="src/automation.sh src/backup.sh src/security.sh \
          src/users.sh src/groups.sh src/processes.sh main.sh"
for f in $ARCHIVOS; do
    COUNT=$(grep -cE "whiptail[[:space:]]+--" "$SCRIPT_DIR/$f" 2>/dev/null || true)
    check_count "$f sin comando whiptail" 0 "$COUNT"
done

separator "7. deps.txt actualizado"
check_contains \
    "figlet en deps.txt" \
    "figlet" \
    "$SCRIPT_DIR/deps.txt"

separator "8. Compatibilidad con suites existentes"
((TOTAL++))
OUT=$(bash "$SCRIPT_DIR/tests/test_gum_phase1.sh" 2>/dev/null | grep "passed")
if echo "$OUT" | grep -q "29 passed"; then
    echo -e "  ${GREEN}PASS${NC}  test_gum_phase1.sh sigue en 29 passed" | tee -a "$REPORT_FILE"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  test_gum_phase1.sh rompió: $OUT" | tee -a "$REPORT_FILE"
    ((FAIL++))
fi

echo "" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo -e "  ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}Fase 3 completada. Migración a gum finalizada.${NC}" | tee -a "$REPORT_FILE"
else
    echo -e "  ${RED}${BOLD}Fase 3 tiene $FAIL fallo(s).${NC}" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo -e "  Reporte guardado en: tests/report_gum_phase3.txt" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

[[ $FAIL -eq 0 ]]
exit $?
