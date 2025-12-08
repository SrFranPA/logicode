import 'dart:convert';
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

  final retroCtrl = TextEditingController(); // Único campo de retroalimentación

  bool loading = true;
  int _cantidadEspacios = 0;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  // ---------------------------------------------------------
  // CARGAR DATOS DESDE Firestore
  // ---------------------------------------------------------
  Future<void> _loadData() async {
    final doc = await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

    if (doc.exists) {
      final data = doc.data()!;
      _enunciadoCtrl.text = data["enunciado"] ?? "";

      final rawJson = data["archivo_url"];

      if (rawJson != null && rawJson.toString().trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);

        final blanksList = List<String>.from(decoded["blanks"] ?? []);
        for (final word in blanksList) {
          _blanks.add(TextEditingController(text: word));
        }

        retroCtrl.text = decoded["retroalimentacion"] ?? "";
      }
    }

    _detectarEspacios();

    setState(() => loading = false);
  }

  // ---------------------------------------------------------
  // DETECTAR "__" EN EL ENUNCIADO
  // ---------------------------------------------------------
  void _detectarEspacios() {
    final matches = RegExp(r'__+').allMatches(_enunciadoCtrl.text);
    final cantidad = matches.length;
    _cantidadEspacios = cantidad;

    // Ajustar lista de blanks
    if (_blanks.length < cantidad) {
      for (int i = 0; i < (cantidad - _blanks.length); i++) {
        _blanks.add(TextEditingController());
      }
    } else if (_blanks.length > cantidad) {
      _blanks.removeRange(cantidad, _blanks.length);
    }

    setState(() {});
  }

  // ---------------------------------------------------------
  // GUARDAR EN Firestore
  // ---------------------------------------------------------
  Future<void> _save() async {
    final enunciado = _enunciadoCtrl.text.trim();
    final retro = retroCtrl.text.trim();

    // ------------ VALIDACIONES ------------
    if (enunciado.isEmpty) {
      return _error("El enunciado no puede estar vacío.");
    }

    if (_cantidadEspacios == 0) {
      return _error("Debes incluir al menos un espacio '__' en el enunciado.");
    }

    final blanksValues =
        _blanks.map((c) => c.text.trim()).where((c) => c.isNotEmpty).toList();

    if (blanksValues.length != _cantidadEspacios) {
      return _error(
        "Debes completar las ${_cantidadEspacios} palabras correspondientes a los espacios.",
      );
    }

    if (retro.isEmpty) {
      return _error("La retroalimentación no puede estar vacía.");
    }

    // ------------ JSON EXACTO SEGÚN TU MODELO ------------
    final jsonData = {
      "tipo": "completa_espacio",
      "blanks": blanksValues,
      "retroalimentacion": retro,
    };

    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "tipo": "completa_espacio",
      "enunciado": enunciado,
      "archivo_url": jsonEncode(jsonData), // ← SE GUARDA AQUÍ
      "fecha_edicion": DateTime.now(),
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guardado ✔")),
      );
      Navigator.pop(context);
    }
  }

  // ---------------------------------------------------------
  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  // ---------------------------------------------------------
  // UI
  // ---------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7EFFA),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        title: const Text("Editor: Fill Blank",
            style: TextStyle(color: Colors.white)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --------------------------------------------------
                  // ENUNCIADO
                  // --------------------------------------------------
                  const Text(
                    "Enunciado (usa __ para marcar los espacios):",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: _enunciadoCtrl,
                    decoration: const InputDecoration(
                      hintText:
                          "Ej: El valor de X es __ cuando Y es __.",
                    ),
                    onChanged: (_) => _detectarEspacios(),
                  ),

                  const SizedBox(height: 20),

                  Text(
                    "Espacios detectados: $_cantidadEspacios",
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w600),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // PALABRAS CORRECTAS
                  // --------------------------------------------------
                  const Text(
                    "Palabras correctas (en orden):",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  Expanded(
                    child: ListView.builder(
                      itemCount: _blanks.length,
                      itemBuilder: (_, i) {
                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.orange,
                            child: Text("${i + 1}",
                                style: const TextStyle(color: Colors.white)),
                          ),
                          title: TextField(
                            controller: _blanks[i],
                            decoration: InputDecoration(
                              labelText:
                                  "Palabra para espacio ${i + 1}",
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // RETROALIMENTACIÓN
                  // --------------------------------------------------
                  const Text(
                    "Retroalimentación:",
                    style:
                        TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  TextField(
                    controller: retroCtrl,
                    maxLines: 3,
                  ),

                  const SizedBox(height: 20),

                  // --------------------------------------------------
                  // BOTÓN GUARDAR
                  // --------------------------------------------------
                  Center(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: _save,
                      child: const Text(
                        "Guardar",
                        style: TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),

                  const SizedBox(height: 10),
                ],
              ),
            ),
    );
  }
}
