class User {
  const User({
    required this.id,
    required this.username,
    required this.fullName,
    required this.typeUser,
    this.isInspector = false,
    this.isLogistics = false,
    this.token,
  });

  final int id;
  final String username;
  final String fullName;
  /// Tipo de usuario: conductor, contratista, inspector, etc.
  final String typeUser;
  final bool isInspector;
  final bool isLogistics;
  final String? token;

  User copyWith({
    int? id,
    String? username,
    String? fullName,
    String? typeUser,
    bool? isInspector,
    bool? isLogistics,
    String? token,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      fullName: fullName ?? this.fullName,
      typeUser: typeUser ?? this.typeUser,
      isInspector: isInspector ?? this.isInspector,
      isLogistics: isLogistics ?? this.isLogistics,
      token: token ?? this.token,
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] as int? ?? 0,
      username: json['username'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      typeUser: json['typeUser'] as String? ?? '',
      isInspector: json['isInspector'] as bool? ?? false,
      isLogistics: json['isLogistics'] as bool? ?? false,
      token: json['token'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'fullName': fullName,
      'typeUser': typeUser,
      'isInspector': isInspector,
      'isLogistics': isLogistics,
      'token': token,
    };
  }
}
