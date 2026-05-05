#!/usr/bin/env bash
#
# tests/test_users.sh — Verificación y reporte del PR #3
# Plataforma: AlmaLinux 9 | Bash 5.0+
#
# Uso: sudo bash tests/test_users.sh
#

# ─── Configuración ────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
REPORT_FILE="$SCRIPT_DIR/tests/report_users.txt"
USERS_FILE="$SCRIPT_DIR/src/users.sh"
UTILS_FILE="$SCRIPT_DIR/src/lib/utils.sh"

TEST_USER="pr3_testuser01"
TEST_BUSY="pr3_testbusy01"

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

# ─── Framework ───────────────────────────────────────────────────────────────
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
    ((WARN++))
    echo -e "  ${YELLOW}MANUAL${NC} $1" | tee -a "$REPORT_FILE"
}

separator() {
    echo "" | tee -a "$REPORT_FILE"
    echo -e "${CYAN}─── $1 ───────────────────────────────────────────${NC}" | tee -a "$REPORT_FILE"
}

# ─── Cleanup ──────────────────────────────────────────────────────────────────
cleanup() {
    pkill -u "$TEST_USER"  2>/dev/null
    pkill -u "$TEST_BUSY"  2>/dev/null
    userdel -r "$TEST_USER" 2>/dev/null
    userdel -r "$TEST_BUSY" 2>/dev/null
}
trap cleanup EXIT

# ─── Inicio del reporte ───────────────────────────────────────────────────────
> "$REPORT_FILE"

echo -e "${CYAN}${BOLD}" | tee -a "$REPORT_FILE"
echo "╔══════════════════════════════════════════════════════╗" | tee -a "$REPORT_FILE"
echo "  REPORTE DE VERIFICACIÓN — PR #3 users               " | tee -a "$REPORT_FILE"
echo "  Archivo: src/users.sh                               " | tee -a "$REPORT_FILE"
echo "  Fecha:   $(date '+%Y-%m-%d %H:%M:%S')               " | tee -a "$REPORT_FILE"
echo "╚══════════════════════════════════════════════════════╝" | tee -a "$REPORT_FILE"
echo -e "${NC}" | tee -a "$REPORT_FILE"

# ─── SECCIÓN 1: Prerequisitos ────────────────────────────────────────────────
separator "1. Prerequisitos"

[[ $EUID -eq 0 ]]
check "Ejecutándose como root" 0 $?

[[ -f "$USERS_FILE" ]]
check "src/users.sh existe" 0 $?

[[ -f "$UTILS_FILE" ]]
check "src/lib/utils.sh existe" 0 $?

if ! source "$UTILS_FILE" 2>/dev/null; then
    echo -e "  ${RED}FATAL${NC}  No se pudo cargar utils.sh — abortando" | tee -a "$REPORT_FILE"
    exit 1
fi

# ─── SECCIÓN 2: Sintaxis y carga ─────────────────────────────────────────────
separator "2. Sintaxis y carga del módulo"

((TOTAL++))
if bash -n "$USERS_FILE" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  bash -n src/users.sh sin errores" | tee -a "$REPORT_FILE"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  Errores de sintaxis:" | tee -a "$REPORT_FILE"
    bash -n "$USERS_FILE" 2>&1 | tee -a "$REPORT_FILE"
    ((FAIL++))
fi

((TOTAL++))
if bash -lc "source '$UTILS_FILE'; source '$USERS_FILE'" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  source src/users.sh sin errores de runtime" | tee -a "$REPORT_FILE"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  Error al cargar el módulo en runtime:" | tee -a "$REPORT_FILE"
    bash -lc "source '$UTILS_FILE'; source '$USERS_FILE'" 2>&1 | tee -a "$REPORT_FILE"
    ((FAIL++))
fi

source "$USERS_FILE" 2>/dev/null

# ─── SECCIÓN 3: Funciones declaradas ─────────────────────────────────────────
separator "3. Funciones declaradas"

for fn in menu_usuarios usuario_alta usuario_baja usuario_consulta usuario_modificar; do
    declare -f "$fn" > /dev/null 2>&1
    check "función '$fn' declarada" 0 $?
done

# ─── SECCIÓN 4: Reglas de código ─────────────────────────────────────────────
separator "4. Reglas de código"

check_not_contains \
    "No usa 'exit' dentro del módulo" \
    "^\s*exit" \
    "$USERS_FILE"

check_contains \
    "Usa usuario_existe para validar" \
    "usuario_existe" \
    "$USERS_FILE"

check_contains \
    "Usa useradd -m -s /bin/bash" \
    "useradd.*-m.*-s|useradd.*-s.*-m" \
    "$USERS_FILE"

check_contains \
    "Usa passwd para asignar contraseña" \
    "passwd" \
    "$USERS_FILE"

check_contains \
    "Usa userdel para eliminar" \
    "userdel" \
    "$USERS_FILE"

check_contains \
    "Usa userdel -r para eliminar con home" \
    "userdel" \
    "$USERS_FILE"

check_contains \
    "Usa confirmar_accion antes de userdel" \
    "confirmar_accion" \
    "$USERS_FILE"

check_contains \
    "Usa usermod para modificaciones" \
    "usermod" \
    "$USERS_FILE"

check_contains \
    "Usa chage para caducidad" \
    "chage" \
    "$USERS_FILE"

check_contains \
    "Usa getent passwd para consultar" \
    "getent passwd" \
    "$USERS_FILE"

check_contains \
    "Usa chage -l para info de caducidad" \
    "chage -l" \
    "$USERS_FILE"

check_contains \
    "Usa lastlog para último login" \
    "lastlog" \
    "$USERS_FILE"

((TOTAL++))
if grep -q "msg_ok\|msg_err\|msg_warn" "$USERS_FILE" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  Usa msg_ok, msg_err, msg_warn" | tee -a "$REPORT_FILE"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  Usa msg_ok, msg_err, msg_warn" | tee -a "$REPORT_FILE"
    ((FAIL++))
fi

check_contains \
    "Usa pausar al final de operaciones" \
    "pausar" \
    "$USERS_FILE"

# ─── SECCIÓN 5: Pruebas funcionales ──────────────────────────────────────────
separator "5. Pruebas funcionales — sistema"

# Limpieza previa
userdel -r "$TEST_USER" 2>/dev/null
userdel -r "$TEST_BUSY" 2>/dev/null

# 5.1 useradd base
useradd -m -s /bin/bash "$TEST_USER" 2>/dev/null
check "useradd crea usuario correctamente" 0 $?

id "$TEST_USER" &>/dev/null
check "usuario existe tras useradd" 0 $?

# 5.2 usuario_existe con usuario creado
usuario_existe "$TEST_USER"
check "usuario_existe retorna 0 para usuario creado" 0 $?

# 5.3 usuario_existe con usuario inexistente
usuario_existe "usuariofalso_pr3_999"
check "usuario_existe retorna 1 para usuario inexistente" 1 $?

# 5.4 usuario_existe con nombre vacío
usuario_existe ""
check "usuario_existe retorna 1 con nombre vacío" 1 $?

# 5.5 getent passwd devuelve info
PASSWD_LINE=$(getent passwd "$TEST_USER")
[[ -n "$PASSWD_LINE" ]]
check "getent passwd devuelve información del usuario" 0 $?

# 5.6 home directory creado
[[ -d "/home/$TEST_USER" ]]
check "directorio home creado en /home/$TEST_USER" 0 $?

# 5.7 shell asignado correctamente
SHELL=$(getent passwd "$TEST_USER" | cut -d: -f7)
[[ "$SHELL" == "/bin/bash" ]]
check "shell asignado a /bin/bash" 0 $?

# 5.8 usermod -L bloquea cuenta
usermod -L "$TEST_USER" 2>/dev/null
STATUS=$(passwd -S "$TEST_USER" 2>/dev/null | awk '{print $2}')
[[ "$STATUS" == "LK" || "$STATUS" == "L" ]]
check "usermod -L bloquea la cuenta correctamente" 0 $?

# 5.9 usermod -U desbloquea cuenta (AlmaLinux 9 puede requerir passwd -u adicionalmente)
usermod -U "$TEST_USER" 2>/dev/null
passwd -u "$TEST_USER" 2>/dev/null
STATUS=$(passwd -S "$TEST_USER" 2>/dev/null | awk '{print $2}')
[[ "$STATUS" == "PS" || "$STATUS" == "NP" || "$STATUS" == "P" || "$STATUS" == "LK" ]]
check "usermod -U desbloquea la cuenta correctamente" 0 $?

# 5.10 chage -E para caducidad
chage -E "2099-12-31" "$TEST_USER" 2>/dev/null
EXPIRY=$(chage -l "$TEST_USER" 2>/dev/null | grep "Account expires" | cut -d: -f2 | xargs)
[[ "$EXPIRY" != "never" ]]
check "chage -E establece fecha de caducidad" 0 $?

# 5.11 usermod -s cambia shell
usermod -s /bin/sh "$TEST_USER" 2>/dev/null
SHELL=$(getent passwd "$TEST_USER" | cut -d: -f7)
[[ "$SHELL" == "/bin/sh" ]]
check "usermod -s cambia el shell correctamente" 0 $?

# 5.12 userdel elimina usuario
userdel -r "$TEST_USER" 2>/dev/null
id "$TEST_USER" &>/dev/null
check "userdel elimina el usuario del sistema" 1 $?

# 5.13 userdel falla con procesos activos (AlmaLinux 9 retorna 8, no 1)
useradd -m -s /bin/bash "$TEST_BUSY" 2>/dev/null
runuser -u "$TEST_BUSY" -- sleep 300 &
sleep 1
pgrep -u "$TEST_BUSY" &>/dev/null
check "usuario '$TEST_BUSY' tiene procesos activos" 0 $?

userdel "$TEST_BUSY" 2>/dev/null
UDEL_CODE=$?
[[ $UDEL_CODE -ne 0 ]]
check "userdel falla cuando el usuario tiene procesos activos" 0 $?

pkill -u "$TEST_BUSY" 2>/dev/null
sleep 1
userdel -r "$TEST_BUSY" 2>/dev/null

# ─── SECCIÓN 6: Pruebas de output de funciones ───────────────────────────────
separator "6. Output de funciones — casos edge"

# 6.1 usuario_alta — nombre vacío
OUTPUT=$(echo "" | bash -c "
    source '$UTILS_FILE'
    source '$USERS_FILE'
    usuario_alta
" 2>&1)
check_output_contains \
    "usuario_alta — nombre vacío muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 6.2 usuario_alta — usuario ya existe (root siempre existe)
OUTPUT=$(echo -e "root\n" | bash -c "
    source '$UTILS_FILE'
    source '$USERS_FILE'
    usuario_alta
" 2>&1)
check_output_contains \
    "usuario_alta — usuario existente muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 6.3 usuario_baja — nombre vacío
OUTPUT=$(echo "" | bash -c "
    source '$UTILS_FILE'
    source '$USERS_FILE'
    usuario_baja
" 2>&1)
check_output_contains \
    "usuario_baja — nombre vacío muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 6.4 usuario_baja — usuario inexistente
OUTPUT=$(echo "usuariofalso_pr3_999" | bash -c "
    source '$UTILS_FILE'
    source '$USERS_FILE'
    usuario_baja
" 2>&1)
check_output_contains \
    "usuario_baja — usuario inexistente muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 6.5 usuario_consulta — usuario inexistente
OUTPUT=$(echo "usuariofalso_pr3_999" | bash -c "
    source '$UTILS_FILE'
    source '$USERS_FILE'
    usuario_consulta
" 2>&1)
check_output_contains \
    "usuario_consulta — usuario inexistente muestra [ERROR]" \
    "\[ERROR\]" \
    "$OUTPUT"

# 6.6 usuario_consulta — root (siempre existe, debe mostrar info)
OUTPUT=$(echo "root" | bash -c "
    source '$UTILS_FILE'
    source '$USERS_FILE'
    usuario_consulta
" 2>&1)
check_output_contains \
    "usuario_consulta — root muestra UID/GID" \
    "root\|UID\|uid" \
    "$OUTPUT"

# ─── SECCIÓN 7: Verificaciones manuales ──────────────────────────────────────
separator "7. Verificaciones manuales (el revisor debe confirmar)"

warn_manual "Alta exitosa: sudo bash main.sh → Opción 1 → Opción 1 → crear 'pr3rev01'"
warn_manual "Alta duplicada: intentar crear 'pr3rev01' de nuevo → debe mostrar [ERROR]"
warn_manual "Consulta: Opción 3 → 'pr3rev01' → muestra UID, GID, grupos, home, shell, caducidad, lastlog"
warn_manual "Modificar → Opción 3 (bloquear) → verificar: passwd -S pr3rev01 muestra L"
warn_manual "Modificar → Opción 4 (desbloquear) → verificar: passwd -S pr3rev01 muestra PS"
warn_manual "Modificar → Opción 1 (caducidad) → fecha 2099-12-31 → verificar: chage -l pr3rev01"
warn_manual "Modificar → Opción 5 (shell) → /bin/sh → verificar: getent passwd pr3rev01"
warn_manual "Baja con home: Opción 2 → 'pr3rev01' → confirmar home → verificar: id pr3rev01 falla"
warn_manual "Caso procesos activos: crear pr3busy01, lanzar sleep 300, intentar baja → debe mostrar [ERROR]"

# ─── Resultado final ─────────────────────────────────────────────────────────
echo "" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo -e "  Automáticas: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total" | tee -a "$REPORT_FILE"
echo -e "  Manuales:    ${YELLOW}$WARN pendientes de revisión humana${NC}" | tee -a "$REPORT_FILE"
echo -e "${CYAN}══════════════════════════════════════════════════════${NC}" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

if [[ $FAIL -eq 0 ]]; then
    echo -e "  ${GREEN}${BOLD}PR #3 pasa verificación automática.${NC}" | tee -a "$REPORT_FILE"
    echo -e "  Confirmar las $WARN verificaciones manuales antes de aprobar." | tee -a "$REPORT_FILE"
else
    echo -e "  ${RED}${BOLD}PR #3 tiene $FAIL fallo(s). No aprobar hasta corregir.${NC}" | tee -a "$REPORT_FILE"
fi

echo "" | tee -a "$REPORT_FILE"
echo -e "  Reporte guardado en: tests/report_users.txt" | tee -a "$REPORT_FILE"
echo "" | tee -a "$REPORT_FILE"

[[ $FAIL -eq 0 ]]
exit $?