// lib/presentation/modals/login_options_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/onboarding/onboarding_cubit.dart';

import '../../../services/user_service.dart';
import '../widgets/social_login_buttons.dart';
import '../widgets/password_rules_widget.dart';

class LoginOptionsModal extends StatefulWidget {
  const LoginOptionsModal({super.key});

  @override
  State<LoginOptionsModal> createState() => _LoginOptionsModalState();
}

class _LoginOptionsModalState extends State<LoginOptionsModal> {
  bool isRegisterMode = false;

  final emailCtrl = TextEditingController();
  final passCtrl = TextEditingController();

  String? _errorMessage;
  int _loginAttempts = 0;
  static const int maxAttempts = 7;

  String _mapAuthError(String message) {
    final lower = message.toLowerCase();
    if (lower.contains('email-already-in-use')) {
      return 'El correo ya está registrado. Inicia sesión o usa otro.';
    }
    if (lower.contains('weak-password')) {
      return 'La contraseña es muy débil. Usa al menos 6 caracteres.';
    }
    if (lower.contains('invalid-email')) {
      return 'El correo no es válido.';
    }
    if (lower.contains('user-not-found') || lower.contains('wrong-password')) {
      return 'Correo o contraseña incorrectos.';
    }
    if (lower.contains('too-many-requests')) {
      return 'Demasiados intentos. Intenta más tarde.';
    }
    return 'Ocurrió un error. Revisa los datos e intenta de nuevo.';
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>();
    final onboarding = context.read<OnboardingCubit>();

    final nombre = onboarding.state.nombre;
    final edad = onboarding.state.edad ?? 0;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() {
            _errorMessage = _mapAuthError(state.message);
            if (!isRegisterMode) _loginAttempts++;
          });
        }

        if (state is AuthAuthenticated) {
          Navigator.of(context).pop();
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 30,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              Text(
                isRegisterMode ? "Crear cuenta" : "Guardar progreso",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303030),
                ),
              ),
              const SizedBox(height: 10),

              Text(
                isRegisterMode
                    ? "Tu cuenta se vinculará con los datos ingresados."
                    : "Inicia sesión o crea una cuenta",
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 15, color: Colors.black54),
              ),

              const SizedBox(height: 25),

              // 🔥 Google
              if (!isRegisterMode) ...[
                GoogleLoginButton(
                  onPressed: () {
                    Navigator.pop(context);
                    auth.loginGoogle();
                  },
                ),
                const SizedBox(height: 12),
                const SizedBox(height: 25),
              ],

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade700,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              if (!isRegisterMode && _loginAttempts >= maxAttempts)
                Text(
                  "Has superado el límite de intentos.\nIntenta más tarde.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),

              const SizedBox(height: 12),

              // Email
              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: passCtrl,
                obscureText: true,
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onChanged: (_) => setState(() => _errorMessage = null),
              ),

              if (isRegisterMode)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: PasswordRulesWidget(password: passCtrl.text),
                ),

              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  onPressed: (!isRegisterMode &&
                          _loginAttempts >= maxAttempts)
                      ? null
                      : () {
                          final email = emailCtrl.text.trim();
                          final pass = passCtrl.text.trim();

                          if (email.isEmpty || pass.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Completa todos los campos.')),
                            );
                            return;
                          }

                          if (isRegisterMode) {
                            auth.registerEmailPassword(
                              email,
                              pass,
                              nombre,
                              edad,
                            );
                          } else {
                            auth.loginEmailPassword(email, pass);
                          }
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    isRegisterMode ? "Crear cuenta" : "Iniciar sesión",
                    style: const TextStyle(
                      fontSize: 20,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              GestureDetector(
                onTap: () {
                  setState(() {
                    isRegisterMode = !isRegisterMode;
                    _errorMessage = null;
                    _loginAttempts = 0;
                  });
                },
                child: Text(
                  isRegisterMode
                      ? "¿Ya tienes cuenta? Inicia sesión"
                      : "Crear cuenta",
                  style: const TextStyle(
                    color: Colors.black87,
                    decoration: TextDecoration.underline,
                    fontSize: 16,
                  ),
                ),
              ),

              const SizedBox(height: 25),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // 🔥 TELEFONO — Paso 1: ingresar número
  // ============================================================
  void _showPhoneInputModal(BuildContext context) {
    final phoneCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ingresa tu número",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: phoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: "Número de teléfono",
                  hintText: "+593 987654321",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  _startPhoneVerification(context, phoneCtrl.text.trim());
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA200),
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text(
                  "Enviar código",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 🔥 TELEFONO — Paso 2: enviar código SMS
  // ============================================================
  void _startPhoneVerification(BuildContext context, String phone) async {
    await FirebaseAuth.instance.verifyPhoneNumber(
      phoneNumber: phone,

      verificationCompleted: (PhoneAuthCredential credential) async {
        // ANDROID: login automático sin escribir código
        final user = await FirebaseAuth.instance.signInWithCredential(credential);
        _onPhoneLoginSuccess(context, user);
      },

      verificationFailed: (FirebaseAuthException e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.message ?? 'Error al verificar el número')),
        );
      },

      codeSent: (String verificationId, int? resendToken) {
        _showCodeInputModal(context, verificationId);
      },

      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // ============================================================
  // 🔥 TELEFONO — Paso 3: ingresar código
  // ============================================================
  void _showCodeInputModal(BuildContext context, String verificationId) {
    final codeCtrl = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Ingresa el código SMS",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 15),

              TextField(
                controller: codeCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Código",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed: () async {
                  final credential = PhoneAuthProvider.credential(
                    verificationId: verificationId,
                    smsCode: codeCtrl.text.trim(),
                  );

                  final user = await FirebaseAuth.instance
                      .signInWithCredential(credential);

                  _onPhoneLoginSuccess(context, user);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFFFA200),
                  minimumSize: const Size(double.infinity, 55),
                ),
                child: const Text(
                  "Verificar",
                  style: TextStyle(color: Colors.white, fontSize: 18),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 🔥 TELEFONO — Paso 4: Registrar usuario si no existe
  // ============================================================
  void _onPhoneLoginSuccess(BuildContext context, UserCredential cred) async {
    final uid = cred.user!.uid;
    final phone = cred.user!.phoneNumber ?? "";

    await UserService().ensureUserExists(
      uid: uid,
      nombre: "Usuario",
      email: phone,
    );

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Inicio de sesión exitoso ✔")),
    );
  }
}


