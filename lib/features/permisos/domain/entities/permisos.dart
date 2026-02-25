/// Entidad de dominio para la feature permisos.
class Permisos {
  const Permisos({
    this.id,
    required this.name,
  });

  final int? id;
  final String name;

  Permisos copyWith({
    int? id,
    String? name,
  }) {
    return Permisos(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory Permisos.fromJson(Map<String, dynamic> json) {
    return Permisos(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
