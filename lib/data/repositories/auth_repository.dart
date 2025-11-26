import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';

class AuthRepository {
  final _auth = FirebaseAuthService();
  final _db = FirebaseFirestore.instance;

  // -------------------------------------------------
  // LOGIN EMAIL
  // -------------------------------------------------
  Future<UserCredential> loginEmail(String email, String pass) {
    return _auth.loginEmailPassword(email, pass);
  }

  // -------------------------------------------------
  // REGISTER EMAIL
  // -------------------------------------------------
  Future<UserCredential> registerEmail(
      String email, String pass, String nombre, int edad) async {

    final cred = await _auth.registerEmailPassword(email, pass);

    await saveUserData(
      uid: cred.user!.uid,
      email: email,
      nombre: nombre,
      edad: edad,
    );

    return cred;
  }

  // -------------------------------------------------
  // GOOGLE LOGIN
  // -------------------------------------------------
  Future<UserCredential> signInWithGoogle() async {
    final cred = await _auth.signInWithGoogle();
    final uid = cred.user!.uid;

    final doc = await _db.collection("usuarios").doc(uid).get();

    if (!doc.exists) {
      await saveUserData(
        uid: uid,
        email: cred.user!.email ?? "",
        nombre: cred.user!.displayName ?? "Sin nombre",
        edad: 0,
      );
    }

    return cred;
  }

  // -------------------------------------------------
  // GUARDAR INFO EN FIRESTORE
  // -------------------------------------------------
  Future<void> saveUserData({
    required String uid,
    required String email,
    required String nombre,
    required int edad,
  }) async {
    await _db.collection("usuarios").doc(uid).set({
      "nombre": nombre,
      "email": email,
      "edad": edad,
      "rol": "estudiante",
      "nivel_actual": "1",
      "division_actual": "explorador_1",
      "curso_actual": "tablas_de_verdad",
      "errores": [],
      "progreso": {
        "racha": 0,
      },
      "fecha_registro": DateTime.now(),
    }, SetOptions(merge: true));
  }

  // -------------------------------------------------
  // OBTENER ROL DEL USUARIO
  // -------------------------------------------------
  Future<String?> getUserRole(String uid) async {
    final doc = await _db.collection("usuarios").doc(uid).get();
    return doc.data()?["rol"];
  }
}
