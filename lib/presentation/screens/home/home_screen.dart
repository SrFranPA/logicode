import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/auth/auth_cubit.dart';
import '../../../blocs/auth/auth_state.dart';
import '../../../blocs/onboarding/onboarding_cubit.dart';
import '../../../services/local_storage_service.dart';
import '../../modals/login_options_modal.dart';
import '../../screens/admin/admin_home_screen.dart';
import '../../screens/student/student_home_screen.dart';

class HomeScreen extends StatefulWidget {
  static const routeName = '/home';

  const HomeScreen({Key? key}) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  Widget build(BuildContext context) {
    final nombre = context.watch<OnboardingCubit>().state.nombre;

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) async {
        if (state is AuthAuthenticated) {
          await LocalStorageService().setOnboardingCompleted(true);

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Inicio de sesion exitoso")),
          );

          if (state.rol == "admin") {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const AdminHomeScreen()),
            );
            return;
          }

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const StudentHomeScreen()),
          );
        }

        if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(state.message)),
          );
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFFFF8EF),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding: const EdgeInsets.fromLTRB(16, 14, 16, 18),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF5D6A1), Color(0xFFE9A34F)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 10,
                        offset: Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: const [
                                Icon(Icons.local_fire_department,
                                    color: Colors.white, size: 18),
                                SizedBox(width: 6),
                                Text(
                                  "0 dias",
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.14),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Row(
                              children: List.generate(
                                5,
                                (i) => Padding(
                                  padding: EdgeInsets.only(left: i == 0 ? 0 : 6),
                                  child: const Icon(
                                    Icons.favorite,
                                    color: Colors.white,
                                    size: 18,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        "Hola, $nombre",
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Text(
                          "Elige tu ruta y guarda tu progreso.",
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            letterSpacing: 0.2,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFFFFFFF), Color(0xFFFDF6EA)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: const [
                      BoxShadow(
                        color: Color(0x22000000),
                        blurRadius: 12,
                        offset: Offset(0, 6),
                      ),
                    ],
                    border: Border.all(color: const Color(0xFFE9A34F).withOpacity(0.16)),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 170,
                        height: 170,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFFFFF2DC), Color(0xFFEFC28A)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: const [
                            BoxShadow(
                              color: Color(0x22000000),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: ClipOval(
                          child: Image.asset(
                            'assets/images/logo.png',
                            fit: BoxFit.cover,
                          ),
                        ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        height: 56,
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
                            backgroundColor: const Color(0xFFE07A1E),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                            elevation: 4,
                          ),
                          child: const Text(
                            "Registrate y comienza",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDF2DE),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFE9A34F).withOpacity(0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            _FeatureRow(
                              icon: Icons.school,
                              text: "Lecciones guiadas y retos interactivos",
                            ),
                            SizedBox(height: 10),
                            _FeatureRow(
                              icon: Icons.cloud_upload,
                              text: "Sincroniza tu avance en cualquier dispositivo",
                            ),
                            SizedBox(height: 10),
                            _FeatureRow(
                              icon: Icons.shield,
                              text: "Tu progreso se guarda de forma segura",
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeatureRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _FeatureRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          height: 34,
          width: 34,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: const Color(0xFFE9A34F).withOpacity(0.18),
          ),
          child: Icon(icon, color: const Color(0xFFE9A34F), size: 18),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              color: Color(0xFF555B64),
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}
