# Responsabilidades del Equipo

## Asignaciones

| PR  | Rama feature              | Archivo             | Responsable | Prioridad |
|-----|---------------------------|---------------------|-------------|-----------|
| #1  | `feat/utils-lib`          | `src/lib/utils.sh`  | Antonio     | ALTA      |
| #2  | `feat/core-entrypoint`    | `main.sh`           | Axel        | ALTA      |
| #3  | `feat/users-module`       | `src/users.sh`      | Diego       | NORMAL    |
| #4  | `feat/groups-module`      | `src/groups.sh`     | Imanol      | NORMAL    |
| #5  | `feat/processes-module`   | `src/processes.sh`  | Osvaldo     | NORMAL    |

> Llenar la columna "Responsable" con el nombre real del miembro asignado.

---

## Dependencias entre PRs

### ¿Hay PRs que deben esperar a otros?

**Durante el desarrollo (coding): NO.** Cada miembro puede codificar de forma completamente independiente desde el domingo porque `develop` ya contiene los stubs con las firmas de todas las funciones.

**Durante el merge: SÍ.** Existe un orden obligatorio de merge a `develop`:

```
┌──────────────────────────────────────────────────────────┐
│  ORDEN DE MERGE (no modificar esta secuencia)            │
│                                                          │
│  1. PR #1 (utils/lib)      ← DEBE ser el primero        │
│     └─ Sin utils, los demás módulos no tienen helpers   │
│                                                          │
│  2. PR #3, #4, #5          ← en cualquier orden        │
│     (usuarios, grupos, procesos)                         │
│                                                          │
│  3. PR #2 (core/entrypoint) ← DEBE ser el último        │
│     └─ Sourcéa todos los módulos; si alguno no está     │
│        en develop, el script falla al cargar             │
└──────────────────────────────────────────────────────────┘
```

### Implicaciones por persona

**PR #1 (utils/lib) — Responsabilidad crítica:**  
Aunque puedes desarrollar durante el fin de semana en paralelo con todos, tu módulo es el primero que se debe revisar y mergear. El **lunes por la mañana** es la meta para que el resto del equipo pueda hacer pruebas de integración completas. Si te bloqueas en alguna función, avisa al grupo lo antes posible.

**PR #2 (core/entrypoint) — Merge al final:**  
El titular del PR #2 (lead del proyecto) mergea de último porque su archivo fuente todos los demás módulos. Durante el desarrollo del sábado/domingo, puede avanzar en la lógica del menú; la integración final se hace el martes.

**PRs #3, #4, #5 — Independientes entre sí:**  
No se bloquean entre ellos. Pueden abrirse como PRs a develop desde el lunes y mergearse en cualquier orden.

---

## Cronograma de merge sugerido

| Día       | Actividad de merge                                     |
|-----------|--------------------------------------------------------|
| Lun 4 may | Revisar y mergear PR #1 (utils) → develop              |
| Mar 5 may | Revisar y mergear PR #3, #4, #5 (en paralelo) → develop|
| Mar 5 may | Revisar y mergear PR #2 (core) → develop               |
| Mar 5 may | Prueba de integración en develop                       |
| Mar 5 may | Merge develop → main (solo el lead)                    |

---

## Criterios de revisión para cada PR

El revisor es **responsable de garantizar** que el código funciona correctamente antes de aprobar. No basta con leer el código — hay que ejecutarlo.

### Verificación obligatoria antes de aprobar

**1. Verificar sintaxis (sin errores de compilación):**
```bash
bash -n src/<archivo-del-pr>.sh
# Si no imprime nada → sin errores de sintaxis
```

**2. Ejecutar el script completo y probar el módulo:**
```bash
sudo bash main.sh
# Navegar al submenú del PR que estás revisando
# Probar cada opción del menú al menos una vez
```

**3. Casos de prueba mínimos por módulo:**

| Módulo    | Qué probar                                                        |
|-----------|-------------------------------------------------------------------|
| utils     | Llamar `print_header`, `msg_ok`, `msg_err`, `confirmar_accion`    |
| usuarios  | Alta con usuario nuevo, alta con usuario ya existente (debe fallar elegante), baja, consulta de usuario inexistente |
| grupos    | Alta con grupo nuevo, baja, consulta, agregar miembro             |
| procesos  | Usuario con procesos activos, usuario sin procesos, usuario inexistente |

### Checklist de aprobación

- [ ] `bash -n <archivo>` no reporta errores de sintaxis
- [ ] El script completo corre sin errores al navegar por el módulo
- [ ] Las funciones tienen los nombres correctos (sin cambiar los stubs)
- [ ] Cada función verifica si el usuario/grupo existe antes de actuar
- [ ] Se usan `msg_ok`, `msg_err`, `msg_warn` de `utils.sh` para todos los mensajes
- [ ] Las acciones destructivas (baja, eliminar) piden confirmación con `confirmar_accion`
- [ ] El PR tiene descripción completa en español
- [ ] El código tiene comentarios mínimos que expliquen bloques no obvios

Si algo del checklist falla, el revisor deja un comentario en español explicando exactamente qué falló y cómo reproducirlo, y **no aprueba** hasta que esté corregido.