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

# Valores actuales (se derivan del proyecto real, no del template).
OLD_PACKAGE=""
OLD_NAME=""
OLD_ANDROID_LABEL=""
OLD_ANDROID_NAMESPACE=""
OLD_IOS_BUNDLE_ID=""
OLD_IOS_DISPLAY_NAME=""
OLD_IOS_CF_BUNDLE_NAME=""
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

# Normalizar NEW_NAME (si el último segmento trae '-', lo convertimos a '_')
NEW_NAME="${NEW_NAME//-/_}"

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

# Derivar valores actuales desde el proyecto actual
if [ -f "pubspec.yaml" ]; then
  # Intentar extraer el `name:` de pubspec.yaml de forma tolerante
  OLD_NAME="$(sed -nE 's/^name:[[:space:]]*([^#[:space:]]+).*/\1/p' pubspec.yaml | head -n1 | tr -d ' \r')"
fi

if [ -f "android/app/build.gradle.kts" ]; then
  OLD_ANDROID_PACKAGE_RAW="$(sed -nE 's/^[[:space:]]*applicationId[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*$/\1/p' android/app/build.gradle.kts | head -n1 | tr -d ' \r')"
  OLD_ANDROID_NAMESPACE_RAW="$(sed -nE 's/^[[:space:]]*namespace[[:space:]]*=[[:space:]]*"([^"]+)"[[:space:]]*$/\1/p' android/app/build.gradle.kts | head -n1 | tr -d ' \r')"
  OLD_PACKAGE="${OLD_ANDROID_PACKAGE_RAW:-$OLD_ANDROID_NAMESPACE_RAW}"
  # Para Kotlin/Java packages, sustituimos '-' por '_' porque '-' no es válido en nombres de package.
  OLD_ANDROID_NAMESPACE="${OLD_ANDROID_NAMESPACE_RAW:-${OLD_PACKAGE//-/_}}"
fi

PBXPROJ="ios/Runner.xcodeproj/project.pbxproj"
INFO_PLIST="ios/Runner/Info.plist"

if [ -f "$PBXPROJ" ]; then
  OLD_IOS_BUNDLE_ID="$(sed -nE 's/^[[:space:]]*PRODUCT_BUNDLE_IDENTIFIER[[:space:]]*=[[:space:]]*([^;]+);.*$/\1/p' "$PBXPROJ" | head -n1 | tr -d ' \r')"
fi

if [ -f "android/app/src/main/AndroidManifest.xml" ]; then
  OLD_ANDROID_LABEL="$(sed -nE 's/.*android:label="([^"]+)".*/\1/p' android/app/src/main/AndroidManifest.xml | head -n1 | tr -d ' \r')"
fi

get_plist_string() {
  # $1 = key, $2 = file
  python3 - <<'PY' "$1" "$2"
import re, sys
key, file = sys.argv[1], sys.argv[2]
text = open(file, "r", encoding="utf-8").read()
m = re.search(r"<key>%s</key>\s*<string>([^<]+)</string>" % re.escape(key), text)
print(m.group(1).strip() if m else "")
PY
}

if [ -f "$INFO_PLIST" ]; then
  OLD_IOS_DISPLAY_NAME="$(get_plist_string "CFBundleDisplayName" "$INFO_PLIST")"
  OLD_IOS_CF_BUNDLE_NAME="$(get_plist_string "CFBundleName" "$INFO_PLIST")"
fi

# Normalizar NEW_PACKAGE:
# - applicationId/bundle id puede llevar '-' (Android), pero el namespace/Kotlin package no.
ANDROID_NAMESPACE="${NEW_PACKAGE//-/_}"

# Validar nombre Flutter (solo minúsculas, números y guión bajo)
if [[ -n "$ANDROID_NAMESPACE" && "$NEW_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  :
else
  # Si el último segmento trae '-', lo convertimos en '_' para respetar reglas de identificador.
  NEW_NAME="${NEW_NAME//-/_}"
fi

# Revalidar tras normalización
if [[ ! "$NEW_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo "Error: el nombre debe ser un identificador Dart válido (minúsculas, números y guión bajo). Ej: miapp, mi_app."
  exit 1
fi

# --- 1) Android: build.gradle.kts ---
echo "[1/8] Android: build.gradle.kts (namespace, applicationId)"
if [ -f "android/app/build.gradle.kts" ]; then
  sed -i.bak -E "s|namespace[[:space:]]*=[[:space:]]*\"[^\"]+\"|namespace = \"$ANDROID_NAMESPACE\"|g" android/app/build.gradle.kts
  sed -i.bak -E "s|applicationId[[:space:]]*=[[:space:]]*\"[^\"]+\"|applicationId = \"$NEW_PACKAGE\"|g" android/app/build.gradle.kts
  rm -f android/app/build.gradle.kts.bak
fi

# (Opcional) Si existe el build.gradle (Groovy), también lo actualizamos.
if [ -f "android/app/build.gradle" ]; then
  sed -i.bak -E "s|namespace[[:space:]]+\"[^\"]+\"|namespace \"$ANDROID_NAMESPACE\"|g" android/app/build.gradle || true
  sed -i.bak -E "s|applicationId[[:space:]]+\"[^\"]+\"|applicationId \"$NEW_PACKAGE\"|g" android/app/build.gradle || true
  rm -f android/app/build.gradle.bak || true
fi

# --- 2) Android: AndroidManifest.xml (label) ---
echo "[2/8] Android: AndroidManifest.xml (android:label)"
if [[ -n "$OLD_ANDROID_LABEL" ]]; then
  sed -i.bak "s|android:label=\"$OLD_ANDROID_LABEL\"|android:label=\"$NEW_NAME\"|g" android/app/src/main/AndroidManifest.xml
else
  # Fallback: reemplazar el primer android:label encontrado.
  sed -i.bak -E "s|android:label=\"[^\"]+\"|android:label=\"$NEW_NAME\"|" android/app/src/main/AndroidManifest.xml
fi
rm -f android/app/src/main/AndroidManifest.xml.bak

# --- 3) Android: MainActivity.kt (nueva ruta y package) ---
echo "[3/8] Android: MainActivity.kt (nueva ruta de package)"
KOTLIN_BASE="android/app/src/main/kotlin"
NEW_KOTLIN_PATH="$KOTLIN_BASE/$(echo "$ANDROID_NAMESPACE" | tr '.' '/')"
mkdir -p "$NEW_KOTLIN_PATH"
cat > "$NEW_KOTLIN_PATH/MainActivity.kt" << EOF
package $ANDROID_NAMESPACE

import io.flutter.embedding.android.FlutterActivity

class MainActivity : FlutterActivity()
EOF
# Eliminar carpeta antigua de Kotlin
if [[ -n "$OLD_ANDROID_NAMESPACE" ]]; then
  OLD_KOTLIN_PATH="$KOTLIN_BASE/$(echo "$OLD_ANDROID_NAMESPACE" | tr '.' '/')"
  if [[ -d "$OLD_KOTLIN_PATH" ]]; then
    rm -f "$OLD_KOTLIN_PATH/MainActivity.kt"
    (cd "$KOTLIN_BASE" && rmdir -p "$(echo "$OLD_ANDROID_NAMESPACE" | tr '.' '/')" 2>/dev/null || true)
  fi
fi

# --- 4) iOS: project.pbxproj (PRODUCT_BUNDLE_IDENTIFIER) ---
echo "[4/8] iOS: project.pbxproj (bundle identifier)"
IOS_OLD="${OLD_IOS_BUNDLE_ID:-$OLD_PACKAGE}"
sed -i.bak "s|PRODUCT_BUNDLE_IDENTIFIER = $IOS_OLD;|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PACKAGE;|g" "$PBXPROJ"
sed -i.bak "s|PRODUCT_BUNDLE_IDENTIFIER = $IOS_OLD.RunnerTests;|PRODUCT_BUNDLE_IDENTIFIER = $NEW_PACKAGE.RunnerTests;|g" "$PBXPROJ"
rm -f "$PBXPROJ.bak"

# --- 5) iOS: Info.plist (CFBundleDisplayName, CFBundleName) ---
echo "[5/8] iOS: Info.plist (nombre de la app)"
# Capitalizar primera letra para display
NEW_DISPLAY_NAME="$(echo "$NEW_NAME" | sed 's/^\(.\)/\U\1/')"
INFO_PLIST="ios/Runner/Info.plist"
if [[ -n "$OLD_IOS_DISPLAY_NAME" ]]; then
  sed -i.bak "s|<string>$OLD_IOS_DISPLAY_NAME</string>|<string>$NEW_DISPLAY_NAME</string>|g" "$INFO_PLIST"
fi
if [[ -n "$OLD_IOS_CF_BUNDLE_NAME" ]]; then
  sed -i.bak "s|<string>$OLD_IOS_CF_BUNDLE_NAME</string>|<string>$NEW_NAME</string>|g" "$INFO_PLIST"
fi
rm -f "$INFO_PLIST.bak"

# --- 6) pubspec.yaml (name) ---
echo "[6/8] pubspec.yaml (name)"
sed -i.bak "s|^name: *.*|name: $NEW_NAME|" pubspec.yaml
rm -f pubspec.yaml.bak

# --- 7) Imports en lib/ (package:... -> package:NEW_NAME) ---
echo "[7/8] lib/: reemplazo de imports package:$OLD_NAME -> package:$NEW_NAME"
if [[ -n "$OLD_NAME" ]]; then
  find lib -name "*.dart" -type f -exec sed -i.bak "s|package:$OLD_NAME/|package:$NEW_NAME/|g" {} \;
fi
# También reemplazar wap_xcontrol por si el template usa ese nombre en imports
find lib -name "*.dart" -type f -exec sed -i.bak "s|package:wap_xcontrol/|package:$NEW_NAME/|g" {} \;
find lib -name "*.dart.bak" -type f -delete

# --- 8) scripts/create_feature_flutter.sh (DEFAULT_PACKAGE para nuevo proyecto) ---
echo "[8/8] scripts/create_feature_flutter.sh (nombre del paquete por defecto)"
CREATE_FEATURE_SCRIPT="scripts/create_feature_flutter.sh"
if [[ -f "$CREATE_FEATURE_SCRIPT" ]]; then
  sed -i.bak -E "s|DEFAULT_PACKAGE=\"[^\"]*\"|DEFAULT_PACKAGE=\"$NEW_NAME\"|g" "$CREATE_FEATURE_SCRIPT"
  rm -f "$CREATE_FEATURE_SCRIPT.bak"
fi

# --- Opcional: .vscode/launch.json ---
if [[ -f ".vscode/launch.json" ]]; then
  echo "       .vscode/launch.json (nombres de configuración)"
  if [[ -n "$OLD_NAME" ]]; then
    sed -i.bak "s|$OLD_NAME|$NEW_NAME|g" .vscode/launch.json
  fi
  rm -f .vscode/launch.json.bak
fi

echo ""
echo "Listo. Próximos pasos:"
echo "  1. flutter pub get"
echo "  2. Revisar android/ e ios/ si necesitas ajustar más (ej: signing)."
echo "  3. flutter run"
echo ""
