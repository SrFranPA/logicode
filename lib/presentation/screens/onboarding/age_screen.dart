import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/onboarding/onboarding_cubit.dart';
import '../../../services/local_storage_service.dart';
import '../home/home_screen.dart';

class AgeScreen extends StatefulWidget {
  const AgeScreen({super.key});

  @override
  State<AgeScreen> createState() => _AgeScreenState();
}

class _AgeScreenState extends State<AgeScreen> {
  double _edad = 12;

  Future<void> _finish() async {
    final onboarding = context.read<OnboardingCubit>();

    // Guardamos la edad en el cubit
    onboarding.setEdad(_edad.toInt());

    // Marcamos el onboarding como completado
    await LocalStorageService().setOnboardingCompleted(true);

    // Navegamos al Home y limpiamos el stack
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const HomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6EDF7),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                "¿Cuántos años tienes?",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303030),
                ),
              ),

              const SizedBox(height: 30),

              Text(
                _edad.toInt().toString(),
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF303030),
                ),
              ),

              const SizedBox(height: 10),

              Slider(
                value: _edad,
                min: 7,
                max: 65,
                divisions: 65 - 7,
                label: _edad.toInt().toString(),
                onChanged: (value) {
                  setState(() {
                    _edad = value;
                  });
                },
              ),

              const SizedBox(height: 30),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: _finish,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: const Text(
                    "Continuar",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
