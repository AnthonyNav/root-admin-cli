# Planeación del Proyecto — Admin de Redes Parte 1

## Descripción

Script interactivo en Bash que permite a un administrador de sistemas gestionar usuarios, grupos y visualizar procesos desde un menú de texto, verificando previamente que quien lo ejecuta tiene privilegios de root.

## Funcionalidades del script

### Verificación de acceso
- Si el proceso se ejecuta como root → muestra el menú principal.
- Si NO es root → imprime `Acceso denegado` y termina con código de salida 1.

### Menú 1 — Usuarios
| Opción         | Comando(s) Linux                          |
|----------------|-------------------------------------------|
| Alta           | `useradd`, `passwd` / `chpasswd`          |
| Baja           | `userdel` / `userdel -r`                  |
| Consulta       | `id`, `getent passwd`, `chage -l`         |
| Modificaciones | `usermod`, `chage`, `passwd`              |

Modificaciones incluye: fecha de caducidad, directorio home, estado de cuenta (lock/unlock), shell.

### Menú 2 — Grupos
| Opción         | Comando(s) Linux                          |
|----------------|-------------------------------------------|
| Alta           | `groupadd`                                |
| Baja           | `groupdel`                                |
| Consulta       | `getent group`                            |
| Modificaciones | `groupmod`, `gpasswd`                     |

Modificaciones incluye: renombrar grupo, agregar/quitar miembros.

### Menú 3 — Procesos del usuario consultado
| Vista         | Comando                                   |
|---------------|-------------------------------------------|
| Snapshot      | `ps aux --user <usuario>`                 |
| Tiempo real   | `top -u <usuario>`                        |

---

## Decisiones técnicas

### Plataforma: AlmaLinux 9

El proyecto utiliza exclusivamente **AlmaLinux 9** por las siguientes razones:

1. **Alineación con los materiales de clase.** La asignatura utilizará herramientas como Nagios, Cacti y OpenManage. Los materiales del profesor, rutas de instalación y comandos de configuración están basados en RHEL/AlmaLinux. Seguir la misma distribución evita divergencias en los laboratorios.

2. **Soporte nativo de Dell OpenManage (OMSA).** OpenManage Server Administrator tiene soporte oficial y paquetes RPM mantenidos por Dell para RHEL 8/9 y sus clones (AlmaLinux, Rocky). En distribuciones Debian/Ubuntu, la instalación requiere repositorios no oficiales y pasos adicionales de configuración.

3. **Entorno empresarial RHEL-compatible.** AlmaLinux 9 es un clon binario de RHEL 9, el estándar de facto en entornos corporativos de administración de servidores Linux.

4. **Nota sobre Cacti y Nagios.** Para ser exactos: tanto Cacti como Nagios Core funcionan en Debian/Ubuntu sin diferencias significativas. El argumento real para usar AlmaLinux en este caso es la coherencia con el entorno de clase, no una incompatibilidad técnica.

### Bash en lugar de Python u otro lenguaje

El script utiliza comandos del sistema (`useradd`, `groupmod`, `chage`, etc.) directamente sin capas de abstracción. Bash es el lenguaje natural para este tipo de administración de sistemas y no requiere instalar intérpretes adicionales.

---

## Dependencias del sistema

Declaradas en `deps.txt`. Todos los paquetes están preinstalados en una instalación mínima de AlmaLinux 9.

| Paquete        | Comandos que provee                                    |
|----------------|--------------------------------------------------------|
| `shadow-utils` | `useradd`, `userdel`, `usermod`, `groupadd`, `groupdel`, `chage`, `passwd` |
| `procps-ng`    | `ps`, `top`                                            |
| `coreutils`    | `id`, `cut`, `sort`, `grep`                            |
| `util-linux`   | `getopt`, utilidades generales                         |
| `glibc-common` | `getent`                                               |

Verificar con: `bash setup.sh`

---

## Supuestos técnicos

- El script siempre se ejecuta en una sesión de terminal interactiva.
- El sistema tiene `bash` en `/usr/bin/env bash` (AlmaLinux 9: `/bin/bash`, enlazado).
- SELinux puede estar en modo `enforcing` en AlmaLinux 9. Si se presentan problemas de permisos con comandos de administración, verificar con `getenforce`.
- No se asume que existe un entorno gráfico ni `sudo` configurado; se documenta uso directo como root.

---

## Estructura de módulos

| Módulo             | Archivo             | PR   | Depende de     |
|--------------------|---------------------|------|----------------|
| Helpers compartidos| `src/lib/utils.sh`  | #1   | ninguno        |
| Entrypoint / core  | `main.sh`           | #2   | todos los demás|
| Gestión usuarios   | `src/users.sh`      | #3   | #1 utils       |
| Gestión grupos     | `src/groups.sh`     | #4   | #1 utils       |
| Procesos           | `src/processes.sh`  | #5   | #1 utils       |

Ver orden de merge en `docs/RESPONSIBILITIES.md`.