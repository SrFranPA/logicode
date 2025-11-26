import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../blocs/onboarding/onboarding_cubit.dart';
import 'age_screen.dart';

class NameScreen extends StatelessWidget {
  const NameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final nameCtrl = TextEditingController();
    final onboarding = context.read<OnboardingCubit>();

    return Scaffold(
      backgroundColor: Color(0xFFF6EDF7),
      body: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              "¿Cuál es tu nombre?",
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 25),
            TextField(
              controller: nameCtrl,
              decoration: InputDecoration(
                labelText: "Tu nombre",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            SizedBox(height: 25),
            ElevatedButton(
              onPressed: () {
                final nombre = nameCtrl.text.trim();
                if (nombre.isEmpty) return;

                onboarding.setNombre(nombre);

                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AgeScreen()),
                );
              },
              child: const Text("Continuar"),
            ),
          ],
        ),
      ),
    );
  }
}
