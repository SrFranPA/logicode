// lib/main.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:logicode/presentation/screens/student/aprende/test/pretest_screen.dart';

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
import 'services/notification_service.dart';

// screens
import 'presentation/screens/onboarding/onboarding_screen.dart';
import 'presentation/screens/home/home_screen.dart';
import 'presentation/screens/student/aprende/leccion_curso_screen.dart';
import 'presentation/screens/role_gate.dart';

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
}

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

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
  await NotificationService.init();

  runApp(LogicodeApp(
    authRepo: AuthRepository(
      FirebaseAuthService(),
      UserService(),
    ),
    cursoRepository: CursoRepository(firestore),
    preguntaRepository: PreguntaRepository(firestore),
    evaluacionesRepository: EvaluacionesRepository(db: firestore), //  CORRECTO
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
        home: const _AuthGate(),
        routes: {
          "/home": (_) => const HomeScreen(),
          "/pretest": (_) => const PretestScreen(),
        },
      ),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator.adaptive()),
          );
        }

        final user = snapshot.data;
        if (user == null) {
          return const OnboardingScreen();
        }

        return _LoginDelayGate(uid: user.uid);
      },
    );
  }
}

class _LoginDelayGate extends StatefulWidget {
  final String uid;

  const _LoginDelayGate({required this.uid});

  @override
  State<_LoginDelayGate> createState() => _LoginDelayGateState();
}

class _LoginDelayGateState extends State<_LoginDelayGate> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) setState(() => _ready = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_ready) {
      return const Scaffold(
        body: Center(
          child: Image(
            image: AssetImage('assets/gif/open.gif'),
            width: 220,
            height: 220,
            fit: BoxFit.contain,
          ),
        ),
      );
    }

    return RoleGate(uid: widget.uid);
  }
}
