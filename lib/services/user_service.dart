import 'package:cloud_firestore/cloud_firestore.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  // 🔥 Crear usuario por PRIMERA vez (registro)
  Future<void> createUser({
    required String uid,
    required String nombre,
    required String email,
    required int edad,
    String rol = "estudiante",
  }) async {
    await _db.collection("usuarios").doc(uid).set({
      "nombre": nombre,
      "email": email,
      "edad": edad,
      "rol": rol,

      // ✔️ Tus valores iniciales
      "division_actual": "explorador_1",
      "curso_actual": "desc_prob",
      "nivel_actual": "1",

      "fecha_registro": Timestamp.now(),
      "vidas": 5,
      "racha": 0,
      "xp_acumulada": 0,

      "telefono": "",
      "errores": [],
      "progreso": {},
    });
  }

  // 🔥 Usado en Google / Facebook Login
  // Solo crea si NO existe
  Future<void> ensureUserExists({
    required String uid,
    required String nombre,
    required String email,
  }) async {
    final doc = await _db.collection("usuarios").doc(uid).get();

    if (!doc.exists) {
      // Google / Facebook no dan edad → la dejamos en 0
      await createUser(
        uid: uid,
        nombre: nombre,
        email: email,
        edad: 0,
        rol: "estudiante",
      );
    }
  }
}
