// lib/services/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter_facebook_auth/flutter_facebook_auth.dart';

class FirebaseAuthService {
  final _auth = FirebaseAuth.instance;

  // EMAIL/PASSWORD REGISTER
  Future<UserCredential> registerEmailPassword(String email, String pass) async {
    return await _auth.createUserWithEmailAndPassword(
      email: email,
      password: pass,
    );
  }

  // EMAIL/PASSWORD LOGIN
  Future<UserCredential> loginEmailPassword(String email, String pass) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: pass,
    );
  }

  // GOOGLE LOGIN
  Future<UserCredential> signInGoogle() async {
    final GoogleSignInAccount? googleUser = await GoogleSignIn().signIn();
    if (googleUser == null) throw Exception("Google cancelado");

    final googleAuth = await googleUser.authentication;

    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    return await _auth.signInWithCredential(credential);
  }

  // FACEBOOK LOGIN
  Future<UserCredential> signInFacebook() async {
    final LoginResult result = await FacebookAuth.instance.login();

    if (result.status != LoginStatus.success) {
      throw Exception("Facebook cancelado");
    }

    final credential = FacebookAuthProvider.credential(
      result.accessToken!.tokenString,
    );

    return await _auth.signInWithCredential(credential);
  }

  Future<void> logout() async {
    await _auth.signOut();
    await GoogleSignIn().signOut();
    await FacebookAuth.instance.logOut();
  }
}
