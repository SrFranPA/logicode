import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ChipSelectEditor extends StatefulWidget {
  final String preguntaId;

  const ChipSelectEditor({super.key, required this.preguntaId});

  @override
  State<ChipSelectEditor> createState() => _ChipSelectEditorState();
}

class _ChipSelectEditorState extends State<ChipSelectEditor> {
  final _db = FirebaseFirestore.instance;

  final enunciadoCtrl = TextEditingController();
  final feedbackCtrl = TextEditingController();

  List<TextEditingController> _opcionesCtrl = [];
  String? _respuestaCorrecta;

  bool _cargando = true;

  /// 🔥 Nuevo: mensaje de error amigable
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final doc =
          await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

      if (!doc.exists) {
        setState(() => _cargando = false);
        return;
      }

      final data = doc.data()!;
      enunciadoCtrl.text = data["enunciado"] ?? "";

      final rawJson = data["archivo_url"];

      if (rawJson != null && rawJson.toString().trim().isNotEmpty) {
        final jsonData = jsonDecode(rawJson);

        final opciones = List<String>.from(jsonData["opciones"] ?? []);
        _opcionesCtrl =
            opciones.map((t) => TextEditingController(text: t)).toList();

        _respuestaCorrecta = jsonData["respuesta_correcta"];
        feedbackCtrl.text = jsonData["feedback"] ?? "";
      }

      if (_opcionesCtrl.isEmpty) {
        _agregarOpcion();
        _agregarOpcion();
      }
    } catch (e) {
      _showError("Ocurrió un error al cargar la pregunta.");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _agregarOpcion() {
    setState(() {
      _opcionesCtrl.add(TextEditingController());
    });
  }

  /// 🔥 Nuevo: widget de error amigable
  Widget _errorBox(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.shade300),
      ),
      child: Text(
        msg,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.red.shade700,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// 🔥 Nuevo: acepta null
  void _showError(String? msg) {
    setState(() => _errorMessage = msg);
  }

  Future<void> _guardar() async {
    final opciones = _opcionesCtrl.map((c) => c.text.trim()).toList();

    if (enunciadoCtrl.text.trim().isEmpty) {
      return _showError("Por favor escribe el enunciado antes de continuar 😊");
    }
    if (opciones.where((o) => o.isNotEmpty).length < 2) {
      return _showError("Necesitas al menos 2 opciones para crear la pregunta 👍");
    }
    if (_respuestaCorrecta == null) {
      return _showError("Debes seleccionar cuál opción es la correcta ✨");
    }
    if (feedbackCtrl.text.trim().isEmpty) {
      return _showError("Agrega una retroalimentación para ayudar al estudiante 🧠💡");
    }

    try {
      final jsonData = {
        "tipo": "chip_select",
        "opciones": opciones,
        "respuesta_correcta": _respuestaCorrecta,
        "feedback": feedbackCtrl.text.trim(),
      };

      await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
        "enunciado": enunciadoCtrl.text.trim(),
        "archivo_url": jsonEncode(jsonData),
      });

      _showError(null);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guardado correctamente ✔")),
      );

      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      _showError("No se pudo guardar la pregunta. Intenta nuevamente 🙏");
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF7F0FF),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        leading: const BackButton(color: Colors.white),
        title: const Text("Editor: Chip Select",
            style: TextStyle(color: Colors.white)),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// 🔥 Mostrar error arriba del formulario
            if (_errorMessage != null) _errorBox(_errorMessage!),

            TextField(
              controller: enunciadoCtrl,
              decoration: const InputDecoration(labelText: "Enunciado"),
              onChanged: (_) => _showError(null),
            ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text("Opciones:"),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: () {
                    _agregarOpcion();
                    _showError(null);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                  ),
                  child: const Text("Agregar opción",
                      style: TextStyle(color: Colors.white)),
                ),
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: _opcionesCtrl.length,
                itemBuilder: (_, i) {
                  return ListTile(
                    title: TextField(
                      controller: _opcionesCtrl[i],
                      decoration:
                          InputDecoration(labelText: "Opción ${i + 1}"),
                      onChanged: (_) => _showError(null),
                    ),
                    leading: Radio<String>(
                      value: _opcionesCtrl[i].text,
                      groupValue: _respuestaCorrecta,
                      onChanged: (v) {
                        _showError(null);
                        setState(() => _respuestaCorrecta = v);
                      },
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        _showError(null);
                        setState(() {
                          if (_opcionesCtrl[i].text == _respuestaCorrecta) {
                            _respuestaCorrecta = null;
                          }
                          _opcionesCtrl.removeAt(i);
                        });
                      },
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 20),

            const Text("Retroalimentación:"),
            TextField(
              controller: feedbackCtrl,
              maxLines: 3,
              onChanged: (_) => _showError(null),
            ),

            const SizedBox(height: 20),

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
                child: const Text("Guardar",
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
