import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'auth_state.dart';
import '../../data/repositories/auth_repository.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository repo;
  final users = FirebaseFirestore.instance.collection('usuarios');

  AuthCubit(this.repo) : super(AuthInitial());

  // LOGIN EMAIL
  Future<void> loginEmailPassword(String email, String pass) async {
    emit(AuthLoading());
    try {
      final user = await repo.loginEmailPassword(email, pass);
      if (user == null) throw Exception("Error iniciando sesión");

      final userDoc = await users.doc(user.uid).get();
      final rol = userDoc.data()?['rol'] ?? "estudiante";

      emit(AuthAuthenticated(uid: user.uid, rol: rol));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // REGISTER EMAIL
  Future<void> registerEmailPassword(
      String email, String pass, String nombre, int edad) async {
    emit(AuthLoading());
    try {
      final user =
          await repo.registerEmailPassword(email, pass, nombre, edad);

      if (user == null) throw Exception("Error creando usuario");

      emit(AuthAuthenticated(uid: user.uid, rol: "estudiante"));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  // LOGIN GOOGLE
  Future<void> loginGoogle() async {
    emit(AuthLoading());
    try {
      final user = await repo.loginGoogle();
      if (user == null) throw Exception("Google cancelado");

      final userDoc = await users.doc(user.uid).get();
      final rol = userDoc.data()?['rol'] ?? "estudiante";

      emit(AuthAuthenticated(uid: user.uid, rol: rol));
    } catch (e) {
      emit(AuthError(e.toString()));
    }
  }

  Future<void> logout() async {
    await repo.logout();
    emit(AuthInitial());
  }
}
