# Template Flutter Extreme

Plantilla de proyecto Flutter con **Clean Architecture** y **Vertical Slice**: estructura por features, dominio desacoplado, estado con Riverpod y scripts para inicializar el proyecto y generar features completas.

---

## Requisitos

- [Flutter](https://docs.flutter.dev/get-started/install) (SDK ^3.10.7)
- Bash (para los scripts en `scripts/`)

---

## Inicio rápido

```bash
# Clonar o usar este repo como base
git clone <url-repo> mi-proyecto && cd mi-proyecto

# 1. Inicializar proyecto (package Android/iOS y nombre de app)
chmod +x init_proyect.sh scripts/*.sh
./init_proyect.sh --package com.empresa.miapp --name miapp

# 2. Instalar dependencias
flutter pub get

# 3. Ejecutar
flutter run
```

Tras `init_proyect.sh` tendrás el package y el nombre de la app configurados. Luego puedes crear features con el script de features.

---

## Cómo usar este repositorio

### 1. Inicializar el proyecto (primera vez)

El script **`init_proyect.sh`** reemplaza el package por defecto y el nombre de la app por los de tu proyecto.

```bash
./init_proyect.sh --package <package_id> [--name <nombre_app>]
```

Ejemplos:

```bash
./init_proyect.sh --package com.extreme.conductores --name conductores
./init_proyect.sh --package com.extreme.caribemar   # nombre = caribemar
./init_proyect.sh --help
```

**Documentación:** [INIT_PROYECT.md](INIT_PROYECT.md) — uso detallado, argumentos, requisitos del nombre y qué archivos modifica. **Léelo antes de ejecutar** si es tu primera vez.

---

### 2. Crear una nueva feature

El script **`scripts/create_feature_flutter.sh`** genera una feature completa con la estructura Clean Architecture + Vertical Slice: domain, application (providers), infrastructure (datasources + repository) y presentation (pantalla + carpeta widgets).

```bash
./scripts/create_feature_flutter.sh --feature <nombre_feature> [--entity <NombreEntidad>] [--no-local]
```

Ejemplos:

```bash
./scripts/create_feature_flutter.sh --feature turno
./scripts/create_feature_flutter.sh -f descarga_maestros --entity Maestro
./scripts/create_feature_flutter.sh -f permisos --no-local
./scripts/create_feature_flutter.sh --help
```

- **`--feature`** (obligatorio): nombre en snake_case (ej: `turno`, `descarga_maestros`).
- **`--entity`** (opcional): nombre de la entidad en PascalCase; por defecto se deriva del nombre de la feature.
- **`--no-local`**: no genera datasource local (solo remoto).

Después de crear la feature debes: ajustar la entidad, el repositorio, configurar el provider con Dio/datasources reales, endpoints y añadir la ruta en el router. Todo eso está explicado en la documentación de arquitectura.

---

## Estructura del proyecto

```
lib/
├── core/           # Router, tema, utilidades (app_router, app_theme, etc.)
├── shared/         # Infra y providers compartidos (prefs, Dio, BD)
├── widgets/        # Widgets reutilizables globales
└── features/       # Una carpeta por feature (Vertical Slice)
    └── <feature>/
        ├── domain/           # Entidades e interfaces de repositorio
        ├── application/      # Providers (Riverpod): estado y notifiers
        ├── infrastructure/   # Datasources (remote/local) e implementación del repo
        └── presentation/     # Pantallas y widgets de la feature
```

Cada feature es una “rebanada” vertical: dominio, aplicación, infraestructura y presentación juntos, para que los cambios queden acotados y el código sea más fácil de mantener y testear.

---

## Documentación

La documentación está en la carpeta **`docs/`** y en la raíz. Conviene leerla para seguir las convenciones del template y sacar partido a los scripts.

| Documento | Descripción |
|-----------|-------------|
| **[docs/CLEAN_ARCHITECTURE_VERTICAL_SLICE.md](docs/CLEAN_ARCHITECTURE_VERTICAL_SLICE.md)** | **Arquitectura del proyecto.** Explica Clean Architecture y Vertical Slice, el propósito de cada carpeta, responsabilidades por capa, **manejo de estado con Riverpod** (providers, StateNotifier, ref.watch/ref.read) y **todos los archivos que genera** `create_feature_flutter.sh` con su responsabilidad. Incluye flujo de datos y próximos pasos tras crear una feature. **Recomendado leer** antes de crear features o tocar la estructura. |
| **[INIT_PROYECT.md](INIT_PROYECT.md)** | **Uso de `init_proyect.sh`.** Argumentos, ejemplos, requisitos del nombre de la app y qué archivos modifica el script. Útil la primera vez que clonas o usas el template. |

---

## Scripts disponibles

| Script | Uso |
|--------|-----|
| `init_proyect.sh` | Inicializar package y nombre de la app (ejecutar una vez desde la raíz). |
| `scripts/create_feature_flutter.sh` | Crear una feature completa con domain, application, infrastructure y presentation. |

Ambos aceptan `--help` / `-h` para ver opciones.

---

## Dependencias principales

- **flutter_riverpod** — estado y inyección (providers, StateNotifier).
- **dio** — cliente HTTP.
- **shared_preferences** — persistencia clave-valor (sesión, cache local en datasources).

---

## Licencia

Según la configuración del repositorio.
