#!/usr/bin/env bash
#
# create_feature_flutter.sh — Crea una feature completa con Clean Architecture + Vertical Slice (Flutter).
# Uso: ./create_feature_flutter.sh --feature <nombre_feature> [--entity <NombreEntidad>] [--no-local]
#
# Ejemplo: ./create_feature_flutter.sh --feature turno
#          ./create_feature_flutter.sh --feature descarga_maestros --entity Maestro
#          ./create_feature_flutter.sh --feature permisos --no-local
#
set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
LIB_PATH="$PROJECT_ROOT/lib"
FEATURES_PATH="$LIB_PATH/features"

# Nombre del paquete Flutter. Lo lee de pubspec.yaml; si falla, usa este valor (actualizado por init_proyect.sh).
DEFAULT_PACKAGE="wap_xcontrol"

# Obtener package name desde pubspec.yaml
get_package_name() {
  if [ -f "$PROJECT_ROOT/pubspec.yaml" ]; then
    grep '^name:' "$PROJECT_ROOT/pubspec.yaml" | sed 's/name:[[:space:]]*//' | tr -d ' \r'
  else
    echo ""
  fi
}

PACKAGE_NAME=$(get_package_name)
PACKAGE_NAME="${PACKAGE_NAME:-$DEFAULT_PACKAGE}"

# Convierte snake_case a PascalCase (ej: descarga_maestros -> DescargaMaestros). Portable (macOS/linux).
snake_to_pascal() {
  echo "$1" | awk -F_ '{
    for (i=1;i<=NF;i++) {
      w = $i
      if (length(w) > 0) {
        first = toupper(substr(w,1,1))
        rest  = substr(w,2)
        $i = first rest
      }
    }
    r = ""
    for (i=1;i<=NF;i++) r = r $i
    print r
  }'
}

# Convierte snake_case a camelCase (ej: descarga_maestros -> descargaMaestros)
snake_to_camel() {
  local s="$1"
  local p
  p=$(snake_to_pascal "$s")
  echo "$(echo "${p:0:1}" | tr '[:upper:]' '[:lower:]')${p:1}"
}

show_help() {
  echo -e "${BLUE}========================================${NC}"
  echo -e "${GREEN}Generador de features Flutter — Clean Architecture + Vertical Slice${NC}"
  echo -e "${BLUE}========================================${NC}"
  echo ""
  echo "Uso: $0 --feature <nombre_feature> [opciones]"
  echo ""
  echo "Opciones:"
  echo "  --feature, -f   Nombre de la feature en snake_case (requerido). Ej: turno, descarga_maestros"
  echo "  --entity, -e    Nombre de la entidad en PascalCase. Por defecto: derivado del nombre de la feature"
  echo "  --no-local      No crear datasource local (solo remote)"
  echo "  --help, -h      Mostrar esta ayuda"
  echo ""
  echo "Ejemplos:"
  echo "  $0 --feature turno"
  echo "  $0 -f descarga_maestros --entity Maestro"
  echo "  $0 -f permisos --no-local"
  echo ""
  echo -e "${CYAN}Estructura generada (Vertical Slice):${NC}"
  echo "  features/<feature>/"
  echo "  ├── domain/"
  echo "  │   ├── entities/"
  echo "  │   └── repositories/"
  echo "  ├── application/"
  echo "  │   └── providers/"
  echo "  ├── infrastructure/"
  echo "  │   ├── datasources/"
  echo "  │   └── repositories/"
  echo "  └── presentation/"
  echo "      ├── <feature>_screen.dart"
  echo "      └── widgets/"
  echo ""
}

# --- Crear directorios ---
create_directories() {
  local feature=$1
  local base="$FEATURES_PATH/$feature"

  echo -e "${YELLOW}📁 Creando estructura...${NC}"

  mkdir -p "$base/domain/entities"
  mkdir -p "$base/domain/repositories"
  mkdir -p "$base/application/providers"
  mkdir -p "$base/infrastructure/datasources"
  mkdir -p "$base/infrastructure/repositories"
  mkdir -p "$base/presentation/widgets"

  echo -e "${GREEN}  ✅ Directorios creados${NC}"
}

# --- DOMAIN: entidad ---
create_entity() {
  local feature=$1
  local entity=$2
  local file="$FEATURES_PATH/$feature/domain/entities/${feature}.dart"

  cat > "$file" << EOF
/// Entidad de dominio para la feature $feature.
class $entity {
  const $entity({
    this.id,
    required this.name,
  });

  final int? id;
  final String name;

  $entity copyWith({
    int? id,
    String? name,
  }) {
    return $entity(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory $entity.fromJson(Map<String, dynamic> json) {
    return $entity(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
EOF
  echo -e "${GREEN}  ✅ domain/entities/${feature}.dart ($entity)${NC}"
}

# --- DOMAIN: interfaz del repositorio ---
create_repository_interface() {
  local feature=$1
  local entity=$2
  local EntityPascal=$entity
  local file="$FEATURES_PATH/$feature/domain/repositories/${feature}_repository.dart"

  cat > "$file" << EOF
import 'package:${PACKAGE_NAME}/features/$feature/domain/entities/${feature}.dart';

abstract class ${EntityPascal}Repository {
  Future<${EntityPascal}> getById(int id);
  Future<List<${EntityPascal}>> getAll();
}
EOF
  echo -e "${GREEN}  ✅ domain/repositories/${feature}_repository.dart${NC}"
}

# --- APPLICATION: providers ---
# Usa camelCase en nombres de providers (lowerCamelCase) para cumplir analysis_options.
create_providers() {
  local feature=$1
  local entity=$2
  local EntityPascal=$entity
  local feature_camel
  feature_camel=$(snake_to_camel "$feature")
  local file="$FEATURES_PATH/$feature/application/providers/${feature}_providers.dart"

  cat > "$file" << EOF
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:${PACKAGE_NAME}/features/$feature/domain/entities/${feature}.dart';
import 'package:${PACKAGE_NAME}/features/$feature/domain/repositories/${feature}_repository.dart';

final ${feature_camel}RepositoryProvider = Provider<${EntityPascal}Repository>((ref) {
  // TODO: inyectar Dio y datasources; devolver ${EntityPascal}RepositoryImpl(remote: ..., local: ...)
  throw UnimplementedError(
    'Configurar ${EntityPascal}Repository con datasources reales',
  );
});

class ${EntityPascal}State {
  const ${EntityPascal}State({
    this.items = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<${EntityPascal}> items;
  final bool isLoading;
  final String? errorMessage;

  ${EntityPascal}State copyWith({
    List<${EntityPascal}>? items,
    bool? isLoading,
    String? errorMessage,
  }) {
    return ${EntityPascal}State(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }

  static const ${EntityPascal}State initial = ${EntityPascal}State();
}

class ${EntityPascal}Notifier extends StateNotifier<${EntityPascal}State> {
  ${EntityPascal}Notifier(this._repository) : super(${EntityPascal}State.initial);

  final ${EntityPascal}Repository _repository;

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final items = await _repository.getAll();
      state = state.copyWith(items: items, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: e.toString(),
      );
    }
  }
}

final ${feature_camel}NotifierProvider =
    StateNotifierProvider<${EntityPascal}Notifier, ${EntityPascal}State>((ref) {
  final repo = ref.watch(${feature_camel}RepositoryProvider);
  return ${EntityPascal}Notifier(repo);
});
EOF
  echo -e "${GREEN}  ✅ application/providers/${feature}_providers.dart${NC}"
}

# --- INFRASTRUCTURE: remote datasource ---
create_remote_datasource() {
  local feature=$1
  local entity=$2
  local file="$FEATURES_PATH/$feature/infrastructure/datasources/${feature}_remote_datasource.dart"

  cat > "$file" << EOF
import 'package:dio/dio.dart';

class ${entity}RemoteDataSource {
  ${entity}RemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<Map<String, dynamic>>> getAll() async {
    final path = '/${feature//_/\/}';
    final response = await _dio.get<dynamic>(path);
    final data = response.data;
    if (data is List) {
      return List<Map<String, dynamic>>.from(
        data.map((e) => e is Map ? Map<String, dynamic>.from(e) : <String, dynamic>{}),
      );
    }
    return [];
  }

  Future<Map<String, dynamic>> getById(int id) async {
    final path = '/${feature//_/\/}/\$id';
    final response = await _dio.get<Map<String, dynamic>>(path);
    final data = response.data;
    if (data == null) throw FormatException('Respuesta vacía');
    return data;
  }
}
EOF
  echo -e "${GREEN}  ✅ infrastructure/datasources/${feature}_remote_datasource.dart${NC}"
}

# --- INFRASTRUCTURE: local datasource (opcional) ---
create_local_datasource() {
  local feature=$1
  local entity=$2
  local file="$FEATURES_PATH/$feature/infrastructure/datasources/${feature}_local_datasource.dart"

  cat > "$file" << EOF
import 'dart:convert';

import 'package:${PACKAGE_NAME}/features/$feature/domain/entities/${feature}.dart';
import 'package:${PACKAGE_NAME}/shared/infrastructure/preferences_datasource.dart';

class ${entity}LocalDataSource {
  ${entity}LocalDataSource(this._prefs);

  final PreferencesDataSource _prefs;

  static const _keyList = '${feature}_list';

  Future<void> saveList(List<${entity}> list) async {
    final jsonList = list.map((e) => e.toJson()).toList();
    await _prefs.setString(_keyList, jsonEncode(jsonList));
  }

  Future<List<${entity}>> getList() async {
    final raw = _prefs.getString(_keyList);
    if (raw == null) return [];
    try {
      final list = jsonDecode(raw) as List<dynamic>;
      return list
          .map((e) => ${entity}.fromJson(Map<String, dynamic>.from(e as Map)))
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> clear() async {
    await _prefs.remove(_keyList);
  }
}
EOF
  echo -e "${GREEN}  ✅ infrastructure/datasources/${feature}_local_datasource.dart${NC}"
}

# --- INFRASTRUCTURE: repository impl ---
create_repository_impl() {
  local feature=$1
  local entity=$2
  local EntityPascal=$entity
  local file="$FEATURES_PATH/$feature/infrastructure/repositories/${feature}_repository_impl.dart"

  if [ "$CREATE_LOCAL" = "true" ]; then
    cat > "$file" << EOF
import 'package:${PACKAGE_NAME}/features/$feature/domain/entities/${feature}.dart';
import 'package:${PACKAGE_NAME}/features/$feature/domain/repositories/${feature}_repository.dart';
import 'package:${PACKAGE_NAME}/features/$feature/infrastructure/datasources/${feature}_local_datasource.dart';
import 'package:${PACKAGE_NAME}/features/$feature/infrastructure/datasources/${feature}_remote_datasource.dart';

class ${EntityPascal}RepositoryImpl implements ${EntityPascal}Repository {
  ${EntityPascal}RepositoryImpl({
    required ${EntityPascal}RemoteDataSource remote,
    required ${EntityPascal}LocalDataSource local,
  })  : _remote = remote,
        _local = local;

  final ${EntityPascal}RemoteDataSource _remote;
  final ${EntityPascal}LocalDataSource _local;

  @override
  Future<${EntityPascal}> getById(int id) async {
    final data = await _remote.getById(id);
    return ${EntityPascal}.fromJson(data);
  }

  @override
  Future<List<${EntityPascal}>> getAll() async {
    try {
      final list = await _remote.getAll();
      final items = list.map((e) => ${EntityPascal}.fromJson(e)).toList();
      await _local.saveList(items);
      return items;
    } catch (_) {
      return _local.getList();
    }
  }
}
EOF
  else
    cat > "$file" << EOF
import 'package:${PACKAGE_NAME}/features/$feature/domain/entities/${feature}.dart';
import 'package:${PACKAGE_NAME}/features/$feature/domain/repositories/${feature}_repository.dart';
import 'package:${PACKAGE_NAME}/features/$feature/infrastructure/datasources/${feature}_remote_datasource.dart';

class ${EntityPascal}RepositoryImpl implements ${EntityPascal}Repository {
  ${EntityPascal}RepositoryImpl({required ${EntityPascal}RemoteDataSource remote})
      : _remote = remote;

  final ${EntityPascal}RemoteDataSource _remote;

  @override
  Future<${EntityPascal}> getById(int id) async {
    final data = await _remote.getById(id);
    return ${EntityPascal}.fromJson(data);
  }

  @override
  Future<List<${EntityPascal}>> getAll() async {
    final list = await _remote.getAll();
    return list.map((e) => ${EntityPascal}.fromJson(e)).toList();
  }
}
EOF
  fi
  echo -e "${GREEN}  ✅ infrastructure/repositories/${feature}_repository_impl.dart${NC}"
}

# --- PRESENTATION: screen ---
create_screen() {
  local feature=$1
  local entity=$2
  local EntityPascal=$entity
  local feature_camel
  feature_camel=$(snake_to_camel "$feature")
  local file="$FEATURES_PATH/$feature/presentation/${feature}_screen.dart"

  cat > "$file" << EOF
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:${PACKAGE_NAME}/features/$feature/application/providers/${feature}_providers.dart';

class ${EntityPascal}Screen extends ConsumerStatefulWidget {
  const ${EntityPascal}Screen({super.key});

  @override
  ConsumerState<${EntityPascal}Screen> createState() => _${EntityPascal}ScreenState();
}

class _${EntityPascal}ScreenState extends ConsumerState<${EntityPascal}Screen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(${feature_camel}NotifierProvider.notifier).loadAll();
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(${feature_camel}NotifierProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text('${EntityPascal}'),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : state.errorMessage != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(
                      state.errorMessage!,
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyLarge,
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: state.items.length,
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return ListTile(
                      title: Text(item.name),
                      subtitle: item.id != null ? Text('ID: \${item.id}') : null,
                    );
                  },
                ),
    );
  }
}
EOF
  echo -e "${GREEN}  ✅ presentation/${feature}_screen.dart${NC}"
}

# --- .gitkeep en presentation/widgets ---
create_widgets_placeholder() {
  local feature=$1
  if [ ! -f "$FEATURES_PATH/$feature/presentation/widgets/.gitkeep" ]; then
    touch "$FEATURES_PATH/$feature/presentation/widgets/.gitkeep"
    echo -e "${GREEN}  ✅ presentation/widgets/.gitkeep${NC}"
  fi
}

# ============================================================================
# MAIN
# ============================================================================

FEATURE_NAME=""
ENTITY_NAME=""
CREATE_LOCAL="true"

while [[ $# -gt 0 ]]; do
  case $1 in
    --feature|-f)
      FEATURE_NAME="$2"
      shift 2
      ;;
    --entity|-e)
      ENTITY_NAME="$2"
      shift 2
      ;;
    --no-local)
      CREATE_LOCAL="false"
      shift
      ;;
    --help|-h)
      show_help
      exit 0
      ;;
    *)
      echo -e "${RED}Opción desconocida: $1${NC}"
      show_help
      exit 1
      ;;
  esac
done

if [ -z "$FEATURE_NAME" ]; then
  echo -e "${RED}❌ Error: --feature es obligatorio${NC}"
  echo ""
  show_help
  exit 1
fi

if [ -z "$PACKAGE_NAME" ]; then
  echo -e "${RED}❌ Error: no se encontró 'name' en pubspec.yaml. Ejecuta el script desde la raíz del proyecto Flutter.${NC}"
  exit 1
fi

# Validar nombre: solo minúsculas, números y guión bajo
if [[ ! "$FEATURE_NAME" =~ ^[a-z][a-z0-9_]*$ ]]; then
  echo -e "${RED}❌ Error: el nombre de la feature debe ser snake_case (ej: turno, descarga_maestros)${NC}"
  exit 1
fi

# Si ya existe la feature, no sobrescribir sin confirmación
if [ -d "$FEATURES_PATH/$FEATURE_NAME" ]; then
  echo -e "${RED}❌ Error: la feature '$FEATURE_NAME' ya existe en $FEATURES_PATH/$FEATURE_NAME${NC}"
  exit 1
fi

# Entidad: por defecto PascalCase del nombre de la feature
if [ -z "$ENTITY_NAME" ]; then
  ENTITY_NAME=$(snake_to_pascal "$FEATURE_NAME")
fi

echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}Creando feature Flutter: $FEATURE_NAME${NC}"
echo -e "${BLUE}========================================${NC}"
echo -e "  Package: ${CYAN}$PACKAGE_NAME${NC}"
echo -e "  Entidad: ${CYAN}$ENTITY_NAME${NC}"
echo -e "  Local datasource: ${CYAN}$CREATE_LOCAL${NC}"
echo ""

if [ ! -f "$PROJECT_ROOT/pubspec.yaml" ]; then
  echo -e "${RED}❌ Error: ejecuta este script desde la raíz del proyecto Flutter (donde está pubspec.yaml)${NC}"
  echo -e "   Ej: cd flutter-migrate-app && ./scripts/create_feature_flutter.sh -f turno"
  exit 1
fi

create_directories "$FEATURE_NAME"
echo ""
echo -e "${CYAN}📦 Domain...${NC}"
create_entity "$FEATURE_NAME" "$ENTITY_NAME"
create_repository_interface "$FEATURE_NAME" "$ENTITY_NAME"
echo ""
echo -e "${CYAN}🔧 Application (providers)...${NC}"
create_providers "$FEATURE_NAME" "$ENTITY_NAME"
echo ""
echo -e "${CYAN}📡 Infrastructure...${NC}"
create_remote_datasource "$FEATURE_NAME" "$ENTITY_NAME"
if [ "$CREATE_LOCAL" = "true" ]; then
  create_local_datasource "$FEATURE_NAME" "$ENTITY_NAME"
fi
create_repository_impl "$FEATURE_NAME" "$ENTITY_NAME"
echo ""
echo -e "${CYAN}🎨 Presentation...${NC}"
create_screen "$FEATURE_NAME" "$ENTITY_NAME"
create_widgets_placeholder "$FEATURE_NAME"
echo ""
echo -e "${BLUE}========================================${NC}"
echo -e "${GREEN}✅ Feature '$FEATURE_NAME' creada${NC}"
echo -e "${BLUE}========================================${NC}"
echo ""
FEATURE_CAMEL=$(snake_to_camel "$FEATURE_NAME")
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. Ajustar la entidad ${ENTITY_NAME} en domain/entities/${FEATURE_NAME}.dart"
echo "  2. Ajustar métodos en domain/repositories/${FEATURE_NAME}_repository.dart"
echo "  3. Configurar ${FEATURE_CAMEL}RepositoryProvider con Dio/datasources reales"
echo "  4. Ajustar endpoints en ${FEATURE_NAME}_remote_datasource.dart"
if [ "$CREATE_LOCAL" = "true" ]; then
  echo "  5. Revisar ${FEATURE_NAME}_local_datasource.dart (claves y modelo)"
fi
echo "  6. Añadir ruta a ${ENTITY_NAME}Screen en core/router si aplica"
echo ""
