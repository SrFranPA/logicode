import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/onboarding/onboarding_cubit.dart';

import '../../../services/local_storage_service.dart';
import '../../modals/login_options_modal.dart';

// 🔥 IMPORTAMOS LAS DOS PANTALLAS
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/student/student_home_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    final nombre = context.watch<OnboardingCubit>().state.nombre;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        // ======================================================
        // 🔥 REDIRECCIONAMIENTO SEGÚN ROL
        // ======================================================
        if (state is AuthAuthenticated) {
          await LocalStorageService().setOnboardingCompleted(true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inicio de sesión exitoso ✔")),
          );

          // ADMIN ----------------------------------------------
          if (state.rol == "admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
            return;
          }

          // ESTUDIANTE -----------------------------------------
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          );
        }

        // ERROR -------------------------------------------------
        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },

      // ======================================================
      // PANTALLA HOME (ANTES DEL LOGIN)
      // ======================================================
      child: Scaffold(
        backgroundColor: const Color(0xFFFDF7E2),

        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 15),

              // ---------------- HUD Superior ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.local_fire_department,
                            color: Colors.black26, size: 30),
                        SizedBox(width: 6),
                        Text(
                          "0 días",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: const [
                        Icon(Icons.favorite, color: Colors.red, size: 28),
                        Icon(Icons.favorite, color: Colors.red, size: 28),
                        Icon(Icons.favorite, color: Colors.red, size: 28),
                        Icon(Icons.favorite, color: Colors.red, size: 28),
                        Icon(Icons.favorite, color: Colors.red, size: 28),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              Text(
                "¡Hola, $nombre! 👋",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303030),
                ),
              ),

              const SizedBox(height: 4),

              SizedBox(
                width: 180,
                height: 180,
                child: ClipOval(
                  child: Image.asset(
                    '../../../../assets/images/mascota.png',
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 35),

              // ---------------- BOTÓN PRINCIPAL ----------------
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  height: 60,
                  child: ElevatedButton(
                    onPressed: () {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        shape: const RoundedRectangleBorder(
                          borderRadius: BorderRadius.vertical(
                            top: Radius.circular(25),
                          ),
                        ),
                        builder: (_) => const LoginOptionsModal(),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(18),
                      ),
                    ),
                    child: const Text(
                      "Guardar mi progreso",
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(),
            ],
          ),
        ),

        // ================= HUD INFERIOR =====================
        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(color: Colors.black12.withOpacity(0.1)),
            ),
          ),
          child: BottomNavigationBar(
            currentIndex: _selectedIndex,
            onTap: (index) => setState(() => _selectedIndex = index),
            type: BottomNavigationBarType.fixed,
            selectedItemColor: const Color(0xFFFFA200),
            unselectedItemColor: Colors.black38,
            iconSize: 28,
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.school),
                label: "Aprende",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.emoji_events),
                label: "Divisiones",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.person),
                label: "Perfil",
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.settings),
                label: "Ajustes",
              ),
            ],
          ),
        ),
      ),
    );
  }
}
