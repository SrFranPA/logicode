// lib/presentation/screens/admin/lecciones/admin_lecciones_screen.dart

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/admin_preguntas/admin_preguntas_cubit.dart';
import '../../../../blocs/admin_preguntas/admin_preguntas_state.dart';
import 'plantillas/chip_select_editor.dart';
import 'plantillas/fill_blank_editor.dart';
import 'plantillas/sort_editor.dart';

String _sanitizeJson(String input) {
  return input.replaceAll(RegExp(r'^\s*//.*$', multiLine: true), '');
}

class AdminLeccionesScreen extends StatefulWidget {
  final ValueNotifier<int?>? lessonCountNotifier;
  const AdminLeccionesScreen({super.key, this.lessonCountNotifier});

  @override
  State<AdminLeccionesScreen> createState() => _AdminLeccionesScreenState();
}

class _AdminLeccionesScreenState extends State<AdminLeccionesScreen> {
  String filtroTexto = "";
  String filtroCurso = "Todos";
  String filtroDificultad = "Todos";
  String filtroTipo = "Todos";

  String _norm(String input) {
    const map = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'Á': 'a',
      'É': 'e',
      'Í': 'i',
      'Ó': 'o',
      'Ú': 'u',
    };
    final buffer = StringBuffer();
    for (final ch in input.split('')) {
      buffer.write(map[ch] ?? ch.toLowerCase());
    }
    return buffer.toString();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
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
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: BlocBuilder<AdminPreguntasCubit, AdminPreguntasState>(
          builder: (_, state) {
            if (state is AdminPreguntasLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            if (state is AdminPreguntasLoaded) {
              final preguntas = state.preguntas;

              if (preguntas.isEmpty) {
                widget.lessonCountNotifier?.value = 0;
                return const Center(child: Text("Aun no existen preguntas"));
              }

              final cursosDisponibles =
                  preguntas.map((p) => p.cursoId).toSet().toList()..sort();

              final filtradas = preguntas.where((p) {
                final t = _norm(filtroTexto);
                final matchTexto =
                    t.isEmpty || _norm(p.enunciado).contains(t);
                final matchCurso =
                    filtroCurso == "Todos" || filtroCurso == p.cursoId;
                final matchDif =
                    filtroDificultad == "Todos" ||
                        _norm(filtroDificultad) ==
                            _norm((p.dificultad ?? "").toString());
                final matchTipo =
                    filtroTipo == "Todos" || filtroTipo == p.tipo;

                return matchTexto && matchCurso && matchDif && matchTipo;
              }).toList();

              final totalFiltradas = filtradas.length;
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (widget.lessonCountNotifier?.value != totalFiltradas) {
                  widget.lessonCountNotifier?.value = totalFiltradas;
                }
              });

              return ListView(
                padding: const EdgeInsets.fromLTRB(12, 14, 12, 100),
                children: [
                  _barraFiltros(cursosDisponibles),
                  const SizedBox(height: 12),
                  if (filtradas.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(22),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 12,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Center(
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
      ),
    );
  }

  Widget _barraFiltros(List<String> cursos) {
    const difOptions = [
      "Todos",
      "Muy facil",
      "Facil",
      "Medio",
      "Dificil",
      "Muy dificil",
    ];

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
            children: [
              Expanded(
                child: DropdownButtonFormField(
                  value: filtroCurso,
                  decoration: const InputDecoration(labelText: "Curso"),
                  items: ["Todos", ...cursos]
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) => setState(() => filtroCurso = v!),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DropdownButtonFormField(
                  value: filtroDificultad,
                  decoration: const InputDecoration(labelText: "Dificultad"),
                  items: difOptions
                      .map((d) => DropdownMenuItem(value: d, child: Text(d)))
                      .toList(),
                  onChanged: (v) => setState(() => filtroDificultad = v!),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
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
              const SizedBox(width: 10),
              Expanded(
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

  Widget _itemPregunta(p) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFA200),
                ),
                child: const Icon(Icons.help_outline, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.enunciado,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        _chip("Curso: ${p.cursoId}", const Color(0xFFFFE4B8)),
                        _chip("Tipo: ${p.tipo}", const Color(0xFFE9ECF3)),
                        _chip("Dificultad: ${p.dificultad}",
                            _difficultyColor(p.dificultad)),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _circleBtn(
                icon: Icons.edit,
                color: const Color(0xFF6A7FDB),
                onTap: () {
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
              const SizedBox(width: 10),
              _circleBtn(
                icon: Icons.delete,
                color: const Color(0xFFE57373),
                onTap: () => _confirmDelete(context, p.id),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Color _difficultyColor(String? dif) {
    switch (dif?.toLowerCase()) {
      case "muy facil":
      case "muy fácil":
        return const Color(0xFFE8F9E5);
      case "facil":
      case "fácil":
        return const Color(0xFFEAF4FF);
      case "medio":
        return const Color(0xFFFFF3E0);
      case "dificil":
      case "difícil":
        return const Color(0xFFFFE6E6);
      case "muy dificil":
      case "muy difícil":
        return const Color(0xFFF9D7D7);
      default:
        return const Color(0xFFF2F4F8);
    }
  }

  Widget _circleBtn(
      {required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 36,
        width: 36,
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }

  Future<void> _importFromJson(BuildContext context) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['json'],
        withData: true,
      );

      if (result == null) return;
      final file = result.files.single;
      if (file.bytes == null) throw Exception("Archivo vacio");

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
          content: Text("Importacion completa. Exitos: $exitos  Fallos: $fallos"),
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

  void _openCreateDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (dialogCtx) {
        String tipo = "seleccion_chips";
        String dificultad = "Muy facil";
        String? curso;

        final db = FirebaseFirestore.instance;

        return AlertDialog(
          title: const Text("Crear nueva pregunta"),
          content: FutureBuilder<QuerySnapshot>(
            future: db.collection("cursos").orderBy("orden").get(),
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
                            child: Text("Seleccion unica (chips)")),
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
                        DropdownMenuItem(value: "Muy facil", child: Text("Muy facil")),
                        DropdownMenuItem(value: "Facil", child: Text("Facil")),
                        DropdownMenuItem(value: "Medio", child: Text("Medio")),
                        DropdownMenuItem(value: "Dificil", child: Text("Dificil")),
                        DropdownMenuItem(value: "Muy dificil", child: Text("Muy dificil")),
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
                          builder: (_) => ChipSelectEditor(preguntaId: id),
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
                          builder: (_) => FillBlankEditor(preguntaId: id),
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

  void _confirmDelete(BuildContext context, String id) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Confirmar eliminacion"),
        content: const Text("Seguro que deseas eliminar esta pregunta?"),
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
