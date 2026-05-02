# Tareas por PR — Admin de Redes Parte 1

Este documento describe exactamente qué debe implementar cada miembro del equipo.
Lee únicamente la sección de tu PR asignado.

> Antes de empezar: clona el repo, muévete a tu rama y corre `bash setup.sh` para
> verificar que tu entorno de AlmaLinux 9 tiene todo lo necesario.

---

## PR #1 — utils/lib · `src/lib/utils.sh`

**Rama:** `feat/utils-lib`  
**Responsable:** Anthony  
**Prioridad:** ALTA — merge el lunes. El resto del equipo depende de este archivo.

### Contexto

Este archivo es una librería de helpers. No tiene lógica de negocio propia — solo
provee funciones reutilizables que los demás módulos llaman. Todos los módulos
asumen que estas funciones existen con exactamente estos nombres.

> Si necesitas renombrar alguna función, avisa al equipo ANTES de hacer push.
> Cambiar un nombre sin avisar rompe los otros cuatro módulos.

### Funciones a implementar

---

#### `print_header <título>`

Imprime un encabezado visual que separa visualmente cada sección del menú.

**Comportamiento esperado:**
- Recibe un string como argumento
- Imprime una línea en blanco, luego el título resaltado, luego otra línea en blanco
- Usa color cian o similar para destacarlo del resto del output

**Ejemplo de salida:**
```
╔══════════════════════════════════════════╗
  Gestión de Usuarios
╚══════════════════════════════════════════╝
```

**Casos a manejar:**
- Si no se pasa argumento, imprimir encabezado vacío (no romper)

---

#### `msg_ok <mensaje>`

Imprime un mensaje de éxito en color verde con prefijo `[OK]`.

**Comportamiento esperado:**
- Salida a stdout
- Color verde
- Prefijo: `[OK]`

**Ejemplo de salida:**
```
[OK] Usuario 'juan' creado correctamente.
```

---

#### `msg_err <mensaje>`

Imprime un mensaje de error en color rojo con prefijo `[ERROR]`.

**Comportamiento esperado:**
- Salida a **stderr** (no stdout)
- Color rojo
- Prefijo: `[ERROR]`

**Ejemplo de salida:**
```
[ERROR] El usuario 'juan' no existe.
```

---

#### `msg_warn <mensaje>`

Imprime un aviso en color amarillo con prefijo `[AVISO]`.

**Comportamiento esperado:**
- Salida a stdout
- Color amarillo
- Prefijo: `[AVISO]`

**Ejemplo de salida:**
```
[AVISO] Opción inválida. Intenta de nuevo.
```

---

#### `confirmar_accion <pregunta>`

Solicita confirmación al usuario antes de ejecutar una acción irreversible.

**Comportamiento esperado:**
- Muestra la pregunta seguida de `[s/N]: `
- Lee la respuesta del usuario
- Retorna **0** si el usuario escribe `s` o `S`
- Retorna **1** para cualquier otra entrada (incluyendo Enter vacío)
- El default es NO (si el usuario solo presiona Enter, se cancela)

**Ejemplo de uso en otro módulo:**
```bash
if confirmar_accion "¿Deseas eliminar el usuario 'juan'?"; then
    userdel juan
    msg_ok "Usuario eliminado."
else
    msg_warn "Operación cancelada."
fi
```

**Casos a manejar:**
- Respuesta vacía (solo Enter) → retorna 1 (no confirma)
- Respuesta `S` mayúscula → retorna 0 (confirma)
- Respuesta `si`, `yes`, `n`, `no` → retorna 1 (solo acepta `s` o `S`)

---

#### `usuario_existe <nombre_usuario>`

Verifica si un usuario existe en el sistema.

**Comportamiento esperado:**
- Retorna **0** si el usuario existe
- Retorna **1** si no existe
- No imprime nada (silencioso)

**Implementación sugerida:** usar el comando `id`

**Ejemplo de uso en otro módulo:**
```bash
if usuario_existe "juan"; then
    echo "El usuario existe"
else
    msg_err "El usuario 'juan' no existe en el sistema."
fi
```

**Casos a manejar:**
- Nombre vacío → retorna 1
- Usuario del sistema (root, nobody) → debe retornar 0 correctamente

---

#### `grupo_existe <nombre_grupo>`

Verifica si un grupo existe en el sistema.

**Comportamiento esperado:**
- Retorna **0** si el grupo existe
- Retorna **1** si no existe
- No imprime nada (silencioso)

**Implementación sugerida:** usar `getent group`

**Casos a manejar:**
- Nombre vacío → retorna 1
- Grupos del sistema (root, wheel, sudo) → debe retornar 0 correctamente

---

#### `pausar`

Detiene la ejecución hasta que el usuario presione Enter.

**Comportamiento esperado:**
- Imprime una línea en blanco
- Muestra el mensaje: `  Presiona Enter para continuar...`
- Espera input del usuario (cualquier tecla + Enter)
- Imprime una línea en blanco al salir

---

### Cómo probar tu PR

```bash
# Carga el archivo directamente
source src/lib/utils.sh

# Prueba print_header
print_header "Prueba de encabezado"

# Prueba mensajes
msg_ok "Todo bien"
msg_err "Algo salió mal"
msg_warn "Cuidado con esto"

# Prueba confirmar_accion
confirmar_accion "¿Confirmas la prueba?"
echo "Retornó: $?"   # debe ser 0 si escribiste 's'

# Prueba usuario_existe
usuario_existe "root"
echo "root existe: $?"     # debe ser 0

usuario_existe "usuarioquenuncaexistira123"
echo "inexistente: $?"     # debe ser 1

# Prueba grupo_existe
grupo_existe "root"
echo "grupo root: $?"      # debe ser 0
```

---

---

## PR #3 — Módulo de usuarios · `src/users.sh`

**Rama:** `feat/users-module`  
**Responsable:** Diego  
**Prioridad:** NORMAL — merge el martes.

### Contexto

Este módulo maneja toda la gestión de usuarios del sistema. Todos los mensajes
de éxito/error deben usar las funciones de `utils.sh` (`msg_ok`, `msg_err`, etc.).
No uses `echo` directo para mensajes al usuario.

Las funciones de `utils.sh` ya están disponibles porque `main.sh` las carga antes
de cargar este módulo.

### Funciones a implementar

---

#### `menu_usuarios`

Muestra el submenú de usuarios en un bucle hasta que el usuario elija volver.

**Comportamiento esperado:**
- Limpiar pantalla (`clear`) al entrar
- Mostrar `print_header "Gestión de Usuarios"`
- Mostrar las 4 opciones numeradas + opción 0 para volver
- Leer opción y llamar a la función correspondiente
- Repetir hasta que el usuario elija 0

**Opciones del menú:**
```
1) Alta de usuario
2) Baja de usuario
3) Consulta de usuario
4) Modificaciones de usuario
0) Volver al menú principal
```

---

#### `usuario_alta`

Da de alta un nuevo usuario en el sistema.

**Flujo completo:**
1. Solicitar nombre de usuario al operador
2. Verificar que el nombre no esté vacío
3. Verificar que el usuario **NO** exista ya (usar `usuario_existe`)
4. Si ya existe → `msg_err` y volver al menú (no continuar)
5. Ejecutar `useradd -m -s /bin/bash <usuario>` (`-m` crea el home, `-s` asigna bash)
6. Solicitar contraseña con `passwd <usuario>`
7. Confirmar alta con `msg_ok`
8. Llamar a `pausar`

**Casos a manejar:**
| Caso | Comportamiento esperado |
|------|------------------------|
| Nombre vacío | `msg_err "El nombre no puede estar vacío."` y volver |
| Usuario ya existe | `msg_err "El usuario '<nombre>' ya existe."` y volver |
| `useradd` falla | `msg_err "No se pudo crear el usuario."` y volver |
| Alta exitosa | `msg_ok "Usuario '<nombre>' creado correctamente."` |

---

#### `usuario_baja`

Elimina un usuario del sistema.

**Flujo completo:**
1. Solicitar nombre de usuario
2. Verificar que el nombre no esté vacío
3. Verificar que el usuario **SÍ** exista (usar `usuario_existe`)
4. Si no existe → `msg_err` y volver
5. Preguntar si se desea eliminar también el directorio home (`confirmar_accion`)
6. Pedir confirmación final antes de eliminar (`confirmar_accion "¿Estás seguro?"`)
7. Si confirma con home: `userdel -r <usuario>`; sin home: `userdel <usuario>`
8. Confirmar con `msg_ok` o reportar error con `msg_err`

**Casos a manejar:**
| Caso | Comportamiento esperado |
|------|------------------------|
| Nombre vacío | `msg_err` y volver |
| Usuario no existe | `msg_err "El usuario '<nombre>' no existe."` y volver |
| Usuario cancela confirmación | `msg_warn "Operación cancelada."` y volver |
| Baja exitosa | `msg_ok "Usuario '<nombre>' eliminado."` |
| Usuario tiene procesos activos | `userdel` fallará — capturar el error y mostrar `msg_err` |

---

#### `usuario_consulta`

Muestra información detallada de un usuario.

**Flujo completo:**
1. Solicitar nombre de usuario
2. Verificar que exista
3. Si no existe → `msg_err` y volver
4. Mostrar la información del usuario

**Información a mostrar:**
```
Usuario:     juan
UID / GID:   1001 / 1001
Grupos:      juan wheel audio
Home:        /home/juan
Shell:       /bin/bash
Último login: [resultado de lastlog -u <usuario>]
--- Caducidad de contraseña ---
[resultado de chage -l <usuario>]
```

**Comandos a usar:**
- `id <usuario>` → UID, GID, grupos
- `getent passwd <usuario>` → home y shell (campo 6 y 7, separados por `:`)
- `chage -l <usuario>` → información de caducidad
- `lastlog -u <usuario>` → último login (opcional, si falla no es crítico)

---

#### `usuario_modificar`

Submenú para modificar atributos de un usuario existente.

**Flujo completo:**
1. Solicitar nombre de usuario
2. Verificar que exista
3. Si no existe → `msg_err` y volver
4. Mostrar submenú de modificaciones

**Submenú de modificaciones:**
```
1) Cambiar fecha de caducidad de cuenta
2) Cambiar directorio home
3) Bloquear cuenta
4) Desbloquear cuenta
5) Cambiar shell
0) Volver
```

**Comandos por opción:**

| Opción | Comando | Notas |
|--------|---------|-------|
| Caducidad | `chage -E YYYY-MM-DD <usuario>` | Pedir fecha en formato YYYY-MM-DD |
| Home | `usermod -d /nuevo/home <usuario>` | Advertir que no mueve los archivos existentes |
| Bloquear | `usermod -L <usuario>` | Confirmar antes de ejecutar |
| Desbloquear | `usermod -U <usuario>` | Confirmar antes de ejecutar |
| Shell | `usermod -s /bin/bash <usuario>` | Pedir ruta del shell (ej. `/bin/bash`, `/bin/sh`) |

---

### Cómo probar tu PR

```bash
# Ejecutar el script completo como root
sudo bash main.sh

# Navegar: Opción 1 (Usuarios)

# Prueba 1 — Alta exitosa
# → Opción 1, ingresar "testuser01", asignar contraseña
# → Verificar: id testuser01

# Prueba 2 — Alta duplicada
# → Opción 1, ingresar "testuser01" de nuevo
# → Debe mostrar [ERROR] usuario ya existe

# Prueba 3 — Consulta
# → Opción 3, ingresar "testuser01"
# → Debe mostrar UID, GID, grupos, home, shell, caducidad

# Prueba 4 — Modificar: bloquear cuenta
# → Opción 4 → Opción 3 (bloquear) con "testuser01"
# → Verificar: passwd -S testuser01  (debe mostrar "L" en segundo campo)

# Prueba 5 — Baja con home
# → Opción 2, ingresar "testuser01", confirmar eliminar home
# → Verificar: id testuser01 debe fallar
# → Verificar: ls /home/testuser01 debe fallar

# Prueba 6 — Usuario inexistente
# → Opción 3, ingresar "usuarioinexistente999"
# → Debe mostrar [ERROR]

# Verificar sintaxis antes del PR:
bash -n src/users.sh
```

---

---

## PR #4 — Módulo de grupos · `src/groups.sh`

**Rama:** `feat/groups-module`  
**Responsable:** Imanol  
**Prioridad:** NORMAL — merge el martes.

### Contexto

Este módulo maneja la gestión de grupos del sistema. Mismas reglas que el módulo
de usuarios: todos los mensajes usan `utils.sh`, sin `echo` directo para mensajes.

### Funciones a implementar

---

#### `menu_grupos`

Muestra el submenú de grupos en un bucle hasta que el usuario elija volver.

**Opciones del menú:**
```
1) Alta de grupo
2) Baja de grupo
3) Consulta de grupo
4) Modificaciones de grupo
0) Volver al menú principal
```

---

#### `grupo_alta`

Da de alta un nuevo grupo en el sistema.

**Flujo completo:**
1. Solicitar nombre del grupo
2. Verificar que el nombre no esté vacío
3. Verificar que el grupo **NO** exista (usar `grupo_existe`)
4. Si ya existe → `msg_err` y volver
5. Ejecutar `groupadd <grupo>`
6. Preguntar si se quieren agregar miembros iniciales (`confirmar_accion`)
7. Si sí: solicitar nombres separados por coma → `gpasswd -M user1,user2 <grupo>`
8. Confirmar con `msg_ok`

**Casos a manejar:**
| Caso | Comportamiento esperado |
|------|------------------------|
| Nombre vacío | `msg_err` y volver |
| Grupo ya existe | `msg_err "El grupo '<nombre>' ya existe."` y volver |
| Alta exitosa | `msg_ok "Grupo '<nombre>' creado correctamente."` |

---

#### `grupo_baja`

Elimina un grupo del sistema.

**Flujo completo:**
1. Solicitar nombre del grupo
2. Verificar que el nombre no esté vacío
3. Verificar que el grupo **SÍ** exista
4. Si no existe → `msg_err` y volver
5. Pedir confirmación con `confirmar_accion`
6. Ejecutar `groupdel <grupo>`
7. Confirmar con `msg_ok` o reportar error

**Casos a manejar:**
| Caso | Comportamiento esperado |
|------|------------------------|
| Grupo no existe | `msg_err` y volver |
| Usuario cancela | `msg_warn "Operación cancelada."` |
| Grupo es primario de algún usuario | `groupdel` fallará — capturar error y mostrar `msg_err "No se puede eliminar: es grupo primario de algún usuario."` |
| Baja exitosa | `msg_ok "Grupo '<nombre>' eliminado."` |

---

#### `grupo_consulta`

Muestra información de un grupo.

**Flujo completo:**
1. Solicitar nombre del grupo
2. Verificar que exista
3. Si no existe → `msg_err` y volver
4. Mostrar información

**Información a mostrar:**
```
Grupo:    devs
GID:      1002
Miembros: juan, pedro, maria
```

**Comandos a usar:**
- `getent group <grupo>` → devuelve `nombre:x:GID:miembros`
- Separar con `cut -d: -f3` (GID) y `cut -d: -f4` (miembros)
- Si la lista de miembros está vacía → mostrar `(sin miembros)`

---

#### `grupo_modificar`

Submenú para modificar un grupo existente.

**Flujo completo:**
1. Solicitar nombre del grupo
2. Verificar que exista
3. Si no existe → `msg_err` y volver
4. Mostrar submenú de modificaciones

**Submenú:**
```
1) Renombrar grupo
2) Agregar miembro
3) Quitar miembro
4) Reemplazar lista completa de miembros
0) Volver
```

**Comandos por opción:**

| Opción | Comando | Notas |
|--------|---------|-------|
| Renombrar | `groupmod -n <nuevo_nombre> <grupo>` | Verificar que el nuevo nombre no exista ya |
| Agregar miembro | `gpasswd -a <usuario> <grupo>` | Verificar que el usuario exista con `usuario_existe` |
| Quitar miembro | `gpasswd -d <usuario> <grupo>` | Verificar que el usuario exista |
| Reemplazar lista | `gpasswd -M user1,user2,user3 <grupo>` | Solicitar lista separada por comas |

---

### Cómo probar tu PR

```bash
sudo bash main.sh
# Navegar: Opción 2 (Grupos)

# Prueba 1 — Alta de grupo
# → Opción 1, nombre "devteam", agregar miembro "root"
# → Verificar: getent group devteam

# Prueba 2 — Alta duplicada
# → Opción 1, nombre "devteam" de nuevo
# → Debe mostrar [ERROR]

# Prueba 3 — Consulta
# → Opción 3, nombre "devteam"
# → Debe mostrar GID y miembros

# Prueba 4 — Agregar miembro
# → Opción 4 → Opción 2, agregar usuario "root" a "devteam"
# → Verificar: id root (debe incluir devteam en grupos)

# Prueba 5 — Quitar miembro
# → Opción 4 → Opción 3, quitar "root" de "devteam"
# → Verificar: getent group devteam

# Prueba 6 — Baja de grupo
# → Opción 2, nombre "devteam", confirmar
# → Verificar: getent group devteam debe devolver vacío

# Prueba 7 — Grupo inexistente
# → Opción 3, nombre "grupoinexistente999"
# → Debe mostrar [ERROR]

bash -n src/groups.sh
```

---

---

## PR #5 — Módulo de procesos · `src/processes.sh`

**Rama:** `feat/processes-module`  
**Responsable:** Osvaldo  
**Prioridad:** NORMAL — merge el martes. Es el módulo más acotado del proyecto.

### Contexto

Este módulo muestra los procesos activos de un usuario consultado. No modifica
nada en el sistema — es solo lectura. Mismas reglas de mensajes con `utils.sh`.

### Funciones a implementar

---

#### `menu_procesos`

Muestra el submenú de procesos.

**Opciones del menú:**
```
1) Ver procesos del usuario (snapshot)
2) Monitor en tiempo real (top)
0) Volver al menú principal
```

---

#### `procesos_snapshot`

Muestra una foto instantánea de los procesos activos de un usuario.

**Flujo completo:**
1. Solicitar nombre de usuario
2. Verificar que el nombre no esté vacío
3. Verificar que el usuario **SÍ** exista (usar `usuario_existe`)
4. Si no existe → `msg_err` y volver
5. Ejecutar `ps aux --user <usuario>` y capturar el resultado
6. Contar cuántos procesos se encontraron (líneas del resultado menos el header)
7. Si no hay procesos → `msg_warn "El usuario '<nombre>' no tiene procesos activos."`
8. Si hay procesos → mostrar el resultado y al final: `msg_ok "X proceso(s) encontrado(s)."`
9. Llamar a `pausar`

**Casos a manejar:**
| Caso | Comportamiento esperado |
|------|------------------------|
| Nombre vacío | `msg_err` y volver |
| Usuario no existe | `msg_err "El usuario '<nombre>' no existe."` y volver |
| Sin procesos activos | `msg_warn "No hay procesos activos para '<nombre>'."` |
| Con procesos | Mostrar salida de `ps aux` + conteo al final |

**Sugerencia de implementación:**
```bash
# Capturar procesos sin el header
PROCESOS=$(ps aux --user "$usuario" 2>/dev/null | tail -n +2)

# Contar líneas
COUNT=$(echo "$PROCESOS" | grep -c .)

if [[ $COUNT -eq 0 ]]; then
    msg_warn "El usuario '$usuario' no tiene procesos activos."
else
    ps aux --user "$usuario"
    echo ""
    msg_ok "$COUNT proceso(s) encontrado(s) para '$usuario'."
fi
```

---

#### `procesos_monitor`

Abre el monitor `top` filtrado por un usuario específico para visualización en tiempo real.

**Flujo completo:**
1. Solicitar nombre de usuario
2. Verificar que el nombre no esté vacío
3. Verificar que el usuario **SÍ** exista
4. Si no existe → `msg_err` y volver
5. Avisar al usuario que presione `q` para salir de `top`
6. Ejecutar `top -u <usuario>`
7. Al regresar (el usuario presionó `q`), llamar a `pausar`

**Casos a manejar:**
| Caso | Comportamiento esperado |
|------|------------------------|
| Nombre vacío | `msg_err` y volver |
| Usuario no existe | `msg_err` y volver |
| Antes de abrir top | `msg_warn "Presiona 'q' para salir del monitor."` |

---

### Cómo probar tu PR

```bash
sudo bash main.sh
# Navegar: Opción 3 (Procesos)

# Prueba 1 — Snapshot de root (siempre tiene procesos)
# → Opción 1, ingresar "root"
# → Debe mostrar lista de procesos y conteo mayor a 0

# Prueba 2 — Usuario sin procesos
# → Crear un usuario de prueba: sudo useradd testproc
# → Opción 1, ingresar "testproc"
# → Debe mostrar [AVISO] sin procesos activos

# Prueba 3 — Usuario inexistente
# → Opción 1, ingresar "usuarioinexistente999"
# → Debe mostrar [ERROR]

# Prueba 4 — Monitor en tiempo real
# → Opción 2, ingresar "root"
# → Debe abrir top filtrado por root
# → Presionar q para salir
# → Debe regresar al menú correctamente

# Prueba 5 — Nombre vacío
# → Opción 1, presionar Enter sin escribir nada
# → Debe mostrar [ERROR]

bash -n src/processes.sh
```

---

---

## PR #2 — Core / Entrypoint · `main.sh`

**Rama:** `feat/core-entrypoint`  
**Responsable:** Axel  
**Prioridad:** ALTA — pero merge el **último**, después de que todos los demás estén en develop.

### Contexto

`main.sh` es el punto de entrada del script. Se encarga de tres cosas:
verificar que quien lo ejecuta es root, cargar todos los módulos, y mostrar
el menú principal. No implementa lógica de usuarios, grupos ni procesos —
eso vive en cada módulo. Su trabajo es ensamblar todo.

### Qué implementar

---

#### Verificación de root

Al inicio del script, antes de cualquier menú:

```bash
if [[ $EUID -ne 0 ]]; then
    echo ""
    echo "Acceso denegado: este script debe ejecutarse como root."
    echo "Usa: sudo bash main.sh"
    echo ""
    exit 1
fi
```

**Casos a manejar:**
- Si el usuario NO es root → imprimir mensaje y salir con código 1
- Si el usuario SÍ es root → continuar al menú principal

---

#### Carga de módulos

Después de la verificación de root, cargar los cuatro archivos en orden:

```bash
source "$SCRIPT_DIR/src/lib/utils.sh"
source "$SCRIPT_DIR/src/users.sh"
source "$SCRIPT_DIR/src/groups.sh"
source "$SCRIPT_DIR/src/processes.sh"
```

Usar `SCRIPT_DIR` para que el script funcione desde cualquier directorio:

```bash
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
```

---

#### Menú principal

Bucle que muestra las tres opciones principales más la salida:

```
1) Usuarios
2) Grupos
3) Procesos de usuario
0) Salir
```

**Comportamiento:**
- Limpiar pantalla (`clear`) en cada iteración
- Mostrar `print_header "Administración de Redes — Menú Principal"`
- Leer opción y llamar al menú del módulo correspondiente
- Opción 0: imprimir despedida y salir con código 0
- Opción inválida: `msg_warn` + `pausar`

---

### Cómo probar tu PR

```bash
# Prueba 1 — Sin root
bash main.sh
# Debe mostrar "Acceso denegado" y salir

# Prueba 2 — Con root, navegación completa
sudo bash main.sh
# → Entrar a cada submenú (1, 2, 3) y volver con 0
# → Verificar que los módulos cargan sin errores

# Prueba 3 — Opción inválida en menú principal
sudo bash main.sh
# → Escribir "9" o letras
# → Debe mostrar [AVISO] y no romper el bucle

# Prueba 4 — Salida limpia
# → Opción 0 desde el menú principal
# → Debe imprimir despedida y salir sin errores

bash -n main.sh
```

---

## Notas generales para todos los PRs

- Cada función debe terminar con `pausar` cuando corresponda (después de mostrar
  información o confirmar una acción), para que el usuario pueda leer el resultado
  antes de que la pantalla se limpie.
- Nunca usar `exit` dentro de un módulo — solo `return` para volver al menú.
  El único `exit` permitido está en `main.sh`.
- Si un comando del sistema falla (useradd, groupdel, etc.), verificar el código
  de retorno con `$?` y reportar el error con `msg_err`.
- Probar siempre con `bash -n <archivo>` antes de abrir el PR.