import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import 'student_detail_screen.dart'; // ✔ Asegúrate que este archivo sí existe

class AdminStudentsScreen extends StatefulWidget {
  const AdminStudentsScreen({super.key});

  @override
  State<AdminStudentsScreen> createState() => _AdminStudentsScreenState();
}

class _AdminStudentsScreenState extends State<AdminStudentsScreen> {
  final searchCtrl = TextEditingController();
  String? selectedCurso;
  String? selectedDivision;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Administrar estudiantes",
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: searchCtrl,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: "Buscar por nombre",
                filled: true,
                fillColor: Colors.white,
              ),
              onChanged: (_) => setState(() {}),
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(child: _buildCursosDropdown()),
                const SizedBox(width: 12),
                Expanded(child: _buildDivisionesDropdown()),
              ],
            ),

            const SizedBox(height: 16),
            Expanded(child: _buildStudentsList()),
          ],
        ),
      ),
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
          decoration: const InputDecoration(labelText: "Curso"),
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
          value: selectedDivision ??
              null,
          decoration: const InputDecoration(labelText: "División"),
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

        final filtrados = data.where((doc) {
          final u = doc.data() as Map<String, dynamic>;

          if (u["rol"] != "estudiante") return false;

          final nombre = (u["nombre"] ?? "").toString().toLowerCase();
          final curso = u["curso_actual"];
          final division = u["division_actual"];

          if (search.isNotEmpty && !nombre.contains(search)) return false;
          if (selectedCurso != null && curso != selectedCurso) return false;
          if (selectedDivision != null && division != selectedDivision) {
            return false;
          }

          return true;
        }).toList();

        if (filtrados.isEmpty) {
          return const Center(child: Text("No se encontraron estudiantes."));
        }

        return ListView(
          children: filtrados.map((doc) {
            final u = doc.data() as Map<String, dynamic>;

            return Container(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF7F2FD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(u["nombre"] ?? "",
                            style: const TextStyle(
                                fontSize: 18, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text("Email: ${u["email"] ?? ""}"),
                        Text("División: ${u["division_actual"] ?? "—"}"),
                        Text("Curso actual: ${u["curso_actual"] ?? "—"}"),
                        Text("Racha: ${u["racha"] ?? 0}"),
                      ],
                    ),
                  ),

                  // --------- ABRIR MODAL ELEGANTE ---------
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) =>
                            StudentDetailScreen(userId: doc.id), // ✔ FIX
                      );
                    },
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }
}
