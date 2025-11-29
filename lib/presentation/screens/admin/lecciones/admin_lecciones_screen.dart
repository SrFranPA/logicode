import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'plantillas/chip_select_editor.dart';
import 'plantillas/drag_drop_editor.dart';
import 'plantillas/fill_blank_editor.dart';

class AdminLeccionesScreen extends StatefulWidget {
  const AdminLeccionesScreen({super.key});

  @override
  State<AdminLeccionesScreen> createState() => _AdminLeccionesScreenState();
}

class _AdminLeccionesScreenState extends State<AdminLeccionesScreen> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),

      appBar: AppBar(
        title: const Text("Banco de preguntas",
            style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.orange,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: _openCreateDialog,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _db
            .collection("banco_preguntas")
            .orderBy("fecha_creacion", descending: true)
            .snapshots(),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar preguntas"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final preguntas = snapshot.data!.docs;

          if (preguntas.isEmpty) {
            return const Center(child: Text("No existen preguntas aún"));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: preguntas.length,
            itemBuilder: (_, i) {
              final p = preguntas[i];

              return Card(
                child: ListTile(
                  title: Text(
                    p["enunciado"] ?? "(sin enunciado)",
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Curso: ${p["cursoId"]}\nTipo: ${p["tipo"]}\nDificultad: ${p["dificultad"]}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon:
                            const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openEditor(p),
                      ),
                      IconButton(
                        icon:
                            const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => _confirmDelete(p.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ================================================================
  // ✨ DIALOGO COMPLETO — 100% CORREGIDO Y FUNCIONAL
  // ================================================================
  void _openCreateDialog() {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        return StatefulBuilder(
          builder: (context, setState) {
            String tipo = "chip_select";
            String dificultad = "Muy fácil";
            String? curso;

            return AlertDialog(
              title: const Text("Crear nueva lección"),

              content: FutureBuilder<QuerySnapshot>(
                future: _db.collection("cursos").orderBy("orden").get(),
                builder: (_, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox(
                      height: 150,
                      child: Center(child: CircularProgressIndicator()),
                    );
                  }

                  final cursos = snapshot.data!.docs;

                  return SizedBox(
                    width: 400,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        DropdownButtonFormField(
                          decoration: const InputDecoration(labelText: "Curso"),
                          items: cursos.map((c) {
                            return DropdownMenuItem(
                              value: c.id,
                              child: Text(c["nombre"]),
                            );
                          }).toList(),
                          onChanged: (v) => setState(() => curso = v),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField(
                          decoration:
                              const InputDecoration(labelText: "Tipo de pregunta"),
                          value: tipo,
                          items: const [
                            DropdownMenuItem(
                                value: "chip_select",
                                child: Text("Chip Select")),
                            DropdownMenuItem(
                                value: "drag_drop",
                                child: Text("Drag & Drop")),
                            DropdownMenuItem(
                                value: "fill_blank",
                                child: Text("Fill in Blank")),
                          ],
                          onChanged: (v) => setState(() => tipo = v.toString()),
                        ),

                        const SizedBox(height: 12),

                        DropdownButtonFormField(
                          decoration:
                              const InputDecoration(labelText: "Dificultad"),
                          value: dificultad,
                          items: const [
                            DropdownMenuItem(
                                value: "Muy fácil",
                                child: Text("Muy fácil")),
                            DropdownMenuItem(
                                value: "Fácil", child: Text("Fácil")),
                            DropdownMenuItem(
                                value: "Medio", child: Text("Medio")),
                            DropdownMenuItem(
                                value: "Difícil", child: Text("Difícil")),
                            DropdownMenuItem(
                                value: "Muy difícil",
                                child: Text("Muy difícil")),
                          ],
                          onChanged: (v) =>
                              setState(() => dificultad = v.toString()),
                        ),
                      ],
                    ),
                  );
                },
              ),

              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(dialogCtx),
                  child: const Text("Cancelar"),
                ),
                ElevatedButton(
                  child: const Text("Editar lección"),
                  onPressed: () async {
                    if (curso == null) return;

                    final ref =
                        await _db.collection("banco_preguntas").add({
                      "cursoId": curso,
                      "enunciado": "",
                      "tipo": tipo,
                      "dificultad": dificultad,
                      "fecha_creacion": DateTime.now(),
                      "archivo_url": null,
                      "contenido": {},
                    });

                    Navigator.pop(dialogCtx);

                    Future.delayed(
                      const Duration(milliseconds: 150),
                      () => _openEditorByType(tipo, ref.id),
                    );
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }

  // ================================================================
  // EDITAR PREGUNTA EXISTENTE
  // ================================================================
  void _openEditor(DocumentSnapshot pregunta) {
    _openEditorByType(pregunta["tipo"], pregunta.id);
  }

  void _openEditorByType(String tipo, String preguntaId) {
    if (tipo == "chip_select") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ChipSelectEditor(preguntaId: preguntaId)),
      );
      return;
    }

    if (tipo == "drag_drop") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => DragDropEditor(preguntaId: preguntaId)),
      );
      return;
    }

    if (tipo == "fill_blank") {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => FillBlankEditor(preguntaId: preguntaId)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("El tipo '$tipo' aún no tiene editor.")),
    );
  }

  // ================================================================
  // ELIMINAR
  // ================================================================
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text(
            "¿Seguro que deseas eliminar esta pregunta? Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () {
              _db.collection("banco_preguntas").doc(id).delete();
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}
