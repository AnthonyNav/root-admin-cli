# Responsabilidades del Equipo — Parte 2

## Asignaciones

| PR | Rama | Archivo(s) | Responsable | Prioridad |
|----|------|-----------|-------------|-----------|
| PC-1 | `feat/part1-corrections` | `utils.sh`, `users.sh`, `groups.sh`, `processes.sh` | Axel | ALTA — merge primero |
| P2-1 | `feat/automation-module` | `src/automation.sh`, `scripts/install_security.sh` | Osvaldo | NORMAL |
| P2-2 | `feat/backup-module` | `src/backup.sh` | Imanol | NORMAL |
| P2-3 | `feat/security-module` | `src/security.sh` | Diego | NORMAL |
| P2-INT | `feat/part2-integration` | `main.sh`, `deps.txt` | Anthony | ALTA — merge último |

> Llenar con nombres completos si se requiere para la entrega formal.

Para el detalle de qué implementar en cada PR → [`docs/TASKS_P2.md`](TASKS_P2.md)

---

## Dependencias entre PRs

**¿Hay PRs que bloquean a otros?**

Durante el desarrollo (coding): **NO.** Todos trabajan en archivos distintos desde el día 1.

Durante el merge: **SÍ**, existe un orden obligatorio:

```
┌─────────────────────────────────────────────────────────────┐
│  ORDEN DE MERGE                                             │
│                                                             │
│  1. PC-1  (Axel correcciones)    ← PRIMERO                 │
│     └─ Modifica utils.sh con helpers whiptail               │
│        Los demás pueden usarlos tras el merge               │
│                                                             │
│  2. P2-1, P2-2, P2-3            ← en cualquier orden       │
│     (automatización, respaldo, seguridad)                   │
│                                                             │
│  3. P2-INT (Anthony integración) ← ÚLTIMO                  │
│     └─ Sourcéa todos los módulos en main.sh                 │
└─────────────────────────────────────────────────────────────┘
```

**Nota sobre seguridad (Diego):**
El módulo `security.sh` requiere que `scripts/install_security.sh` (de Osvaldo)
ya se haya ejecutado en la máquina para poder probar Nagios, Wireshark y Nmap.
Coordinar con Osvaldo antes de hacer pruebas funcionales.

---

## Cronograma

| Fecha | Actividad |
|-------|-----------|
| Dom 10 may | Crear ramas, subir stubs, todo el equipo inicia coding |
| Lun 11 may | Coding — Axel termina whiptail; resto avanza módulos |
| Mar 12 may | Coding — todos abren PRs hacia develop |
| Mié 13 may | Anthony revisa PC-1 y lo mergea; revisa P2-1, P2-2, P2-3 |
| Jue 14 may | Mergear P2-1, P2-2, P2-3 → develop |
| Vie 15 may | Anthony mergea P2-INT → develop; prueba integración completa |
| Vie 15 may | Merge develop → main (entrega final Parte 2) |

**Rol de Anthony durante días 2-3:**
Mientras el equipo codifica, Anthony revisa los PRs que se vayan abriendo.
No empieza a codificar P2-INT hasta que los 4 PRs anteriores estén en develop.

---

## Criterios de revisión para cada PR

El revisor (Anthony) verifica antes de aprobar:

- [ ] `bash -n <archivo>` sin errores de sintaxis
- [ ] `source src/lib/utils.sh; source <archivo>` sin errores de runtime
- [ ] Funciones con nombres correctos según `TASKS_P2.md`
- [ ] Sin `exit` dentro de módulos (solo `return`)
- [ ] Mensajes usando `msg_ok`, `msg_err`, `msg_warn`
- [ ] `pausar` al final de operaciones donde corresponde
- [ ] **PC-1 adicional:** whiptail funciona en terminal interactiva
- [ ] **PC-1 adicional:** listing de usuarios/grupos muestra correctamente
- [ ] **P2-1 adicional:** `install_security.sh` corre sin errores en AlmaLinux 9.7
- [ ] **P2-3 adicional:** cada herramienta verifica si está instalada antes de abrirse
- [ ] PR tiene descripción completa en español

---

## Merge orden de merge sugerido

| Día | Actividad de merge |
|-----|--------------------|
| Mié 13 may | Revisar y mergear PC-1 (correcciones) → develop |
| Jue 14 may | Revisar y mergear P2-1, P2-2, P2-3 → develop (en paralelo) |
| Vie 15 may | Revisar y mergear P2-INT (integración) → develop |
| Vie 15 may | Prueba de integración completa en develop |
| Vie 15 may | Merge develop → main (Anthony) |