// lib/presentation/screens/admin/students/student_detail_screen.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class StudentDetailScreen extends StatefulWidget {
  final String userId;
  const StudentDetailScreen({super.key, required this.userId});

  @override
  State<StudentDetailScreen> createState() => _StudentDetailScreenState();
}

class _StudentDetailScreenState extends State<StudentDetailScreen> {
  final _db = FirebaseFirestore.instance;

  Map<String, dynamic>? userData;
  bool cargando = true;

  @override
  void initState() {
    super.initState();
    loadUser();
  }

  Future<void> loadUser() async {
    final doc = await _db.collection("usuarios").doc(widget.userId).get();
    userData = doc.data();
    setState(() => cargando = false);
  }

  // ============================================================
  // 🔥 MODAL: EDITAR CAMPO
  // ============================================================
  void showEditModal({
    required String fieldName,
    required String label,
    required dynamic initialValue,
    required bool isDropdown,
    Future<List<Map<String, String>>> Function()? fetchOptions,
    bool editable = true,
  }) {
    if (!editable) return;

    final ctrl = TextEditingController(text: initialValue?.toString() ?? "");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20, right: 20, top: 25,
          ),
          child: FutureBuilder<List<Map<String, String>>>(
            future: isDropdown ? fetchOptions!() : Future.value([]),
            builder: (context, snap) {
              final options = snap.data ?? [];

              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Editar $label",
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 20),

                  if (!isDropdown)
                    TextField(
                      controller: ctrl,
                      decoration: InputDecoration(
                        labelText: label,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    ),

                  if (isDropdown)
                    DropdownButtonFormField<String>(
                      value: initialValue?.toString(),
                      decoration: const InputDecoration(labelText: "Seleccione"),
                      items: options
                          .map((opt) => DropdownMenuItem(
                                value: opt["id"],
                                child: Text(opt["nombre"]!),
                              ))
                          .toList(),
                      onChanged: (v) => ctrl.text = v!,
                    ),

                  const SizedBox(height: 30),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      TextButton(
                        child: const Text("Cancelar",
                            style: TextStyle(color: Colors.red)),
                        onPressed: () => Navigator.pop(context),
                      ),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.orange,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 20, vertical: 12),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        onPressed: () async {
                          await _db
                              .collection("usuarios")
                              .doc(widget.userId)
                              .update({fieldName: ctrl.text.trim()});

                          Navigator.pop(context);
                          loadUser();
                        },
                        child: const Text("Guardar",
                            style: TextStyle(color: Colors.white)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                ],
              );
            },
          ),
        );
      },
    );
  }

  // ============================================================
  // 🔥 MODAL: DESACTIVAR
  // ============================================================
  void showDeactivateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Desactivar estudiante",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "Esto desactivará al estudiante, pero NO eliminará sus datos.",
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      child: const Text("Cancelar"),
                      onPressed: () => Navigator.pop(context)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                    child: const Text("Desactivar",
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      await _db
                          .collection("usuarios")
                          .doc(widget.userId)
                          .update({"activo": false});

                      Navigator.pop(context);
                      loadUser();
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // 🔥 MODAL: REACTIVAR
  // ============================================================
  void showReactivateModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text("Reactivar estudiante",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                "El estudiante podrá volver a acceder a la plataforma.",
              ),
              const SizedBox(height: 25),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                      child: const Text("Cancelar"),
                      onPressed: () => Navigator.pop(context)),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 12)),
                    child: const Text("Reactivar",
                        style: TextStyle(color: Colors.white)),
                    onPressed: () async {
                      await _db
                          .collection("usuarios")
                          .doc(widget.userId)
                          .update({"activo": true});

                      Navigator.pop(context);
                      loadUser();
                    },
                  )
                ],
              )
            ],
          ),
        );
      },
    );
  }

  // ============================================================
  // WIDGET INFO ITEM
  // ============================================================
  Widget infoItem({
    required String label,
    required String? value,
    bool editable = true,
    VoidCallback? onEdit,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFF7F2FD),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(label,
                    style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                        fontWeight: FontWeight.w500)),
                const SizedBox(height: 4),
                Text(value ?? "—",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600)),
              ])),
          if (editable)
            IconButton(
                onPressed: onEdit,
                icon: const Icon(Icons.edit, color: Colors.orange))
        ],
      ),
    );
  }

  // ============================================================
  // UI PRINCIPAL
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
          body: Center(child: CircularProgressIndicator()));
    }

    final u = userData!;

    return Scaffold(
      backgroundColor: const Color(0xFFF1ECEF),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Detalle del estudiante",
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            infoItem(
              label: "Nombre:",
              value: u["nombre"],
              onEdit: () => showEditModal(
                fieldName: "nombre",
                label: "Nombre",
                initialValue: u["nombre"],
                isDropdown: false,
              ),
            ),

            infoItem(
              label: "Email:",
              value: u["email"],
              editable: false,
            ),

            infoItem(
              label: "División actual:",
              value: u["division_actual"],
              onEdit: () => showEditModal(
                fieldName: "division_actual",
                label: "División",
                initialValue: u["division_actual"],
                isDropdown: true,
                fetchOptions: () async {
                  final snap = await _db
                      .collection("divisiones")
                      .orderBy("nombre")
                      .get();

                  return snap.docs
                      .map((d) =>
                          {"id": d.id.toString(), "nombre": d["nombre"].toString()})
                      .toList();
                },
              ),
            ),

            infoItem(
              label: "Curso actual:",
              value: u["curso_actual"],
              editable: false,
            ),

            infoItem(
              label: "Rol:",
              value: u["rol"],
              onEdit: () => showEditModal(
                fieldName: "rol",
                label: "Rol",
                initialValue: u["rol"],
                isDropdown: true,
                fetchOptions: () async => [
                  {"id": "estudiante", "nombre": "Estudiante"},
                  {"id": "admin", "nombre": "Administrador"},
                ],
              ),
            ),

            infoItem(
              label: "Racha:",
              value: u["racha"]?.toString(),
              editable: false,
            ),

            const SizedBox(height: 20),

            // 🔥 BOTÓN DINÁMICO
            if (u["activo"] == true)
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: showDeactivateModal,
                child: const Text("Desactivar estudiante",
                    style: TextStyle(color: Colors.white)),
              )
            else
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14))),
                onPressed: showReactivateModal,
                child: const Text("Reactivar estudiante",
                    style: TextStyle(color: Colors.white)),
              ),
          ],
        ),
      ),
    );
  }
}
