# Tareas por PR — Admin de Redes Parte 2

Lee únicamente la sección de tu PR asignado.

> Antes de empezar: `git checkout <tu-rama>` y `bash setup.sh` para verificar el entorno.

---

## PC-1 — Correcciones Parte 1 · múltiples archivos

**Rama:** `feat/part1-corrections`
**Responsable:** Axel
**Prioridad:** ALTA — merge el domingo 10.

### Contexto

Este PR corrige las observaciones de la primera revisión del profesor.
Toca 4 archivos existentes. No se crean archivos nuevos.

**Regla importante:** Las funciones existentes en `utils.sh` NO se eliminan ni renombran.
Solo se agregan funciones nuevas. Esto evita romper los módulos de Parte 2 que se
desarrollan en paralelo.

---

### 1. Nuevas funciones en `src/lib/utils.sh`

---

#### `seleccionar_usuario`

Muestra una lista de usuarios del sistema con UID ≥ 1000 usando whiptail.
El usuario selecciona uno de la lista o cancela.

**Retorna:** nombre del usuario seleccionado en stdout. Retorna 1 si cancela.

```bash
# Ejemplo de uso en users.sh:
usuario=$(seleccionar_usuario) || return
```

**Implementación sugerida:**
```bash
seleccionar_usuario() {
    local usuarios=()
    while IFS=: read -r nombre _ uid _; do
        (( uid >= 1000 )) && usuarios+=("$nombre" "UID: $uid")
    done < /etc/passwd

    whiptail --title "Seleccionar Usuario" \
             --menu "Elige un usuario:" 20 50 10 \
             "${usuarios[@]}" \
             3>&1 1>&2 2>&3
}
```

---

#### `seleccionar_grupo`

Muestra una lista de grupos con GID ≥ 1000 usando whiptail.

**Retorna:** nombre del grupo seleccionado. Retorna 1 si cancela.

```bash
# Ejemplo de uso en groups.sh:
grupo=$(seleccionar_grupo) || return
```

**Implementación sugerida:**
```bash
seleccionar_grupo() {
    local grupos=()
    while IFS=: read -r nombre _ gid _; do
        (( gid >= 1000 )) && grupos+=("$nombre" "GID: $gid")
    done < /etc/group

    whiptail --title "Seleccionar Grupo" \
             --menu "Elige un grupo:" 20 50 10 \
             "${grupos[@]}" \
             3>&1 1>&2 2>&3
}
```

---

#### `input_campo <titulo> <prompt> [valor_inicial]`

Reemplaza `read -rp` con un cuadro de input visual de whiptail.

**Retorna:** texto ingresado en stdout. Retorna 1 si cancela.

```bash
nombre=$(input_campo "Alta de Usuario" "Nombre del nuevo usuario:") || return
```

---

#### `confirmar_whiptail <titulo> <pregunta>`

Reemplaza `confirmar_accion` con un cuadro de confirmación visual.

**Retorna:** 0 si confirma (Sí), 1 si cancela (No).

```bash
if confirmar_whiptail "Baja de Usuario" "¿Eliminar al usuario '$usuario'?"; then
    userdel "$usuario"
fi
```

---

### 2. Actualizar `src/users.sh`

Aplicar en las funciones que requieren seleccionar un usuario existente:
`usuario_baja`, `usuario_consulta`, `usuario_modificar`.

**Flujo actualizado para cada una:**
1. Llamar `seleccionar_usuario` para mostrar la lista con whiptail
2. Si el usuario cancela → `return`
3. Confirmar que el usuario aún existe con `usuario_existe` (validación de seguridad)
4. Continuar con el flujo normal de la función

**Función `usuario_alta` NO cambia** — está creando uno nuevo, no seleccionando uno existente.

**Reemplazar también:**
- `read -rp "..."` → `input_campo`
- `confirmar_accion` → `confirmar_whiptail`
- El menú principal de `menu_usuarios` puede usar `whiptail --menu`

**Casos a manejar:**
| Caso | Comportamiento |
|------|---------------|
| No hay usuarios con UID ≥ 1000 | `msg_warn "No hay usuarios disponibles."` y return |
| Usuario cancela la selección | return sin error |
| Usuario seleccionado ya no existe | `msg_err` y return |

---

### 3. Actualizar `src/groups.sh`

Aplicar `seleccionar_grupo` en: `grupo_baja`, `grupo_consulta`, `grupo_modificar`.

**Grupo alta NO cambia** — crea uno nuevo.

**Mismos criterios que users.sh:**
- Reemplazar `read` + `confirmar_accion` con helpers whiptail
- Manejar lista vacía (sin grupos con GID ≥ 1000)
- Validar existencia tras selección

---

### 4. Agregar opción Root en `src/processes.sh`

Agregar opción 3 al `menu_procesos`:

**Menú actualizado:**
```
1) Ver procesos del usuario (snapshot)
2) Monitor en tiempo real (top)
3) Ver procesos de root
0) Volver al menú principal
```

**Nueva función `procesos_root`:**
- Ejecuta directamente `ps aux --user root`
- Cuenta procesos y muestra `msg_ok` con el conteo
- Llama a `pausar` al final
- No solicita nombre de usuario (va directo a root)

---

### Cómo probar PC-1

```bash
bash -n src/lib/utils.sh
bash -n src/users.sh
bash -n src/groups.sh
bash -n src/processes.sh

sudo bash main.sh
# → Opción 1: verificar que baja/consulta/modificar muestran lista whiptail
# → Opción 2: verificar que baja/consulta/modificar muestran lista whiptail
# → Opción 3: verificar que opción 3 muestra procesos de root directamente
# → Navegar todo el menú y verificar que el diseño se ve profesional
```

---

---

## P2-1 — Automatización + Script de instalación

**Rama:** `feat/automation-module`
**Responsable:** Osvaldo
**Archivos:** `src/automation.sh`, `scripts/install_security.sh`

### Contexto

Este PR tiene dos entregables independientes. El script de instalación es
un utilitario que todo el equipo ejecuta en sus máquinas para tener las
herramientas de seguridad disponibles. El módulo de automatización es la
opción 4 del menú principal.

---

### Entregable 1: `src/automation.sh`

#### `menu_automatizacion`

```
1) Programar tarea con Cron (recurrente)
2) Programar tarea con At (puntual)
3) Ver tareas programadas en Cron
4) Ver cola de At
0) Volver al menú principal
```

---

#### `automatizar_cron`

Programa una tarea recurrente en el crontab del usuario root.

**Flujo completo:**
1. Solicitar comando a ejecutar (ej: `/usr/bin/df -h >> /var/log/disco.log`)
2. Solicitar programación — ofrecer opciones simples:
   ```
   1) Cada minuto          → * * * * *
   2) Cada hora            → 0 * * * *
   3) Diariamente (00:00)  → 0 0 * * *
   4) Semanalmente (lunes) → 0 0 * * 1
   5) Mensualmente (día 1) → 0 0 1 * *
   6) Personalizado        → pedir expresión cron manual
   ```
3. Mostrar la línea cron completa antes de confirmar
4. Agregar al crontab: `(crontab -l 2>/dev/null; echo "<cron> <comando>") | crontab -`
5. Confirmar con `msg_ok`

**Casos a manejar:**
| Caso | Comportamiento |
|------|---------------|
| Comando vacío | `msg_err` y return |
| `crontab` no disponible | `msg_err "Instalar cronie: dnf install cronie"` |
| Expresión personalizada vacía | `msg_err` y return |

---

#### `automatizar_at`

Programa una tarea puntual para ejecutarse una sola vez.

**Flujo completo:**
1. Verificar que `at` esté instalado (`command -v at`)
2. Solicitar comando a ejecutar
3. Solicitar fecha y hora en formato `HH:MM MM/DD/YYYY`
   (ej: `23:30 05/15/2026`)
4. Mostrar resumen antes de confirmar
5. Ejecutar: `echo "<comando>" | at <fecha>`
6. Confirmar con `msg_ok` y mostrar el job ID asignado

**Casos a manejar:**
| Caso | Comportamiento |
|------|---------------|
| `at` no instalado | `msg_err "Instalar at: dnf install at"` |
| Formato de fecha inválido | `at` lo detecta — capturar stderr y mostrar `msg_err` |
| Servicio `atd` no corriendo | `msg_warn "Iniciar servicio: systemctl start atd"` |

---

#### `listar_cron`

Muestra el crontab actual de root.

```bash
crontab -l 2>/dev/null || msg_warn "No hay tareas programadas en crontab."
```

---

#### `listar_at`

Muestra la cola de trabajos de at.

```bash
atq 2>/dev/null || msg_warn "No hay trabajos pendientes en at."
```

---

### Entregable 2: `scripts/install_security.sh`

Script que instala y configura las herramientas de seguridad en AlmaLinux 9.7.
Todo el equipo lo ejecuta una vez antes de la demo.

**Flujo del script:**

```bash
#!/usr/bin/env bash
# scripts/install_security.sh
# Uso: sudo bash scripts/install_security.sh
```

**Pasos a implementar:**

1. Verificar AlmaLinux 9
2. Verificar que se ejecuta como root
3. Actualizar el sistema: `dnf update -y`
4. Habilitar repositorio CRB: `dnf config-manager --set-enabled crb`
5. Instalar EPEL: `dnf install -y epel-release`
6. Poner SELinux en permissive:
   ```bash
   setenforce 0
   sed -i 's/SELINUX=.*/SELINUX=permissive/g' /etc/selinux/config
   ```
7. Instalar herramientas:
   ```bash
   dnf install -y nagios nagios-common nagios-plugins-all nrpe nagios-plugins-nrpe
   dnf install -y wireshark-qt nmap iftop at cronie
   ```
8. Configurar nagiosadmin (pedir contraseña interactivamente):
   ```bash
   htpasswd -c /etc/nagios/passwd nagiosadmin
   ```
9. Habilitar y arrancar servicios:
   ```bash
   systemctl enable --now httpd nagios
   ```
10. Abrir firewall para http:
    ```bash
    firewall-cmd --permanent --add-service=http
    firewall-cmd --reload
    ```
11. Verificar que Nagios responde: `curl -s http://localhost/nagios | grep -q Nagios`
12. Mostrar resumen final con URLs y credenciales

**Casos a manejar:**
- Si un paso falla, mostrar el error y continuar (no usar `set -e`)
- Al final indicar qué pasos tuvieron éxito y cuáles fallaron

---

### Cómo probar P2-1

```bash
bash -n src/automation.sh

# Probar install script:
sudo bash scripts/install_security.sh
# → Debe completarse sin errores fatales
# → Nagios debe estar corriendo: systemctl status nagios

# Probar módulo de automatización:
sudo bash main.sh
# → Opción 4 (Automatización)
# → Opción 1: programar "echo hola >> /tmp/test.log" cada minuto
# → Verificar: crontab -l | grep "echo hola"
# → Opción 3: debe mostrar la tarea recién creada
# → Opción 2: programar tarea con at para 1 minuto adelante
# → Verificar: atq
```

---

---

## P2-2 — Respaldo de información

**Rama:** `feat/backup-module`
**Responsable:** Imanol
**Archivo:** `src/backup.sh`

### Contexto

Módulo para comprimir carpetas del sistema en dos formatos.
No modifica nada existente — solo crea el archivo nuevo.

---

#### `menu_respaldo`

```
1) Respaldo con Gzip  (.tar.gz)
2) Respaldo con Bzip2 (.tar.bz2)
0) Volver al menú principal
```

---

#### `respaldar_gzip` y `respaldar_bzip2`

Ambas funciones siguen el mismo flujo. La única diferencia es el flag de `tar`
(`-czf` para gzip, `-cjf` para bzip2) y la extensión del archivo resultante.

**Flujo completo:**
1. Solicitar carpeta origen (ej: `/home/anthony`)
2. Verificar que la carpeta origen existe (`[[ -d "$origen" ]]`)
3. Si no existe → `msg_err "La carpeta '$origen' no existe."` y return
4. Solicitar ruta de destino (ej: `/backups`)
5. Verificar que la ruta de destino existe y tiene permisos de escritura
6. Si no existe → preguntar con `confirmar_accion` si se desea crearla
7. Generar nombre automático del archivo:
   ```bash
   nombre="backup_$(basename "$origen")_$(date +%Y%m%d_%H%M%S).tar.gz"
   ```
8. Ejecutar tar con barra de progreso:
   ```bash
   tar -czf "$destino/$nombre" "$origen" 2>/dev/null
   ```
9. Verificar que el archivo se creó correctamente (`[[ -f "$destino/$nombre" ]]`)
10. Mostrar tamaño del respaldo: `du -sh "$destino/$nombre"`
11. Confirmar con `msg_ok "Respaldo creado: $destino/$nombre (tamaño: X)"`
12. Llamar a `pausar`

**Casos a manejar:**
| Caso | Comportamiento |
|------|---------------|
| Carpeta origen no existe | `msg_err` y return |
| Ruta destino no existe | ofrecer crearla con `mkdir -p` |
| Sin espacio suficiente | `tar` fallará — capturar `$?` y mostrar `msg_err` |
| Sin permisos en destino | `msg_err "Sin permisos de escritura en '$destino'"` |
| Carpeta origen vacía | continuar normalmente (tar crea archivo vacío) |

---

### Cómo probar P2-2

```bash
bash -n src/backup.sh

sudo bash main.sh
# → Opción 5 (Respaldo)

# Prueba 1 — gzip exitoso
# → Opción 1, origen: /etc, destino: /tmp
# → Verificar: ls -lh /tmp/backup_etc_*.tar.gz

# Prueba 2 — bzip2 exitoso
# → Opción 2, origen: /var/log, destino: /tmp
# → Verificar: ls -lh /tmp/backup_log_*.tar.bz2
# → Verificar que se puede extraer: tar -tjf /tmp/backup_log_*.tar.bz2 | head

# Prueba 3 — carpeta inexistente
# → Opción 1, origen: /carpetafalsa999
# → Debe mostrar [ERROR]

# Prueba 4 — destino inexistente
# → Opción 1, origen: /etc, destino: /ruta/que/no/existe
# → Debe preguntar si crear la carpeta
```

---

---

## P2-3 — Seguridad / Monitoreo

**Rama:** `feat/security-module`
**Responsable:** Diego
**Archivo:** `src/security.sh`

### Contexto

Módulo que abre herramientas de monitoreo. Asume que
`scripts/install_security.sh` ya se ejecutó en la máquina.
Si una herramienta no está instalada, muestra `msg_err` con instrucción de
correr el script.

**Coordinación:** ejecuta `sudo bash scripts/install_security.sh` antes de
comenzar a probar este módulo.

---

#### `menu_seguridad`

```
1) Nagios     (dashboard web)
2) Wireshark  (captura de tráfico)
3) Nmap / iftop (monitoreo de red)
0) Volver al menú principal
```

---

#### `abrir_nagios`

**Flujo completo:**
1. Verificar que `nagios` está instalado: `command -v nagios`
2. Si no está → `msg_err "Nagios no instalado. Ejecuta: sudo bash scripts/install_security.sh"` y return
3. Verificar que el servicio `nagios` está corriendo: `systemctl is-active nagios`
4. Si no está corriendo → intentar iniciarlo: `systemctl start nagios httpd`
5. Verificar que `httpd` está corriendo
6. Mostrar `msg_ok "Abriendo Nagios en el navegador..."`
7. Mostrar URL: `http://localhost/nagios` y credenciales: usuario `nagiosadmin`
8. Abrir en navegador: `xdg-open http://localhost/nagios &`
9. Llamar a `pausar`

**Casos a manejar:**
| Caso | Comportamiento |
|------|---------------|
| Nagios no instalado | `msg_err` con instrucción |
| Servicio caído | intentar `systemctl start` y reportar resultado |
| `xdg-open` no disponible | mostrar URL para abrir manualmente |

---

#### `abrir_wireshark`

**Flujo completo:**
1. Verificar que `wireshark` está instalado: `command -v wireshark`
2. Si no → `msg_err` con instrucción y return
3. `msg_warn "Wireshark se abrirá en una ventana separada."`
4. Lanzar en segundo plano: `wireshark &`
5. `msg_ok "Wireshark iniciado. Cierra la ventana para volver al script."`
6. Llamar a `pausar`

---

#### `menu_monitor_red`

Submenú para elegir entre Nmap y iftop:

```
1) Nmap  — escaneo de puertos y hosts
2) iftop — monitor de tráfico en tiempo real
0) Volver
```

**`ejecutar_nmap`:**
1. Verificar instalación
2. Solicitar objetivo: IP, rango (ej: `192.168.1.0/24`) o `localhost`
3. Ofrecer tipo de escaneo:
   ```
   1) Escaneo básico de puertos    → nmap <objetivo>
   2) Detección de versiones       → nmap -sV <objetivo>
   3) Escaneo de red local         → nmap -sn <objetivo>
   ```
4. Ejecutar y mostrar resultado en terminal
5. Llamar a `pausar`

**`ejecutar_iftop`:**
1. Verificar instalación
2. `msg_warn "iftop se ejecutará en tiempo real. Presiona 'q' para salir."`
3. Ejecutar: `iftop`
4. Llamar a `pausar` al regresar

---

### Cómo probar P2-3

```bash
# Prerequisito: ejecutar primero
sudo bash scripts/install_security.sh

bash -n src/security.sh

sudo bash main.sh
# → Opción 6 (Seguridad)

# Prueba 1 — Nagios
# → Opción 1: debe abrir http://localhost/nagios en el navegador
# → Verificar: systemctl status nagios debe estar activo

# Prueba 2 — Wireshark
# → Opción 2: debe abrir la interfaz gráfica de Wireshark
# → Verificar que el proceso existe: pgrep wireshark

# Prueba 3 — Nmap
# → Opción 3 → Opción 1, objetivo: localhost
# → Debe mostrar puertos abiertos

# Prueba 4 — iftop
# → Opción 3 → Opción 2
# → Debe abrir monitor en tiempo real, salir con q

# Prueba 5 — herramienta no instalada (simulación)
# Renombrar temporalmente: mv /usr/bin/nmap /usr/bin/nmap.bak
# → Debe mostrar [ERROR] con instrucción
# Restaurar: mv /usr/bin/nmap.bak /usr/bin/nmap
```

---

---

## P2-INT — Integración Parte 2

**Rama:** `feat/part2-integration`
**Responsable:** Anthony
**Archivo:** `main.sh`, `deps.txt`
**Prioridad:** ALTA — merge el último.

### Contexto

Integra los 3 módulos nuevos en `main.sh` y aplica whiptail al menú principal.
Este PR se codifica cuando P2-1, P2-2 y P2-3 ya están en develop.
Durante los días de coding (antes de que los módulos estén listos),
Anthony se enfoca en revisar los otros PRs.

---

### Cambios en `main.sh`

**1. Agregar sources de nuevos módulos:**
```bash
source "$SCRIPT_DIR/src/automation.sh"
source "$SCRIPT_DIR/src/backup.sh"
source "$SCRIPT_DIR/src/security.sh"
```

**2. Actualizar menú principal con whiptail:**

```bash
main() {
    while true; do
        opcion=$(whiptail --title "Administración de Redes" \
                          --menu "Selecciona una opción:" 20 60 9 \
                          "1" "Usuarios" \
                          "2" "Grupos" \
                          "3" "Procesos" \
                          "4" "Automatización de tareas" \
                          "5" "Respaldo de información" \
                          "6" "Seguridad / Monitoreo" \
                          "0" "Salir" \
                          3>&1 1>&2 2>&3) || exit 0

        case $opcion in
            1) menu_usuarios ;;
            2) menu_grupos   ;;
            3) menu_procesos ;;
            4) menu_automatizacion ;;
            5) menu_respaldo ;;
            6) menu_seguridad ;;
            0) exit 0 ;;
        esac
    done
}
```

**3. Actualizar `deps.txt`** con los nuevos paquetes documentados en `PLANNING_P2.md`.

---

### Cómo probar P2-INT

```bash
bash -n main.sh

sudo bash main.sh
# → Verificar que el menú principal muestra las 6 opciones con whiptail
# → Navegar a cada opción y confirmar que los módulos cargan
# → Opción 0: salir limpiamente
# → Prueba sin root: bash main.sh → debe mostrar "Acceso denegado"
```

---

## Notas generales para todos los PRs

- Nunca usar `exit` dentro de un módulo — solo `return`
- El único `exit` permitido está en `main.sh`
- Si un comando del sistema falla, capturar `$?` y reportar con `msg_err`
- Probar siempre `bash -n <archivo>` antes de abrir el PR
- Verificar también con `source` que no hay errores de runtime
- La descripción del PR en GitHub debe estar en español con secciones:
  qué hace, funciones implementadas, cómo probarlo, notas adicionales