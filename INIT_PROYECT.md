# Uso de `init_proyect.sh`

Script para **inicializar el template Flutter** con un nuevo package (Android/iOS) y nombre de proyecto. Reemplaza los valores por defecto del template (`co.com.extreme.xtdespachos` / `xtdespachos`) por los que indiques.

---

## Uso básico

```bash
./init_proyect.sh --package <package_id> [--name <nombre_app>]
```

| Argumento     | Obligatorio | Descripción |
|--------------|-------------|-------------|
| `--package`  | Sí          | Package Android / Bundle ID iOS (ej: `com.empresa.miapp`). |
| `--name`     | No          | Nombre del proyecto Flutter y de la app (ej: `miapp`). Si se omite, se usa el **último segmento** del package. |

---

## Ejemplos

```bash
# Con package y nombre explícito
./init_proyect.sh --package com.extreme.conductores --name conductores

# Solo package (el nombre será el último segmento; ej: "caribemar")
./init_proyect.sh --package com.extreme.caribemar

# Ayuda
./init_proyect.sh --help
./init_proyect.sh -h
```

---

## Requisitos del nombre

- Solo **minúsculas**, **números** y **guión bajo**.
- Debe ser un identificador Dart válido (ej: `miapp`, `mi_app`).
- Si no cumple, el script mostrará un error y no continuará.

---

## Dónde ejecutarlo

Desde la **raíz del proyecto Flutter** (carpeta donde está el script):

```bash
cd flutter-migrate-app
chmod +x init_proyect.sh   # solo la primera vez, si no es ejecutable
./init_proyect.sh --package com.tuempresa.tuapp --name tuapp
```

---

## Qué hace el script (pasos 1–7)

| Paso | Archivo / zona | Cambios |
|------|----------------|---------|
| 1 | `android/app/build.gradle.kts` | `namespace` y `applicationId` |
| 2 | `android/app/src/main/AndroidManifest.xml` | `android:label` (nombre de la app) |
| 3 | `android/app/src/main/kotlin/` | Nueva ruta de package y `MainActivity.kt` actualizado |
| 4 | `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` (app y tests) |
| 5 | `ios/Runner/Info.plist` | Nombre mostrado y nombre del bundle |
| 6 | `pubspec.yaml` | Campo `name` del proyecto Flutter |
| 7 | `lib/**/*.dart` | Reemplazo de imports `package:xtdespachos/` → `package:<nuevo_nombre>/` |

Si existe `.vscode/launch.json`, también actualiza los nombres de configuración.

---

## Después de ejecutarlo

1. Ejecutar dependencias:
   ```bash
   flutter pub get
   ```
2. Revisar `android/` e `ios/` si necesitas ajustar firma u otras opciones.
3. Ejecutar la app:
   ```bash
   flutter run
   ```

---

## Resumen

- **Cuándo usarlo:** Una sola vez al crear un nuevo proyecto a partir de este template.
- **Qué hace:** Deja Android, iOS y Flutter configurados con tu package y nombre de app.
- **Obligatorio:** `--package`. Opcional: `--name` (si no se pasa, se usa el último segmento del package).
