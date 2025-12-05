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

  @override
  void initState() {
    super.initState();
    _load();
  }

  // ============================================================
  // CARGAR
  // ============================================================
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

      // 3 elementos por defecto, PERO VACÍOS (solo guía visual)
      if (listElements.isEmpty) {
        listElements = [
          TextEditingController(),
          TextEditingController(),
          TextEditingController(),
        ];
      }
    } catch (_) {
      // Silencioso
    }

    if (mounted) {
      setState(() => cargando = false);
    }
  }

  // ============================================================
  // GUARDAR
  // ============================================================
  Future<void> _guardar() async {
    final enunciado = enunciadoCtrl.text.trim();
    final retro = retroCtrl.text.trim();
    final elementos = listElements
        .map((c) => c.text.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (enunciado.isEmpty) {
      return _msg("El enunciado no puede estar vacío.");
    }
    if (elementos.length < 2) {
      return _msg("Agrega al menos 2 elementos válidos.");
    }
    if (retro.isEmpty) {
      return _msg("La retroalimentación es obligatoria.");
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

    _msg("Guardado correctamente ✔");

    if (mounted) {
      Future.delayed(const Duration(milliseconds: 400), () {
        Navigator.pop(context);
      });
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================
  void _msg(String t) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: Colors.grey[800],
        content: Text(t),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  // ============================================================
  // ITEM DE LA LISTA
  // ============================================================
  Widget _buildItem(int index) {
    final controller = listElements[index];

    return Container(
      key: ValueKey(controller),
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFF6F0E8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          // Handler para arrastrar (puntos a la izquierda)
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

          // Texto del elemento (GUÍA, NO TEXTO FIJO)
          Expanded(
            child: TextField(
              controller: controller,
              decoration: const InputDecoration(
                hintText: "Elemento", // ← guía, no texto que borrar
                border: InputBorder.none,
                isCollapsed: true,
              ),
            ),
          ),

          // Botón eliminar
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

  // ============================================================
  // UI
  // ============================================================
  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text(
          "Ordenar elementos",
          style: TextStyle(color: Colors.white),
        ),
        leading: const BackButton(color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: ListView(
          children: [
            // ====== ENUNCIADO (ESTILO SIMPLE CON LÍNEA) ======
            const Text("Enunciado", style: TextStyle(fontSize: 16)),
            const SizedBox(height: 6),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey),
                ),
              ),
              child: TextField(
                controller: enunciadoCtrl,
                maxLines: 2,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),

            const SizedBox(height: 20),

            const Text(
              "Elementos (arrastra para ordenar)",
              style: TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 10),

            // Lista reordenable
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

            // Botón agregar elemento (nuevo vacío)
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
                  backgroundColor: Colors.orange,
                ),
              ),
            ),

            const SizedBox(height: 24),

            // Retroalimentación (igual que te gustaba)
            Center(
              child: Text(
                "Retroalimentación:",
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.grey[800],
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Container(
              decoration: const BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: Colors.grey),
                ),
              ),
              child: TextField(
                controller: retroCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  isCollapsed: true,
                  contentPadding: EdgeInsets.symmetric(vertical: 8),
                ),
              ),
            ),

            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _guardar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
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
    );
  }
}
