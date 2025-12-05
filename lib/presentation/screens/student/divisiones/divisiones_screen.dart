import 'package:flutter/material.dart';

class DivisionesScreen extends StatelessWidget {
  const DivisionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFFF7E8),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          'Divisiones',
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: const Center(
        child: Text(
          'Aquí irá el detalle de divisiones 🏆',
          style: TextStyle(fontSize: 18),
        ),
      ),
    );
  }
}
