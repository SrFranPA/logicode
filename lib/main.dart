// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'blocs/onboarding/onboarding_cubit.dart';
import 'blocs/auth/auth_cubit.dart';
import 'blocs/auth/auth_state.dart';

import 'data/repositories/auth_repository.dart';
import 'services/local_storage_service.dart';
import 'firebase_options.dart';

import 'presentation/screens/onboarding/name_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/role_gate.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await _initFirebase();

  // Un solo OnboardingCubit para toda la app
  final onboardingCubit = OnboardingCubit();

  // ¿Ya terminó onboarding previamente?
  final onboardingCompleted =
      await LocalStorageService().getOnboardingCompleted();

  runApp(MyApp(
    onboardingCubit: onboardingCubit,
    showOnboarding: !onboardingCompleted,
  ));
}

class MyApp extends StatelessWidget {
  final OnboardingCubit onboardingCubit;
  final bool showOnboarding;

  const MyApp({
    super.key,
    required this.onboardingCubit,
    required this.showOnboarding,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        // OnboardingCubit global reutilizando la instancia creada en main
        BlocProvider<OnboardingCubit>.value(
          value: onboardingCubit,
        ),

        // AuthCubit con repositorio y onboarding adjunto
        BlocProvider<AuthCubit>(
          create: (_) => AuthCubit(AuthRepository())
            ..attachOnboarding(onboardingCubit),
        ),
      ],

      // Escucha global para redirigir segun el rol
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(
                builder: (_) => RoleGate(uid: state.user.uid),
              ),
              (route) => false,
            );
          }
        },

        child: MaterialApp(
          debugShowCheckedModeBanner: false,
          home: showOnboarding ? const NameScreen() : const HomeScreen(),
        ),
      ),
    );
  }
}

Future<FirebaseApp> _initFirebase() async {
  // Evita el error [core/duplicate-app] cuando se reinicia o hay auto-inicialización nativa
  final existingDefault = Firebase.apps.where((app) => app.name == '[DEFAULT]').toList();
  if (existingDefault.isNotEmpty) {
    return existingDefault.first;
  }

  try {
    return await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    // Si mientras tanto se inicializó, reúsala
    final apps = Firebase.apps.where((app) => app.name == '[DEFAULT]').toList();
    if (e.code == 'duplicate-app' && apps.isNotEmpty) {
      return apps.first;
    }
    rethrow;
  }
}
