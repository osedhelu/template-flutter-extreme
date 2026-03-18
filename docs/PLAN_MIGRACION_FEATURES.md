## Plan de migración de features – Gestor PQRS

**Objetivo:** migrar de forma iterativa y modular la app Android nativa `gestor_pqr` a Flutter (`flutter-migrate-app`), manteniendo el mismo comportamiento funcional en Android e iOS.

**Arquitectura destino:** Clean Architecture + Vertical Slice por feature (según `CLEAN_ARCHITECTURE_VERTICAL_SLICE.md` y reglas de `arquitectura-clean-vertical-slice.mdc`).

**Regla de ámbito:** toda implementación nueva se hace únicamente dentro de `flutter-migrate-app/` (no se modifica código Android existente).

---

## 1. Mapa general de features y dependencias

Tabla resumen de slices a migrar (orden recomendado de migración):

| ID | Feature (snake_case) | Descripción corta | Depende de |
|----|----------------------|-------------------|------------|
| F01 | `permisos_app` | Gestión centralizada de permisos (almacenamiento, ubicación, cámara, Bluetooth) y chequeos de GPS al iniciar flujos críticos. | — |
| F02 | `config_http` | Configuración de conexión HTTP (URL base, logos remotos, parámetros de entorno) equivalente a `ConfHttpActivity`/`ConfHttpFragment`. | `permisos_app` |
| F03 | `auth` | Login, sesión persistente y redirección automática (login ↔ main) equivalente a `LoginActivity`. | `config_http`, `permisos_app` |
| F04 | `maestros` | Descarga y actualización de maestros/catálogos necesarios para otras features (motivos, tipos de trabajo, responsables, estados, etc.). Equivalente a `DownloadActivity` + facades de maestros. | `auth`, `config_http` |
| F05 | `rutas_trabajo` | Selección de zona/ciclo (`RoutesActivity`, `Batch`, `TasksFacade.updateRoute`) y conteo de trabajos por ruta. | `maestros`, `auth` |
| F06 | `tareas_pqrs` | Listado y gestión principal de PQRS/trabajos (`TasksActivity`, `Pqr`, `TasksFacade`, `PqrsFacade`), búsquedas, descargas, envío de pendientes y navegación al resto de flujos. | `rutas_trabajo`, `maestros`, `gps_core`, `sync_pendientes`, `encuestas_pqr`, `precierre_pqr`, `notificacion_pqr`, `materiales_pqr` |
| F07 | `gps_core` | Servicio/abstracción de GPS y validaciones de ubicación (permisos + obligatoriedad de GPS) usado por rutas, tareas, georreferenciación y notificaciones. | `permisos_app` |
| F08 | `sync_pendientes` | Gestión y envío manual/automático de pendientes (`XPendingController`, `PendingFacade`) integrado con tareas, encuestas, imágenes y firmas. | `config_http`, `auth` |
| F09 | `encuestas_pqr` | Motor de encuestas dinámicas de precierre/aplazo/rechazo (`SurveyActivity`, `DynamicFragment`, `Survey*`), incluyendo validaciones y navegación a resumen/firma. | `tareas_pqrs`, `materiales_pqr`, `notificacion_pqr` |
| F10 | `precierre_pqr` | Flujo de precierre/aprobación programada tipo mantenimiento (`PrecloseActivity`, `PrecloseProgrammedActivity`, `RejectAmpActivity`). | `tareas_pqrs`, `encuestas_pqr`, `maestros` |
| F11 | `materiales_pqr` | Manejo de materiales asociados al trabajo (uso de `MaterialsActivity`, `MaterialVO`, integración con encuestas/precierre). | `tareas_pqrs`, `maestros` |
| F12 | `notificacion_pqr` | Flujo de notificación formal al usuario: observación, impresión, fotos, firmas múltiples, alarmas (`NotificationActivity`, impresión Bluetooth). | `tareas_pqrs`, `gps_core`, `sync_pendientes` |
| F13 | `georeferencia_pqr` | Georreferenciación manual de trabajos en mapa (`MapActivity`, `TasksFacade.georeference`, `XGPSData`). | `gps_core`, `tareas_pqrs` |
| F14 | `reportes_pqr` | Pantallas de reportes y estadísticas (`ReportsActivity`, posibles consultas de `ReportFacade`). | `tareas_pqrs`, `maestros` |
| F15 | `busqueda_avanzada` | Búsqueda avanzada/local de trabajos y PQRS (`SearchActivity`, diálogos de búsqueda en `TasksActivity`). | `tareas_pqrs` |
| F16 | `configuracion_app` | Configuración general de la app móvil (no HTTP), incluyendo parámetros de usuario, comportamiento, inactividad, etc. (`ConfigurationActivity`, `InactividadActivity`, `InfoActivity`). | `auth`, `maestros` |
| F17 | `firmas_pqr` | Captura y envío de firmas (usuario, recurso, testigos) asociadas a trabajos/PQRS (parte de `NotificationActivity` y `SignatureActivity`). | `tareas_pqrs`, `notificacion_pqr`, `sync_pendientes` |
| F18 | `multimedia_pqr` | Captura/envío de fotos e imágenes asociadas a trabajos, precierre y encuestas (`CameraActivity` usos desde `TasksActivity`, `PrecloseActivity`, `SurveyActivity`, `NotificationActivity`). | `gps_core`, `sync_pendientes`, `tareas_pqrs` |

> Nota: `auth` y `config_http` ya tienen slice inicial en Flutter; este plan los amplía y los conecta con el resto de features.

---

## 2. Detalle por feature (formato compatible con `/migratefeature`)

Cada subsección está pensada para poder copiarse casi directamente como texto de entrada de `/migratefeature`, ajustando si hace falta el número/título.

---

### F01. Permisos al abrir la app (`permisos_app`)

- **Qué hacer:**
  - Centralizar en Flutter el flujo de solicitud de permisos que hoy se hace de forma distribuida en `LoginActivity`, `TasksActivity`, `RoutesActivity` y otras (permisos: `WRITE_EXTERNAL_STORAGE`, `READ_EXTERNAL_STORAGE`, `ACCESS_FINE_LOCATION`, `ACCESS_LOCATION_EXTRA_COMMANDS`, `CAMERA`, `BLUETOOTH`, `BLUETOOTH_ADMIN`).
  - Implementar una entidad de dominio que represente el estado de permisos críticos de la app (almacenamiento, GPS, cámara, Bluetooth).
  - Crear un provider de aplicación que:
    - Revise permisos al inicio de la app y antes de entrar a flujos que los requieran (rutas, tareas, notificaciones, fotos, mapas).
    - Exponga estados tipo: “faltan permisos”, “mostrar explicación”, “listo”.
  - Diseñar una pantalla/popup `PermissionsGate` reutilizable que:
    - Bloquee navegación a features críticas mientras falten permisos obligatorios.
    - Guíe al usuario a ajustes del sistema (similar a los diálogos manuales de GPS en `TasksActivity`/`RoutesActivity`).
  - Integrar esta feature con `main.dart` y el router para que:
    - Después del splash/login, si faltan permisos obligatorios, se derive a `PermissionsGate`.
    - Si todo está concedido, se continúe con el flujo normal (login o home).
- **Depende de:** ninguna (feature base sobre la que se apoyan las demás).
- **Permisos / Endpoints / Otros:**
  - Permisos Android: los que se piden explícitamente en `LoginActivity.checkPermission()` y validaciones de GPS en `TasksActivity` / `RoutesActivity`.
  - En iOS: reflejar equivalentes (location, camera, photos, Bluetooth) en `Info.plist`.
  - No introduce endpoints HTTP nuevos; solo condiciona el acceso al resto de features.

---

### F02. Configuración HTTP (`config_http`)

- **Qué hacer:**
  - Completar la migración de `ConfHttpActivity` + `ConfHttpFragment` hacia el slice existente `features/config_http/`:
    - Replicar la lógica de lectura/guardado de URL base, credenciales/identificadores y parámetros necesarios para endpoints.
    - Reproducir la descarga/mostrado dinámico del logo corporativo (lógica `CargarFoto()` que usa `AppController.ConsultarUrlFoto`).
  - Conectar `config_http` con `shared/api_client.dart` para establecer:
    - URL base.
    - Timeouts por defecto.
    - Headers comunes (por ejemplo, identificadores de recurso/contratista si aplican).
  - Definir claramente:
    - Entidad `HttpConfig` (ya existe) con todos los campos realmente usados en Android.
    - Repositorio de dominio `ConfigHttpRepository` y su implementación real que persista en preferences/BD local y sincronice con la UI.
  - Integrar la pantalla `ConfigHttpScreen` al router para que:
    - Sea accesible desde login (doble tap / opción de menú).
    - Pueda forzar re-login / recarga de maestros cuando cambia la config.
- **Depende de:** `permisos_app` (para descarga de logos a almacenamiento si se mantiene esa UX).
- **Permisos / Endpoints / Otros:**
  - Acceso HTTP base hacia los mismos servlets que usa `XCUtilsServlets` vía `xasynchttp`.
  - Posible manejo de imágenes: almacenamiento interno de imagen descargada para logos.

---

### F03. Autenticación y sesión (`auth`)

- **Qué hacer:**
  - Consolidar en Flutter el flujo de `LoginActivity`:
    - Formulario usuario/contraseña.
    - Validaciones de campos obligatorios.
    - Verificación de conectividad (`isConnectedToInternet`) antes de llamar al backend.
    - Llamada a `AppController.login(user, password)` → mapear a `AuthRepository.login(...)` con endpoints reales.
  - Replicar la lógica de sesión persistente (`user_logged_in` en `SharedPreferences`):
    - Al abrir la app, decidir si se muestra login o se entra directo a la pantalla principal.
    - En caso de sesión existente pero backend invalide la sesión, forzar logout.
  - Mantener la lógica de redirección posterior al login:
    - Actualmente se redirige a `DownloadActivity` con parámetros `SEARCH_MASTERS`, `VALIDATE_PARAMETERS`.
    - En Flutter, tras login exitoso se debe:
      - Lanzar el flujo de descarga de maestros (`maestros`) si corresponde.
      - Solo entonces permitir navegar a la pantalla principal (`home` con rutas/tareas).
  - Integrar el estado de sesión `AuthNotifier` con el router y con providers de otras features (para acceso al recurso actual, tipo de usuario, etc.).
- **Depende de:** `config_http`, `permisos_app`.
- **Permisos / Endpoints / Otros:**
  - Endpoints de login usados en `AppController.login` (a revisar en fase de análisis detallado).
  - Almacenar datos de `Resource` (tipo de usuario, nombre, id, etc.) porque son usados en múltiples flujos (tareas, notificación, precierre).

---

### F04. Descarga de maestros (`maestros`)

- **Qué hacer:**
  - Identificar todos los maestros que se cargan en la app actual:
    - Tipos de trabajo (`TypeTask`).
    - Motivos (`MotivosFacade`).
    - Maestros de responsables (`VisitManagerVO`).
    - Estados de ejecución (`ExecutionStatesVO`).
    - Parámetros de impresión (`Parameter`, formatos para notificación).
    - Cualquier otro catálogo que se usa sin ir al backend cada vez.
  - Modelar en Flutter:
    - Entidades de dominio por maestro (por ejemplo, `ExecutionState`, `VisitManager`, `PrintParameter`).
    - Un repositorio `MaestrosRepository` que:
      - Descargue todos los maestros necesarios después del login o cuando el usuario lo solicite.
      - Los persista en BD local o preferences (similar a `AppController` + `DBController` actual).
  - Exponer providers que:
    - Permitan al resto de features leer maestros en memoria sin volver al backend.
    - Ofrezcan estados de “cargando maestros” y gestionen errores.
  - Reproducir la UX de `DownloadActivity`:
    - Mostrar progreso mientras se descargan maestros y trabajos iniciales.
    - Manejar reintentos cuando no hay conexión.
- **Depende de:** `auth`, `config_http`.
- **Permisos / Endpoints / Otros:**
  - Endpoints de maestros en `XCUtilsServlets` utilizados por `MastersFacade`, `MotivosFacade`, etc.
  - Sin permisos extra distintos a red.

---

### F05. Rutas / Zonas de trabajo (`rutas_trabajo`)

- **Qué hacer:**
  - Migrar el comportamiento de `RoutesActivity` y `TasksFacade` relevante a rutas (`Batch`):
    - Listar zonas con trabajos asociados, mostrando conteos de trabajos por zona.
    - Permitir seleccionar una sola ruta activa (marcar `selected` y desmarcar las demás).
    - Actualizar el conteo de trabajos pendientes cuando se completan/precierra una PQRS.
  - Diseñar en Flutter:
    - Entidad `RouteBatch` (equivalente a `Batch`).
    - Repositorio `RutasRepository` que lea/escriba rutas en almacenamiento local (BD o preferences).
    - Provider que exponga:
      - Lista de rutas.
      - Ruta seleccionada.
      - Operación para seleccionar ruta (actualizando tanto memoria como persistencia).
  - Integrar esta feature con `tareas_pqrs`:
    - Al seleccionar una ruta, refrescar el listado de tareas filtrado por zona.
    - Mantener visualmente qué ruta está activa (íconos y color, como en `RoutesActivity`).
- **Depende de:** `maestros`, `auth`, `gps_core` (para validaciones de GPS obligatorias antes de trabajar en rutas).
- **Permisos / Endpoints / Otros:**
  - Validación de GPS similar a `RoutesActivity.GpsObligatorio`.
  - Endpoints de descarga de rutas si los hay (a revisar en `AppController.getAllRoutes()` y `TasksFacade.downloadTasks`).

---

### F06. Listado y gestión de tareas/PQRS (`tareas_pqrs`)

- **Qué hacer:**
  - Migrar el papel central de `TasksActivity` y `TasksFacade`:
    - Listado de PQRS/trabajos (usando entidad `Pqr` y/o `Task`).
    - Distintas vistas según tipo de usuario (`RESPONSABLE`, `TECNICO`, `BRIGADISTA`).
    - Filtros y búsquedas (`searchPqrs`, `searchTask`, selección de criterios).
    - Descarga/actualización de trabajos (`downloadpqrs`, `downloadTasks`).
    - Envío de pendientes (`sendPendings`).
    - Menús contextuales (QuickAction) para:
      - Gestionar (precierre).
      - Aprobar/rechazar.
      - Programar/desprogramar.
      - Ver información (`InfoActivity`, `InfoJobsActivity`).
      - Abrir mapa (georreferencia).
      - Tomar foto.
  - En Flutter:
    - Definir entidades de dominio:
      - `Pqr`, `Task`, `TipoUsuario`, `EstadoPqr`, `EstadoProgramacion`, etc.
    - Repositorio `TareasPqrsRepository`:
      - Sincroniza con backend (descarga y actualizaciones).
      - Lee/escribe en BD local (equivalente a `DBController` vía `TasksFacade`).
      - Expone operaciones de negocio: descargar, recargar, filtrar, buscar, marcar como precerrada/postergada, etc.
    - Provider principal:
      - Maneja estado: lista de PQRS, filtros activos, loading, error.
      - Orquesta llamadas a `sync_pendientes`, `gps_core`, `encuestas_pqr`, `precierre_pqr`, `notificacion_pqr`, `georeferencia_pqr`.
  - Reproducir UX de selección múltiple y asignación/desasignación (menú “asignar”, “desasignar”, “seleccionar todo”).
  - Sincronizar con rutas:
    - Cuando cambia la ruta seleccionada, se actualiza la lista de trabajos.
    - Ajustar contadores de trabajos por zona cuando se precierra o pospone.
- **Depende de:** `rutas_trabajo`, `maestros`, `gps_core`, `sync_pendientes`, `encuestas_pqr`, `precierre_pqr`, `multimedia_pqr`, `georeferencia_pqr`.
- **Permisos / Endpoints / Otros:**
  - Uso intensivo de endpoints de tareas y PQRS (`XCUtilsServlets.TASK_D`, `TASK_B`, etc.).
  - Validación de conexión (`NetworkUtil.isNetworkConnected`) previa a operaciones sensibles.

---

### F07. Núcleo de GPS y ubicación (`gps_core`)

- **Qué hacer:**
  - Unificar todo el comportamiento de GPS disperso en:
    - `TasksActivity.GpsObligatorio` / `checkGpsStatus` / diálogos de “GPS obligatorio”.
    - `RoutesActivity.GpsObligatorio` y sus validaciones.
    - Georreferenciación en `TasksFacade.georeference(Task, XGPSData)` y el uso de `XGPSData`.
  - En Flutter:
    - Crear una entidad simple `GpsStatus` (estado de permiso + estado de proveedor).
    - Provider/servicio `GpsService`:
      - Revisa y solicita permisos de localización.
      - Chequea si el GPS está encendido, mostrando diálogos equivalentes a Android (en Flutter: navegación a ajustes).
      - Expone ubicaciones actuales/últimas.
    - Integrar con:
      - `tareas_pqrs` para georreferenciación y precierre.
      - `rutas_trabajo` al seleccionar zona (si se requiere validación de GPS).
      - Flujos de notificación y encuestas que requieran coordenadas.
  - Mapear `georeference` a una operación de dominio reutilizable (no acoplada a UI).
- **Depende de:** `permisos_app`.
- **Permisos / Endpoints / Otros:**
  - Permisos de localización fina y comandos extra.
  - Endpoints relacionados a georreferenciación (`XCUtilsServlets.TASK_G`).

---

### F08. Sincronización de pendientes (`sync_pendientes`)

- **Qué hacer:**
  - Reproducir en Flutter la lógica de pendientes de `XPendingController` y `PendingFacade` usada en:
    - `TasksActivity.sendPendings`.
    - `TasksFacade.sendSurvey`, `sendImage`, `sendSignatures`.
    - Notificación y precierre.
  - Diseñar:
    - Entidad `Pending` (equivalente a `XPending`).
    - Datasource local en Flutter para almacenar pendientes (por ejemplo, BD SQLite/Hive).
    - Repositorio `PendingRepository` con:
      - Cola de pendientes a enviar.
      - Operaciones para disparar envíos manuales y automáticos.
  - Provider que:
    - Pueda ser invocado desde otras features para “enqueuear” operaciones (encuestas, imágenes, firmas, georreferenciación, etc.).
    - Exponga estado global de sincronización (por ejemplo, hay pendientes/enviado/errores).
- **Depende de:** `config_http`, `auth`.
- **Permisos / Endpoints / Otros:**
  - Reutiliza los mismos servlets que Android para cada tipo de pendiente (precierre, rechazo, aplazo, fotos, firmas, georreferencia).

---

### F09. Encuestas dinámicas de PQR (`encuestas_pqr`)

- **Qué hacer:**
  - Migrar el motor de encuestas de `SurveyActivity`, `DynamicFragment`, `XFormView`, `SurveyItem`, `SurveyQuestion`, `SurveyResponse`:
    - Tabbed UI por secciones de encuesta.
    - Validación por pregunta (`xView.isValidResponse()` y mensajes de error).
    - Navegación controlada: no permite pasar de tab si la sección actual tiene errores.
  - En Flutter:
    - Mantener una representación de:
      - `Survey` (tipo: precierre realizado, no realizado, rechazo, aplazo).
      - `SurveyItem`/secciones.
      - `SurveyQuestion` y `SurveyResponse`.
    - Construir un widget dinámico de formulario basado en estos modelos (análogo a `XFormView`).
    - Provider que orqueste:
      - Carga de encuestas desde BD local/maestros.
      - Recogida de respuestas.
      - Transformación a la estructura que necesita `sync_pendientes` / backend.
  - Conectar con:
    - `tareas_pqrs` para decidir qué encuesta se usa según tipo de trabajo y estado.
    - `materiales_pqr` cuando la encuesta permite/obliga captura de materiales.
    - `notificacion_pqr` cuando hay flujos de notificación específicos (precierre de notificación vs inspección).
- **Depende de:** `tareas_pqrs`, `maestros`, `sync_pendientes`.
- **Permisos / Endpoints / Otros:**
  - Endpoints de envío de encuestas (`XCUtilsServlets.TASK_E`, `TASK_R`, `TASK_A`).
  - Sin permisos adicionales, pero se combina con fotos (feature `multimedia_pqr`).

---

### F10. Precierre y aprobación de PQR (`precierre_pqr`)

- **Qué hacer:**
  - Migrar el flujo de precierre y aprobación que hoy implementa `PrecloseActivity` y `PrecloseProgrammedActivity`:
    - Formulario de visita (responsable, fechas, estado de ejecución, trimestre, concepto técnico, observaciones).
    - Diferenciar entre:
      - Guardar precierre localmente.
      - Enviar precierre.
      - Aprobar precierre programado (con cálculo de días hasta fecha límite).
    - Integración con consultas previas (`ConsultarDatos_Aprobacion`).
  - En Flutter:
    - Entidades de dominio:
      - `GestionPqr` / `PrecloseData` (con todos los campos que se envían).
      - `ExecutionState`, `VisitManager` (apoyarse en `maestros`).
    - Repositorio `PrecierreRepository` que:
      - Consulte datos previos de mantenimiento.
      - Guarde/actualice precierres locales.
      - Genere pendientes de envío cuando haya conexión.
    - Pantallas:
      - `PrecloseScreen` (precierre normal).
      - `PrecloseProgrammedScreen` (precierre programado).
      - Integradas con `tareas_pqrs` (desde QuickAction de cada PQR).
  - Respetar reglas de negocio:
    - Campos obligatorios por tipo de estado de ejecución.
    - Habilitar campos de planeación/trimestre solo cuando el estado corresponde a programación.
- **Depende de:** `tareas_pqrs`, `maestros`, `encuestas_pqr`, `sync_pendientes`.
- **Permisos / Endpoints / Otros:**
  - Endpoints gestionados actualmente por `AppController.GestionPqr`, `GestionGuardarPqr`, `AprobarGestionPqr`.

---

### F11. Materiales asociados a PQR (`materiales_pqr`)

- **Qué hacer:**
  - Migrar la lógica de materiales que se usa conjuntamente con encuestas y precierre (`MaterialsActivity`, `MaterialVO`, `TasksFacade`):
    - Catálogo de materiales.
    - Selección/cantidad por trabajo.
    - Asociación de materiales al envío de precierre/encuesta.
  - En Flutter:
    - Entidad `Material` de dominio.
    - Repositorio `MaterialesRepository`:
      - Lee catálogo de materiales desde maestros.
      - Asocia materiales seleccionados a un trabajo/PQR.
    - Provider y widgets para:
      - Listado/selección de materiales.
      - Integración limpia con `encuestas_pqr` y `precierre_pqr`.
- **Depende de:** `tareas_pqrs`, `maestros`.
- **Permisos / Endpoints / Otros:**
  - Endpoints de materiales usados en backend vía `TasksFacade.sendSurvey` cuando `typeMaterials` es true.

---

### F12. Notificación formal de PQR (`notificacion_pqr`)

- **Qué hacer:**
  - Migrar el flujo completo de `NotificationActivity`:
    - Modo solo observación (texto).
    - Modo con preguntas: datos del usuario, testigos, recurso, firmas, observación.
    - Integración con impresión Bluetooth (`BTController`, `PrinterPage`, parámetros de impresión).
    - Integración con fotos y firmas (ver `multimedia_pqr` y `firmas_pqr`).
    - Envío/registro de alarmas desde esta pantalla.
  - En Flutter:
    - Entidades de dominio:
      - `NotificationPrint` (datos que se imprimen y se envían).
      - `NotificationParty` (usuario, testigo, recurso) con sus datos y firma asociada.
    - Repositorio `NotificacionRepository`:
      - Guarda notificaciones pendientes/locales.
      - Orquesta el envío de notificación completa (datos + fotos + firmas) a través de `sync_pendientes`.
    - Pantallas:
      - `NotificationObservationScreen` (solo texto).
      - `NotificationSignScreen` (recolección de datos y firmas).
      - Integradas al flujo desde `TasksActivity` y `SurveyActivity`.
    - Adaptar impresión Bluetooth:
      - En Flutter, encapsular la lógica de impresión en un servicio, reutilizando JSON de `PrinterPage`.
  - Mantener reglas:
    - No permitir volver atrás una vez iniciado cierto punto del flujo (similar a restricciones de back actuales).
    - Validar que toda la información requerida esté presente antes de continuar.
- **Depende de:** `tareas_pqrs`, `gps_core`, `sync_pendientes`, `firmas_pqr`, `multimedia_pqr`.
- **Permisos / Endpoints / Otros:**
  - Bluetooth clásico para impresión.
  - Endpoints de envío de notificación (a partir de `NotificationFacade`).

---

### F13. Georreferenciación en mapa (`georeferencia_pqr`)

- **Qué hacer:**
  - Migrar el flujo de mapa (`MapActivity`) que muestra trabajos/PQRS en mapa y permite georreferenciar:
    - Presentar la posición actual del dispositivo y la posición de la PQR.
    - Permitir actualizar coordenadas de la PQR (usando `TasksFacade.georeference`).
  - En Flutter:
    - Crear pantalla `PqrMapScreen` conectada a `gps_core` y `tareas_pqrs`.
    - Integrar un plugin de mapas (Google Maps/Apple Maps) según plataforma.
    - Mantener la regla de guardar nueva latitud/longitud localmente y generar pendiente para el backend.
- **Depende de:** `gps_core`, `tareas_pqrs`, `sync_pendientes`.
- **Permisos / Endpoints / Otros:**
  - Permisos de localización.
  - Endpoints de georreferenciación (`TASK_G`).

---

### F14. Reportes (`reportes_pqr`)

- **Qué hacer:**
  - Identificar qué reportes existen en `ReportsActivity` y `ReportFacade`:
    - Listados/resúmenes de PQRS por estado, zona, tiempo, etc.
  - En Flutter:
    - Definir entidad `ReportePqr` o similares.
    - Repositorio `ReportesRepository` que:
      - Consulte backend para datos agregados.
      - Use, cuando sea posible, datos ya descargados (reutilizar `tareas_pqrs`).
    - Pantallas de reportes con filtros básicos y visualizaciones acordes (tablas/listas/gráficas simples).
- **Depende de:** `tareas_pqrs`, `maestros`, `auth`.
- **Permisos / Endpoints / Otros:**
  - Endpoints de reportes que use hoy `ReportFacade`.

---

### F15. Búsqueda avanzada de PQRS (`busqueda_avanzada`)

- **Qué hacer:**
  - Extraer y organizar en Flutter las capacidades de búsqueda ya presentes en:
    - Diálogo de búsqueda en `TasksActivity` (`showSearchDialog` + `searchPqrs`, `searchTask`, `searchPqr`).
    - `SearchActivity` si tiene lógica adicional.
  - En Flutter:
    - Provider `BusquedaPqrsProvider` responsable de:
      - Mantener criterios de búsqueda (radicado, estado, tipo actividad, etc.).
      - Ejecutar búsquedas a nivel local (sobre datos descargados) y/o remotas (backend).
    - Pantalla dedicada de búsqueda con:
      - Campos y combos equivalentes a los de Android.
      - Integración con `tareas_pqrs` para mostrar resultados.
- **Depende de:** `tareas_pqrs`, `maestros`.
- **Permisos / Endpoints / Otros:**
  - Endpoints de búsqueda si se usan (`TasksFacade.searchTaskByCode`, `AppController.searchPqrs`).

---

### F16. Configuración general de la app (`configuracion_app`)

- **Qué hacer:**
  - Migrar funcionalidades de:
    - `ConfigurationActivity` (opciones de configuración general).
    - `InactividadActivity` (manejo de inactividad).
    - `InfoActivity` (información general de recurso, app, etc.).
  - En Flutter:
    - Agrupar estas pantallas en un slice que:
      - Exponga ajustes persistentes (inactividad, preferencias de impresión, etc.).
      - Muestre información de versión, recurso actual, empresa.
    - Repositorio `ConfiguracionAppRepository`:
      - Persistencia de ajustes en preferences/BD.
      - Lectura para integrarse con otras features (por ejemplo, temporizadores de inactividad).
- **Depende de:** `auth`, `maestros`.
- **Permisos / Endpoints / Otros:**
  - Sin permisos especiales más allá de los ya gestionados en features base.

---

### F17. Firmas asociadas a PQR (`firmas_pqr`)

- **Qué hacer:**
  - Separar en Flutter la responsabilidad de captura/envío de firmas que hoy está distribuida entre:
    - `NotificationActivity` (usuario, recurso, testigo 1, testigo 2).
    - `SignatureActivity`.
    - Lógica de envío en `TasksFacade.sendImage` y `sendSignatures`.
  - En Flutter:
    - Crear un conjunto de widgets reutilizables de firma (canvas + guardado de imagen).
    - Entidades de dominio:
      - `Firma` (tipo, imagen, metadata).
    - Repositorio `FirmasRepository`:
      - Maneja almacenamiento temporal/local de imágenes de firma.
      - Genera pendientes para envío junto con datos de notificación/encuesta.
  - Integrar con:
    - `notificacion_pqr` (firmas de notificación).
    - `encuestas_pqr` y `precierre_pqr` donde aplique.
- **Depende de:** `multimedia_pqr`, `sync_pendientes`, `tareas_pqrs`.
- **Permisos / Endpoints / Otros:**
  - Endpoints de carga de imágenes/firmas (los mismos que utiliza hoy `XCUtilsServlets.TASK_F`).

---

### F18. Multimedia de PQR (fotos e imágenes) (`multimedia_pqr`)

- **Qué hacer:**
  - Unificar en Flutter todos los usos de `CameraActivity` y envío de fotos:
    - Desde `TasksActivity` (fotos de trabajos).
    - Desde `PrecloseActivity` (soporte de precierre).
    - Desde `SurveyActivity` (fotos asociadas a encuestas).
    - Desde `NotificationActivity` (fotos de notificación, fotos con hora).
  - En Flutter:
    - Servicios y widgets para:
      - Capturar foto con cámara.
      - Seleccionar fotos desde galería (donde aplique).
      - Manejar metadata (timestamp, tipo de foto, poliza/trabajo).
    - Repositorio `MultimediaRepository`:
      - Simplifica generación de pendientes de fotos (similar a `TasksFacade.sendImage`).
      - Asocia fotos a trabajos/PQRS, notificaciones y encuestas.
  - Integrar estrechamente con `sync_pendientes` para:
    - Enviar fotos en background.
    - Manejar reintentos.
- **Depende de:** `gps_core` (cuando se requiera posición para fotos), `sync_pendientes`, `tareas_pqrs`.
- **Permisos / Endpoints / Otros:**
  - Permisos de cámara y almacenamiento.
  - Endpoints de upload de imágenes (`TASK_F`).

---

## 3. Orden sugerido de migración iterativa

1. **Base técnica y features ya iniciadas**
   - Completar/afinar `config_http` y `auth`.
   - Implementar `permisos_app`, `gps_core`, `sync_pendientes`.
2. **Flujo mínimo funcional**
   - `maestros` → `rutas_trabajo` → `tareas_pqrs` (listado simple sin todos los subflujos).
3. **Flujos de gestión principales**
   - `encuestas_pqr`, `precierre_pqr`, `materiales_pqr`, `multimedia_pqr`.
4. **Flujos avanzados**
   - `notificacion_pqr`, `firmas_pqr`, `georeferencia_pqr`.
5. **Complementos**
   - `reportes_pqr`, `busqueda_avanzada`, `configuracion_app`.

Este orden permite ir liberando valor incremental en Flutter mientras la app nativa sigue operativa, migrando módulo a módulo con dependencias claras.

