import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

// IMPORTAMOS EL EDITOR
import 'plantillas/chip_select_editor.dart';

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
        title: const Text("Banco de preguntas", style: TextStyle(color: Colors.white)),
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
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    "Curso: ${p["cursoId"]}\nDificultad: ${p["dificultad"]}\nTipo: ${p["tipo"]}",
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _openEditor(p),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
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

  // ───────────────────────────────────────────────────────────────
  // Crear Pregunta
  // ───────────────────────────────────────────────────────────────
  void _openCreateDialog() {
    String tipoSeleccionado = "chip_select";
    String dificultad = "Muy fácil";

    String? cursoSeleccionado;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
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

            return StatefulBuilder(
              builder: (context, setState) {
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
                        onChanged: (value) {
                          setState(() {
                            cursoSeleccionado = value.toString();
                          });
                        },
                      ),

                      const SizedBox(height: 12),
                      DropdownButtonFormField(
                        decoration: const InputDecoration(labelText: "Tipo de pregunta"),
                        value: tipoSeleccionado,
                        items: const [
                          DropdownMenuItem(value: "chip_select", child: Text("Chip Select")),
                          DropdownMenuItem(value: "drag_drop", child: Text("Drag & Drop")),
                          DropdownMenuItem(value: "fill_blank", child: Text("Fill in Blank")),
                          DropdownMenuItem(value: "tabla", child: Text("Tabla")),
                          DropdownMenuItem(value: "visual_logic", child: Text("Lógica Visual")),
                        ],
                        onChanged: (value) {
                          setState(() => tipoSeleccionado = value.toString());
                        },
                      ),

                      const SizedBox(height: 12),
                      DropdownButtonFormField(
                        decoration: const InputDecoration(labelText: "Dificultad"),
                        value: dificultad,
                        items: const [
                          DropdownMenuItem(value: "Muy fácil", child: Text("Muy fácil")),
                          DropdownMenuItem(value: "Fácil", child: Text("Fácil")),
                          DropdownMenuItem(value: "Medio", child: Text("Medio")),
                          DropdownMenuItem(value: "Difícil", child: Text("Difícil")),
                          DropdownMenuItem(value: "Muy difícil", child: Text("Muy difícil")),
                        ],
                        onChanged: (value) {
                          setState(() => dificultad = value.toString());
                        },
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (cursoSeleccionado == null) return;

              // Crear el doc
              final docRef = await _db.collection("banco_preguntas").add({
                "cursoId": cursoSeleccionado,
                "enunciado": "",
                "tipo": tipoSeleccionado,
                "dificultad": dificultad,
                "fecha_creacion": DateTime.now(),
                "archivo_url": null,
                "contenido": {},
              });

              Navigator.pop(context);

              // Abrir editor correspondiente
              _openEditorByType(tipoSeleccionado, docRef.id);
            },
            child: const Text("Editar lección"),
          ),
        ],
      ),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Abrir editor según tipo
  // ───────────────────────────────────────────────────────────────
  void _openEditor(DocumentSnapshot pregunta) {
    _openEditorByType(pregunta["tipo"], pregunta.id);
  }

  void _openEditorByType(String tipo, String preguntaId) {
    if (tipo == "chip_select") {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ChipSelectEditor(preguntaId: preguntaId),
        ),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("El tipo '$tipo' aún no tiene editor.")),
    );
  }

  // ───────────────────────────────────────────────────────────────
  // Confirmar eliminación
  // ───────────────────────────────────────────────────────────────
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
