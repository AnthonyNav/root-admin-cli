#!/usr/bin/env bash
#
# src/security.sh — Modulo de seguridad y monitoreo
# Rama: feat/security-module
#
# Requiere que scripts/install_security.sh ya haya sido ejecutado.

# ─── verificar_comando <comando> ──────────────────────────────────────────────
# Verifica que la herramienta exista antes de usarla.
verificar_comando() {
    local comando="$1"

    command -v "$comando" >/dev/null 2>&1 || {
        msg_err "No instalado. Ejecuta: sudo bash scripts/install_security.sh"
        return 1
    }

    return 0
}

# ─── verificar_servicio <servicio> ────────────────────────────────────────────
# Verifica si un servicio esta activo; si no, intenta iniciarlo.
verificar_servicio() {
    local servicio="$1"

    verificar_comando systemctl || return 1

    if systemctl is-active --quiet "$servicio"; then
        msg_ok "Servicio $servicio activo."
        return 0
    fi

    msg_warn "Servicio $servicio detenido. Intentando iniciar..."

    if systemctl start "$servicio"; then
        msg_ok "Servicio $servicio iniciado correctamente."
        return 0
    fi

    msg_err "No se pudo iniciar el servicio $servicio."
    return 1
}

# ─── abrir_nagios ─────────────────────────────────────────────────────────────
# Verifica Nagios y HTTPD, intenta iniciar servicios y abre navegador.
abrir_nagios() {
    local url="http://localhost/nagios"

    verificar_comando nagios || return
    verificar_comando httpd  || return

    verificar_servicio nagios || return
    verificar_servicio httpd  || return

    print_header "Nagios"

    echo "URL: $url"
    echo "Usuario: nagiosadmin"
    echo ""

    if command -v xdg-open >/dev/null 2>&1; then
        msg_ok "Intentando abrir Nagios en el navegador..."

        # Si corremos como root vía sudo, abrir el navegador como el usuario original
        # para que tenga acceso al display gráfico
        if [[ -n "$SUDO_USER" && "$SUDO_USER" != "root" ]]; then
            sudo -u "$SUDO_USER" xdg-open "$url" >/dev/null 2>&1 &
        else
            xdg-open "$url" >/dev/null 2>&1 &
        fi
    else
        msg_warn "xdg-open no disponible. Abre manualmente: $url"
    fi

    pausar
}

# ─── abrir_wireshark ──────────────────────────────────────────────────────────
# Lanza Wireshark en segundo plano para no bloquear el script.
abrir_wireshark() {
    verificar_comando wireshark || return

    print_header "Wireshark"

    msg_ok "Lanzando Wireshark en segundo plano..."
    wireshark >/dev/null 2>&1 &

    msg_ok "Wireshark fue abierto. Puedes seguir usando el menu."
    pausar
}

# ─── ejecutar_nmap ────────────────────────────────────────────────────────────
# Pide objetivo y tipo de escaneo.
ejecutar_nmap() {
    local objetivo
    local tipo

    verificar_comando nmap || return

    print_header "Nmap"

    objetivo=$(input_campo "Objetivo: localhost, 192.168.1.1 o 192.168.1.0/24")

    if [[ -z "$objetivo" ]]; then
        msg_err "Debes ingresar un objetivo."
        pausar
        return
    fi

    while true; do
        tipo=$(gum choose \
            --header "Tipo de escaneo para: $objetivo" \
            --cursor "▸ " \
            "Escaneo básico de puertos" \
            "Detección de versiones (-sV)" \
            "Escaneo de red local (-sn)" \
            "← Volver al menú anterior")

        [[ -z "$tipo" || "$tipo" == "← Volver al menú anterior" ]] && return

        case "$tipo" in
            "Escaneo básico de puertos")
                msg_ok "Ejecutando: nmap $objetivo"
                nmap "$objetivo"
                ;;
            "Detección de versiones (-sV)")
                msg_ok "Ejecutando: nmap -sV $objetivo"
                nmap -sV "$objetivo"
                ;;
            "Escaneo de red local (-sn)")
                msg_ok "Ejecutando: nmap -sn $objetivo"
                nmap -sn "$objetivo"
                ;;
        esac
        pausar
    done
}

# ─── ejecutar_iftop ───────────────────────────────────────────────────────────
# Abre monitor en tiempo real. Con q regresa al menu.
ejecutar_iftop() {
    verificar_comando iftop || return

    print_header "iftop"

    msg_warn "Se abrira iftop en tiempo real."
    msg_warn "Presiona q para salir y regresar al menu."
    pausar

    iftop

    msg_ok "Regresaste al menu de monitoreo."
    pausar
}

# ─── menu_monitor_red ─────────────────────────────────────────────────────────
# Submenu para elegir entre nmap o iftop.
menu_monitor_red() {
    local opcion

    while true; do
        clear
        print_header "Monitor de Red"
        opcion=$(gum choose \
            --header "Selecciona una herramienta:" \
            --cursor "▸ " \
            "Nmap — escaneo de puertos y hosts" \
            "iftop — monitor de tráfico en tiempo real" \
            "← Volver")

        [[ -z "$opcion" || "$opcion" == "← Volver" ]] && return

        case "$opcion" in
            "Nmap — escaneo de puertos y hosts")         ejecutar_nmap  ;;
            "iftop — monitor de tráfico en tiempo real") ejecutar_iftop ;;
        esac
    done
}

# ─── menu_seguridad ───────────────────────────────────────────────────────────
# Menu principal del modulo de seguridad.
menu_seguridad() {
    local opcion

    while true; do
        clear
        print_header "Seguridad / Monitoreo"
        opcion=$(gum choose \
            --header "Selecciona una opción:" \
            --cursor "▸ " \
            "Abrir Nagios (dashboard web)" \
            "Abrir Wireshark (captura de tráfico)" \
            "Monitor de red: Nmap o iftop" \
            "← Volver al menú principal")

        [[ -z "$opcion" || "$opcion" == "← Volver al menú principal" ]] && return

        case "$opcion" in
            "Abrir Nagios (dashboard web)")          abrir_nagios     ;;
            "Abrir Wireshark (captura de tráfico)")  abrir_wireshark  ;;
            "Monitor de red: Nmap o iftop")          menu_monitor_red ;;
        esac
    done
}
