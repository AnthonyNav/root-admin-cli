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
    verificar_comando httpd || return
    verificar_comando xdg-open || return

    verificar_servicio nagios || return
    verificar_servicio httpd || return

    print_header "Nagios"

    echo "URL: $url"
    echo "Usuario: nagiosadmin"
    echo ""

    msg_ok "Intentando abrir Nagios en el navegador..."
    xdg-open "$url" >/dev/null 2>&1 &

    msg_warn "Si el navegador no abre, entra manualmente a: $url"
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
    local opcion

    verificar_comando nmap || return

    print_header "Nmap"

    read -rp "Objetivo a escanear, ejemplo localhost, 192.168.1.1 o 192.168.1.0/24: " objetivo

    if [[ -z "$objetivo" ]]; then
        msg_err "Debes ingresar un objetivo."
        pausar
        return
    fi

    echo ""
    echo "Tipo de escaneo:"
    echo "1) Escaneo basico"
    echo "2) Deteccion de versiones"
    echo "3) Escaneo red local"
    echo "0) Volver"
    echo ""

    read -rp "Selecciona una opcion: " opcion
    echo ""

    case "$opcion" in
        1)
            msg_ok "Ejecutando: nmap $objetivo"
            nmap "$objetivo"
            ;;
        2)
            msg_ok "Ejecutando: nmap -sV $objetivo"
            nmap -sV "$objetivo"
            ;;
        3)
            msg_ok "Ejecutando: nmap -sn $objetivo"
            nmap -sn "$objetivo"
            ;;
        0)
            return
            ;;
        *)
            msg_err "Opcion invalida."
            ;;
    esac

    pausar
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

        echo "1) Nmap"
        echo "2) iftop"
        echo "0) Volver"
        echo ""

        read -rp "Selecciona una opcion: " opcion

        case "$opcion" in
            1)
                ejecutar_nmap
                ;;
            2)
                ejecutar_iftop
                ;;
            0)
                return
                ;;
            *)
                msg_err "Opcion invalida."
                pausar
                ;;
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

        echo "1) Abrir Nagios"
        echo "2) Abrir Wireshark"
        echo "3) Monitor de red: Nmap o iftop"
        echo "0) Volver al menu principal"
        echo ""

        read -rp "Selecciona una opcion: " opcion

        case "$opcion" in
            1)
                abrir_nagios
                ;;
            2)
                abrir_wireshark
                ;;
            3)
                menu_monitor_red
                ;;
            0)
                return
                ;;
            *)
                msg_err "Opcion invalida."
                pausar
                ;;
        esac
    done
}
