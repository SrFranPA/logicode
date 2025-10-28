// lib/screens/home_screen.dart
import 'package:flutter/material.dart';
import '../widgets/custom_button.dart';
import 'register_screen.dart';
import 'main_menu_screen.dart';
import '../blocs/auth_bloc.dart';

class HomeScreen extends StatelessWidget {
  HomeScreen({super.key});

  final AuthBloc _authBloc = AuthBloc();

  void _handleGoogleLogin(BuildContext context) async {
    try {
      final user = await _authBloc.signInWithGoogle();
      if (user != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => MainMenuScreen()),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString()),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

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
                        )
                      ]),
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
                      shadows: [
                        Shadow(
                          blurRadius: 10,
                          color: Colors.black45,
                          offset: Offset(2, 2),
                        )
                      ]),
                ),
                const SizedBox(height: 50),
                CustomButton(
                  text: 'Registrarse',
                  color: const Color.fromARGB(255, 203, 145, 30),
                  icon: Icons.person_add,
                  onPressed: () {
                    Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => RegisterScreen()));
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
                  text: 'Salir',
                  color: const Color.fromARGB(255, 40, 37, 37),
                  textColor: Colors.white,
                  icon: Icons.exit_to_app,
                  onPressed: () => _authBloc.signOutGoogle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
