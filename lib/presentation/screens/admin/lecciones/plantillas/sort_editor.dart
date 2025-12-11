import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class SortEditor extends StatefulWidget {
  final String preguntaId;

  const SortEditor({super.key, required this.preguntaId});

  @override
  State<SortEditor> createState() => _SortEditorState();
}

class _SortEditorState extends State<SortEditor> {
  final _db = FirebaseFirestore.instance;

  final enunciadoCtrl = TextEditingController();
  final retroCtrl = TextEditingController();

  List<TextEditingController> listElements = [];
  bool cargando = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final doc =
          await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

      final data = doc.data();
      enunciadoCtrl.text = data?["enunciado"] ?? "";

      final raw = data?["archivo_url"];
      if (raw != null && raw.toString().trim().isNotEmpty) {
        final jsonData = jsonDecode(raw);

        retroCtrl.text = jsonData["retroalimentacion"] ?? "";

        final elementos = (jsonData["elementos"] ?? []) as List<dynamic>;
        listElements = elementos
            .map((e) => TextEditingController(text: e.toString()))
            .toList();
      }

      if (listElements.isEmpty) {
        listElements = [
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ];
      }
    } catch (_) {
      _error = "No se pudo cargar la pregunta.";
    }

    if (mounted) {
      setState(() => cargando = false);
    }
  }

  Future<void> _guardar() async {
    final enunciado = enunciadoCtrl.text.trim();
    final retro = retroCtrl.text.trim();
    final elementos = listElements
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (enunciado.isEmpty) {
      return _msg("El enunciado no puede estar vacio.");
    }
    if (elementos.length < 2) {
      return _msg("Agrega al menos 2 elementos validos.");
    }
    if (retro.isEmpty) {
      return _msg("La retroalimentacion es obligatoria.");
    }

    final jsonData = {
      "tipo": "ordenar",
      "elementos": elementos,
      "retroalimentacion": retro,
    };

    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "enunciado": enunciado,
      "archivo_url": jsonEncode(jsonData),
    });

    if (!mounted) return;
    _msg("Guardado correctamente");

    Future.delayed(const Duration(milliseconds: 400), () {
      if (mounted) Navigator.pop(context);
    });
  }

  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey[850],
        content: Text(t),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildItem(int index) {
    final controller = listElements[index];

    return Container(
      key: ValueKey(controller),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          MouseRegion(
            cursor: SystemMouseCursors.click,
            child: ReorderableDragStartListener(
              index: index,
              child: const Icon(
                Icons.drag_indicator,
                color: Colors.black54,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Elemento",
                border: InputBorder.none,
                isCollapsed: true,
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete, color: Colors.red),
            onPressed: () {
              setState(() {
                if (listElements.length > 1) {
                  listElements.removeAt(index);
                }
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.black.withOpacity(0.65),
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D2034),
        title: const Text(
          "Ordenar elementos",
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_error != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.red.shade300),
                    ),
                    child: Text(
                      _error!,
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                _sectionCard(
                  title: "Enunciado",
                  subtitle: "Define la instruccion para ordenar.",
                  child: TextField(
                    controller: enunciadoCtrl,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: "Ej: Ordena los pasos del algoritmo...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: "Elementos",
                  subtitle: "Arrastra para reordenar y agrega los que necesites.",
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ReorderableListView(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        onReorder: (oldIndex, newIndex) {
                          setState(() {
                            if (newIndex > oldIndex) newIndex--;
                            final item = listElements.removeAt(oldIndex);
                            listElements.insert(newIndex, item);
                          });
                        },
                        children: [
                          for (int i = 0; i < listElements.length; i++) _buildItem(i),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              listElements.add(TextEditingController());
                            });
                          },
                          icon: const Icon(Icons.add, color: Colors.white),
                          label: const Text(
                            "Agregar elemento",
                            style: TextStyle(color: Colors.white),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA200),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _sectionCard(
                  title: "Retroalimentacion",
                  subtitle: "Mensaje que veran al finalizar.",
                  child: TextField(
                    controller: retroCtrl,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      hintText: "Ej: Revisa el orden de las etapas...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA200),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                    ),
                    child: const Text(
                      "Guardar",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
