import 'package:flutter/material.dart';
import 'cursos/admin_cursos_screen.dart';
import 'lecciones/admin_lecciones_screen.dart';
import 'ajustes/admin_settings_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;

  final List<Widget> _screens = const [
    AdminCursosScreen(),
    AdminLeccionesScreen(),
    AdminSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),

      // -------------------------
      // HUD SUPERIOR DEL ADMIN
      // -------------------------
      appBar: AppBar(
        backgroundColor: const Color(0xFFFDF7E2),
        elevation: 0,
        centerTitle: true,
        title: const Text(
          "Panel de administrador",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black87),
      ),

      // -------------------------
      // CONTENIDO SEGÚN SECCIÓN
      // -------------------------
      body: _screens[_selectedIndex],

      // -------------------------
      // HUD INFERIOR
      // -------------------------
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        backgroundColor: Colors.white,
        selectedItemColor: const Color(0xFFFFA200),
        unselectedItemColor: Colors.black45,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.folder_copy),
            label: "Cursos",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.view_list),
            label: "Lecciones",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Ajustes",
          ),
        ],
      ),
    );
  }
}
