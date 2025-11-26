// lib/presentation/modals/login_options_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/onboarding/onboarding_cubit.dart';

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

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthCubit>();

    /// 🔥 Recuperamos directamente del OnboardingCubit (flujo original)
    final onboarding = context.read<OnboardingCubit>();
    final nombre = onboarding.nombre;
    final edad = onboarding.edad;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthError) {
          setState(() {
            _errorMessage = state.message;
            if (!isRegisterMode) {
              _loginAttempts++;
            }
          });
        }

        if (state is AuthAuthenticated) {
          Navigator.of(context).pop();
        }

        if (state is AuthLoading) {
          setState(() => _errorMessage = null);
        }
      },
      child: Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: SingleChildScrollView(
          child: Column(
            children: [
              const SizedBox(height: 40),

              Text(
                isRegisterMode ? "Crear cuenta" : "Guardar progreso",
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF303030)),
              ),

              const SizedBox(height: 10),

              Text(
                isRegisterMode
                    ? "Tu cuenta se vinculará con los datos que ingresaste al inicio."
                    : "Inicia sesión o crea una cuenta para guardar tu progreso",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black54, fontSize: 15),
              ),

              const SizedBox(height: 20),

              if (!isRegisterMode) ...[
                GoogleLoginButton(onPressed: () => auth.signInWithGoogle()),
                const SizedBox(height: 12),
                FacebookLoginButton(onPressed: () {}),
                const SizedBox(height: 12),
                PhoneLoginButton(onPressed: () {}),
                const SizedBox(height: 25),
              ],

              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    border: Border.all(color: Colors.red.shade200),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _errorMessage!,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.red.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

              const SizedBox(height: 12),

              if (!isRegisterMode && _loginAttempts >= maxAttempts)
                Column(
                  children: [
                    Text(
                      "Has superado el número máximo de intentos.\nIntenta más tarde.",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                          color: Colors.red.shade700,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 15),
                  ],
                ),

              TextField(
                controller: emailCtrl,
                decoration: InputDecoration(
                  labelText: "Correo electrónico",
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: passCtrl,
                obscureText: true,
                onChanged: (_) => setState(() => _errorMessage = null),
                decoration: InputDecoration(
                  labelText: "Contraseña",
                  border:
                      OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
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

                          if (isRegisterMode) {
                            /// 🔥 pasa nombre y edad correctos
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
                    backgroundColor: (!isRegisterMode &&
                            _loginAttempts >= maxAttempts)
                        ? Colors.grey
                        : const Color(0xFFFFA200),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Text(
                    isRegisterMode ? "Crear cuenta" : "Iniciar sesión",
                    style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold),
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
                      decoration: TextDecoration.underline,
                      color: Colors.black87),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
