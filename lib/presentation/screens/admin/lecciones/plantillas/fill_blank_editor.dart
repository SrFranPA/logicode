import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class FillBlankEditor extends StatefulWidget {
  final String preguntaId;

  const FillBlankEditor({super.key, required this.preguntaId});

  @override
  State<FillBlankEditor> createState() => _FillBlankEditorState();
}

class _FillBlankEditorState extends State<FillBlankEditor> {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final _enunciadoCtrl = TextEditingController();
  final List<TextEditingController> _blanks = [];

  final feedbackCorrectoCtrl = TextEditingController();
  final feedbackIncorrectoCtrl = TextEditingController();

  File? imagenPrincipal;
  String? urlImagenPrincipal;

  bool loading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final doc = await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

    if (doc.exists) {
      final data = doc.data()!;
      _enunciadoCtrl.text = data["enunciado"] ?? "";

      if (data["contenido"] != null) {
        final contenido = data["contenido"];

        urlImagenPrincipal = contenido["imagen_pregunta"];

        final blanksList = List<String>.from(contenido["blanks"] ?? []);
        for (final word in blanksList) {
          _blanks.add(TextEditingController(text: word));
        }

        feedbackCorrectoCtrl.text = contenido["feedback_correcto"] ?? "";
        feedbackIncorrectoCtrl.text = contenido["feedback_incorrecto"] ?? "";
      } else if (data["blanks"] != null) {
        for (final word in List<String>.from(data["blanks"])) {
          _blanks.add(TextEditingController(text: word));
        }
      }
    }

    if (_blanks.isEmpty) {
      _blanks.add(TextEditingController());
    }

    setState(() => loading = false);
  }

  Future<String?> _subirImagen(File file, String nombre) async {
    final ref = _storage.ref().child("preguntas/${widget.preguntaId}/$nombre");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imagenPrincipal = File(picked.path);
      });
    }
  }

  Future<void> _save() async {
    if (_enunciadoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El enunciado no puede estar vacío")),
      );
      return;
    }

    final blanksValues = _blanks.map((e) => e.text.trim()).where((e) => e.isNotEmpty).toList();
    if (blanksValues.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes agregar al menos una palabra correcta")),
      );
      return;
    }

    String? imagenUrl = urlImagenPrincipal;
    if (imagenPrincipal != null) {
      imagenUrl = await _subirImagen(imagenPrincipal!, "imagen_pregunta.png");
    }

    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "enunciado": _enunciadoCtrl.text.trim(),
      "contenido": {
        "imagen_pregunta": imagenUrl,
        "blanks": blanksValues,
        "feedback_correcto": feedbackCorrectoCtrl.text.trim(),
        "feedback_incorrecto": feedbackIncorrectoCtrl.text.trim(),
      },
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
                  const Text(
                    "Enunciado con __ espacios a completar:",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _enunciadoCtrl,
                    decoration: const InputDecoration(
                      hintText: "Ej: El perro __ en el parque.",
                    ),
                  ),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        "Imagen principal:",
                        style: TextStyle(fontSize: 16),
                      ),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                        onPressed: _seleccionarImagen,
                        child: const Text("Subir imagen"),
                      )
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (urlImagenPrincipal != null)
                    Image.network(urlImagenPrincipal!, height: 120),
                  if (imagenPrincipal != null)
                    Image.file(imagenPrincipal!, height: 120),

                  const SizedBox(height: 20),
                  Row(
                    children: [
                      const Text(
                        "Palabras correctas:",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                      ),
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
                  const Text(
                    "Retroalimentación correcta",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: feedbackCorrectoCtrl,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 12),
                  const Text(
                    "Retroalimentación incorrecta",
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: feedbackIncorrectoCtrl,
                    maxLines: 2,
                  ),

                  const SizedBox(height: 16),
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
