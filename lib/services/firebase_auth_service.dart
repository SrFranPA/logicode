// lib/services/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // ----------------------------------------
  // EMAIL / PASSWORD
  // ----------------------------------------
  Future<UserCredential> loginEmailPassword(String email, String pass) {
    return _auth.signInWithEmailAndPassword(email: email, password: pass);
  }

  Future<UserCredential> registerEmailPassword(String email, String pass) {
    return _auth.createUserWithEmailAndPassword(email: email, password: pass);
  }

  // ----------------------------------------
  // GOOGLE WEB LOGIN (Correcto)
  // ----------------------------------------
  Future<UserCredential> signInWithGoogle() async {
    // Importante: soporte Web
    GoogleAuthProvider googleProvider = GoogleAuthProvider();
    googleProvider.addScope('email');
    googleProvider.setCustomParameters({'prompt': 'select_account'});

    return await _auth.signInWithPopup(googleProvider);
  }
}
