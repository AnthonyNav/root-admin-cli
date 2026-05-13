#!/usr/bin/env bash
# install_security.sh - Install and configure security tooling for AlmaLinux 9.

# Stop on unhandled errors during the installation flow.
set -e

# ANSI colors used by the installation output.
RED='\033[0;31m'
GREEN='\033[0;32m'
TITLE_COLOR='\033[1;36m' # Cyan works well as a section title color.
YELLOW='\033[1;33m'
NC='\033[0m' # Reset color.

# Logging helpers.
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Run environment validation before installing packages.
phase1_preflight() {
    echo -e "\n${TITLE_COLOR}=== FASE 1: Pre-requisitos y Comprobaciones de Seguridad ===${NC}"

    # 1. Require root privileges.
    log_info "Verificando privilegios de root..."
    if [ "$EUID" -ne 0 ]; then
        log_error "El script debe ejecutarse como root (sudo)."
        exit 1
    fi
    log_info "Usuario root verificado."

    # 2. Confirm that the host is AlmaLinux 9.
    log_info "Verificando la versión del Sistema Operativo..."
    if ! grep -qiE "AlmaLinux.*release 9" /etc/redhat-release 2>/dev/null; then
        log_error "El sistema operativo no es AlmaLinux 9. Abortando instalación."
        exit 1
    fi
    log_info "Sistema operativo $(cat /etc/redhat-release) verificado."

    # 3. Check internet connectivity silently.
    log_info "Verificando conectividad a internet..."
    if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        log_error "No hay conectividad a internet. Verifique la red y vuelva a intentar."
        exit 1
    fi
    log_info "Conectividad a internet exitosa."

    # 4. Free port 80 when another process is already using it.
    log_info "Verificando disponibilidad del puerto 80 (HTTP)..."
    if ss -tlnp | grep -q ':80 '; then
        log_warn "El puerto 80 está en uso. Intentando liberar el puerto automáticamente..."

        # Stop httpd first when it is the current owner of the port.
        if systemctl is-active --quiet httpd 2>/dev/null; then
            systemctl stop httpd || true
        fi

        # Force-kill any remaining process that still owns port 80.
        PIDS=$(ss -tlnp | grep ':80 ' | grep -Eo 'pid=[0-9]+' | cut -d= -f2 | sort -u)
        if [ -n "$PIDS" ]; then
            for pid in $PIDS; do
                kill -9 $pid 2>/dev/null || true
            done
        fi

        # Confirm the port is now free before continuing.
        sleep 2
        if ss -tlnp | grep -q ':80 '; then
            log_error "No se pudo liberar el puerto 80 automáticamente. Abortando instalación."
            exit 1
        fi
        log_info "Puerto 80 liberado con éxito."
    else
        log_info "Puerto 80 disponible para uso."
    fi

    # 5. Detect whether CRB or EPEL already exists.
    log_info "Verificando estado de repositorios CRB y EPEL..."
    if dnf repolist 2>/dev/null | grep -qiE 'crb|epel'; then
        log_warn "Los repositorios CRB o EPEL ya se encuentran habilitados. Se asegurará su configuración en la Fase 2."
    else
        log_info "Repositorios CRB o EPEL no detectados. Serán instalados/habilitados."
    fi

    log_info "Todas las comprobaciones de la Fase 1 pasaron con éxito."
}

# Install packages and perform the required service configuration.
phase2_install() {
    echo -e "\n${TITLE_COLOR}=== FASE 2: Instalación y Configuración ===${NC}"

    # 1. Enable the CRB repository.
    log_info "Habilitando repositorio CRB (Code Ready Builder)..."
    dnf config-manager --set-enabled crb

    # 2. Install EPEL.
    log_info "Instalando el repositorio EPEL..."
    dnf install -y epel-release

    # 3. Set SELinux to permissive mode for the expected tooling.
    log_info "Configurando SELinux en modo permissive..."
    if [ -f /etc/selinux/config ]; then
        sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
    fi
    if command -v setenforce >/dev/null 2>&1; then
        setenforce 0 || log_warn "No se pudo cambiar el estado de SELinux en caliente."
    fi

    # 4. Install all required packages in one transaction.
    log_info "Instalando paquetes: nagios, nagios-plugins-all, nrpe, nagios-plugins-nrpe, wireshark, nmap, iftop, at, cronie, httpd, httpd-tools..."
    dnf install -y nagios nagios-plugins-all nrpe nagios-plugins-nrpe wireshark nmap iftop at cronie httpd httpd-tools

    # 5. Configure the Nagios web credentials.
    log_info "Configurando autenticación para Nagios (httpd)..."
    echo -e "${TITLE_COLOR}=== CREACIÓN DE CREDENCIALES NAGIOS ===${NC}"
    echo -e "A continuación, se le pedirá de forma interactiva que asigne una contraseña para el usuario administrador '${GREEN}nagiosadmin${NC}'"
    
    # Temporarily relax set -e to report htpasswd failures cleanly.
    set +e
    htpasswd -c /etc/nagios/passwd nagiosadmin
    if [ $? -ne 0 ]; then
        log_error "Hubo un error al asignar la contraseña para nagiosadmin."
        exit 1
    fi
    set -e

    # 6. Enable and start the required services.
    log_info "Habilitando y arrancando servicios principales (httpd, nagios, crond, atd, nrpe)..."
    systemctl enable --now httpd nagios crond atd nrpe

    # 7. Open HTTP in firewalld when the service is available.
    log_info "Configurando excepciones en firewalld..."
    if systemctl is-active --quiet firewalld; then
        firewall-cmd --add-service=http --permanent
        firewall-cmd --reload
        log_info "Reglas de firewall para HTTP aplicadas exitosamente."
    else
        log_warn "El servicio firewalld no está activo. Se omitirá la configuración del firewall."
    fi

    log_info "La Fase 2 finalizó exitosamente."
}

# Run post-install verification checks and print the final summary.
phase3_postflight() {
    echo -e "\n${TITLE_COLOR}=== FASE 3: Pruebas y Verificación (Post-flight checks) ===${NC}"

    local errores_encontrados=0

    # 1. Confirm that core services are active.
    log_info "Verificando el estado de los servicios..."
    for servicio in httpd nagios crond atd nrpe; do
        if systemctl is-active --quiet "$servicio"; then
            echo -e "  - $servicio: ${GREEN}Activo y Corriendo${NC}"
        else
            echo -e "  - $servicio: ${RED}Inactivo o en Falla${NC}"
            errores_encontrados=$((errores_encontrados + 1))
        fi
    done

    # 2. Probe the Nagios HTTP endpoint locally.
    log_info "Realizando petición HTTP al portal de Nagios..."
    # Only keep the HTTP status code from the curl response.
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/nagios/ || true)
    
    if [ "$HTTP_CODE" = "401" ]; then
        echo -e "  - Servidor Web (Nagios): ${GREEN}Responde Correctamente (HTTP 401 - Autenticación requerida)${NC}"
    elif [ "$HTTP_CODE" = "200" ]; then
        echo -e "  - Servidor Web (Nagios): ${GREEN}Responde Correctamente (HTTP 200 - OK)${NC}"
    else
        echo -e "  - Servidor Web (Nagios): ${RED}Fallo de respuesta (Código HTTP: $HTTP_CODE)${NC}"
        errores_encontrados=$((errores_encontrados + 1))
    fi

    # 3. Verify that cron and at tools are callable.
    log_info "Verificando estado de utilidades del sistema (crontab, atq)..."

    # Treat "no crontab for user" as a valid condition rather than a failure.
    if crontab -l >/dev/null 2>&1 || [ $? -eq 1 ]; then
        echo -e "  - Comando 'crontab': ${GREEN}Disponible y funcional${NC}"
    else
        echo -e "  - Comando 'crontab': ${RED}Error al ejecutar${NC}"
        errores_encontrados=$((errores_encontrados + 1))
    fi

    if atq >/dev/null 2>&1; then
        echo -e "  - Comando 'atq': ${GREEN}Disponible y funcional${NC}"
    else
        echo -e "  - Comando 'atq': ${RED}Error al ejecutar${NC}"
        errores_encontrados=$((errores_encontrados + 1))
    fi

    # 4. Print a summary and discover the most useful local IP address.
    LOCAL_IP=$(ip -4 route get 8.8.8.8 2>/dev/null | awk '{print $7}' | head -n 1)
    [ -z "$LOCAL_IP" ] && LOCAL_IP=$(hostname -I | awk '{print $1}')

    echo -e "\n======================================================="
    if [ $errores_encontrados -eq 0 ]; then
        echo -e "${GREEN}  ¡Instalación y Configuración Completada con Éxito!  ${NC}"
        echo -e "======================================================="
        echo -e "Resumen de las tareas realizadas:"
        echo -e " ${GREEN}✓${NC} Sistema operativo AlmaLinux 9 y privilegios root verificados."
        echo -e " ${GREEN}✓${NC} Repositorios EPEL y CRB habilitados."
        echo -e " ${GREEN}✓${NC} Políticas de SELinux ajustadas a Permissive."
        echo -e " ${GREEN}✓${NC} Herramientas de seguridad (nmap, wireshark, iftop) instaladas."
        echo -e " ${GREEN}✓${NC} Monitoreo (Nagios, NRPE) instalado y corriendo."
        echo -e " ${GREEN}✓${NC} Tareas programadas (cronie, at) operativas."
        echo -e " ${GREEN}✓${NC} Puerto HTTP (80) abierto en Firewall."
        
        echo -e "\n${TITLE_COLOR}"
        echo -e "  _   _    _    ____ ___ ___  ____  "
        echo -e " | \ | |  / \  / ___|_ _/ _ \/ ___| "
        echo -e " |  \| | / _ \| |  _ | | | | \___ \ "
        echo -e " | |\  |/ ___ \ |_| || | |_| |___) |"
        echo -e " |_| \_/_/   \_\____|___\___/|____/ "
        echo -e "${NC}"
        
        echo -e "${TITLE_COLOR}INSTRUCCIONES FINALES PARA ACCEDER A NAGIOS:${NC}"
        echo -e " 1. Abra un navegador web."
        echo -e " 2. Ingrese a la URL: ${GREEN}http://${LOCAL_IP}/nagios${NC}"
        echo -e " 3. Se le pedirá iniciar sesión."
        echo -e " 4. Usuario: ${GREEN}nagiosadmin${NC}"
        echo -e " 5. Contraseña: ${GREEN}[La contraseña ingresada durante la instalación]${NC}"
    else
        echo -e "${RED}  Atención: La instalación finalizó con $errores_encontrados error(es).  ${NC}"
        echo -e "======================================================="
        echo -e "Por favor, revise el detalle en los logs de la Fase 3 mostrados arriba."
    fi
    echo -e "=======================================================\n"
}

# Run all phases in order.
main() {
    # Ensure the script remains executable after checkout or copy operations.
    chmod +x "$0" 2>/dev/null || true

    echo -e "${TITLE_COLOR}"
    echo -e "  ____  _____ ____ _   _ ____  ___ _______   __"
    echo -e " / ___|| ____/ ___| | | |  _ \|_ _|__   \ \ / /"
    echo -e " \___ \|  _|| |  _| | | | |_) || |   | | \ V / "
    echo -e "  ___) | |__| |_| | |_| |  _ < | |   | |  | |  "
    echo -e " |____/|_____\____|\___/|_| \_\___|  |_|  |_|  "
    echo -e "${NC}"
    echo -e "${TITLE_COLOR}=======================================================${NC}"
    echo -e "${TITLE_COLOR}      DEPLOYMENT DE SEGURIDAD Y MONITOREO (ALMALINUX)    ${NC}"
    echo -e "${TITLE_COLOR}=======================================================${NC}"
    
    phase1_preflight
    phase2_install
    
    # Deshabilitar 'set -e' en la Fase 3 para poder terminar las pruebas y reportar errores
    set +e
    phase3_postflight
}

# Entrypoint.
main
