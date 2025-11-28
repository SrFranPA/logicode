// lib/presentation/screens/admin/lecciones/plantillas/fill_blank_editor.dart

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FillBlankEditor extends StatefulWidget {
  final String preguntaId;

  const FillBlankEditor({super.key, required this.preguntaId});

  @override
  State<FillBlankEditor> createState() => _FillBlankEditorState();
}

class _FillBlankEditorState extends State<FillBlankEditor> {
  final _db = FirebaseFirestore.instance;

  final _enunciadoCtrl = TextEditingController();
  final List<TextEditingController> _blanks = [];

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------------
  // Cargar datos existentes de la pregunta
  // ---------------------------------------------------------------
  Future<void> _loadData() async {
    final doc = await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

    if (doc.exists) {
      final data = doc.data()!;
      _enunciadoCtrl.text = data["enunciado"] ?? "";

      if (data["blanks"] != null) {
        for (final word in List<String>.from(data["blanks"])) {
          final ctrl = TextEditingController(text: word);
          _blanks.add(ctrl);
        }
      }
    }

    setState(() => loading = false);
  }

  // ---------------------------------------------------------------
  // Guardar cambios
  // ---------------------------------------------------------------
  Future<void> _save() async {
    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "enunciado": _enunciadoCtrl.text.trim(),
      "blanks": _blanks.map((e) => e.text.trim()).toList(),
      "fecha_edicion": DateTime.now(),
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Guardado ✔")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EFFA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Editor: Fill Blank", style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),

      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Enunciado con __ espacios a completar:",
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                  TextField(
                    controller: _enunciadoCtrl,
                    decoration: const InputDecoration(hintText: "Ej: El perro __ en el parque."),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text("Palabras correctas:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: () {
                          setState(() => _blanks.add(TextEditingController()));
                        },
                        child: const Text("Agregar palabra"),
                      )
                    ],
                  ),

                  const SizedBox(height: 12),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _blanks.length,
                      itemBuilder: (_, i) {
                        return Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _blanks[i],
                                decoration: InputDecoration(
                                  labelText: "Palabra ${i + 1}",
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red),
                              onPressed: () {
                                setState(() => _blanks.removeAt(i));
                              },
                            )
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 10),
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 14),
                      ),
                      onPressed: _save,
                      child: const Text("Guardar", style: TextStyle(fontSize: 18)),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
