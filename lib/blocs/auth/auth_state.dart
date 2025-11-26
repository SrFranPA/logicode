import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final User user;
  final String rol;      // 🔥 AGREGADO

  AuthAuthenticated(this.user, this.rol);
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
