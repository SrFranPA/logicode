import 'package:flutter/material.dart';

class StudentPracticasScreen extends StatelessWidget {
  const StudentPracticasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(backgroundColor: Colors.orange, title: const Text("Prácticas")),
      body: const Center(child: Text("Pantalla de Prácticas")),
    );
  }
}
