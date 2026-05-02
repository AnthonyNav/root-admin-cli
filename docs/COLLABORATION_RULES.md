# Reglas de Colaboración

## Estrategia de ramas

```
main          ← versión final entregable (protegida)
  └── develop ← integración del equipo (protegida)
        ├── feat/utils-lib
        ├── feat/core-entrypoint
        ├── feat/users-module
        ├── feat/groups-module
        └── feat/processes-module
```

**Nadie trabaja directamente en `main` ni en `develop`.**  
Toda modificación al código llega a `develop` a través de un Pull Request.

---

## Regla 1 — Nunca modificar `develop` ni `main` directamente

**Qué significa:**  
Está prohibido hacer `git push origin develop` con cambios propios. Aunque técnicamente sea posible (antes de activar la protección de rama), hacerlo sin revisión rompe el flujo del equipo.

**Ejemplo incorrecto — qué NO hacer:**
```bash
# Juan terminó users.sh y quiere subirlo rápido
git checkout develop
git merge feat/users-module    # ← MAL: saltó el proceso
git push origin develop        # ← MAL: no hubo revisión
```

**Ejemplo correcto — cómo sí hacerlo:**
```bash
# Juan terminó users.sh
git checkout feat/users-module
git add src/users.sh
git commit -m "feat: implementar alta, baja y consulta de usuario"
git push origin feat/users-module

# Luego en GitHub:
# New Pull Request → base: develop ← compare: feat/users-module
# Asignar revisor y esperar aprobación
```

---

## Regla 2 — Toda modificación va por Pull Request

**Qué significa:**  
Incluso un cambio de una línea (typo, comentario) debe ir como commit en la rama feature y subirse mediante PR. Esto mantiene el historial limpio y permite que el equipo vea exactamente qué cambió.

**Convención de commits:**

```
feat: <descripción>    → funcionalidad nueva
fix: <descripción>     → corrección de un bug
docs: <descripción>    → cambios en documentación
refactor: <descripción>→ refactorización sin cambio de comportamiento
```

Ejemplos válidos:
```bash
git commit -m "feat: implementar usuario_baja con confirmación"
git commit -m "fix: corregir validación en grupo_consulta"
git commit -m "docs: agregar ejemplos en PLANNING.md"
```

---

## Regla 3 — El merge requiere aprobación

**Qué significa:**  
Un PR a `develop` necesita la aprobación de **al menos 1 miembro del equipo** antes de poder hacer merge. Esto aplica a todos los integrantes.

**Excepción documentada:**  
El titular del repositorio ([Lead/Anthony]) puede hacer merge de sus propios PRs sin aprobación adicional cuando la situación lo requiera (por ejemplo, PRs de documentación o configuración inicial el día sábado).

**Ejemplo del flujo de revisión:**

```
1. Ana abre PR: feat/groups-module → develop
2. El sistema notifica al equipo
3. Luis revisa el código en GitHub y deja comentarios
4. Ana responde los comentarios y sube nuevos commits si es necesario
5. Luis aprueba el PR
6. Ana (o el lead) hace el merge
```

**¿Qué revisa el revisor?**  
Ver lista de criterios en `docs/RESPONSIBILITIES.md`.

---

## Regla 4 — Orden de merge (ver RESPONSIBILITIES.md)

Los PRs se mergean en orden específico para evitar que el script falle:

```
PR #1 (utils) → primero
PR #3 #4 #5   → después, en cualquier orden
PR #2 (core)  → último
```

Si abres un PR antes de que su dependencia esté mergeada, no hay problema: el PR puede existir abierto, simplemente espera a mergearse hasta que el orden sea correcto.

---

## Flujo diario resumido

```
Sáb 2 → Lead: inicializa repo, sube estructura, crea ramas
Dom 3 → Todos: codifican en su rama feature
Lun 4 → PR #1 se abre, revisa y mergea a develop
         Resto del equipo termina código
Mar 5 → PRs #3 #4 #5 se abren, revisan y mergean
         PR #2 (core) mergea último
         Prueba de integración en develop
         develop → main (solo el lead)
```

---

## Configuración local para cada miembro

```bash
# 1. Clonar el repositorio
git clone https://github.com/<usuario>/admin-redes-p1.git
cd admin-redes-p1

# 2. Ir a tu rama asignada
git checkout feat/<tu-modulo>

# 3. Verificar en qué rama estás
git branch   # debe mostrar * feat/<tu-modulo>

# 4. Después de cada sesión de trabajo
git add <tu-archivo>
git commit -m "feat: descripción de lo que hiciste"
git push origin feat/<tu-modulo>
```

---

## Resolución de conflictos

Los conflictos son muy poco probables porque cada persona tiene exactamente un archivo asignado. Si ocurriera un conflicto (por ejemplo, en `main.sh` que sourcéa todo), el lead lo resuelve y los demás hacen `git pull` en sus ramas.

En caso de duda: avisar al grupo antes de hacer merge, nunca resolver un conflicto de otro sin avisar.