// lib/presentation/screens/admin/lecciones/admin_lecciones_screen.dart

import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/admin_preguntas/admin_preguntas_cubit.dart';
import '../../../../blocs/admin_preguntas/admin_preguntas_state.dart';

import 'plantillas/chip_select_editor.dart';
import 'plantillas/sort_editor.dart';
import 'plantillas/fill_blank_editor.dart';

/// Limpia JSON quitando comentarios //
String _sanitizeJson(String input) {
  return input.replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
}

class AdminLeccionesScreen extends StatefulWidget {
  const AdminLeccionesScreen({super.key});

  @override
  State<AdminLeccionesScreen> createState() => _AdminLeccionesScreenState();
}

class _AdminLeccionesScreenState extends State<AdminLeccionesScreen> {
  // 🔎 VARIABLES DE FILTRO
  String filtroTexto = "";
  String filtroCurso = "Todos";
  String filtroDificultad = "Todos";
  String filtroTipo = "Todos";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),

      // ⭐ FAB EXACTAMENTE COMO EN CURSOS
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFFA200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          onPressed: () => _openCreateDialog(context),
          child: const Icon(Icons.add, size: 30, color: Colors.white),
        ),
      ),

      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          "Banco de preguntas",
          style: TextStyle(color: Colors.white),
        ),
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

            // Extraer cursos disponibles
            final cursosDisponibles =
                preguntas.map((p) => p.cursoId).toSet().toList()..sort();

            // APLICAR FILTROS
            final filtradas = preguntas.where((p) {
              final t = filtroTexto.toLowerCase();

              final matchTexto =
                  t.isEmpty || p.enunciado.toLowerCase().contains(t);

              final matchCurso =
                  filtroCurso == "Todos" || filtroCurso == p.cursoId;

              final matchDif =
                  filtroDificultad == "Todos" || filtroDificultad == p.dificultad;

              final matchTipo =
                  filtroTipo == "Todos" || filtroTipo == p.tipo;

              return matchTexto && matchCurso && matchDif && matchTipo;
            }).toList();

            return ListView(
              padding: const EdgeInsets.only(bottom: 100),
              children: [
                const SizedBox(height: 10),

                // ⭐⭐ NUEVA BARRA DE FILTROS (ESTILO B)
                _barraFiltros(cursosDisponibles),

                const SizedBox(height: 10),

                if (filtradas.isEmpty)
                  const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(
                      child: Text("No hay resultados con los filtros aplicados"),
                    ),
                  ),

                ...filtradas.map(_itemPregunta),
              ],
            );
          }

          return const SizedBox.shrink();
        },
      ),
    );
  }

  // =======================================================
  // ⭐ WIDGET DE LA BARRA DE FILTROS (ESTILO TARJETA BONITA)
  // =======================================================
  Widget _barraFiltros(List<String> cursos) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF8E7),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 8,
            offset: const Offset(0, 3),
          )
        ],
      ),

      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // === FILA SUPERIOR: CURSO + DIFICULTAD + TIPO
          Row(
            children: [
              // CURSO
              Expanded(
                child: DropdownButtonFormField(
                  value: filtroCurso,
                  decoration:
                      const InputDecoration(labelText: "Curso"),
                  items: ["Todos", ...cursos]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => filtroCurso = v!),
                ),
              ),
              const SizedBox(width: 8),

              // DIFICULTAD
              Expanded(
                child: DropdownButtonFormField(
                  value: filtroDificultad,
                  decoration:
                      const InputDecoration(labelText: "Dificultad"),
                  items: [
                    "Todos",
                    "Muy fácil",
                    "Fácil",
                    "Medio",
                    "Difícil",
                    "Muy difícil"
                  ].map((d) => DropdownMenuItem(value: d, child: Text(d))).toList(),
                  onChanged: (v) => setState(() => filtroDificultad = v!),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // === FILA INFERIOR: TIPO + BUSCADOR
          Row(
            children: [
              Expanded(
                flex: 1,
                child: DropdownButtonFormField(
                  value: filtroTipo,
                  decoration: const InputDecoration(labelText: "Tipo"),
                  items: const [
                    "Todos",
                    "seleccion_chips",
                    "ordenar",
                    "completa_espacio",
                  ].map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                  onChanged: (v) => setState(() => filtroTipo = v!),
                ),
              ),

              const SizedBox(width: 12),

              // 🔍 BUSCADOR GRANDE DERECHA
              Expanded(
                flex: 2,
                child: TextField(
                  decoration: InputDecoration(
                    labelText: "Buscar enunciado...",
                    suffixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onChanged: (v) => setState(() => filtroTexto = v),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // =======================================================
  // ITEM DE LA LISTA
  // =======================================================
  Widget _itemPregunta(p) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        title: Text(
          p.enunciado,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
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
                switch (p.tipo) {
                  case "seleccion_chips":
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ChipSelectEditor(preguntaId: p.id),
                      ),
                    );
                    break;

                  case "ordenar":
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => SortEditor(preguntaId: p.id),
                      ),
                    );
                    break;

                  case "completa_espacio":
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => FillBlankEditor(preguntaId: p.id),
                      ),
                    );
                    break;
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
  }

  // =======================================================
  // IMPORTAR JSON
  // =======================================================
  Future<void> _importFromJson(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null) return;
      final file = result.files.single;
      if (file.bytes == null) throw Exception("Archivo vacío");

      final cleaned = _sanitizeJson(utf8.decode(file.bytes!));
      dynamic parsed = jsonDecode(cleaned);

      if (parsed is! List) {
        throw Exception("El archivo debe ser una LISTA de preguntas.");
      }

      final col = FirebaseFirestore.instance.collection("banco_preguntas");

      int exitos = 0;
      int fallos = 0;

      for (final item in parsed) {
        if (item is! Map<String, dynamic>) {
          fallos++;
          continue;
        }

        final p = item;

        const required = [
          "cursoId",
          "dificultad",
          "enunciado",
          "tipo",
          "archivo_url",
        ];

        final faltantes = required.where((f) => !p.containsKey(f));
        if (faltantes.isNotEmpty) {
          fallos++;
          _mostrarErrorPregunta(
            context,
            p,
            "Faltan campos: ${faltantes.join(', ')}",
          );
          continue;
        }

        try {
          await col.add({
            "cursoId": p["cursoId"],
            "dificultad": p["dificultad"],
            "enunciado": p["enunciado"],
            "tipo": p["tipo"],
            "fecha_creacion": DateTime.now(),
            "archivo_url": p["archivo_url"],
          });
          exitos++;
        } catch (e) {
          fallos++;
          _mostrarErrorPregunta(context, p, "Error al guardar: $e");
        }
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Importación completa ✔  Éxitos: $exitos  Fallos: $fallos"),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error al importar: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  // =======================================================
  // ERROR INDIVIDUAL
  // =======================================================
  void _mostrarErrorPregunta(
      BuildContext context, Map pregunta, String mensaje) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Error en una pregunta"),
        content: SizedBox(
          height: 220,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(mensaje, style: const TextStyle(color: Colors.red)),
                const SizedBox(height: 12),
                const Text("Pregunta:",
                    style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text(
                  const JsonEncoder.withIndent('  ').convert(pregunta),
                  style: const TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cerrar"),
          )
        ],
      ),
    );
  }

  // =======================================================
  // CREAR PREGUNTA
  // =======================================================
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
                      items: cursos
                          .map((c) => DropdownMenuItem(
                                value: c.id,
                                child: Text(c["nombre"]),
                              ))
                          .toList(),
                      onChanged: (v) => curso = v,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(
                      value: tipo,
                      decoration:
                          const InputDecoration(labelText: "Tipo de pregunta"),
                      items: const [
                        DropdownMenuItem(
                            value: "seleccion_chips",
                            child: Text("Selección única (chips)")),
                        DropdownMenuItem(
                            value: "ordenar", child: Text("Ordenar elementos")),
                        DropdownMenuItem(
                            value: "completa_espacio",
                            child: Text("Completar espacio")),
                      ],
                      onChanged: (v) => tipo = v.toString(),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField(
                      value: dificultad,
                      decoration:
                          const InputDecoration(labelText: "Dificultad"),
                      items: const [
                        DropdownMenuItem(
                            value: "Muy fácil", child: Text("Muy fácil")),
                        DropdownMenuItem(value: "Fácil", child: Text("Fácil")),
                        DropdownMenuItem(value: "Medio", child: Text("Medio")),
                        DropdownMenuItem(
                            value: "Difícil", child: Text("Difícil")),
                        DropdownMenuItem(
                            value: "Muy difícil", child: Text("Muy difícil")),
                      ],
                      onChanged: (v) => dificultad = v.toString(),
                    ),
                    const Divider(height: 24),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () {
                          Navigator.pop(dialogCtx);
                          _importFromJson(context);
                        },
                        icon: const Icon(Icons.file_upload),
                        label: const Text("Importar archivo JSON"),
                      ),
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
                  switch (tipo) {
                    case "seleccion_chips":
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              ChipSelectEditor(preguntaId: id),
                        ),
                      );
                      break;

                    case "ordenar":
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SortEditor(preguntaId: id),
                        ),
                      );
                      break;

                    case "completa_espacio":
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) =>
                              FillBlankEditor(preguntaId: id),
                        ),
                      );
                      break;
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

  // =======================================================
  // ELIMINAR
  // =======================================================
  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminación"),
        content:
            const Text("¿Seguro que deseas eliminar esta pregunta?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              await context
                  .read<AdminPreguntasCubit>()
                  .eliminarPregunta(id);
              Navigator.pop(context);
            },
            child: const Text("Eliminar"),
          ),
        ],
      ),
    );
  }
}
