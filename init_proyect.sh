#!/usr/bin/env bash
#
# init_proyect.sh — Inicializa el template Flutter con un nuevo package y nombre.
# Uso: ./init_proyect.sh --package com.empresa.appname [--name nombre_app]
#
# --package  Obligatorio. Package Android / Bundle ID iOS (ej: com.miempresa.miapp).
# --name     Opcional.  Nombre del proyecto Flutter y nombre de la app (ej: miapp).
#                      Si no se indica, se usa el último segmento del package.
#

set -e

# Valores por defecto del template
OLD_PACKAGE="co.com.extreme.xtdespachos"
OLD_NAME="xtdespachos"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR" && pwd)"

# Variables a rellenar por argumentos
NEW_PACKAGE=""
NEW_NAME=""

usage() {
  echo "Uso: $0 --package <package_id> [--name <nombre_app>]"
  echo ""
  echo "  --package   Package Android / Bundle ID iOS (ej: com.empresa.miapp)"
  echo "  --name      Nombre Flutter y de la app (ej: miapp). Si se omite, se usa el último segmento del package."
  echo ""
  echo "Ejemplo:"
  echo "  $0 --package com.extreme.conductores --name conductores"
  exit 1
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --package)
      NEW_PACKAGE="$2"
      shift 2
      ;;
    --name)
      NEW_NAME="$2"
      shift 2
      ;;
    -h|--help)
      usage
      ;;
    *)
      echo "Opción desconocida: $1"
      usage
      ;;
  esac
done

if [[ -z "$NEW_PACKAGE" ]]; then
  echo "Error: --package es obligatorio."
  usage
fi

# Nombre del proyecto: si no se pasó --name, usar el último segmento del package
if [[ -z "$NEW_NAME" ]]; then
  NEW_NAME="${NEW_PACKAGE##*.}"
fi

# Validar nombre Flutter (solo minúsculas, números y guión bajo)
if [[ ! "$NEW_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Error: el nombre debe ser un identificador Dart válido (minúsculas, números, guión bajo). Ej: miapp, mi_app."
  exit 1
fi

echo "Inicializando proyecto:"
echo "  Package (Android/iOS): $NEW_PACKAGE"
echo "  Nombre (Flutter/app):  $NEW_NAME"
echo "  Raíz del proyecto:     $PROJECT_ROOT"
echo ""

cd "$PROJECT_ROOT"

# --- 1) Android: build.gradle.kts ---
echo "[1/7] Android: build.gradle.kts (namespace, applicationId)"
sed -i.bak "s|namespace = \"$OLD_PACKAGE\"|namespace = \"$NEW_PACKAGE\"|g" android/app/build.gradle.kts
sed -i.bak "s|applicationId = \"$OLD_PACKAGE\"|applicationId = \"$NEW_PACKAGE\"|g" android/app/build.gradle.kts
rm -f android/app/build.gradle.kts.bak

# --- 2) Android: AndroidManifest.xml (label) ---
echo "[2/7] Android: AndroidManifest.xml (android:label)"
sed -i.bak "s|android:label=\"$OLD_NAME\"|android:label=\"$NEW_NAME\"|g" android/app/src/main/AndroidManifest.xml
rm -f android/app/src/main/AndroidManifest.xml.bak

# --- 3) Android: MainActivity.kt (nueva ruta y package) ---
echo "[3/7] Android: MainActivity.kt (nueva ruta de package)"
KOTLIN_BASE="android/app/src/main/kotlin"
NEW_KOTLIN_PATH="$KOTLIN_BASE/$(echo "$NEW_PACKAGE" | tr '.' '/')"
mkdir -p "$NEW_KOTLIN_PATH"
cat > "$NEW_KOTLIN_PATH/MainActivity.kt" << EOF
package $NEW_PACKAGE

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
EOF
# Eliminar carpeta antigua de Kotlin
OLD_KOTLIN_PATH="$KOTLIN_BASE/co/com/extreme/xtdespachos"
if [[ -d "$OLD_KOTLIN_PATH" ]]; then
  rm -f "$OLD_KOTLIN_PATH/MainActivity.kt"
  (cd "$KOTLIN_BASE" && rmdir -p co/com/extreme/xtdespachos 2>/dev/null || true)
fi

# --- 4) iOS: project.pbxproj (PRODUCT_BUNDLE_IDENTIFIER) ---
echo "[4/7] iOS: project.pbxproj (bundle identifier)"
PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
sed -i.bak "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PACKAGE;|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PACKAGE;|g" "$PBXPROJ"
sed -i.bak "s|PRODUCT_BUNDLE_IDENTIFIER = $OLD_PACKAGE.RunnerTests;|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PACKAGE.RunnerTests;|g" "$PBXPROJ"
rm -f "$PBXPROJ.bak"

# --- 5) iOS: Info.plist (CFBundleDisplayName, CFBundleName) ---
echo "[5/7] iOS: Info.plist (nombre de la app)"
# Capitalizar primera letra para display
NEW_DISPLAY_NAME="$(echo "$NEW_NAME" | sed 's/^\(.\)/\U\1/')"
INFO_PLIST="ios/Runner/Info.plist"
sed -i.bak "s|<string>Xtdespachos</string>|<string>$NEW_DISPLAY_NAME</string>|g" "$INFO_PLIST"
sed -i.bak "s|<string>$OLD_NAME</string>|<string>$NEW_NAME</string>|g" "$INFO_PLIST"
rm -f "$INFO_PLIST.bak"

# --- 6) pubspec.yaml (name) ---
echo "[6/7] pubspec.yaml (name)"
sed -i.bak "s|^name: $OLD_NAME$|name: $NEW_NAME|g" pubspec.yaml
rm -f pubspec.yaml.bak

# --- 7) Imports en lib/ (package:xtdespachos -> package:NEW_NAME) ---
echo "[7/7] lib/: reemplazo de imports package:$OLD_NAME -> package:$NEW_NAME"
find lib -name "*.dart" -type f -exec sed -i.bak "s|package:$OLD_NAME/|package:$NEW_NAME/|g" {} \;
find lib -name "*.dart.bak" -type f -delete

# --- Opcional: .vscode/launch.json ---
if [[ -f ".vscode/launch.json" ]]; then
  echo "       .vscode/launch.json (nombres de configuración)"
  sed -i.bak "s|$OLD_NAME|$NEW_NAME|g" .vscode/launch.json
  rm -f .vscode/launch.json.bak
fi

echo ""
echo "Listo. Próximos pasos:"
echo "  1. flutter pub get"
echo "  2. Revisar android/ e ios/ si necesitas ajustar más (ej: signing)."
echo "  3. flutter run"
echo ""
