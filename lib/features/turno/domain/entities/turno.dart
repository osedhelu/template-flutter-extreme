/// Entidad de dominio para la feature turno.
class Turno {
  const Turno({
    this.id,
    required this.name,
  });

  final int? id;
  final String name;

  Turno copyWith({
    int? id,
    String? name,
  }) {
    return Turno(
      id: id ?? this.id,
      name: name ?? this.name,
    );
  }

  factory Turno.fromJson(Map<String, dynamic> json) {
    return Turno(
      id: json['id'] as int?,
      name: json['name'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
      };
}
