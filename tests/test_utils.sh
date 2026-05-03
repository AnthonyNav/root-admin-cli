#!/usr/bin/env bash
#
# test_utils.sh — Suite de pruebas para src/lib/utils.sh
# Ejecutar en AlmaLinux 9 como root:
#   sudo bash test_utils.sh
#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source "$SCRIPT_DIR/src/lib/utils.sh"

# ─── Framework mínimo de pruebas ─────────────────────────────────────────────
PASS=0
FAIL=0
TOTAL=0

check() {
    local desc="$1"
    local expected="$2"
    local actual="$3"
    ((TOTAL++))
    if [[ "$actual" -eq "$expected" ]]; then
        echo -e "  ${GREEN}PASS${NC}  $desc"
        ((PASS++))
    else
        echo -e "  ${RED}FAIL${NC}  $desc"
        echo -e "        esperado: $expected  |  obtenido: $actual"
        ((FAIL++))
    fi
}

separator() {
    echo ""
    echo -e "${CYAN}─── $1 ───────────────────────────────────────────${NC}"
}

# ─── 1. Verificar que el archivo carga sin errores ───────────────────────────
separator "Carga del archivo"
((TOTAL++))
if bash -n "$SCRIPT_DIR/src/lib/utils.sh" 2>/dev/null; then
    echo -e "  ${GREEN}PASS${NC}  Sin errores de sintaxis (bash -n)"
    ((PASS++))
else
    echo -e "  ${RED}FAIL${NC}  Errores de sintaxis detectados"
    ((FAIL++))
fi

# ─── 2. print_header ─────────────────────────────────────────────────────────
separator "print_header"
echo -e "  Output visual (verifica manualmente que se ve bien):"
print_header "Prueba de encabezado"

# ─── 3. Mensajes ─────────────────────────────────────────────────────────────
separator "msg_ok / msg_err / msg_warn"
echo -e "  Output visual (verifica colores manualmente):"
msg_ok   "Mensaje de éxito — debe verse en VERDE"
msg_warn "Mensaje de aviso — debe verse en AMARILLO"
msg_err  "Mensaje de error — debe verse en ROJO (va a stderr)"
echo ""

# Verificar que msg_err va a stderr y no a stdout
STDOUT=$(msg_err "test" 2>/dev/null)
check "msg_err no imprime a stdout" "" ${#STDOUT}

STDERR=$(msg_err "test" 2>&1 >/dev/null)
[[ "$STDERR" == *"[ERROR]"* ]]
check "msg_err imprime [ERROR] a stderr" 0 $?

# ─── 4. usuario_existe ───────────────────────────────────────────────────────
separator "usuario_existe"
usuario_existe "root"
check "root existe en el sistema"                0 $?

usuario_existe "usuarioquenuncaexistira_abc123"
check "usuario inexistente retorna 1"            1 $?

usuario_existe ""
check "nombre vacío retorna 1"                   1 $?

# ─── 5. grupo_existe ─────────────────────────────────────────────────────────
separator "grupo_existe"
grupo_existe "root"
check "grupo root existe en el sistema"          0 $?

grupo_existe "grupoinexistente_abc123"
check "grupo inexistente retorna 1"              1 $?

grupo_existe ""
check "nombre vacío retorna 1"                   1 $?

# ─── 6. confirmar_accion ─────────────────────────────────────────────────────
separator "confirmar_accion"
echo "s"  | bash -c "source $SCRIPT_DIR/src/lib/utils.sh; confirmar_accion 'Prueba' >/dev/null 2>&1"
check "respuesta 's' retorna 0 (confirma)"       0 $?

echo "S"  | bash -c "source $SCRIPT_DIR/src/lib/utils.sh; confirmar_accion 'Prueba' >/dev/null 2>&1"
check "respuesta 'S' retorna 0 (confirma)"       0 $?

echo ""   | bash -c "source $SCRIPT_DIR/src/lib/utils.sh; confirmar_accion 'Prueba' >/dev/null 2>&1"
check "Enter vacío retorna 1 (cancela)"          1 $?

echo "si" | bash -c "source $SCRIPT_DIR/src/lib/utils.sh; confirmar_accion 'Prueba' >/dev/null 2>&1"
check "respuesta 'si' retorna 1 (no acepta)"     1 $?

echo "yes"| bash -c "source $SCRIPT_DIR/src/lib/utils.sh; confirmar_accion 'Prueba' >/dev/null 2>&1"
check "respuesta 'yes' retorna 1 (no acepta)"    1 $?

echo "n"  | bash -c "source $SCRIPT_DIR/src/lib/utils.sh; confirmar_accion 'Prueba' >/dev/null 2>&1"
check "respuesta 'n' retorna 1 (cancela)"        1 $?

# ─── 7. pausar ───────────────────────────────────────────────────────────────
separator "pausar"
echo "" | bash -c "source $SCRIPT_DIR/src/lib/utils.sh; pausar" > /dev/null 2>&1
check "pausar no rompe con Enter simulado"       0 $?

# ─── Resultado final ─────────────────────────────────────────────────────────
echo ""
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo -e "  Resultado: ${GREEN}$PASS passed${NC} / ${RED}$FAIL failed${NC} / $TOTAL total"
echo -e "${CYAN}══════════════════════════════════════════${NC}"
echo ""

if [[ $FAIL -eq 0 ]]; then
    msg_ok "utils.sh listo para PR."
else
    msg_err "$FAIL prueba(s) fallaron. Revisar antes de abrir el PR."
    exit 1
fi