# Plan de migración: Android nativo → Flutter (Caribe Mar)

**Proyecto origen:** `app` (Android nativo, Java/Kotlin)  
**Proyecto destino:** `flutter-migrate-app` (Flutter)  
**Objetivo:** Migrar todas las funcionalidades de la app Android a Flutter, con **solicitud de permisos al abrir la app** (antes del login).

---

## 1. Permisos al abrir la app

### Requerimiento
Los permisos deben pedirse **desde que se abra la app**, no al hacer clic en "Login".

### En Android actual
- En **LoginActivity** los permisos se piden al pulsar el botón Login (`checkPermission()` → `requestPermissions`).
- Se solicitan: `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, y en API ≥ 29 `ACCESS_BACKGROUND_LOCATION`.

### En Flutter (a implementar)
1. **Pantalla/splash de permisos al inicio**
   - Primera pantalla tras abrir la app: comprobar y solicitar permisos necesarios.
   - Permisos a pedir desde el inicio:
     - Ubicación (fine + coarse; en Android 10+ también background si aplica).
     - Opcional en este momento: cámara, almacenamiento, teléfono (se pueden pedir cuando el usuario entre en la feature que los use).
   - Si el usuario deniega ubicación: mostrar explicación y opción de “Reintentar” o “Abrir ajustes”; permitir continuar a login solo con aviso de que algunas funciones (GPS) no estarán disponibles.
2. **Flujo propuesto**
   - `main()` → **Splash/PermissionsGate** (pedir permisos) → **RootRouter** (login si no hay sesión / home si hay sesión).
3. **Paquetes Flutter**
   - `permission_handler`: solicitud y estado de permisos.
   - Configurar `AndroidManifest.xml` e `Info.plist` con los mismos permisos que la app Android (ver sección de permisos más abajo).

---

## 2. Resumen de features a migrar

| # | Feature | Depende de | Prioridad |
|---|--------|------------|-----------|
| 0 | **Permisos al inicio** | — | P0 |
| 1 | **Auth (login, sesión, logout)** | Permisos, Config HTTP | P0 |
| 2 | **Config HTTP / Configuración conexión** | — | P0 |
| 3 | **Config GPS** | Config HTTP, sesión | P1 |
| 4 | **Descarga de maestros** | Auth, Config HTTP | P1 |
| 5 | **Turno (inicio/fin)** | Auth, Maestros | P1 |
| 6 | **Lista de trabajos (XControl principal)** | Auth, Turno, Maestros | P1 |
| 7 | **Reglas de trabajo + cámara/fotos** | Trabajos, Permisos cámara/almacenamiento | P2 |
| 8 | **Causales (causa localizada)** | Trabajos | P2 |
| 9 | **Precierre / observación / resumen** | Trabajos, Reglas | P2 |
| 10 | **Materiales (lista, búsqueda, desmontados)** | Auth, Maestros | P2 |
| 11 | **Trabajadores (alta, formulario)** | Auth, Config HTTP | P2 |
| 12 | **Utilidades (turno, info recurso, cerrar sesión)** | Auth | P2 |
| 13 | **Servicio GPS en segundo plano** | Permisos ubicación, Auth, Config GPS | P1 |
| 14 | **Cola de pendientes (envío)** | Auth, BD local | P1 |
| 15 | **Conteo horario (service)** | Auth, Turno, Pendientes | P2 |
| 16 | **Widget flotante (opcional)** | Pendientes, Permisos overlay | P3 |
| 17 | **Push (Firebase)** | Auth | P2 |
| 18 | **Avisos asignados** | Auth, Trabajos | P2 |
| 19 | **Encuestas (aplazo, precierre, rechazo, etc.)** | Trabajos | P2 |
| 20 | **Órdenes de apoyo** | Trabajos | P2 |
| 21 | **Galería de fotos** | Almacenamiento, Trabajos/Reglas | P2 |
| 22 | **Info trabajo / Info recurso** | Auth, Trabajos/Recurso | P2 |

---

## 3. Dependencias entre features (grafo resumido)

```
Permisos al inicio
       │
       ├──► Auth (login, sesión)
       │         │
       │         ├──► Config GPS
       │         ├──► Descarga maestros
       │         │         │
       │         │         └──► Turno
       │         │                   │
       │         │                   └──► Lista trabajos (XControl)
       │         │                                 │
       │         │                                 ├──► Reglas + Cámara
       │         │                                 ├──► Causales
       │         │                                 ├──► Precierre / Observación / Resumen
       │         │                                 ├──► Encuestas
       │         │                                 ├──► Órdenes apoyo
       │         │                                 ├──► Avisos asignados
       │         │                                 └──► Info trabajo / recurso
       │         │
       │         ├──► Materiales (lista, búsqueda, desmontados)
       │         ├──► Trabajadores (alta, formulario)
       │         ├──► Utilidades
       │         ├──► Servicio GPS
       │         ├──► Cola pendientes
       │         │         │
       │         │         └──► Conteo horario ──► Widget flotante (opcional)
       │         ├──► Push (Firebase)
       │         └──► Galería fotos
       │
Config HTTP ──► Auth, Descarga, Trabajadores
```

- **Permisos al inicio** y **Config HTTP** no dependen de nada; son la base.
- **Auth** depende de Config HTTP (URL/servidor) y de tener permisos pedidos ya al abrir la app.
- **Trabajos, materiales, trabajadores, utilidades, GPS, pendientes, push, galería** dependen de Auth (y en muchos casos de maestros/turno).

---

## 4. Estado actual del proyecto Flutter

Ya existe en `flutter-migrate-app`:

- **Auth:** login, sesión, `AuthNotifier`, `AuthRepository`, `AuthRepositoryGate`, `RootRouter` (login vs home).
- **Config HTTP:** entidades, repositorio, datasources (local/remote), providers, pantalla `ConfigHttpScreen`.
- **Shared:** `preferences_datasource`, `api_client`, `app_database`, `preferences_provider`.
- **Core:** `app_router`, `app_theme`, `app_palette`, `app_env`, `api_error_message`.

Falta por migrar (entre otros): permisos al inicio, config GPS, descarga maestros, turno, lista trabajos, reglas, causales, precierre, materiales, trabajadores, utilidades, servicio GPS, pendientes, conteo, widget flotante, push, avisos, encuestas, órdenes apoyo, galería, info trabajo/recurso.

---

## 5. Detalle por feature (qué hacer en cada una)

### 0. Permisos al abrir la app (P0)
- **Qué hacer:**
  - Añadir `permission_handler` y declarar en `AndroidManifest.xml` e `Info.plist` los mismos permisos que la app Android (ubicación, cámara, almacenamiento, teléfono, etc.).
  - Crear pantalla o widget **PermissionsGate**: al abrir la app, comprobar ubicación (y opcionalmente el resto); si faltan, solicitar; si denegados, mostrar mensaje y botón “Reintentar” / “Abrir ajustes”; cuando esté resuelto (o el usuario continúe), navegar a `RootRouter`.
  - Cambiar flujo: `main` → `PermissionsGate` → `RootRouter` (login/home).
- **Depende de:** nada.
- **Permisos a declarar/pedir desde inicio:** al menos `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`; en Android 10+, considerar `ACCESS_BACKGROUND_LOCATION` en el mismo flujo inicial.

---

### 1. Auth – Login, sesión, logout (P0)
- **Qué hacer:**
  - Mantener y ajustar login (usuario/clave), llamada a API `perfil/login`, guardar sesión (SharedPreferences/secure storage), recurso y estado de vista.
  - Redirección post-login: si `session.getStateView()` → home principal (XControl); si no → pantalla de alta de trabajadores (AddWorkers).
  - Logout: `perfil/logout`, limpiar sesión y detener servicios (GPS, pendientes, etc.) antes de ir a login.
  - Integrar con PermissionsGate: primero permisos, luego esta pantalla si no hay usuario.
- **Endpoints:** `perfil/login`, `perfil/logout`, `perfil/conexion`, `perfil/disponible`, `perfil/horaservidor`, `perfil/registro` (notificaciones).
- **Depende de:** Permisos al inicio, Config HTTP.

---

### 2. Config HTTP / Configuración conexión (P0)
- **Qué hacer:**
  - Ya existe `ConfigHttpScreen` y capa de datos; completar si falta: URL base, timeouts, y persistencia en BD/local (equivalente a `XConfHttp`).
  - Desde configuración (o primera vez) permitir cambiar servidor y probar conexión; después poder volver a login.
- **Depende de:** nada (es base para login y descarga).

---

### 3. Config GPS (P1)
- **Qué hacer:**
  - Pantalla/opciones para intervalo de envío GPS, habilitar/deshabilitar en segundo plano, etc. (equivalente a `ConfiguracionGPSBL` y `XConfGPS` en BD).
  - Persistir configuración y usarla en el servicio GPS Flutter.
- **Depende de:** Config HTTP, Auth (para saber si hay sesión al guardar).

---

### 4. Descarga de maestros (P1)
- **Qué hacer:**
  - Pantalla “Descarga” (como `DescargaActivity`): llamar a `maestro/cantidades` y `maestro/descargar` por cada maestro (Causales, Contactos, Encuestas, Materiales, Municipios, Motivos no disponible, Pendientes, Trabajos, Tipos trabajo, Reglas, Trabajadores, Parametros, Turnos).
  - Persistir en BD local (SQLite vía drift/sqlite o equivalente) las entidades: CausalVO, ContactoVO, EncuestaA/P/R, MaterialVO, MotivoNoDisponibleVO, OperacionTrabajoVO, RecursoVO, ReglaVO, TrabajadorVO, TrabajoVO, TipoTrabajoVO, ParametrosVO, TurnoV0, etc.
  - Sincronizar esquema de BD con el de Android (DBController, tablas existentes).
- **Depende de:** Auth, Config HTTP.

---

### 5. Turno (inicio/fin) (P1)
- **Qué hacer:**
  - Pantalla `TurnoActivity`: inicio de turno (y posiblemente fin/salida con `perfil/salirturno`).
  - Guardar turno activo en BD (`TurnoV0`) y en sesión; desde Utilidades o flujo principal permitir “salir turno”.
  - Navegación: si hay que elegir turno antes del home, mostrar turno antes de XControl.
- **Depende de:** Auth, Descarga maestros (turnos y recurso).

---

### 6. Lista de trabajos (XControl principal) (P1)
- **Qué hacer:**
  - Recrear `XControlActivity`: tabs principales (Lista Trabajos, Reglas, Configuración, Utilidades).
  - **Tab Lista Trabajos:** lista de trabajos desde BD/local + posible refresco con `trabajo/descargar` o `descargarespecificos`; ítems con estado, prioridad, etc.
  - Navegación a: Reglas, Causales, Precierre, Materiales, Órdenes apoyo, Avisos, Info trabajo, etc.
  - Quick actions / menú contextual por trabajo (iniciar, aplazar, rechazar, apoyo, fallida, etc.) con llamadas a los endpoints correspondientes.
- **Endpoints:** `trabajo/descargar`, `trabajo/descargarespecificos`, `trabajo/iniciar`, `trabajo/precerrar`, `trabajo/causalocalizada`, `trabajo/regla`, `trabajo/aplazar`, `trabajo/rechazar`, `trabajo/apoyo`, `trabajo/fallida`, `trabajo/descargado`, `fileupload/foto`.
- **Depende de:** Auth, Turno, Descarga maestros.

---

### 7. Reglas de trabajo + cámara/fotos (P2)
- **Qué hacer:**
  - Pantalla reglas (`ReglasActivity`): listado de reglas por trabajo; captura de fotos (cámara) y subida con `fileupload/foto`.
  - Pedir permisos de cámara y almacenamiento en el momento de abrir cámara o galería (o en PermissionsGate si se quiere todo al inicio).
  - Guardar fotos en ruta conocida y asociar a regla/trabajo; subir a servidor.
- **Depende de:** Trabajos, Permisos cámara/almacenamiento.

---

### 8. Causales – Causa localizada (P2)
- **Qué hacer:**
  - Pantalla causal (`CausalActivity`): selección de causal desde maestros (CausalVO), envío con `trabajo/causalocalizada`.
  - Navegación desde lista de trabajos o detalle de trabajo.
- **Depende de:** Trabajos, Maestros (causales).

---

### 9. Precierre / observación / resumen (P2)
- **Qué hacer:**
  - **Observación precierre:** pantalla de observación y envío (endpoints de precierre).
  - **Resumen precierre:** pantalla resumen de precierres realizados.
  - Encuestas de precierre si aplican (maestros EncuestaP).
- **Depende de:** Trabajos, Reglas, Maestros.

---

### 10. Materiales – Lista, búsqueda, desmontados (P2)
- **Qué hacer:**
  - Pantallas: lista de materiales (`MaterialesActivity`), búsqueda (`BusquedaMaterialesActivity`), materiales desmontados (`MaterialDesmontadoActivity`).
  - Datos desde BD local (MaterialVO) y posibles llamadas a servidor si hay sincronización.
  - Navegación desde XControl o menú.
- **Depende de:** Auth, Maestros (materiales).

---

### 11. Trabajadores – Alta y formulario (P2)
- **Qué hacer:**
  - Pantallas `AddWorkersActivity` y `WorkersFormActivity`: formulario de alta de trabajadores, envío con `trabajadores/registrar`, persistencia local (TrabajadorVO).
  - Redirección post-login cuando no hay “state view” (igual que en Android).
- **Depende de:** Auth, Config HTTP.

---

### 12. Utilidades (P2)
- **Qué hacer:**
  - Pantalla utilidades (`UtilidadesActivity`): acceso a Turno, Info recurso, Cerrar sesión, y cualquier otro ítem (configuración, etc.).
  - Info recurso: datos del recurso logueado (desde sesión/BD).
  - Permiso de llamada (`CALL_PHONE`) si hay “llamar” en utilidades; pedirlo al usar la acción.
- **Depende de:** Auth.

---

### 13. Servicio GPS en segundo plano (P1)
- **Qué hacer:**
  - Usar `geolocator` (o similar) con ubicación en segundo plano; foreground service en Android (plugin o `flutter_foreground_task` / equivalente) para cumplir políticas de Android.
  - Enviar ubicación al servidor según intervalo configurado (`gpsnew/gps_services`, `gpsnew/count_gps`); usar Config GPS para intervalo y opciones.
  - Iniciar/parar servicio según sesión y turno (equivalente a Controlador iniciando/parando `XGPSService`).
- **Depende de:** Permisos ubicación (ya pedidos al inicio), Auth, Config GPS.

---

### 14. Cola de pendientes (P1)
- **Qué hacer:**
  - Modelo y BD local para cola de pendientes (equivalente a `XPending`); envío en background con reintentos (equivalente a `XPendingService` y `SendPendiente`).
  - Integrar con operaciones que generan pendientes (trabajos, reglas, etc.) cuando no hay red.
  - Opcional: widget flotante para “enviar pendientes” (ver feature 16).
- **Depende de:** Auth, BD local.

---

### 15. Conteo horario (P2)
- **Qué hacer:**
  - Tarea programada (cada hora) que lee turno de BD, prepara datos de conteo y envía (o encola en pendientes); equivalente a `ConteoService`.
  - Usar `workmanager` o similar en Flutter para tareas en background.
- **Depende de:** Auth, Turno, Pendientes.

---

### 16. Widget flotante (P3, opcional)
- **Qué hacer:**
  - Botón/vista flotante que permita “enviar pendientes” sin abrir la app; requiere permiso `SYSTEM_ALERT_WINDOW` en Android.
  - Evaluar si es imprescindible; en Flutter puede implicar código nativo o plugins específicos.
- **Depende de:** Pendientes, Permisos overlay.

---

### 17. Push – Firebase (P2)
- **Qué hacer:**
  - Configurar `firebase_messaging` (y `firebase_core`); registrar token con `perfil/registro`.
  - Manejar notificaciones “tasignado”/“tdesasignado” y actualizar BD local (trabajos/asignaciones); mostrar notificación local si la app está en segundo plano.
- **Depende de:** Auth.

---

### 18. Avisos asignados (P2)
- **Qué hacer:**
  - Pantalla `AvisosAsignadosActivity`: lista de avisos asignados al recurso; datos desde BD y/o API.
  - Navegación desde XControl o menú.
- **Depende de:** Auth, Trabajos.

---

### 19. Encuestas (P2)
- **Qué hacer:**
  - Pantallas de encuestas (aplazo, precierre, rechazo, inicio, apoyo, fallida) según tipo de trabajo/operación; usar maestros EncuestaA/P/R y endpoints que las consuman.
  - `EncuestaActivity` en Android; en Flutter una pantalla reutilizable por tipo de encuesta.
- **Depende de:** Trabajos, Maestros (encuestas).

---

### 20. Órdenes de apoyo (P2)
- **Qué hacer:**
  - Pantalla `OrdenApoyoActivity`: listado y gestión de órdenes de apoyo; endpoint `trabajo/apoyo` y relacionados.
- **Depende de:** Trabajos.

---

### 21. Galería de fotos (P2)
- **Qué hacer:**
  - Pantalla galería (`GaleriaActivity`): listar fotos guardadas (p. ej. en ruta tipo `DCIM/Camera/Extreme/` o equivalente en Flutter); permisos de almacenamiento.
  - Opción de abrir desde reglas o info de trabajo.
- **Depende de:** Almacenamiento (permisos), Trabajos/Reglas.

---

### 22. Info trabajo / Info recurso (P2)
- **Qué hacer:**
  - `InfoTrabajoActivity`: detalle del trabajo seleccionado (desde BD y sesión).
  - `InfoRecursoActivity`: datos del recurso (ya cubierto en Utilidades); unificar si aplica.
- **Depende de:** Auth, Trabajos/Recurso.

---

## 6. Permisos (Android / iOS) a declarar y usar

- **Ubicación:** `ACCESS_FINE_LOCATION`, `ACCESS_COARSE_LOCATION`, `ACCESS_BACKGROUND_LOCATION` (Android); en iOS equivalente en `Info.plist` y uso en background.
- **Red:** INTERNET, ACCESS_NETWORK_STATE (ya implícitos en muchas configuraciones).
- **Cámara:** CAMERA; en iOS `NSCameraUsageDescription`.
- **Almacenamiento:** READ_EXTERNAL_STORAGE, WRITE_EXTERNAL_STORAGE (o scoped storage en Android 10+); en iOS fotos si aplica.
- **Teléfono:** CALL_PHONE (solo si se usa en Utilidades); READ_PHONE_STATE si se usa.
- **Otros:** WAKE_LOCK, VIBRATE, FOREGROUND_SERVICE (para GPS); SYSTEM_ALERT_WINDOW solo si se implementa widget flotante.
- **Firebase:** permisos C2D_MESSAGE y configuración en manifest si se usa FCM.

Todos estos deben estar en `AndroidManifest.xml` e `Info.plist` del proyecto Flutter; los críticos para “al abrir la app” son los de **ubicación**.

---

## 7. Orden sugerido de implementación (sprints)

### Fase 0 – Base
1. **Permisos al abrir la app** (PermissionsGate, ubicación al inicio).
2. Ajustar **Config HTTP** si falta algo.
3. Ajustar **Auth** (login, redirección a XControl vs AddWorkers, logout).

### Fase 1 – Core operativo
4. **Config GPS** (pantalla + persistencia).
5. **Descarga de maestros** (pantalla + BD local con todas las entidades).
6. **Turno** (inicio/fin, persistencia).
7. **Servicio GPS** en segundo plano (foreground, envío según config).
8. **Cola de pendientes** (modelo, BD, envío en background).

### Fase 2 – Pantalla principal y trabajos
9. **Lista de trabajos (XControl)** con tabs y navegación.
10. **Reglas de trabajo + cámara** y subida de fotos.
11. **Causales** y **Precierre / observación / resumen**.
12. **Encuestas** y **Órdenes de apoyo**.
13. **Info trabajo / Info recurso** y **Avisos asignados**.

### Fase 3 – Resto de pantallas y servicios
14. **Materiales** (lista, búsqueda, desmontados).
15. **Trabajadores** (alta, formulario).
16. **Utilidades** (turno, info recurso, cerrar sesión).
17. **Conteo horario** (workmanager).
18. **Push (Firebase)**.
19. **Galería de fotos**.
20. **Widget flotante** (opcional).

---

## 8. Referencias rápidas Android

- **Application:** `Controlador` (inicia/para servicios, guarda estado global: trabajo, regla, recurso, etc.).
- **LAUNCHER:** `LoginActivity`.
- **Servicios:** `XGPSService`, `ConteoService`, `XPendingService`, `FloatingWidgetService`; Firebase: `MyFirebaseMessagingService`, `InstanceIDListenerService`.
- **BD:** `DBController`, `XControlECA.db`, tablas para todos los VO listados en el plan.
- **Endpoints:** `MyServlets` (perfil, gps, maestro, trabajo, trabajadores, fileupload).
- **Permisos en runtime:** LoginActivity (ubicación), XControlActivity/ReglasActivity (cámara), UtilidadesFragment (llamada).

Con este plan se puede migrar la app Android a Flutter de forma ordenada, con **permisos solicitados al abrir la app** y todas las features detalladas y priorizadas según dependencias.
