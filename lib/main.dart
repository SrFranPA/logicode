// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'firebase_options.dart';

// blocs 
import 'blocs/auth/auth_cubit.dart';
import 'blocs/onboarding/onboarding_cubit.dart';
import 'blocs/admin_cursos/admin_cursos_cubit.dart';
import 'blocs/admin_preguntas/admin_preguntas_cubit.dart';
import 'blocs/evaluaciones/evaluaciones_cubit.dart';

// repos
import 'data/repositories/auth_repository.dart';
import 'data/repositories/curso_repository.dart';
import 'data/repositories/pregunta_repository.dart';
import 'data/repositories/evaluaciones_repository.dart';

import 'services/firebase_auth_service.dart';
import 'services/user_service.dart';

// screens
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/student/aprende/test/pretest_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } else {
      Firebase.app();
    }
  } on FirebaseException catch (e) {
    if (e.code == 'duplicate-app') {
      Firebase.app();
    } else {
      rethrow;
    }
  }

  final firestore = FirebaseFirestore.instance;

  runApp(LogicodeApp(
    authRepo: AuthRepository(
      FirebaseAuthService(),
      UserService(),
    ),
    cursoRepository: CursoRepository(firestore),
    preguntaRepository: PreguntaRepository(firestore),
    evaluacionesRepository: EvaluacionesRepository(db: firestore), // 🔥 CORRECTO
  ));
}

class LogicodeApp extends StatelessWidget {
  final AuthRepository authRepo;
  final CursoRepository cursoRepository;
  final PreguntaRepository preguntaRepository;
  final EvaluacionesRepository evaluacionesRepository;

  const LogicodeApp({
    super.key,
    required this.authRepo,
    required this.cursoRepository,
    required this.preguntaRepository,
    required this.evaluacionesRepository,
  });

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => AuthCubit(authRepo)),
        BlocProvider(create: (_) => OnboardingCubit()),

        // admin
        BlocProvider(create: (_) => AdminCursosCubit(cursoRepository)),
        BlocProvider(create: (_) => AdminPreguntasCubit(preguntaRepository)),

        // evaluaciones (pre / post test)
        BlocProvider(create: (_) => EvaluacionesCubit(evaluacionesRepository)),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const OnboardingScreen(),
        routes: {
          "/home": (_) => const HomeScreen(),
          "/pretest": (_) => const PretestScreen(),
        },
      ),
    );
  }
}
