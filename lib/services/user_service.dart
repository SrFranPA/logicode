import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final users = FirebaseFirestore.instance.collection('usuarios');

  Future<void> saveUserData({
    required String uid,
    required String email,
    required String nombre,
    required int edad,
  }) async {
    await users.doc(uid).set({
      'email': email,
      'nombre': nombre,
      'edad': edad,
      'rol': 'estudiante',
      'telefono': '',
      'fecha_registro': FieldValue.serverTimestamp(),
      'progreso': {
        'racha': 0,
      },
      'division_actual': 'explorador_1',
      'curso_actual': 'tablas_de_verdad',
      'nivel_actual': '1',
      'errores': {},
    }, SetOptions(merge: true));
  }
}
