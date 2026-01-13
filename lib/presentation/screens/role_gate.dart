import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../screens/admin/admin_home_screen.dart';
import '../screens/student/student_home_screen.dart';

class RoleGate extends StatelessWidget {
  final String uid;

  const RoleGate({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection('usuarios')
          .doc(uid)
          .get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        final data = snapshot.data!.data() as Map<String, dynamic>?;

        final rol = data?['rol'] ?? "estudiante";

        if (rol == "admin") {
          return const AdminHomeScreen();
        } else {
          return const StudentHomeScreen();
        }
      },
    );
  }
}
