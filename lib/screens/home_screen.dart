import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/custom_button.dart';
import 'register_screen.dart';
import 'main_menu_screen.dart';
import 'admin_menu_screen.dart';
import '../blocs/auth_bloc.dart';


class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final AuthBloc _authBloc = AuthBloc();

  /// 🔐 Encriptar contraseña igual que en registro
  String _encrypt(String text) {
    final bytes = utf8.encode(text);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 🔹 LOGIN con Google
  Future<void> _handleGoogleLogin(BuildContext context) async {
    try {
      final user = await _authBloc.signInWithGoogle();

      if (user != null) {
        final userDoc =
            FirebaseFirestore.instance.collection('usuarios').doc(user.uid);

        await userDoc.set({
          'nombre': user.displayName?.toLowerCase() ?? 'sin nombre',
          'correo': user.email ?? '',
          'edad': 18,
          'foto': user.photoURL ?? '',
          'uid': user.uid,
          'password': 'google_auth',
          'tipo': 'estudiante',
          'fecha_registro': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        if (context.mounted) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const MainMenuScreen()),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error al iniciar con Google: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// 🔹 LOGIN manual con validación por tipo
  Future<void> _handleIngresar(BuildContext context) async {
    final nameController = TextEditingController();
    final passwordController = TextEditingController();
    bool errorNombre = false;
    bool errorPassword = false;

    await showDialog(
      barrierDismissible: false,
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(builder: (context, setState) {
          Future<void> verificarUsuario() async {
            final nombre = nameController.text.trim().toLowerCase();
            final password = passwordController.text.trim();

            setState(() {
              errorNombre = false;
              errorPassword = false;
            });

            if (nombre.isEmpty || password.isEmpty) {
              if (nombre.isEmpty) setState(() => errorNombre = true);
              if (password.isEmpty) setState(() => errorPassword = true);
              return;
            }

            try {
              final query = await FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('nombre', isEqualTo: nombre)
                  .limit(1)
                  .get();

              if (query.docs.isEmpty) {
                setState(() => errorNombre = true);
                return;
              }

              final data = query.docs.first.data();
              final storedPassword = data['password']?.toString() ?? '';
              final tipo = data['tipo']?.toString() ?? 'estudiante';

              // 🔐 Comparar contraseñas encriptadas
              final inputHashed = _encrypt(password);
              if (storedPassword != inputHashed) {
                setState(() => errorPassword = true);
                return;
              }

              Navigator.pop(dialogContext);

              if (tipo == 'admin') {
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const AdminMenuScreen()),
                  );
                }
              } else {
                if (context.mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (_) => const MainMenuScreen()),
                  );
                }
              }
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error al verificar usuario: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return AlertDialog(
            title: const Text("Ingresar"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(
                    labelText: "Nombre de usuario",
                    hintText: "Ejemplo: juan123",
                    errorText: errorNombre ? "Usuario no encontrado" : null,
                  ),
                  onChanged: (_) => setState(() => errorNombre = false),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: "Contraseña",
                    hintText: "••••••••",
                    errorText: errorPassword ? "Contraseña incorrecta" : null,
                  ),
                  onChanged: (_) => setState(() => errorPassword = false),
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    child: const Text("¿Olvidaste tu contraseña?"),
                    onPressed: () {
                      Navigator.pop(dialogContext);
                      _handleForgotPassword(context);
                    },
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(dialogContext),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: verificarUsuario,
                child: const Text("Aceptar"),
              ),
            ],
          );
        });
      },
    );
  }

  /// 🔹 Recuperar contraseña (simulado)
  Future<void> _handleForgotPassword(BuildContext context) async {
    final userController = TextEditingController();
    final phoneController = TextEditingController();
    bool errorUser = false;
    bool errorPhone = false;

    await showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(builder: (context, setState) {
          Future<void> verificarDatos() async {
            final user = userController.text.trim().toLowerCase();
            final phone = phoneController.text.trim();

            setState(() {
              errorUser = false;
              errorPhone = false;
            });

            if (user.isEmpty || phone.isEmpty) {
              if (user.isEmpty) setState(() => errorUser = true);
              if (phone.isEmpty) setState(() => errorPhone = true);
              return;
            }

            try {
              final query = await FirebaseFirestore.instance
                  .collection('usuarios')
                  .where('nombre', isEqualTo: user)
                  .limit(1)
                  .get();

              if (query.docs.isEmpty) {
                setState(() => errorUser = true);
                return;
              }

              final data = query.docs.first.data();
              final storedPhone = data['telefono']?.toString() ?? '';

              // Encriptar el número ingresado para comparar
              final encryptedInputPhone = sha256.convert(utf8.encode(phone)).toString();

              if (storedPhone != encryptedInputPhone) {
                setState(() => errorPhone = true);
                return;
              }

              Navigator.pop(ctx);

              // ⚠️ Simulación de envío de SMS
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                      '📩 Se ha enviado un SMS al número registrado con instrucciones para $user'),
                  backgroundColor: Colors.green,
                ),
              );
            } catch (e) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("Error al recuperar contraseña: $e"),
                  backgroundColor: Colors.red,
                ),
              );
            }
          }

          return AlertDialog(
            title: const Text("Recuperar contraseña"),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: userController,
                  decoration: InputDecoration(
                    labelText: "Nombre de usuario",
                    errorText: errorUser ? "Usuario no encontrado" : null,
                  ),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  decoration: InputDecoration(
                    labelText: "Número de teléfono",
                    errorText:
                        errorPhone ? "No coincide con el registrado" : null,
                  ),
                  keyboardType: TextInputType.phone,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text("Cancelar"),
              ),
              ElevatedButton(
                onPressed: verificarDatos,
                child: const Text("Enviar SMS"),
              ),
            ],
          );
        });
      },
    );
  }

  /// 🔹 INTERFAZ PRINCIPAL
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/fondo1.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Bienvenido',
                  style: TextStyle(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    shadows: [
                      Shadow(
                        blurRadius: 10,
                        color: Colors.black45,
                        offset: Offset(2, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Image.asset('assets/images/logo.png', height: 200),
                const SizedBox(height: 10),
                const Text(
                  '¡CodLogic!',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 50),
                CustomButton(
                  text: 'Registrarse',
                  color: const Color.fromARGB(255, 203, 145, 30),
                  icon: Icons.person_add,
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => RegisterScreen()),
                    );
                  },
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Continuar con Google',
                  color: const Color.fromARGB(255, 60, 56, 56),
                  textColor: Colors.white,
                  icon: Icons.g_mobiledata,
                  onPressed: () => _handleGoogleLogin(context),
                ),
                const SizedBox(height: 20),
                CustomButton(
                  text: 'Ingresar',
                  color: const Color.fromARGB(255, 40, 37, 37),
                  textColor: Colors.white,
                  icon: Icons.login,
                  onPressed: () => _handleIngresar(context),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
