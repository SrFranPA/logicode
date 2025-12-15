import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

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
  final List<TextEditingController> _extras = [];
  final retroCtrl = TextEditingController();

  bool loading = true;
  int _cantidadEspacios = 0;

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

      final rawJson = data["archivo_url"];
      if (rawJson != null && rawJson.toString().trim().isNotEmpty) {
        final decoded = jsonDecode(rawJson);
        final blanksList = List<String>.from(decoded["blanks"] ?? []);
        for (final word in blanksList) {
          _blanks.add(TextEditingController(text: word));
        }
        final extrasList = List<String>.from(decoded["opciones"] ?? decoded["distractores"] ?? []);
        for (final opt in extrasList) {
          _extras.add(TextEditingController(text: opt));
        }
        retroCtrl.text = decoded["retroalimentacion"] ?? "";
      }
    }

    _detectarEspacios();
    if (mounted) setState(() => loading = false);
  }

  void _detectarEspacios() {
    final matches = RegExp(r'__+').allMatches(_enunciadoCtrl.text);
    final cantidad = matches.length;
    _cantidadEspacios = cantidad;

    if (_blanks.length < cantidad) {
      for (int i = 0; i < (cantidad - _blanks.length); i++) {
        _blanks.add(TextEditingController());
      }
    } else if (_blanks.length > cantidad) {
      _blanks.removeRange(cantidad, _blanks.length);
    }

    setState(() {});
  }

  Future<void> _save() async {
    final enunciado = _enunciadoCtrl.text.trim();
    final retro = retroCtrl.text.trim();

    if (enunciado.isEmpty) {
      return _error("El enunciado no puede estar vacio.");
    }

    if (_cantidadEspacios == 0) {
      return _error("Debes incluir al menos un espacio '__' en el enunciado.");
    }

    final blanksValues =
        _blanks.map((c) => c.text.trim()).where((c) => c.isNotEmpty).toList();
    final extrasValues =
        _extras.map((c) => c.text.trim()).where((c) => c.isNotEmpty).toList();

    if (blanksValues.length != _cantidadEspacios) {
      return _error(
        "Debes completar las $_cantidadEspacios palabras correspondientes a los espacios.",
      );
    }

    if (retro.isEmpty) {
      return _error("La retroalimentacion no puede estar vacia.");
    }

    final jsonData = {
      "tipo": "completa_espacio",
      "blanks": blanksValues,
      "opciones": extrasValues,
      "retroalimentacion": retro,
    };

    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "tipo": "completa_espacio",
      "enunciado": enunciado,
      "archivo_url": jsonEncode(jsonData),
      "fecha_edicion": DateTime.now(),
    });

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Guardado")),
    );
    Navigator.pop(context);
  }

  void _error(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D2034),
        title: const Text(
          "Editor: Completa el espacio",
          style: TextStyle(color: Colors.white),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: loading
            ? const Center(child: CircularProgressIndicator())
            : SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _cardSection(
                        title: "Enunciado",
                        subtitle: "Usa __ para marcar los espacios en blanco.",
                        child: TextField(
                          controller: _enunciadoCtrl,
                          decoration: const InputDecoration(
                            hintText: "Ej: El valor de X es __ cuando Y es __.",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.all(Radius.circular(12)),
                            ),
                          ),
                          maxLines: 3,
                          onChanged: (_) => _detectarEspacios(),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _cardSection(
                        title: "Espacios detectados",
                        subtitle: _cantidadEspacios > 0
                            ? "Completa cada espacio en el orden correcto."
                            : "Agrega '__' en el enunciado para crear espacios.",
                        child: Column(
                          children: List.generate(_blanks.length, (i) {
                            return Container(
                              margin: EdgeInsets.only(top: i == 0 ? 0 : 10),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 10),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.black.withOpacity(0.06),
                                ),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    height: 32,
                                    width: 32,
                                    decoration: const BoxDecoration(
                                      color: Color(0xFFFFA200),
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        "${i + 1}",
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w800),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: TextField(
                                      controller: _blanks[i],
                                      decoration: InputDecoration(
                                        labelText: "Palabra para espacio ${i + 1}",
                                        filled: true,
                                        fillColor: Colors.white,
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(10),
                                          borderSide: BorderSide.none,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _cardSection(
                        title: "Retroalimentacion",
                        subtitle: "Mensaje que veran al responder.",
                        child: TextField(
                          controller: retroCtrl,
                          maxLines: 3,
                          decoration: InputDecoration(
                            hintText: "Ej: Recuerda que...",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _cardSection(
                        title: "Opciones erróneas (distractores)",
                        subtitle:
                            "Agrega palabras que aparecerán para arrastrar y confundir al estudiante.",
                        child: Column(
                          children: [
                            ...List.generate(_extras.length, (i) {
                              return Container(
                                margin: EdgeInsets.only(top: i == 0 ? 0 : 10),
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Colors.black.withOpacity(0.06),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: TextField(
                                        controller: _extras[i],
                                        decoration: InputDecoration(
                                          labelText: "Distractor ${i + 1}",
                                          filled: true,
                                          fillColor: Colors.white,
                                          border: OutlineInputBorder(
                                            borderRadius: BorderRadius.circular(10),
                                            borderSide: BorderSide.none,
                                          ),
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    IconButton(
                                      icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
                                      onPressed: () {
                                        setState(() {
                                          _extras.removeAt(i);
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              );
                            }),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerLeft,
                              child: TextButton.icon(
                                onPressed: () {
                                  setState(() {
                                    _extras.add(TextEditingController());
                                  });
                                },
                                icon: const Icon(Icons.add),
                                label: const Text("Agregar opcion errónea"),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA200),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 28, vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          onPressed: _save,
                          child: const Text(
                            "Guardar",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
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

  Widget _cardSection({
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
}
