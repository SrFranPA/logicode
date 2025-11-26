import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'auth_state.dart';
import '../../data/repositories/auth_repository.dart';
import '../onboarding/onboarding_cubit.dart';

class AuthCubit extends Cubit<AuthState> {
  final AuthRepository _repo;
  OnboardingCubit? _onboarding;

  AuthCubit(this._repo) : super(AuthInitial());

  void attachOnboarding(OnboardingCubit onboarding) {
    _onboarding = onboarding;
  }

  // -------------------------------------------------
  // LOGIN EMAIL
  // -------------------------------------------------
  Future<void> loginEmailPassword(String email, String pass) async {
    emit(AuthLoading());
    try {
      final cred = await _repo.loginEmail(email, pass);
      final rol = await _repo.getUserRole(cred.user!.uid);

      emit(AuthAuthenticated(cred.user!, rol ?? "estudiante"));
    } catch (_) {
      emit(AuthError("Correo o contraseña incorrectos."));
    }
  }

  // -------------------------------------------------
  // REGISTER EMAIL
  // -------------------------------------------------
  Future<void> registerEmailPassword(
      String email, String pass, String nombre, int edad) async {
    emit(AuthLoading());
    try {
      final cred = await _repo.registerEmail(email, pass, nombre, edad);
      emit(AuthAuthenticated(cred.user!, "estudiante"));
    } catch (_) {
      emit(AuthError("Ya existe una cuenta con ese correo."));
    }
  }

  // -------------------------------------------------
  // GOOGLE LOGIN
  // -------------------------------------------------
  Future<void> signInWithGoogle() async {
    emit(AuthLoading());
    try {
      final cred = await _repo.signInWithGoogle();
      final rol = await _repo.getUserRole(cred.user!.uid);

      emit(AuthAuthenticated(cred.user!, rol ?? "estudiante"));
    } catch (_) {
      emit(AuthError("Error al conectar con Google"));
    }
  }
}
