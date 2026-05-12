#!/usr/bin/env bash
#
# tests/test_gum_phase1.sh — Pruebas de Fase 1: migración a gum
# Verifica que utils.sh usa gum, que los módulos cargan y que
# los tests existentes siguen pasando.
# Uso: bash tests/test_gum_phase1.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="$SCRIPT_DIR/tests/report_gum_phase1.txt"
UTILS_FILE="$SCRIPT_DIR/src/lib/utils.sh"

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

PASS=0; FAIL=0; WARN=0; TOTAL=0

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
        echo -e "        patrón prohibido '$pattern' encontrado" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

check_output_contains() {
    local desc="$1" pattern="$2" output="$3"
    ((TOTAL++))
    if echo "$output" | grep -q "$pattern"; then
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
echo "  REPORTE — Fase 1 Migración a gum                     " | tee -a "$REPORT_FILE"
echo "  Fecha: $(date '+%Y-%m-%d %H:%M:%S')                  " | tee -a "$REPORT_FILE"
echo "╚══════════════════════════════════════════════════════╝" | tee -a "$REPORT_FILE"
echo -e "${NC}" | tee -a "$REPORT_FILE"

# ─── SECCIÓN 1: Herramientas instaladas ──────────────────────────────────────
separator "1. Herramientas UI instaladas"

command -v gum &>/dev/null
check "gum está instalado" 0 $?

command -v figlet &>/dev/null
check "figlet está instalado" 0 $?

command -v whiptail &>/dev/null
check "whiptail sigue disponible (compatibilidad)" 0 $?

# ─── SECCIÓN 2: Sintaxis de todos los archivos ───────────────────────────────
separator "2. Sintaxis de todos los archivos"

for archivo in main.sh src/lib/utils.sh src/users.sh src/groups.sh \
               src/processes.sh src/automation.sh src/backup.sh src/security.sh; do
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

# ─── SECCIÓN 3: Source de todos los módulos ──────────────────────────────────
separator "3. Source sin errores de runtime"

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

# ─── SECCIÓN 4: utils.sh usa gum (sin invocar whiptail) ──────────────────────
separator "4. utils.sh migrado a gum"

check_not_contains \
    "utils.sh no invoca whiptail como comando" \
    "whiptail[[:space:]]+--" \
    "$UTILS_FILE"

check_contains \
    "seleccionar_usuario usa gum choose" \
    "gum choose" \
    "$UTILS_FILE"

check_contains \
    "seleccionar_grupo usa gum choose" \
    "gum choose" \
    "$UTILS_FILE"

check_contains \
    "input_campo usa gum input" \
    "gum input" \
    "$UTILS_FILE"

check_contains \
    "confirmar_whiptail usa gum confirm" \
    "gum confirm" \
    "$UTILS_FILE"

check_contains \
    "print_header usa gum style" \
    "gum style" \
    "$UTILS_FILE"

# ─── SECCIÓN 5: confirmar_accion y pausar NO fueron migradas ─────────────────
separator "5. confirmar_accion y pausar sin cambios (backward compat)"

CONFIRMAR_IMPL=$(grep -A5 "^confirmar_accion()" "$UTILS_FILE")
[[ "$CONFIRMAR_IMPL" == *"read -rp"* ]]
check "confirmar_accion sigue usando read -rp" 0 $?

PAUSAR_IMPL=$(grep -A5 "^pausar()" "$UTILS_FILE")
[[ "$PAUSAR_IMPL" == *"read -rp"* ]]
check "pausar sigue usando read -rp" 0 $?

# ─── SECCIÓN 6: main.sh tiene instalar_ui y show_titulo ─────────────────────
separator "6. main.sh actualizado"

check_contains \
    "main.sh tiene instalar_ui()" \
    "instalar_ui" \
    "$SCRIPT_DIR/main.sh"

check_contains \
    "main.sh tiene show_titulo()" \
    "show_titulo" \
    "$SCRIPT_DIR/main.sh"

check_contains \
    "main.sh tiene figlet" \
    "figlet" \
    "$SCRIPT_DIR/main.sh"

check_contains \
    "instalar_ui configura el repo de Charm" \
    "charm.sh" \
    "$SCRIPT_DIR/main.sh"

# ─── SECCIÓN 7: Pruebas mock de funciones gum ────────────────────────────────
separator "7. Pruebas mock de funciones gum"

# Mock de gum para pruebas no interactivas
GUM_MOCK='
gum() {
    case "$1" in
        confirm) return 0 ;;
        input)   echo "valor_de_prueba" ;;
        choose)  head -1 ;;
        style)   echo "${@: -1}" ;;
    esac
}
export -f gum
'

# 7.1 confirmar_whiptail retorna 0 con mock (simula Yes)
OUTPUT=$(bash -c "
    $GUM_MOCK
    source '$UTILS_FILE'
    ui_interactiva() { return 0; }
    confirmar_whiptail 'Prueba'
    echo \$?
" 2>/dev/null)
check_output_contains \
    "confirmar_whiptail retorna 0 con gum confirm mock" \
    "^0$" \
    "$OUTPUT"

# 7.2 input_campo retorna el valor del mock
OUTPUT=$(bash -c "
    $GUM_MOCK
    source '$UTILS_FILE'
    ui_interactiva() { return 0; }
    input_campo 'Ingresa algo'
" 2>/dev/null)
check_output_contains \
    "input_campo retorna texto con gum input mock" \
    "valor_de_prueba" \
    "$OUTPUT"

# 7.3 print_header retorna el título con mock
OUTPUT=$(bash -c "
    $GUM_MOCK
    source '$UTILS_FILE'
    ui_interactiva() { return 0; }
    print_header 'Prueba Header'
" 2>/dev/null)
check_output_contains \
    "print_header muestra el título con gum style mock" \
    "Prueba Header" \
    "$OUTPUT"

# 7.4 seleccionar_usuario retorna el primer usuario mock
OUTPUT=$(bash -c "
    $GUM_MOCK
    source '$UTILS_FILE'
    ui_interactiva() { return 0; }
    seleccionar_usuario 'Elige:'
" 2>/dev/null)
[[ -n "$OUTPUT" ]]
check "seleccionar_usuario retorna un valor con gum choose mock" 0 $?

# ─── SECCIÓN 8: Compatibilidad con test_utils.sh existente ──────────────────
separator "8. Compatibilidad con test_utils.sh (debe seguir 16/16)"

((TOTAL++))
UTILS_TEST_OUTPUT=$(bash "$SCRIPT_DIR/tests/test_utils.sh" 2>/dev/null | tail -5)
if echo "$UTILS_TEST_OUTPUT" | grep -q "16 passed"; then
    echo -e "  ${GREEN}PASS${NC}  test_utils.sh sigue en 16 passed, 0 failed" | tee -a "$REPORT_FILE"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  test_utils.sh ya no pasa 16/16" | tee -a "$REPORT_FILE"
    echo "$UTILS_TEST_OUTPUT" | tee -a "$REPORT_FILE"
    ((FAIL++))
fi

# ─── Resultado final ─────────────────────────────────────────────────────────
echo "" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo -e "  Automáticas: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}Fase 1 completada. utils.sh migrado a gum correctamente.${NC}" | tee -a "$REPORT_FILE"
else
    echo -e "  ${RED}${BOLD}Fase 1 tiene $FAIL fallo(s). Revisar antes de continuar.${NC}" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo -e "  Reporte guardado en: tests/report_gum_phase1.txt" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

[[ $FAIL -eq 0 ]]
exit $?
