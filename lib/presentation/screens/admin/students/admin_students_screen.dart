import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'student_detail_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  final ValueNotifier<bool>? viewAdminsNotifier;
  final ValueNotifier<int?>? studentCountNotifier;
  const AdminStudentsScreen({super.key, this.viewAdminsNotifier, this.studentCountNotifier});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final searchCtrl = TextEditingController();
  String? selectedCurso;
  String? selectedDivision;
  bool showingAdmins = false;
  VoidCallback? _notifierListener;

  @override
  void initState() {
    super.initState();
    showingAdmins = widget.viewAdminsNotifier?.value ?? false;
    if (widget.viewAdminsNotifier != null) {
      _notifierListener = () {
        final newVal = widget.viewAdminsNotifier!.value;
        if (newVal != showingAdmins) {
          setState(() => showingAdmins = newVal);
        }
      };
      widget.viewAdminsNotifier!.addListener(_notifierListener!);
    }
  }

  @override
  void dispose() {
    if (_notifierListener != null && widget.viewAdminsNotifier != null) {
      widget.viewAdminsNotifier!.removeListener(_notifierListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              _filtersCard(),
              const SizedBox(height: 12),
              _buildStudentsList(shrinkWrap: true),
            ],
          ),
        ),
      ),
    );
  }

  Widget _searchBar() {
    return TextField(
      controller: searchCtrl,
      decoration: InputDecoration(
        labelText: "Buscar estudiante...",
        suffixIcon: const Icon(Icons.search),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      onChanged: (_) => setState(() {}),
    );
  }

  Widget _roleToggle() {
    final toAdmins = !showingAdmins;
    final Color bg = toAdmins ? const Color(0xFF6A7FDB) : const Color(0xFFFFA200);
    final IconData icon = toAdmins ? Icons.shield_outlined : Icons.school;
    final String label = toAdmins ? "Ver administradores" : "Ver estudiantes";

    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          final next = !showingAdmins;
          setState(() => showingAdmins = next);
          widget.viewAdminsNotifier?.value = next;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 4,
          padding: const EdgeInsets.symmetric(horizontal: 12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon),
            const SizedBox(width: 6),
            Text(label),
          ],
        ),
      ),
    );
  }

  Widget _buildCursosDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("cursos").orderBy("orden").snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        final items = snap.data!.docs;
        return DropdownButtonFormField<String>(
          value: selectedCurso,
          decoration: InputDecoration(
            labelText: "Curso",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text("Todos")),
            ...items.map(
              (c) => DropdownMenuItem(
                value: c.id,
                child: Text(c["nombre"]),
              ),
            ),
          ],
          onChanged: (v) => setState(() => selectedCurso = v),
        );
      },
    );
  }

  Widget _buildDivisionesDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("divisiones").snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();
        final items = snap.data!.docs;
        return DropdownButtonFormField<String>(
          value: selectedDivision,
          decoration: InputDecoration(
            labelText: "División",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: [
            const DropdownMenuItem(value: null, child: Text("Todas")),
            ...items.map(
              (d) => DropdownMenuItem(
                value: d.id,
                child: Text(d["nombre"]),
              ),
            ),
          ],
          onChanged: (v) => setState(() => selectedDivision = v),
        );
      },
    );
  }

  Widget _filtersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Text(
                "Filtros",
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 14,
                  color: Color(0xFF2C1B0E),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: _searchBar()),
              const SizedBox(width: 10),
              _roleToggle(),
            ],
          ),
          if (!showingAdmins) ...[
            const SizedBox(height: 12),
            _buildCursosDropdown(),
            const SizedBox(height: 12),
            _buildDivisionesDropdown(),
          ],
        ],
      ),
    );
  }

  Widget _buildStudentsList({bool shrinkWrap = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("usuarios").snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.studentCountNotifier?.value = 0;
          });
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.docs;
        final search = searchCtrl.text.toLowerCase();
        final targetRole = showingAdmins ? "admin" : "estudiante";

        final filtrados = data.where((doc) {
          final u = doc.data() as Map<String, dynamic>;

          final rol = (u["rol"] ?? "").toString().trim().toLowerCase();
          if (rol != targetRole) return false;

          final nombre = (u["nombre"] ?? "").toString().toLowerCase();
          final curso = (u["curso_actual"] ?? "").toString().trim();
          final division = (u["division_actual"] ?? "").toString().trim();

          if (search.isNotEmpty && !nombre.contains(search)) return false;
          if (!showingAdmins) {
            if (selectedCurso != null && curso != selectedCurso) return false;
            if (selectedDivision != null && division != selectedDivision) return false;
          }
          return true;
        }).toList();

        if (!showingAdmins) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            widget.studentCountNotifier?.value = filtrados.length;
          });
        }

        if (filtrados.isEmpty) {
          return const Center(child: Text("No se encontraron estudiantes."));
        }

        return ListView.builder(
          shrinkWrap: shrinkWrap,
          physics: shrinkWrap ? const NeverScrollableScrollPhysics() : null,
          itemCount: filtrados.length,
          itemBuilder: (_, index) {
            final doc = filtrados[index];
            final u = doc.data() as Map<String, dynamic>;
            final nombre = (u["nombre"] ?? "") as String;
            final email = (u["email"] ?? "") as String;
            final division = (u["division_actual"] ?? "") as String;
            final curso = (u["curso_actual"] ?? "") as String;
            final racha = u["racha"] ?? 0;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _avatar(nombre),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          nombre,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black87,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          email.isNotEmpty ? email : "Sin correo",
                          style: const TextStyle(
                            color: Colors.black54,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            _pill("Rol: ${showingAdmins ? 'Administrador' : 'Estudiante'}",
                                color: const Color(0xFFFFE4B8)),
                            if (!showingAdmins)
                              _pill("División: ${division.isEmpty ? 'N/D' : division}",
                                  color: const Color(0xFFE9ECF3)),
                            if (!showingAdmins)
                              _pill("Curso: ${curso.isEmpty ? 'N/D' : curso}",
                                  color: const Color(0xFFFFF3E0)),
                            if (!showingAdmins)
                              _pill("Racha: $racha dias",
                                  color: const Color(0xFFE8F9E5)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  GestureDetector(
                    onTap: () {
                      showDialog(
                        context: context,
                        builder: (_) => StudentDetailScreen(userId: doc.id),
                      );
                    },
                    child: Container(
                      height: 36,
                      width: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF6A7FDB).withOpacity(0.16),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Color(0xFF6A7FDB), size: 18),
                    ),
                  ),
                  if (!showingAdmins) ...[
                    const SizedBox(width: 8),
                    GestureDetector(
                      onTap: () => _confirmDelete(context, doc.id),
                      child: Container(
                        height: 36,
                        width: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFFE57373).withOpacity(0.16),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.delete, color: Color(0xFFE57373), size: 18),
                      ),
                    ),
                  ],
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _pill(String text,
      {Color color = const Color(0xFFF2F4F8), Color textColor = Colors.black87}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.04)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _avatar(String name) {
    final initials =
        name.isNotEmpty ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join() : "?";
    return Container(
      height: 46,
      width: 46,
      decoration: const BoxDecoration(
        shape: BoxShape.circle,
        color: Color(0xFFFFA200),
      ),
      child: Center(
        child: Text(
          initials.toUpperCase(),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Seguro que deseas eliminar este estudiante?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await FirebaseFirestore.instance.collection("usuarios").doc(userId).delete();
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}
