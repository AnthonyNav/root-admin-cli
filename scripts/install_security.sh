#!/bin/bash
# install_security.sh - Script de instalación y configuración de seguridad y monitoreo para AlmaLinux 9.7
# Autor: Administrador de Sistemas
# Descripción: Prepara un entorno defensivo instalando Nagios, Wireshark, Nmap y más.

# Detener la ejecución en caso de error en cualquier comando (Fase 1 y 2)
set -e

# ==========================================
# Definición de Colores para el Output
# ==========================================
RED='\033[0;31m'
GREEN='\033[0;32m'
TITLE_COLOR='\033[1;36m' # Azul claro / Cyan para mejor lectura
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# ==========================================
# Funciones de Logging
# ==========================================
log_info() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

log_warn() {
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# ==========================================
# Fase 1: Pre-requisitos y Comprobaciones
# ==========================================
phase1_preflight() {
    echo -e "\n${TITLE_COLOR}=== FASE 1: Pre-requisitos y Comprobaciones de Seguridad ===${NC}"
    
    # 1. Verificar que el usuario es root
    log_info "Verificando privilegios de root..."
    if [ "$EUID" -ne 0 ]; then
        log_error "El script debe ejecutarse como root (sudo)."
        exit 1
    fi
    log_info "Usuario root verificado."

    # 2. Verificar que el sistema operativo es AlmaLinux 9
    log_info "Verificando la versión del Sistema Operativo..."
    if ! grep -qiE "AlmaLinux.*release 9" /etc/redhat-release 2>/dev/null; then
        log_error "El sistema operativo no es AlmaLinux 9. Abortando instalación."
        exit 1
    fi
    log_info "Sistema operativo $(cat /etc/redhat-release) verificado."

    # 3. Verificar conectividad a internet de forma silenciosa
    log_info "Verificando conectividad a internet..."
    if ! ping -c 1 -W 3 8.8.8.8 >/dev/null 2>&1; then
        log_error "No hay conectividad a internet. Verifique la red y vuelva a intentar."
        exit 1
    fi
    log_info "Conectividad a internet exitosa."

    # 4. Verificar si el puerto 80 ya está en uso y liberar
    log_info "Verificando disponibilidad del puerto 80 (HTTP)..."
    if ss -tlnp | grep -q ':80 '; then
        log_warn "El puerto 80 está en uso. Intentando liberar el puerto automáticamente..."
        
        # Intentar detener el servicio httpd primero de forma limpia
        if systemctl is-active --quiet httpd 2>/dev/null; then
            systemctl stop httpd || true
        fi
        
        # Forzar el cierre de cualquier proceso restante en el puerto 80
        PIDS=$(ss -tlnp | grep ':80 ' | grep -Eo 'pid=[0-9]+' | cut -d= -f2 | sort -u)
        if [ -n "$PIDS" ]; then
            for pid in $PIDS; do
                kill -9 $pid 2>/dev/null || true
            done
        fi
        
        # Verificar nuevamente si se logró liberar
        sleep 2
        if ss -tlnp | grep -q ':80 '; then
            log_error "No se pudo liberar el puerto 80 automáticamente. Abortando instalación."
            exit 1
        fi
        log_info "Puerto 80 liberado con éxito."
    else
        log_info "Puerto 80 disponible para uso."
    fi

    # 5. Verificar repositorios CRB o EPEL
    log_info "Verificando estado de repositorios CRB y EPEL..."
    if dnf repolist 2>/dev/null | grep -qiE 'crb|epel'; then
        log_warn "Los repositorios CRB o EPEL ya se encuentran habilitados. Se asegurará su configuración en la Fase 2."
    else
        log_info "Repositorios CRB o EPEL no detectados. Serán instalados/habilitados."
    fi

    log_info "Todas las comprobaciones de la Fase 1 pasaron con éxito."
}

# ==========================================
# Fase 2: Instalación y Configuración
# ==========================================
phase2_install() {
    echo -e "\n${TITLE_COLOR}=== FASE 2: Instalación y Configuración ===${NC}"

    # 1. Habilitar el repositorio CRB
    log_info "Habilitando repositorio CRB (Code Ready Builder)..."
    dnf config-manager --set-enabled crb

    # 2. Instalar el repositorio EPEL
    log_info "Instalando el repositorio EPEL..."
    dnf install -y epel-release

    # 3. Cambiar estado de SELinux a permissive
    log_info "Configurando SELinux en modo permissive..."
    if [ -f /etc/selinux/config ]; then
        sed -i 's/^SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
    fi
    if command -v setenforce >/dev/null 2>&1; then
        setenforce 0 || log_warn "No se pudo cambiar el estado de SELinux en caliente."
    fi

    # 4. Instalar paquetes requeridos
    log_info "Instalando paquetes: nagios, nagios-plugins-all, nrpe, nagios-plugins-nrpe, wireshark-qt, nmap, iftop, at, cronie, httpd, httpd-tools..."
    dnf install -y nagios nagios-plugins-all nrpe nagios-plugins-nrpe wireshark-qt nmap iftop at cronie httpd httpd-tools

    # 5. Configurar autenticación web de Nagios
    log_info "Configurando autenticación para Nagios (httpd)..."
    echo -e "${TITLE_COLOR}=== CREACIÓN DE CREDENCIALES NAGIOS ===${NC}"
    echo -e "A continuación, se le pedirá de forma interactiva que asigne una contraseña para el usuario administrador '${GREEN}nagiosadmin${NC}'"
    
    # Desactivamos momentáneamente 'set -e' en caso de que htpasswd no exista o falle la entrada
    set +e
    htpasswd -c /etc/nagios/passwd nagiosadmin
    if [ $? -ne 0 ]; then
        log_error "Hubo un error al asignar la contraseña para nagiosadmin."
        exit 1
    fi
    set -e

    # 6. Habilitar y arrancar servicios
    log_info "Habilitando y arrancando servicios principales (httpd, nagios, crond, atd, nrpe)..."
    systemctl enable --now httpd nagios crond atd nrpe

    # 7. Configurar firewalld
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

# ==========================================
# Fase 3: Pruebas y Verificación (Post-flight)
# ==========================================
phase3_postflight() {
    echo -e "\n${TITLE_COLOR}=== FASE 3: Pruebas y Verificación (Post-flight checks) ===${NC}"

    local errores_encontrados=0

    # 1. Comprobar servicios en estado active
    log_info "Verificando el estado de los servicios..."
    for servicio in httpd nagios crond atd nrpe; do
        if systemctl is-active --quiet "$servicio"; then
            echo -e "  - $servicio: ${GREEN}Activo y Corriendo${NC}"
        else
            echo -e "  - $servicio: ${RED}Inactivo o en Falla${NC}"
            errores_encontrados=$((errores_encontrados + 1))
        fi
    done

    # 2. Curl a Nagios
    log_info "Realizando petición HTTP al portal de Nagios..."
    # Se extrae únicamente el código HTTP devuelto
    HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" http://localhost/nagios/ || true)
    
    if [ "$HTTP_CODE" = "401" ]; then
        echo -e "  - Servidor Web (Nagios): ${GREEN}Responde Correctamente (HTTP 401 - Autenticación requerida)${NC}"
    elif [ "$HTTP_CODE" = "200" ]; then
        echo -e "  - Servidor Web (Nagios): ${GREEN}Responde Correctamente (HTTP 200 - OK)${NC}"
    else
        echo -e "  - Servidor Web (Nagios): ${RED}Fallo de respuesta (Código HTTP: $HTTP_CODE)${NC}"
        errores_encontrados=$((errores_encontrados + 1))
    fi

    # 3. Verificar crontab y atq
    log_info "Verificando estado de utilidades del sistema (crontab, atq)..."
    
    # crontab -l devuelve código 1 si no hay crontab, así que lo manejamos para que no lo cuente como error falso
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

    # 4. Mostrar resumen visual
    # Obtener IP de la máquina
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

# ==========================================
# Ejecución Principal (Main)
# ==========================================
main() {
    # Dar permisos de ejecución a este script por si acaso
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

# Llamada a la función principal
main
