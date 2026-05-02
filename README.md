# Administración de Redes — Proyecto Parte 1

Script Bash interactivo para administración de **usuarios**, **grupos** y **procesos** en servidores bajo AlmaLinux 9.

> Materia: Administración de Redes · BUAP  
> Plataforma certificada: **AlmaLinux 9.x**

---

## Requisitos del sistema

| Elemento           | Especificación        |
|--------------------|-----------------------|
| Sistema operativo  | AlmaLinux 9.x         |
| Shell              | Bash 5.0+             |
| Permisos           | Root (sudo)           |
| Paquetes requeridos| ver `deps.txt`        |

Verifica que tu entorno tenga todo lo necesario antes de correr el script:

```bash
bash setup.sh
```

Si detecta paquetes faltantes y tienes conexión, puedes instalarlos con:

```bash
sudo dnf install $(grep -v '^#' deps.txt | tr '\n' ' ')
```

---

## Uso

```bash
sudo bash main.sh
```

El script verifica automáticamente si se ejecuta como root. De lo contrario, imprime `Acceso denegado` y termina.

---

## Flujo de contribución (5 pasos)

```
1. Muévete a tu rama feature
   git checkout feat/<tu-modulo>

2. Codifica únicamente en tu archivo asignado
   (ver docs/RESPONSIBILITIES.md)

3. Haz commits frecuentes y descriptivos
   git commit -m "feat: descripción de lo que hiciste"

4. Abre un Pull Request hacia develop cuando tu módulo esté listo
   GitHub → New Pull Request → base: develop ← compare: feat/<tu-modulo>

5. Espera al menos 1 aprobación antes de hacer merge
```

Reglas completas y ejemplos → [`docs/COLLABORATION_RULES.md`](docs/COLLABORATION_RULES.md)  
Quién hace qué → [`docs/RESPONSIBILITIES.md`](docs/RESPONSIBILITIES.md)

---

## Estructura del repositorio

```
admin-redes/
├── README.md                    ← estás aquí
├── main.sh                      ← entrypoint del script (PR #2)
├── setup.sh                     ← verificador de dependencias
├── deps.txt                     ← paquetes requeridos (como requirements.txt)
├── src/
│   ├── lib/
│   │   └── utils.sh             ← helpers compartidos (PR #1 · ruta crítica)
│   ├── users.sh                 ← módulo usuarios (PR #3)
│   ├── groups.sh                ← módulo grupos (PR #4)
│   └── processes.sh             ← módulo procesos (PR #5)
└── docs/
    ├── PLANNING.md              ← alcance, decisiones técnicas, comandos
    ├── RESPONSIBILITIES.md      ← quién hace qué y orden de merge
    ├── TASKS.md                 ← qué implementar en cada PR (leer tu sección)
    └── COLLABORATION_RULES.md  ← reglas de Git con ejemplos
```

---

## Ramas activas

| Rama                     | Propósito                          |
|--------------------------|------------------------------------|
| `main`                   | Versión final entregable           |
| `develop`                | Integración continua del equipo    |
| `feat/utils-lib`         | PR #1 — helpers compartidos        |
| `feat/core-entrypoint`   | PR #2 — entrypoint y menú raíz     |
| `feat/users-module`      | PR #3 — módulo usuarios            |
| `feat/groups-module`     | PR #4 — módulo grupos              |
| `feat/processes-module`  | PR #5 — módulo procesos            |