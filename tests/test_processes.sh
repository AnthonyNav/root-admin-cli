#!/usr/bin/env bash
#
# tests/test_processes.sh — Verificación y reporte del PR #5
# Plataforma: AlmaLinux 9 | Bash 5.0+
#
# Uso: sudo bash tests/test_processes.sh
#
# Nota: procesos_monitor no se puede automatizar completamente
# porque top es interactivo. Esa prueba queda marcada como manual.
#

# ─── Configuración ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="$SCRIPT_DIR/tests/report_processes.txt"
PROCESSES_FILE="$SCRIPT_DIR/src/processes.sh"
UTILS_FILE="$SCRIPT_DIR/src/lib/utils.sh"

TEST_USER="pr5_noprocs"

# ─── Colores ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

# ─── Contadores ───────────────────────────────────────────────────────────────
PASS=0
FAIL=0
WARN=0
TOTAL=0

# ─── Framework de pruebas ─────────────────────────────────────────────────────
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
    if grep -q "$pattern" "$file" 2>/dev/null; then
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
    if echo "$output" | grep -q "$pattern" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}  $desc" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc" | tee -a "$REPORT_FILE"
        echo -e "        patrón '$pattern' no encontrado en output" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

warn_manual() {
    local desc="$1"
    ((WARN++))
    echo -e "  ${YELLOW}MANUAL${NC} $desc" | tee -a "$REPORT_FILE"
}

separator() {
    echo "" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}─── $1 ───────────────────────────────────────────${NC}" | tee -a "$REPORT_FILE"
}

# ─── Cleanup ──────────────────────────────────────────────────────────────────
cleanup() {
    userdel "$TEST_USER" 2>/dev/null
}
trap cleanup EXIT

# ─── Inicio del reporte ───────────────────────────────────────────────────────
> "$REPORT_FILE"

echo -e "${CYAN}${BOLD}" | tee -a "$REPORT_FILE"
echo "╔══════════════════════════════════════════════════════╗" | tee -a "$REPORT_FILE"
echo "  REPORTE DE VERIFICACIÓN — PR #5 processes            " | tee -a "$REPORT_FILE"
echo "  Archivo: src/processes.sh                            " | tee -a "$REPORT_FILE"
echo "  Fecha:   $(date '+%Y-%m-%d %H:%M:%S')                " | tee -a "$REPORT_FILE"
echo "╚══════════════════════════════════════════════════════╝" | tee -a "$REPORT_FILE"
echo -e "${NC}" | tee -a "$REPORT_FILE"

# ─── SECCIÓN 1: Prerequisitos ────────────────────────────────────────────────
separator "1. Prerequisitos"

[[ $EUID -eq 0 ]]
check "Ejecutándose como root" 0 $?

[[ -f "$PROCESSES_FILE" ]]
check "src/processes.sh existe" 0 $?

[[ -f "$UTILS_FILE" ]]
check "src/lib/utils.sh existe" 0 $?

if ! source "$UTILS_FILE" 2>/dev/null; then
    echo -e "  ${RED}FATAL${NC}  No se pudo cargar utils.sh — abortando" | tee -a "$REPORT_FILE"
    exit 1
fi

# ─── SECCIÓN 2: Sintaxis ─────────────────────────────────────────────────────
separator "2. Sintaxis"

((TOTAL++))
if bash -n "$PROCESSES_FILE" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  bash -n src/processes.sh sin errores" | tee -a "$REPORT_FILE"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  Errores de sintaxis detectados:" | tee -a "$REPORT_FILE"
    bash -n "$PROCESSES_FILE" 2>&1 | tee -a "$REPORT_FILE"
    ((FAIL++))
fi

# ─── SECCIÓN 3: Funciones declaradas ─────────────────────────────────────────
separator "3. Funciones declaradas"

source "$PROCESSES_FILE" 2>/dev/null

for fn in menu_procesos procesos_snapshot procesos_monitor; do
    declare -f "$fn" > /dev/null 2>&1
    check "función '$fn' está declarada" 0 $?
done

# ─── SECCIÓN 4: Reglas de código ─────────────────────────────────────────────
separator "4. Reglas de código"

check_not_contains \
    "No usa 'exit' dentro del módulo" \
    "^\s*exit" \
    "$PROCESSES_FILE"

check_contains \
    "Usa usuario_existe para validar" \
    "usuario_existe" \
    "$PROCESSES_FILE"

check_contains \
    "Usa ps con --user o -u para filtrar" \
    "ps.*--user\|ps.*-u" \
    "$PROCESSES_FILE"

check_contains \
    "Usa top -u para el monitor" \
    "top -u" \
    "$PROCESSES_FILE"

check_contains \
    "Usa msg_err para errores" \
    "msg_err" \
    "$PROCESSES_FILE"

check_contains \
    "Usa msg_ok para confirmaciones de éxito" \
    "msg_ok" \
    "$PROCESSES_FILE"

check_contains \
    "Usa msg_warn para el aviso de top" \
    "msg_warn.*[Pp]resiona\|msg_warn.*salir" \
    "$PROCESSES_FILE"

check_not_contains \
    "No usa msg_ok para el aviso de top" \
    "msg_ok.*[Pp]resiona\|msg_ok.*salir" \
    "$PROCESSES_FILE"

check_contains \
    "Usa pausar al final de operaciones" \
    "pausar" \
    "$PROCESSES_FILE"

# ─── SECCIÓN 5: Pruebas funcionales — procesos_snapshot ──────────────────────
separator "5. procesos_snapshot — pruebas funcionales"

# Crear usuario de prueba sin procesos
userdel "$TEST_USER" 2>/dev/null
useradd -M -s /sbin/nologin "$TEST_USER" 2>/dev/null
check "Usuario de prueba '$TEST_USER' creado" 0 $?

# 5.1 Nombre vacío — debe retornar error (stderr contiene [ERROR])
OUTPUT=$(echo "" | bash -c "
    source '$UTILS_FILE'
    source '$PROCESSES_FILE'
    procesos_snapshot
" 2>&1)
check_output_contains \
    "Nombre vacío → muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 5.2 Usuario inexistente — debe retornar error
OUTPUT=$(echo "usuariofalso_pr5_999" | bash -c "
    source '$UTILS_FILE'
    source '$PROCESSES_FILE'
    procesos_snapshot
" 2>&1)
check_output_contains \
    "Usuario inexistente → muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 5.3 Usuario sin procesos — debe mostrar [AVISO]
OUTPUT=$(echo "$TEST_USER" | bash -c "
    source '$UTILS_FILE'
    source '$PROCESSES_FILE'
    procesos_snapshot
" 2>&1)
check_output_contains \
    "Usuario sin procesos → muestra [AVISO]" \
    "\[AVISO\]" \
    "$OUTPUT"

# 5.4 Usuario con procesos (root) — debe mostrar [OK] y procesos
OUTPUT=$(echo "root" | bash -c "
    source '$UTILS_FILE'
    source '$PROCESSES_FILE'
    procesos_snapshot
" 2>&1)
check_output_contains \
    "root con procesos → muestra [OK]" \
    "\[OK\]" \
    "$OUTPUT"

check_output_contains \
    "root con procesos → muestra lista ps" \
    "root" \
    "$OUTPUT"

# 5.5 Verificar que el conteo es mayor a 0 para root
COUNT=$(ps aux --user root 2>/dev/null | tail -n +2 | grep -c .)
[[ $COUNT -gt 0 ]]
check "root tiene procesos activos en este sistema (conteo: $COUNT)" 0 $?

# ─── SECCIÓN 6: Pruebas funcionales — procesos_monitor ───────────────────────
separator "6. procesos_monitor — pruebas automáticas parciales"

# 6.1 Nombre vacío
OUTPUT=$(echo "" | bash -c "
    source '$UTILS_FILE'
    source '$PROCESSES_FILE'
    procesos_monitor
" 2>&1)
check_output_contains \
    "Nombre vacío → muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 6.2 Usuario inexistente
OUTPUT=$(echo "usuariofalso_pr5_999" | bash -c "
    source '$UTILS_FILE'
    source '$PROCESSES_FILE'
    procesos_monitor
" 2>&1)
check_output_contains \
    "Usuario inexistente → muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 6.3 Verificar que el aviso de q aparece antes de top
# Simulamos top con un mock para no abrir la interfaz real
OUTPUT=$(echo "root" | bash -c "
    source '$UTILS_FILE'
    top() { echo 'MOCK_TOP_EJECUTADO'; }
    source '$PROCESSES_FILE'
    procesos_monitor
" 2>&1)
check_output_contains \
    "Monitor → muestra aviso de presionar q antes de top" \
    "\[AVISO\]" \
    "$OUTPUT"

check_output_contains \
    "Monitor → top se ejecuta con usuario root" \
    "MOCK_TOP_EJECUTADO" \
    "$OUTPUT"

# ─── SECCIÓN 7: Verificaciones manuales ──────────────────────────────────────
separator "7. Verificaciones manuales (el revisor debe confirmar)"

warn_manual "sudo bash main.sh → Opción 3 → Opción 1 con root: lista procesos y conteo correcto"
warn_manual "sudo bash main.sh → Opción 3 → Opción 1 con $TEST_USER: muestra [AVISO] sin procesos"
warn_manual "sudo bash main.sh → Opción 3 → Opción 2 con root: [AVISO] aparece ANTES de abrir top"
warn_manual "top abre filtrado por root y al presionar q regresa limpiamente al menú"
warn_manual "Al regresar de top aparece la pausa antes de volver al menú"

# ─── Resultado final ─────────────────────────────────────────────────────────
echo "" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo -e "  Automáticas: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total" | tee -a "$REPORT_FILE"
echo -e "  Manuales:    ${YELLOW}$WARN pendientes de revisión humana${NC}" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}PR #5 pasa verificación automática.${NC}" | tee -a "$REPORT_FILE"
    echo -e "  Confirmar las $WARN verificaciones manuales antes de aprobar." | tee -a "$REPORT_FILE"
else
    echo -e "  ${RED}${BOLD}PR #5 tiene $FAIL fallo(s). No aprobar hasta corregir.${NC}" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo -e "  Reporte guardado en: tests/report_processes.txt" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

[[ $FAIL -eq 0 ]]
exit $?