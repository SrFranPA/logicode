import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminCursosScreen extends StatefulWidget {
  const AdminCursosScreen({super.key});

  @override
  State<AdminCursosScreen> createState() => _AdminCursosScreenState();
}

class _AdminCursosScreenState extends State<AdminCursosScreen> {
  final _db = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),

      appBar: AppBar(
        title: const Text(
          "Gestión de cursos",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: Colors.orange,
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: _openCreateDialog,
      ),

      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection("cursos").orderBy("orden").snapshots(),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text("Error al cargar cursos"));
          }

          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final cursos = snapshot.data!.docs;

          if (cursos.isEmpty) {
            return const Center(child: Text("No existen cursos aún"));
          }

          return ListView.builder(
            itemCount: cursos.length,
            itemBuilder: (_, i) {
              final curso = cursos[i];

              return Card(
                margin: const EdgeInsets.all(12),
                color: const Color(0xFFFFF7FB),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        curso["nombre"],
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 4),

                      Text(
                        "Orden: ${curso["orden"]}",
                        style: const TextStyle(color: Colors.black54),
                      ),

                      const SizedBox(height: 6),

                      Text(
                        curso["descripcion"] ?? "",
                        style: const TextStyle(fontSize: 15),
                      ),

                      const SizedBox(height: 10),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.edit, color: Colors.blue),
                            onPressed: () => _openEditDialog(curso),
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _confirmDelete(curso.id),
                          ),
                        ],
                      )
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

  // -------------------------------------------------------------------
  // CREAR CURSO
  // -------------------------------------------------------------------
  void _openCreateDialog() {
    final idCtrl = TextEditingController();
    final nameCtrl = TextEditingController();
    final orderCtrl = TextEditingController();
    final descCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Crear curso"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(labelText: "ID del curso (ej: desc_prob)"),
              ),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: orderCtrl,
                decoration: const InputDecoration(labelText: "Orden"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descCtrl,
                maxLines: 3,
                decoration: const InputDecoration(labelText: "Descripción"),
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final id = idCtrl.text.trim();
              final nombre = nameCtrl.text.trim();
              final descripcion = descCtrl.text.trim();
              final orden = int.tryParse(orderCtrl.text) ?? -1;

              // Validación real
              if (id.isEmpty || nombre.isEmpty || orden < 0) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Llena todos los campos correctamente")),
                );
                return;
              }

              await _db.collection("cursos").doc(id).set({
                "nombre": nombre,
                "orden": orden,
                "descripcion": descripcion,
              });

              Navigator.pop(context);
            },
            child: const Text("Guardar"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // EDITAR
  // -------------------------------------------------------------------
  void _openEditDialog(DocumentSnapshot curso) {
    final nameCtrl = TextEditingController(text: curso["nombre"]);
    final orderCtrl = TextEditingController(text: curso["orden"].toString());
    final descCtrl = TextEditingController(text: curso["descripcion"]);

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Editar curso"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: "Nombre"),
              ),
              TextField(
                controller: orderCtrl,
                decoration: const InputDecoration(labelText: "Orden"),
                keyboardType: TextInputType.number,
              ),
              TextField(
                controller: descCtrl,
                decoration: const InputDecoration(labelText: "Descripción"),
                maxLines: 3,
              ),
            ],
          ),
        ),

        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              final nombre = nameCtrl.text.trim();
              final descripcion = descCtrl.text.trim();
              final orden = int.tryParse(orderCtrl.text) ?? -1;

              if (nombre.isEmpty || orden < 0) return;

              await _db.collection("cursos").doc(curso.id).update({
                "nombre": nombre,
                "orden": orden,
                "descripcion": descripcion,
              });

              Navigator.pop(context);
            },
            child: const Text("Guardar cambios"),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------------
  // ELIMINAR
  // -------------------------------------------------------------------
  void _confirmDelete(String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("¿Eliminar curso?"),
        content: const Text("Esta acción no se puede deshacer."),
        actions: [
          TextButton(
            child: const Text("Cancelar"),
            onPressed: () => Navigator.pop(context),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text("Eliminar"),
            onPressed: () {
              _db.collection("cursos").doc(id).delete();
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
