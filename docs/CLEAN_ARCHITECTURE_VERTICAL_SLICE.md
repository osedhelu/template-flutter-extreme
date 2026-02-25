# Clean Architecture + Vertical Slice — Documentación

**Proyecto:** Template Flutter Extreme  
**Última actualización:** Febrero 2025

Este documento explica la arquitectura del proyecto Flutter: **Clean Architecture** combinada con **Vertical Slice**, el propósito de cada carpeta, las responsabilidades, el **manejo de estado** con Riverpod y todos los archivos que genera el script `create_feature_flutter.sh`.

---

## Índice

1. [Clean Architecture](#1-clean-architecture)
2. [Vertical Slice](#2-vertical-slice)
3. [Estructura de carpetas por feature](#3-estructura-de-carpetas-por-feature)
4. [Responsabilidades por capa](#4-responsabilidades-por-capa)
5. [Manejo de estado (Riverpod)](#5-manejo-de-estado-riverpod)
6. [Script `create_feature_flutter.sh`](#6-script-create_feature_fluttersh)
7. [Archivos generados por el script](#7-archivos-generados-por-el-script)
8. [Flujo de datos end-to-end](#8-flujo-de-datos-end-to-end)
9. [Próximos pasos tras crear una feature](#9-próximos-pasos-tras-crear-una-feature)

---

## 1. Clean Architecture

**Clean Architecture** (Uncle Bob) organiza el código en capas concéntricas donde:

- **Las dependencias apuntan hacia dentro**: la capa más interna (dominio) no conoce a la infraestructura ni a la UI.
- **El dominio es el núcleo**: entidades y reglas de negocio sin dependencias de frameworks ni de I/O.
- **Las capas externas implementan interfaces** definidas en el dominio (inversión de dependencias).

En este proyecto las capas son:

| Capa            | Ubicación        | Depende de        | Contiene                                      |
|-----------------|------------------|-------------------|-----------------------------------------------|
| **Domain**      | `domain/`        | Nada (solo Dart)  | Entidades, interfaces de repositorios         |
| **Application** | `application/`   | Domain            | Casos de uso / orquestación, providers        |
| **Infrastructure** | `infrastructure/` | Domain, Application | Implementaciones: APIs, BD, SharedPreferences |
| **Presentation**  | `presentation/`  | Application       | Pantallas, widgets, UI                        |

Ventajas: dominio testeable sin Flutter, cambio de API o BD sin tocar reglas de negocio, y una base clara para escalar.

---

## 2. Vertical Slice

En lugar de organizar por “capas horizontales” (todos los repositorios juntos, todas las pantallas juntas), usamos **Vertical Slice**: cada **feature** es una “rebanada” que incluye su propio dominio, aplicación, infraestructura y presentación.

```
lib/
├── core/                    # Router, tema, utilidades globales
├── shared/                  # Infra y providers compartidos (prefs, Dio, BD)
├── widgets/                 # Widgets reutilizables globales
└── features/
    ├── auth/                # Slice: login, sesión, logout
    │   ├── domain/
    │   ├── application/
    │   ├── infrastructure/
    │   └── presentation/
    ├── config_http/         # Slice: configuración de conexión HTTP
    └── turno/               # Slice: inicio/fin de turno (ejemplo)
```

Ventajas:

- Cambios en una funcionalidad se limitan a una carpeta (`features/<nombre>/`).
- Menos conflictos en Git y equipos que trabajan en features distintas.
- Cada slice puede entenderse y testearse de forma aislada.

---

## 3. Estructura de carpetas por feature

Cada feature generada por el script sigue esta estructura:

```
features/<nombre_feature>/
├── domain/
│   ├── entities/              # Modelos de dominio (puros)
│   └── repositories/          # Interfaces (contratos) de repositorio
├── application/
│   └── providers/             # Riverpod: repositorio, estado, notifier
├── infrastructure/
│   ├── datasources/           # Remote (API) y opcional Local (cache/prefs)
│   └── repositories/         # Implementación del repositorio de dominio
└── presentation/
    ├── <feature>_screen.dart  # Pantalla principal de la feature
    └── widgets/               # Widgets específicos de la feature
```

| Carpeta              | Propósito breve                                                                 |
|----------------------|----------------------------------------------------------------------------------|
| `domain/entities`    | Entidades de negocio (sin lógica de red/BD). Ej: `User`, `Turno`, `Maestro`.    |
| `domain/repositories`| Contratos (abstract class) que la infraestructura implementa.                   |
| `application/providers` | Inyección del repositorio, estado (State) y lógica (Notifier) con Riverpod.  |
| `infrastructure/datasources` | Llamadas HTTP (Dio) y/o persistencia local (PreferencesDataSource).   |
| `infrastructure/repositories` | Implementación concreta del repositorio que usa los datasources.      |
| `presentation`       | Pantallas y widgets que consumen los providers.                                 |

---

## 4. Responsabilidades por capa

### Domain

- **Entidades**: representan conceptos del negocio; tienen datos y pueden tener `fromJson`/`toJson` para serialización (la decisión de “quién” llama a eso queda en infra).
- **Repositorios (interfaces)**: definen *qué* se puede hacer (ej: `getById`, `getAll`, `login`), no *cómo* (eso es infra).

El dominio **no** importa Flutter, Dio, SharedPreferences ni archivos fuera de `domain/`.

### Application

- Exponer el **repositorio** vía `Provider` (o `FutureProvider` si es async).
- Definir el **estado** de la feature (ej: lista de ítems, loading, error).
- Definir el **Notifier** (StateNotifier) que usa el repositorio y actualiza el estado (ej: `loadAll()`, `login()`).

La aplicación **no** conoce detalles de HTTP ni de almacenamiento; solo usa la interfaz del repositorio.

### Infrastructure

- **Datasources**: hablan con API (Dio) o con almacenamiento local (por ejemplo `PreferencesDataSource`).
- **Repository impl**: implementa la interfaz del dominio usando uno o más datasources (por ejemplo “primero remoto, si falla usar local”).

La infraestructura **sí** conoce Dio, SharedPreferences, etc., pero el dominio y la aplicación no.

### Presentation

- **Screens**: leen estado con `ref.watch(...NotifierProvider)` y disparan acciones con `ref.read(...NotifierProvider.notifier).loadAll()` (o similar).
- **Widgets**: componentes reutilizables dentro de la feature; pueden recibir datos por parámetro o leer providers.

La presentación **no** implementa lógica de red ni de persistencia; solo orquesta UI y llamadas al Notifier.

---

## 5. Manejo de estado (Riverpod)

En este proyecto el estado se maneja con **Riverpod** (flutter_riverpod).

### Tipos de providers usados

| Tipo                | Uso típico                          | Ejemplo en el script / proyecto        |
|---------------------|-------------------------------------|----------------------------------------|
| `Provider<T>`       | Objeto que no cambia (repositorio)  | `turnoRepositoryProvider`               |
| `StateNotifierProvider<Notifier, State>` | Estado mutable manejado por un Notifier | `turnoNotifierProvider`            |
| `FutureProvider<T>` | Valor asíncrono (ej: crear repo)    | `authRepositoryProvider`, `dioProvider` |

### Estado de una feature (patrón del script)

- **State**: clase inmutable con `copyWith` (ej: `items`, `isLoading`, `errorMessage`).
- **Notifier**: extiende `StateNotifier<State>`, recibe el repositorio, expone métodos como `loadAll()` que:
  - ponen `isLoading = true`,
  - llaman al repositorio,
  - actualizan el estado con `state = state.copyWith(...)` o manejan error.

En la UI:

- **Leer estado**: `ref.watch(turnoNotifierProvider)` para reconstruir cuando cambie.
- **Ejecutar acción**: `ref.read(turnoNotifierProvider.notifier).loadAll()` (típico en `initState` con `addPostFrameCallback` o en callbacks).

### Override en `main.dart`

Para features cuyo repositorio depende de `FutureProvider` (por ejemplo `authRepositoryProvider`), el **Notifier** se inyecta con un override en `ProviderScope`:

```dart
ProviderScope(
  overrides: [
    authNotifierProvider.overrideWith((ref) {
      final asyncRepo = ref.watch(authRepositoryProvider);
      return AuthNotifier(
        asyncRepo.when(
          data: (repo) => repo,
          loading: () => throw StateError('...'),
          error: (_, __) => throw StateError('...'),
        ),
      );
    }),
  ],
  child: const MyApp(),
)
```

Así el `AuthNotifier` recibe el `AuthRepository` cuando esté disponible. Para features más simples (solo `Provider` del repositorio), no hace falta override; basta con configurar el `RepositoryProvider` para que devuelva la implementación real en lugar de `throw UnimplementedError`.

---

## 6. Script `create_feature_flutter.sh`

**Ubicación:** `scripts/create_feature_flutter.sh`

**Propósito:** Crear una feature completa con la estructura Clean Architecture + Vertical Slice y los archivos base listos para completar.

### Uso

```bash
./scripts/create_feature_flutter.sh --feature <nombre_feature> [--entity <NombreEntidad>] [--no-local]
```

| Opción        | Descripción                                                                 |
|---------------|-----------------------------------------------------------------------------|
| `--feature,-f`| Nombre de la feature en **snake_case** (obligatorio). Ej: `turno`, `descarga_maestros` |
| `--entity,-e` | Nombre de la entidad en **PascalCase**. Por defecto: derivado del nombre (ej: `turno` → `Turno`) |
| `--no-local`  | No crear datasource local (solo remoto)                                     |
| `--help,-h`   | Muestra la ayuda                                                            |

### Ejemplos

```bash
./scripts/create_feature_flutter.sh --feature turno
./scripts/create_feature_flutter.sh -f descarga_maestros --entity Maestro
./scripts/create_feature_flutter.sh -f permisos --no-local
```

### Requisitos

- Ejecutar desde la **raíz del proyecto** (donde está `pubspec.yaml`).
- El nombre de la feature debe ser **snake_case** (minúsculas, números y `_`).
- La feature **no debe existir** en `lib/features/<nombre_feature>` (el script no sobrescribe).

El script lee el **nombre del paquete** desde `pubspec.yaml` para generar los imports correctos (`package:nombre_paquete/...`).

---

## 7. Archivos generados por el script

A continuación se detalla **cada archivo** que crea el script y su responsabilidad. En los ejemplos se usa la feature `turno` y la entidad `Turno` (derivada por defecto).

---

### 7.1 Directorios

El script crea solo la estructura de carpetas; no crea archivos “de carpeta” salvo un `.gitkeep` en widgets:

- `features/<feature>/domain/entities`
- `features/<feature>/domain/repositories`
- `features/<feature>/application/providers`
- `features/<feature>/infrastructure/datasources`
- `features/<feature>/infrastructure/repositories`
- `features/<feature>/presentation/widgets`

---

### 7.2 Domain

#### `domain/entities/<feature>.dart` (ej: `turno.dart`)

- **Clase:** Entidad de dominio (ej: `Turno`).
- **Campos típicos:** `id` (int?), `name` (String) — plantilla mínima para que puedas ampliar.
- **Métodos:** `copyWith`, `fromJson`, `toJson` para inmutabilidad y serialización.
- **Responsabilidad:** Representar el concepto de negocio; sin dependencias externas.

Debes **ajustar campos y nombres** según tu dominio (ej: `fechaInicio`, `fechaFin`, etc.).

---

#### `domain/repositories/<feature>_repository.dart` (ej: `turno_repository.dart`)

- **Contenido:** Interfaz abstracta del repositorio (ej: `TurnoRepository`).
- **Métodos de plantilla:** `getById(int id)`, `getAll()` que devuelven `Future<Entidad>` y `Future<List<Entidad>>`.
- **Responsabilidad:** Contrato que la capa de infraestructura implementa; la aplicación solo depende de esta interfaz.

Puedes **añadir o cambiar métodos** (ej: `iniciarTurno()`, `finalizarTurno()`) y luego implementarlos en el repository impl.

---

### 7.3 Application (providers)

#### `application/providers/<feature>_providers.dart` (ej: `turno_providers.dart`)

Incluye:

1. **Provider del repositorio** (ej: `turnoRepositoryProvider`):
   - Tipo: `Provider<TurnoRepository>`.
   - Por defecto hace `throw UnimplementedError` con un TODO para inyectar Dio y datasources y devolver `TurnoRepositoryImpl`.
   - Debes **sustituir** este provider para que devuelva la implementación real (remote y opcionalmente local).

2. **Clase de estado** (ej: `TurnoState`):
   - Campos: `items` (lista de entidad), `isLoading`, `errorMessage`.
   - `copyWith` y `TurnoState.initial`.
   - Responsabilidad: modelo inmutable del estado de la feature en la UI.

3. **Notifier** (ej: `TurnoNotifier`):
   - Extiende `StateNotifier<TurnoState>`.
   - Recibe `TurnoRepository` en el constructor.
   - Método de plantilla: `loadAll()` (pone loading, llama a `getAll()`, actualiza estado o error).
   - Responsabilidad: orquestar acciones y actualizar el estado.

4. **StateNotifierProvider** (ej: `turnoNotifierProvider`):
   - Conecta el Notifier con el repositorio vía `turnoRepositoryProvider`.
   - La UI usa `ref.watch(turnoNotifierProvider)` y `ref.read(turnoNotifierProvider.notifier)`.

---

### 7.4 Infrastructure

#### `infrastructure/datasources/<feature>_remote_datasource.dart` (ej: `turno_remote_datasource.dart`)

- **Clase:** Ej: `TurnoRemoteDataSource`.
- **Constructor:** Recibe `Dio _dio`.
- **Métodos:** `getAll()` y `getById(int id)` que hacen GET a rutas derivadas del nombre de la feature (ej: `/turno`, `/turno/$id`) y devuelven `List<Map<String, dynamic>>` o `Map<String, dynamic>`.
- **Responsabilidad:** Única capa que conoce URLs y formato de respuesta HTTP; convierte respuesta en mapas, no en entidades (eso lo hace el repositorio).

Debes **ajustar paths y parsing** según tu API real.

---

#### `infrastructure/datasources/<feature>_local_datasource.dart` (ej: `turno_local_datasource.dart`) — solo si no usas `--no-local`

- **Clase:** Ej: `TurnoLocalDataSource`.
- **Constructor:** Recibe `PreferencesDataSource _prefs`.
- **Clave:** Constante tipo `_keyList = 'turno_list'`.
- **Métodos:** `saveList(List<Turno>)`, `getList()` (devuelve lista de entidades), `clear()`.
- **Responsabilidad:** Cache local de la lista en SharedPreferences (vía `PreferencesDataSource`); usa `toJson`/`fromJson` de la entidad.

Debes **revisar la clave** si tienes varias listas o namespaces, y el formato si cambias el modelo.

---

#### `infrastructure/repositories/<feature>_repository_impl.dart` (ej: `turno_repository_impl.dart`)

- **Clase:** Ej: `TurnoRepositoryImpl implements TurnoRepository`.
- **Con local:** Constructor con `TurnoRemoteDataSource remote` y `TurnoLocalDataSource local`. `getAll()`: intenta remoto, si falla devuelve `_local.getList()`; si tiene éxito guarda en local. `getById` solo remoto.
- **Sin local (`--no-local`):** Solo `remote`; `getAll()` y `getById()` solo usan el remoto.
- **Responsabilidad:** Implementar el contrato del dominio usando los datasources; convertir mapas a entidades con `Entidad.fromJson(...)`.

Debes **alinear** métodos con la interfaz del repositorio si la amplías (ej: añadir `iniciarTurno` que llame a un endpoint específico).

---

### 7.5 Presentation

#### `presentation/<feature>_screen.dart` (ej: `turno_screen.dart`)

- **Widget:** Ej: `TurnoScreen` como `ConsumerStatefulWidget`.
- **initState:** En un `addPostFrameCallback` llama a `ref.read(turnoNotifierProvider.notifier).loadAll()` para cargar datos al montar.
- **build:** Usa `ref.watch(turnoNotifierProvider)` y muestra:
  - `CircularProgressIndicator` si `isLoading`;
  - mensaje de error si `errorMessage != null`;
  - `ListView.builder` con `ListTile` (título y subtítulo con `item.name` e `item.id`) en caso de éxito.
- **Responsabilidad:** Pantalla principal de la feature; solo lee estado y dispara acciones; no contiene lógica de red ni de persistencia.

Debes **personalizar** la lista y las acciones (navegación, filtros, etc.) según la feature.

---

#### `presentation/widgets/.gitkeep`

- Archivo vacío (o solo nueva línea) para que Git mantenga la carpeta `widgets/` en el repositorio.
- Aquí puedes añadir después widgets específicos de la feature (tarjetas, formularios, etc.).

---

## 8. Flujo de datos end-to-end

Ejemplo con “cargar lista” en la feature `turno`:

1. **Usuario** abre la pantalla → `TurnoScreen` se monta.
2. **Presentation:** En `addPostFrameCallback`, `ref.read(turnoNotifierProvider.notifier).loadAll()`.
3. **Application:** `TurnoNotifier.loadAll()` pone `state = state.copyWith(isLoading: true)`, luego llama a `_repository.getAll()`.
4. **Infrastructure:** `TurnoRepositoryImpl.getAll()` llama a `TurnoRemoteDataSource.getAll()` (y opcionalmente guarda en local o usa cache local si falla).
5. **Infrastructure:** El datasource hace `_dio.get(...)` y devuelve mapas; el repositorio hace `Turno.fromJson(e)` y devuelve `List<Turno>`.
6. **Application:** El Notifier recibe la lista y hace `state = state.copyWith(items: items, isLoading: false)` (o actualiza error si hubo excepción).
7. **Presentation:** `ref.watch(turnoNotifierProvider)` provoca un rebuild; la UI muestra la lista (o loading/error).

El dominio solo ve entidades e interfaz del repositorio; la UI solo ve estado y Notifier.

---

## 9. Próximos pasos tras crear una feature

El script imprime al final una checklist. Resumida:

1. **Ajustar la entidad** en `domain/entities/<feature>.dart` (campos, validaciones, nombres).
2. **Ajustar la interfaz** en `domain/repositories/<feature>_repository.dart` (métodos que necesites).
3. **Configurar el RepositoryProvider** en `application/providers/<feature>_providers.dart`: inyectar Dio y datasources y devolver la implementación real (no `UnimplementedError`). Si el repositorio depende de `FutureProvider` (como en auth), considerar override en `main.dart` para el Notifier.
4. **Ajustar endpoints y parsing** en `infrastructure/datasources/<feature>_remote_datasource.dart`.
5. Si creaste local: **revisar** `infrastructure/datasources/<feature>_local_datasource.dart` (claves, modelo).
6. **Añadir ruta** a la pantalla en `core/router` (o tu sistema de rutas) para poder navegar a `<Entidad>Screen`.

Opcional: añadir widgets en `presentation/widgets/` y tests unitarios para dominio y para el Notifier (mockeando el repositorio).

---

## Referencias rápidas

- **Clean Architecture:** dominio en el centro, dependencias hacia dentro, interfaces en dominio.
- **Vertical Slice:** una feature = una carpeta con domain, application, infrastructure, presentation.
- **Estado:** Riverpod con State + StateNotifier en `application/providers`; UI solo watch/read.
- **Script:** `scripts/create_feature_flutter.sh --feature <snake_case> [--entity <PascalCase>] [--no-local]`.

Si quieres extender esta doc (por ejemplo con ejemplos de tests o de inyección de repositorio en un app ya existente), se puede añadir una sección extra en `docs/`.
