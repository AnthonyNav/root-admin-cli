#!/usr/bin/env bash
#
# tests/test_groups.sh — Verificación y reporte del PR #4
# Plataforma: AlmaLinux 9 | Bash 5.0+
#
# Uso: sudo bash tests/test_groups.sh
#
# Genera un reporte completo del estado del PR #4 indicando
# qué está correcto, qué falla y qué le falta al revisor aprobar.
#

# ─── Configuración ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="$SCRIPT_DIR/tests/report_groups.txt"
GROUPS_FILE="$SCRIPT_DIR/src/groups.sh"
UTILS_FILE="$SCRIPT_DIR/src/lib/utils.sh"

# Grupo de prueba temporal
TEST_GROUP="testgrupo_pr4"
TEST_GROUP_2="testgrupo_pr4_renamed"

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
        echo -e "        patrón '${pattern}' no encontrado en $file" | tee -a "$REPORT_FILE"
        ((FAIL++))
    fi
}

check_not_contains() {
    local desc="$1" pattern="$2" file="$3"
    ((TOTAL++))
    if ! grep -q "$pattern" "$file" 2>/dev/null; then
        echo -e "  ${GREEN}PASS${NC}  $desc" | tee -a "$REPORT_FILE"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc" | tee -a "$REPORT_FILE"
        echo -e "        patrón prohibido '${pattern}' encontrado en $file" | tee -a "$REPORT_FILE"
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

# ─── Cleanup de grupos de prueba al salir ────────────────────────────────────
cleanup() {
    groupdel "$TEST_GROUP"   2>/dev/null
    groupdel "$TEST_GROUP_2" 2>/dev/null
}
trap cleanup EXIT

# ─── Inicio del reporte ───────────────────────────────────────────────────────
> "$REPORT_FILE"  # limpiar reporte anterior

echo -e "${CYAN}${BOLD}" | tee -a "$REPORT_FILE"
echo "╔══════════════════════════════════════════════════════╗" | tee -a "$REPORT_FILE"
echo "  REPORTE DE VERIFICACIÓN — PR #4 grupos              " | tee -a "$REPORT_FILE"
echo "  Archivo: src/groups.sh                              " | tee -a "$REPORT_FILE"
echo "  Fecha:   $(date '+%Y-%m-%d %H:%M:%S')               " | tee -a "$REPORT_FILE"
echo "╚══════════════════════════════════════════════════════╝" | tee -a "$REPORT_FILE"
echo -e "${NC}" | tee -a "$REPORT_FILE"

# ─── SECCIÓN 1: Prerequisitos ────────────────────────────────────────────────
separator "1. Prerequisitos"

# Root
[[ $EUID -eq 0 ]]
check "Ejecutándose como root" 0 $?

# Archivos existen
[[ -f "$GROUPS_FILE" ]]
check "src/groups.sh existe" 0 $?

[[ -f "$UTILS_FILE" ]]
check "src/lib/utils.sh existe" 0 $?

# Cargar dependencias
if ! source "$UTILS_FILE" 2>/dev/null; then
    echo -e "  ${RED}FATAL${NC}  No se pudo cargar utils.sh — abortando" | tee -a "$REPORT_FILE"
    exit 1
fi

# ─── SECCIÓN 2: Sintaxis ─────────────────────────────────────────────────────
separator "2. Sintaxis"

((TOTAL++))
if bash -n "$GROUPS_FILE" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  bash -n src/groups.sh sin errores" | tee -a "$REPORT_FILE"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  Errores de sintaxis en src/groups.sh" | tee -a "$REPORT_FILE"
    bash -n "$GROUPS_FILE" 2>&1 | tee -a "$REPORT_FILE"
    ((FAIL++))
fi

# ─── SECCIÓN 3: Funciones declaradas ─────────────────────────────────────────
separator "3. Funciones declaradas"

source "$GROUPS_FILE" 2>/dev/null

for fn in menu_grupos grupo_alta grupo_baja grupo_consulta grupo_modificar; do
    declare -f "$fn" > /dev/null 2>&1
    check "función '$fn' está declarada" 0 $?
done

# ─── SECCIÓN 4: Reglas de código ─────────────────────────────────────────────
separator "4. Reglas de código"

check_not_contains \
    "No usa 'exit' dentro del módulo (solo 'return')" \
    "^\s*exit" \
    "$GROUPS_FILE"

check_contains \
    "Usa confirmar_accion antes de groupdel" \
    "confirmar_accion" \
    "$GROUPS_FILE"

check_contains \
    "Usa grupo_existe para validar" \
    "grupo_existe" \
    "$GROUPS_FILE"

check_contains \
    "Usa msg_ok para confirmaciones" \
    "msg_ok" \
    "$GROUPS_FILE"

check_contains \
    "Usa msg_err para errores" \
    "msg_err" \
    "$GROUPS_FILE"

check_contains \
    "Usa msg_warn para avisos" \
    "msg_warn" \
    "$GROUPS_FILE"

check_contains \
    "Llama a pausar al final de operaciones" \
    "pausar" \
    "$GROUPS_FILE"

check_contains \
    "Usa groupadd para crear grupos" \
    "groupadd" \
    "$GROUPS_FILE"

check_contains \
    "Usa groupdel para eliminar grupos" \
    "groupdel" \
    "$GROUPS_FILE"

check_contains \
    "Usa groupmod o gpasswd para modificar" \
    "groupmod\|gpasswd" \
    "$GROUPS_FILE"

check_contains \
    "Usa getent group para consultar" \
    "getent group" \
    "$GROUPS_FILE"

# ─── SECCIÓN 5: Pruebas funcionales ──────────────────────────────────────────
separator "5. Pruebas funcionales"

# Limpieza previa por si existen de una corrida anterior
groupdel "$TEST_GROUP"   2>/dev/null
groupdel "$TEST_GROUP_2" 2>/dev/null

# 5.1 grupo_alta — grupo nuevo
groupadd "$TEST_GROUP" 2>/dev/null
getent group "$TEST_GROUP" &>/dev/null
check "groupadd crea el grupo correctamente en el sistema" 0 $?

# 5.2 grupo_alta — grupo duplicado (debe fallar)
groupadd "$TEST_GROUP" 2>/dev/null
check "groupadd falla si el grupo ya existe (código != 0)" 9 $((${PIPESTATUS[0]}==0 ? 0 : 9))

# 5.3 grupo_existe con grupo creado
grupo_existe "$TEST_GROUP"
check "grupo_existe retorna 0 para grupo recién creado" 0 $?

# 5.4 grupo_existe con grupo inexistente
grupo_existe "grupoinexistente_abc999"
check "grupo_existe retorna 1 para grupo inexistente" 1 $?

# 5.5 grupo_existe con nombre vacío
grupo_existe ""
check "grupo_existe retorna 1 con nombre vacío" 1 $?

# 5.6 getent devuelve GID
GID_LINE=$(getent group "$TEST_GROUP")
[[ -n "$GID_LINE" ]]
check "getent group devuelve información del grupo" 0 $?

# 5.7 Agregar miembro con gpasswd
gpasswd -a root "$TEST_GROUP" &>/dev/null
MIEMBROS=$(getent group "$TEST_GROUP" | cut -d: -f4)
[[ "$MIEMBROS" == *"root"* ]]
check "gpasswd -a agrega miembro correctamente" 0 $?

# 5.8 Quitar miembro con gpasswd
gpasswd -d root "$TEST_GROUP" &>/dev/null
MIEMBROS=$(getent group "$TEST_GROUP" | cut -d: -f4)
[[ "$MIEMBROS" != *"root"* ]]
check "gpasswd -d quita miembro correctamente" 0 $?

# 5.9 Renombrar grupo con groupmod
groupmod -n "$TEST_GROUP_2" "$TEST_GROUP" 2>/dev/null
grupo_existe "$TEST_GROUP_2"
check "groupmod -n renombra el grupo correctamente" 0 $?

grupo_existe "$TEST_GROUP"
check "grupo anterior ya no existe tras renombrar" 1 $?

# 5.10 groupdel
groupdel "$TEST_GROUP_2" 2>/dev/null
grupo_existe "$TEST_GROUP_2"
check "groupdel elimina el grupo del sistema" 1 $?

# 5.11 groupdel en grupo primario de usuario (debe fallar)
groupdel "root" 2>/dev/null
check "groupdel falla al intentar eliminar grupo primario de root" 6 $?

# ─── SECCIÓN 6: Verificaciones manuales ──────────────────────────────────────
separator "6. Verificaciones manuales (el revisor debe confirmar)"

warn_manual "El menú de grupos muestra las 4 opciones y la opción 0 para volver"
warn_manual "grupo_alta solicita nombre, rechaza vacío y duplicado con msg_err"
warn_manual "grupo_baja pide confirmar_accion antes de ejecutar groupdel"
warn_manual "grupo_baja muestra msg_err si groupdel falla (grupo primario)"
warn_manual "grupo_consulta muestra GID, miembros, e indica '(sin miembros)' si está vacío"
warn_manual "grupo_modificar valida con usuario_existe al agregar un miembro"
warn_manual "Ninguna función rompe el bucle del menú con exit"
warn_manual "Prueba navegando: sudo bash main.sh → Opción 2 → probar cada subopción"

# ─── Resultado final ─────────────────────────────────────────────────────────
echo "" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo -e "  Automáticas: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total" | tee -a "$REPORT_FILE"
echo -e "  Manuales:    ${YELLOW}$WARN pendientes de revisión humana${NC}" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}PR #4 pasa verificación automática.${NC}" | tee -a "$REPORT_FILE"
    echo -e "  Confirmar las $WARN verificaciones manuales antes de aprobar." | tee -a "$REPORT_FILE"
else
    echo -e "  ${RED}${BOLD}PR #4 tiene $FAIL fallo(s). No aprobar hasta corregir.${NC}" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo -e "  Reporte guardado en: tests/report_groups.txt" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

[[ $FAIL -eq 0 ]]
exit $?
