import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'student_detail_screen.dart';

class AdminStudentsScreen extends StatefulWidget {
  final ValueNotifier<bool>? viewAdminsNotifier;
  const AdminStudentsScreen({super.key, this.viewAdminsNotifier});

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
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8EEDA), Color(0xFFF2DFBF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(child: _searchBar()),
                const SizedBox(width: 10),
                _roleToggle(),
              ],
            ),
            const SizedBox(height: 12),
            if (!showingAdmins) ...[
              _filtersRow(),
              const SizedBox(height: 12),
            ],
            Expanded(child: _buildStudentsList()),
          ],
        ),
      ),
    );
  }

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

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: TextField(
        controller: searchCtrl,
        decoration: const InputDecoration(
          border: InputBorder.none,
          prefixIcon: Icon(Icons.search, color: Colors.black54),
          hintText: "Buscar estudiante",
          contentPadding: EdgeInsets.symmetric(vertical: 14),
        ),
        onChanged: (_) => setState(() {}),
      ),
    );
  }

  Widget _roleToggle() {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: () {
          final next = !showingAdmins;
          setState(() => showingAdmins = next);
          widget.viewAdminsNotifier?.value = next;
        },
        style: ElevatedButton.styleFrom(
          backgroundColor:
              showingAdmins ? const Color(0xFF6A7FDB) : const Color(0xFFFFA200),
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
            Icon(showingAdmins ? Icons.verified_user : Icons.school),
            const SizedBox(width: 6),
            Text(showingAdmins ? "Ver admins" : "Ver estudiantes"),
          ],
        ),
      ),
    );
  }

  Widget _filtersRow() {
    return Row(
      children: [
        Expanded(child: _buildCursosDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _buildDivisionesDropdown()),
      ],
    );
  }

  Widget _buildCursosDropdown() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("cursos")
          .orderBy("orden")
          .snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) return const SizedBox();

        final items = snap.data!.docs;

        return DropdownButtonFormField<String>(
          value: selectedCurso,
          decoration: InputDecoration(
            labelText: "Curso",
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
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

  Widget _buildStudentsList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("usuarios").snapshots(),
      builder: (_, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final data = snap.data!.docs;
        final search = searchCtrl.text.toLowerCase();
        final targetRole = showingAdmins ? "admin" : "estudiante";

        final filtrados = data.where((doc) {
          final u = doc.data() as Map<String, dynamic>;

          if (u["rol"] != targetRole) return false;

          final nombre = (u["nombre"] ?? "").toString().toLowerCase();
          final curso = u["curso_actual"];
          final division = u["division_actual"];

          if (search.isNotEmpty && !nombre.contains(search)) return false;
          if (!showingAdmins) {
            if (selectedCurso != null && curso != selectedCurso) return false;
            if (selectedDivision != null && division != selectedDivision) {
              return false;
            }
          }

          return true;
        }).toList();

        if (filtrados.isEmpty) {
          return const Center(child: Text("No se encontraron estudiantes."));
        }

        return ListView.builder(
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
                            _pill(
                                "Rol: ${showingAdmins ? 'Administrador' : 'Estudiante'}"),
                            if (!showingAdmins)
                              _pill(
                                  "División: ${division.isEmpty ? 'N/D' : division}"),
                            if (!showingAdmins)
                              _pill("Curso: ${curso.isEmpty ? 'N/D' : curso}"),
                            if (!showingAdmins) _pill("Racha: $racha días"),
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
                        color: const Color(0xFF6A7FDB).withOpacity(0.14),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, color: Color(0xFF6A7FDB)),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _avatar(String name) {
    final initials = name.isNotEmpty
        ? name.trim().split(' ').map((e) => e.isNotEmpty ? e[0] : '').take(2).join()
        : "?";
    return Container(
      height: 44,
      width: 44,
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
          ),
        ),
      ),
    );
  }

  Widget _pill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF2F4F8),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w600,
          fontSize: 12,
        ),
      ),
    );
  }
}
