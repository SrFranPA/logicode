// lib/blocs/auth_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthBloc {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('users');

  // ---------------------- GOOGLE LOGIN ----------------------
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn.instance.authenticate();
      if (googleUser == null) return null;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await _auth.signInWithCredential(credential);
      final user = userCredential.user;
      if (user != null) {
        // Si es primera vez, crear usuario en DB con nodos vacíos
        final snapshot = await _dbRef.child(user.uid).get();
        if (!snapshot.exists) {
          final newUser = UserModel(
            uid: user.uid,
            nombre: user.displayName ?? 'Usuario',
            email: user.email ?? '',
            fechaRegistro: DateTime.now().toIso8601String(),
            progress: {
              'nivel1': {
                'cursoId': '',
                'leccionId': '',
                'completado': false,
                'puntuacion': 0,
                'fechaCompletado': '',
                'intentos': 0,
                'errores': 0,
                'ejerciciosErrados': [],
              }
            },
            records: {},
          );
          await _dbRef.child(user.uid).set(newUser.toMap());
        }
      }
      return user;
    } catch (e) {
      throw Exception('Error Google SignIn: $e');
    }
  }

  Future<void> signOutGoogle() async {
  try {
    // Cerrar sesión de Firebase
    await FirebaseAuth.instance.signOut();
    
    // Cerrar sesión de Google
    await GoogleSignIn.instance.signOut();

    print('Usuario desconectado correctamente');
  } catch (e) {
    print('Error al cerrar sesión: $e');
  }
}
}
