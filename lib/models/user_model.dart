// lib/models/user_model.dart
class UserModel {
  String uid;
  String nombre;
  String email;
  int experiencia;
  int nivel;
  String division;
  String fechaRegistro;

  Map<String, dynamic> progress;
  Map<String, dynamic> records;

  UserModel({
    required this.uid,
    required this.nombre,
    required this.email,
    this.experiencia = 0,
    this.nivel = 1,
    this.division = 'A',
    required this.fechaRegistro,
    Map<String, dynamic>? progress,
    Map<String, dynamic>? records,
  })  : progress = progress ?? {},
        records = records ?? {};

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'nombre': nombre,
      'email': email,
      'experiencia': experiencia,
      'nivel': nivel,
      'division': division,
      'fechaRegistro': fechaRegistro,
      'progress': progress,
      'records': records,
    };
  }
}
