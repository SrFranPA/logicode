abstract class AuthState {}

class AuthInitial extends AuthState {}

class AuthLoading extends AuthState {}

class AuthAuthenticated extends AuthState {
  final String uid;
  final String rol; // 🔥 AGREGADO

  AuthAuthenticated({required this.uid, required this.rol});
}

class AuthError extends AuthState {
  final String message;
  AuthError(this.message);
}
