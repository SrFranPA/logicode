// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

import 'blocs/auth/auth_cubit.dart';
import 'blocs/onboarding/onboarding_cubit.dart';

import 'data/repositories/auth_repository.dart';
import 'services/firebase_auth_service.dart';
import 'services/user_service.dart';

import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final authRepo = AuthRepository(
    FirebaseAuthService(),
    UserService(),
  );

  runApp(LogicodeApp(authRepo: authRepo));
}

class LogicodeApp extends StatelessWidget {
  final AuthRepository authRepo;
  const LogicodeApp({super.key, required this.authRepo});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authRepo)),
        BlocProvider(create: (_) => OnboardingCubit()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const OnboardingScreen(),
        routes: {
          "/home": (_) => const HomeScreen(),
        },
      ),
    );
  }
}
