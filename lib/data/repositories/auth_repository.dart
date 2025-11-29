// lib/data/repositories/auth_repository.dart

import 'package:firebase_auth/firebase_auth.dart';
import '../../services/firebase_auth_service.dart';
import '../../services/user_service.dart';

class AuthRepository {
  final FirebaseAuthService authService;
  final UserService userService;

  AuthRepository(this.authService, this.userService);

  // REGISTRO EMAIL
  Future<User?> registerEmailPassword(
    String email,
    String pass,
    String nombre,
    int edad,
  ) async {
    try {
      final credential = await authService.registerEmailPassword(email, pass);

      final uid = credential.user?.uid;
      if (uid == null) throw Exception("No se pudo obtener UID.");

      await userService.createUser(
        uid: uid,
        nombre: nombre,
        email: email,
        edad: edad,
        rol: "estudiante",
      );

      return credential.user;
    } catch (e) {
      rethrow;
    }
  }

  // LOGIN EMAIL
  Future<User?> loginEmailPassword(String email, String pass) async {
    final cred = await authService.loginEmailPassword(email, pass);
    return cred.user;
  }

  // LOGIN GOOGLE
  Future<User?> loginGoogle() async {
    final cred = await authService.signInGoogle();

    // si es el primer login, registrar
    await userService.ensureUserExists(
      uid: cred.user!.uid,
      nombre: cred.user!.displayName ?? "Usuario",
      email: cred.user!.email ?? "",
    );

    return cred.user;
  }

  // LOGIN FACEBOOK
  Future<User?> loginFacebook() async {
    final cred = await authService.signInFacebook();

    await userService.ensureUserExists(
      uid: cred.user!.uid,
      nombre: cred.user!.displayName ?? "Usuario",
      email: cred.user!.email ?? "",
    );

    return cred.user;
  }

  Future<void> logout() async => authService.logout();
}
