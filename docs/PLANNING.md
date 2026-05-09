# Planeación del Proyecto — Admin de Redes Parte 2

## Estado del proyecto

### Parte 1 — Completada ✓

| Módulo | Archivo | Responsable | Estado |
|--------|---------|-------------|--------|
| Helpers compartidos | `src/lib/utils.sh` | Anthony | ✓ Mergeado |
| Gestión de usuarios | `src/users.sh` | Diego | ✓ Mergeado |
| Gestión de grupos | `src/groups.sh` | Imanol | ✓ Mergeado |
| Gestión de procesos | `src/processes.sh` | Osvaldo | ✓ Mergeado |
| Core / entrypoint | `main.sh` | Axel | ✓ Mergeado |

### Parte 2 — En desarrollo

Agrega 3 nuevas opciones al menú principal y corrige observaciones de la primera revisión.

---

## Correcciones de Parte 1 (PC-1)

Observaciones recibidas en la primera revisión del proyecto:

1. **Listar usuarios/grupos antes de operar** — en baja, consulta y modificación de usuarios y grupos, el operador debe ver la lista de recursos disponibles en lugar de escribir el nombre a ciegas.
2. **Opción Root en procesos** — agregar opción 3 en el submenú de procesos que muestre directamente los procesos de root sin solicitar nombre.
3. **Diseño profesional** — mejorar la apariencia visual del script usando herramientas TUI disponibles en AlmaLinux 9.

**Solución de diseño adoptada: `whiptail`**

`whiptail` viene preinstalada en AlmaLinux 9 como parte del paquete `newt`. No requiere instalación adicional ni agregar dependencias al proyecto. Permite:

- `--menu` → listas seleccionables de usuarios y grupos
- `--inputbox` → campos de entrada con ventana visual
- `--yesno` → confirmaciones con botones Sí/No
- `--msgbox` → mensajes con ventana

Todas las correcciones van en un solo PR asignado a Axel.

---

## Parte 2 — Nuevas funcionalidades

### Opción 4 — Automatización de tareas

| Sub-opción | Herramienta | Descripción |
|------------|-------------|-------------|
| 1) Cron | `crontab` | Programar tarea recurrente (diaria, semanal, etc.) |
| 2) At | `at` | Programar tarea puntual en fecha/hora específica |

El módulo pide al usuario la tarea a ejecutar y la fecha/hora de ejecución.

### Opción 5 — Respaldo de información

| Sub-opción | Herramienta | Descripción |
|------------|-------------|-------------|
| 1) Tar-gzip | `tar -czf` | Comprimir carpeta con gzip (.tar.gz) |
| 2) Tar-bzip2 | `tar -cjf` | Comprimir carpeta con bzip2 (.tar.bz2) |

El módulo pide la carpeta origen y la ruta de destino del respaldo.

### Opción 6 — Seguridad / Monitoreo

| Sub-opción | Herramienta | Modo |
|------------|-------------|------|
| a) Nagios | `nagios` + `httpd` | Abre el dashboard en el navegador |
| b) Wireshark | `wireshark` | Lanza la interfaz gráfica |
| c) Nmap / iftop | `nmap` / `iftop` | Ejecuta en la misma terminal |

---

## Decisiones técnicas

### Instalación de herramientas de seguridad

Las herramientas del módulo de seguridad (Nagios, Wireshark, Nmap, iftop) requieren instalación previa en cada máquina. La docente advirtió sobre problemas de compatibilidad con instalaciones desde código fuente en AlmaLinux 9.

**Solución adoptada:** instalación vía repositorio EPEL, que resuelve automáticamente los plugins y dependencias sin necesidad de compilar desde fuente ni cambiar la versión del sistema operativo.

```bash
# Los pasos clave del script de instalación
dnf config-manager --set-enabled crb
dnf install -y epel-release
setenforce 0  # SELinux permissive (requerido por Nagios)
dnf install -y nagios nagios-common nagios-plugins-all nrpe wireshark-qt nmap iftop
```

**Versión del sistema:** AlmaLinux 9.7 — no se requiere downgrade.

Osvaldo crea `scripts/install_security.sh` que el equipo completo ejecuta antes de hacer la demo. Este script va en su mismo PR de automatización.

### whiptail como capa de diseño

Las funciones de whiptail se agregan a `src/lib/utils.sh` como helpers nuevos. Las funciones existentes (`msg_ok`, `msg_err`, etc.) se mantienen sin cambios para no romper compatibilidad con los módulos de Parte 2 que se desarrollan en paralelo.

### Módulos nuevos son completamente independientes

`automation.sh`, `backup.sh` y `security.sh` son archivos nuevos que no tocan nada de Parte 1. Solo `main.sh` los integra al final (PR de Anthony). Esto garantiza trabajo en paralelo sin bloqueos.

---

## Estructura final del repositorio

```
admin-redes/
├── README.md
├── main.sh                      ← P2-INT Anthony · opciones 4/5/6 + whiptail menú
├── setup.sh
├── deps.txt                     ← actualizar con nuevas dependencias
├── src/
│   ├── lib/
│   │   └── utils.sh             ← PC-1 Axel · nuevas funciones whiptail
│   ├── users.sh                 ← PC-1 Axel · listar usuarios + whiptail
│   ├── groups.sh                ← PC-1 Axel · listar grupos + whiptail
│   ├── processes.sh             ← PC-1 Axel · opción 3 Root
│   ├── automation.sh            ← P2-1 Osvaldo · NUEVO
│   ├── backup.sh                ← P2-2 Imanol · NUEVO
│   └── security.sh              ← P2-3 Diego · NUEVO
├── scripts/
│   └── install_security.sh      ← P2-1 Osvaldo · NUEVO
├── tests/
│   ├── test_utils.sh
│   ├── test_groups.sh
│   ├── test_processes.sh
│   └── test_users.sh
└── docs/
    ├── PLANNING.md              ← Parte 1
    ├── PLANNING_P2.md           ← estás aquí
    ├── RESPONSIBILITIES.md      ← Parte 1
    ├── RESPONSIBILITIES_P2.md
    ├── TASKS.md                 ← Parte 1
    ├── TASKS_P2.md
    ├── COLLABORATION_RULES.md
    └── MANUAL_TESTS.md
```

---

## Dependencias entre PRs

```
PC-1 (Axel correcciones)     → merge primero (día 3)
                               Modifica utils.sh — los nuevos módulos
                               pueden usar sus helpers una vez mergeado.

P2-1 (Osvaldo automatización) → paralelo, sin dependencias
P2-2 (Imanol respaldo)        → paralelo, sin dependencias
P2-3 (Diego seguridad)        → paralelo, requiere install_security.sh
                               de Osvaldo ejecutado en la máquina

P2-INT (Anthony integración)  → merge último (día 5)
                               Sourcéa los 3 nuevos módulos en main.sh
                               y agrega las opciones 4/5/6 al menú.
```

**Nota para Diego:** el módulo de seguridad asume que `scripts/install_security.sh`
de Osvaldo ya se ejecutó en la máquina. Si una herramienta no está instalada,
el módulo muestra `msg_err` con instrucción de correr el script.

---

## Nuevas dependencias del sistema

A agregar en `deps.txt`:

| Paquete | Proveedor | Necesario para |
|---------|-----------|----------------|
| `at` | base | Automatización puntual |
| `cronie` | base | Cron (puede ya estar) |
| `tar` | base | Respaldos |
| `nagios` | EPEL | Monitoreo |
| `nagios-plugins-all` | EPEL | Monitoreo |
| `nrpe` | EPEL | Monitoreo |
| `wireshark-qt` | base | Captura de tráfico |
| `nmap` | base | Escaneo de red |
| `iftop` | EPEL | Monitor de tráfico en tiempo real |