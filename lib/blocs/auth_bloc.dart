// lib/blocs/auth_bloc.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user_model.dart';

class AuthBloc {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref().child('users');

  // ---------------------- GOOGLE LOGIN CORREGIDO ----------------------
  Future<User?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth =
          await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      final user = userCredential.user;

      if (user != null) {
        final userRef = _dbRef.child(user.uid);
        final snapshot = await userRef.get();

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

          await userRef.set(newUser.toMap());
          print("✅ Usuario creado en Firebase Database");
        } else {
          print("ℹ️ El usuario ya existía en Firebase Database");
        }
      }

      return user;
    } catch (e) {
      print("⚠️ ERROR Google Sign-In: $e");
      return null;
    }
  }

  // ---------------------- SIGN OUT ----------------------
  Future<void> signOutGoogle() async {
    try {
      await _auth.signOut();
      await GoogleSignIn().signOut();
      print('✅ Usuario desconectado correctamente');
    } catch (e) {
      print('❌ Error al cerrar sesión: $e');
    }
  }
}
