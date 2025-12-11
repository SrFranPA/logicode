import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../blocs/admin_cursos/admin_cursos_cubit.dart';
import 'ajustes/admin_settings_screen.dart';
import 'cursos/admin_cursos_screen.dart';
import 'lecciones/admin_lecciones_screen.dart';
import 'students/admin_students_screen.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  int _selectedIndex = 0;
  final ValueNotifier<bool> _viewAdminsNotifier = ValueNotifier(false);
  final ValueNotifier<int?> _lessonCountNotifier = ValueNotifier<int?>(0);

  final List<_NavItem> _navItems = const [
    _NavItem(icon: Icons.folder_copy_rounded, label: "Cursos"),
    _NavItem(icon: Icons.view_list_rounded, label: "Lecciones"),
    _NavItem(icon: Icons.group_rounded, label: "Estudiantes"),
    _NavItem(icon: Icons.settings_rounded, label: "Ajustes"),
  ];

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      const AdminCursosScreen(),
      AdminLeccionesScreen(lessonCountNotifier: _lessonCountNotifier),
      AdminStudentsScreen(viewAdminsNotifier: _viewAdminsNotifier),
      const AdminSettingsScreen(),
    ];
  }

  @override
  void dispose() {
    _viewAdminsNotifier.dispose();
    _lessonCountNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const accent = Color(0xFFFFA200);
    const darkBar = Color(0xFF131421);

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 255, 255, 255),
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(94),
        child: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [Color(0xFF1D2034), Color(0xFF121425)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
              child: Row(
                children: [
                  IconButton(
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    onPressed: () => Navigator.of(context).maybePop(),
                  ),
                  const SizedBox(width: 10),
                  Row(
                    children: const [
                      Icon(Icons.shield_outlined, color: Colors.white, size: 20),
                      SizedBox(width: 8),
                      Text(
                        "Panel administrador",
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _sectionHeader(_navItems[_selectedIndex].label),
              const SizedBox(height: 14),
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  child: DecoratedBox(
                    key: ValueKey(_selectedIndex),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFDF2DF),
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: Colors.black.withOpacity(0.035)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 16,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: _screens[_selectedIndex],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: _bottomNav(accent, darkBar),
    );
  }

  Widget _sectionHeader(String label) {
    final normalized = label.toLowerCase();
    final isCursos = normalized == "cursos";
    final isEstudiantes = normalized == "estudiantes";
    final isLecciones = normalized == "lecciones";

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4B3324), Color(0xFF2C1D16)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ValueListenableBuilder<bool>(
        valueListenable: _viewAdminsNotifier,
        builder: (_, viewingAdmins, __) {
          final showAdminsCount = isEstudiantes && viewingAdmins;
          return Row(
            children: [
              const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Text(
                "Gestion de ${label.toLowerCase()}",
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
              const Spacer(),
              if (isCursos) _coursesTotalBadge(),
              if (isEstudiantes)
                showAdminsCount
                    ? _adminTotalBadge()
                    : _studentsTotalBadge(),
              if (isLecciones) _lessonsTotalBadge(),
            ],
          );
        },
      ),
    );
  }

  Widget _coursesTotalBadge() {
    return BlocBuilder<AdminCursosCubit, AdminCursosState>(
      builder: (context, state) {
        final total = state is AdminCursosLoaded ? state.cursos.length : null;

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Text(
            total != null ? "$total cursos" : "Cargando...",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _studentsTotalBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("usuarios")
          .where("rol", isEqualTo: "estudiante")
          .snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.hasData ? snapshot.data!.docs.length : null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Text(
            total != null ? "$total estudiantes" : "Cargando...",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _adminTotalBadge() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("usuarios")
          .where("rol", isEqualTo: "admin")
          .snapshots(),
      builder: (context, snapshot) {
        final total = snapshot.hasData ? snapshot.data!.docs.length : null;
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Text(
            total != null ? "$total administradores" : "Cargando...",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _lessonsTotalBadge() {
    return ValueListenableBuilder<int?>(
      valueListenable: _lessonCountNotifier,
      builder: (_, total, __) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.14),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white.withOpacity(0.18)),
          ),
          child: Text(
            total != null && total > 0 ? "$total preguntas" : "Sin preguntas",
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }

  Widget _bottomNav(Color accent, Color darkBar) {
    return SafeArea(
      minimum: EdgeInsets.zero,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: darkBar,
          borderRadius: BorderRadius.circular(0),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: List.generate(_navItems.length, (index) {
            final item = _navItems[index];
            final selected = _selectedIndex == index;

            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _selectedIndex = index),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  decoration: BoxDecoration(
                    color:
                        selected ? accent.withOpacity(0.12) : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        item.icon,
                        size: 20,
                        color: selected ? accent : Colors.white70,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        item.label,
                        style: TextStyle(
                          color: selected ? accent : Colors.white70,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;

  const _NavItem({
    required this.icon,
    required this.label,
  });
}
