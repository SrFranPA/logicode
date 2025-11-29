import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/onboarding/onboarding_cubit.dart';
import 'name_screen.dart';
import 'age_screen.dart';
import '../home/home_screen.dart';

class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final onboarding = context.watch<OnboardingCubit>();

    final nombre = onboarding.state.nombre;
    final edad = onboarding.state.edad;

    if (nombre.isEmpty) return const NameScreen();
    if (edad == null) return const AgeScreen();

    return const HomeScreen();
  }
}
