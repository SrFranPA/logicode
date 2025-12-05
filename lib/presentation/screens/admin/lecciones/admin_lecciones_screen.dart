import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../../../../blocs/admin_preguntas/admin_preguntas_cubit.dart';
import '../../../../blocs/admin_preguntas/admin_preguntas_state.dart';

import 'plantillas/chip_select_editor.dart';
import 'plantillas/sort_editor.dart';

class AdminLeccionesScreen extends StatelessWidget {
  const AdminLeccionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),

      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          "Banco de preguntas",
          style: TextStyle(color: Colors.white),
        ),
      ),

      floatingActionButton: FloatingActionButton(
        backgroundColor: Colors.orange,
        child: const Icon(Icons.add),
        onPressed: () => _openCreateDialog(context),
      ),

      body: BlocBuilder<AdminPreguntasCubit, AdminPreguntasState>(
        builder: (_, state) {
          if (state is AdminPreguntasLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminPreguntasLoaded) {
            final preguntas = state.preguntas;

            if (preguntas.isEmpty) {
              return const Center(child: Text("Aún no existen preguntas"));
            }

            return ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: preguntas.length,
              itemBuilder: (_, i) {
                final p = preguntas[i];

                return Card(
                  child: ListTile(
                    title: Text(
                      p.enunciado.isEmpty ? "(sin enunciado)" : p.enunciado,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: Text(
                      "Curso: ${p.cursoId}\n"
                      "Tipo: ${p.tipo}\n"
                      "Dificultad: ${p.dificultad}",
                    ),

                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: Colors.blue),
                          onPressed: () {
                            if (p.tipo == "seleccion_chips") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ChipSelectEditor(
                                    preguntaId: p.id,
                                  ),
                                ),
                              );
                            }

                            if (p.tipo == "ordenar") {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => SortEditor(
                                    preguntaId: p.id,
                                  ),
                                ),
                              );
                            }
                          },
                        ),

                        IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _confirmDelete(context, p.id),
                        ),
                      ],
                    ),
                  ),
                );
              },
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // ============================================================
  // CREAR NUEVA PREGUNTA
  // ============================================================

  void _openCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        String tipo = "seleccion_chips";
        String dificultad = "Muy fácil";
        String? curso;

        final _db = FirebaseFirestore.instance;

        return AlertDialog(
          title: const Text("Crear nueva pregunta"),

          content: FutureBuilder<QuerySnapshot>(
            future: _db.collection("cursos").orderBy("orden").get(),
            builder: (_, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cursos = snap.data!.docs;

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
                      onChanged: (v) => curso = v,
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField(
                      value: tipo,
                      decoration: const InputDecoration(labelText: "Tipo de pregunta"),
                      items: const [
                        DropdownMenuItem(
                          value: "seleccion_chips",
                          child: Text("Selección única"),
                        ),
                        DropdownMenuItem(
                          value: "ordenar",
                          child: Text("Ordenar elementos"),
                        ),
                      ],
                      onChanged: (v) => tipo = v.toString(),
                    ),

                    const SizedBox(height: 12),

                    DropdownButtonFormField(
                      value: dificultad,
                      decoration: const InputDecoration(labelText: "Dificultad"),
                      items: const [
                        DropdownMenuItem(value: "Muy fácil", child: Text("Muy fácil")),
                        DropdownMenuItem(value: "Fácil", child: Text("Fácil")),
                        DropdownMenuItem(value: "Medio", child: Text("Medio")),
                        DropdownMenuItem(value: "Difícil", child: Text("Difícil")),
                        DropdownMenuItem(value: "Muy difícil", child: Text("Muy difícil")),
                      ],
                      onChanged: (v) => dificultad = v.toString(),
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
              onPressed: () async {
                if (curso == null) return;

                final cubit = context.read<AdminPreguntasCubit>();

                final id = await cubit.crearPregunta(
                  cursoId: curso!,
                  tipo: tipo,
                  dificultad: dificultad,
                );

                if (id == null) return;

                Navigator.pop(dialogCtx);

                Future.delayed(const Duration(milliseconds: 150), () {
                  if (tipo == "seleccion_chips") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChipSelectEditor(preguntaId: id),
                      ),
                    );
                  }

                  if (tipo == "ordenar") {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SortEditor(preguntaId: id),
                      ),
                    );
                  }
                });
              },
              child: const Text("Crear y editar"),
            ),
          ],
        );
      },
    );
  }

  // ============================================================
  // ELIMINAR
  // ============================================================

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content: const Text("¿Seguro que deseas eliminar esta pregunta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),

          ElevatedButton(
            onPressed: () async {
              await context.read<AdminPreguntasCubit>().eliminarPregunta(id);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}
