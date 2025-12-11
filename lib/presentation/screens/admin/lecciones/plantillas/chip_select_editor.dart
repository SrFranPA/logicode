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
  int? _respuestaIndex;

  bool _cargando = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    try {
      final doc = await _db.collection("banco_preguntas").doc(widget.preguntaId).get();
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
        _opcionesCtrl = opciones.map((t) => TextEditingController(text: t)).toList();

        final correcta = jsonData["respuesta_correcta"];
        _respuestaIndex = correcta != null ? opciones.indexOf(correcta) : null;
        feedbackCtrl.text = jsonData["feedback"] ?? "";
      }

      if (_opcionesCtrl.length < 2) {
        _agregarOpcion();
        _agregarOpcion();
      }
    } catch (e) {
      _showError("Ocurrio un error al cargar la pregunta.");
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  void _agregarOpcion() {
    setState(() {
      _opcionesCtrl.add(TextEditingController());
    });
  }

  void _showError(String? msg) {
    setState(() => _errorMessage = msg);
  }

  Future<void> _guardar() async {
    final opciones = _opcionesCtrl.map((c) => c.text.trim()).toList();

    if (enunciadoCtrl.text.trim().isEmpty) {
      return _showError("Escribe el enunciado antes de continuar.");
    }
    if (opciones.where((o) => o.isNotEmpty).length < 2) {
      return _showError("Necesitas al menos 2 opciones con texto.");
    }
    if (_respuestaIndex == null ||
        _respuestaIndex! >= opciones.length ||
        opciones[_respuestaIndex!].isEmpty) {
      return _showError("Selecciona cual opcion es la correcta.");
    }
    if (feedbackCtrl.text.trim().isEmpty) {
      return _showError("Agrega una retroalimentacion para el estudiante.");
    }

    try {
      final jsonData = {
        "tipo": "chip_select",
        "opciones": opciones,
        "respuesta_correcta": opciones[_respuestaIndex!],
        "feedback": feedbackCtrl.text.trim(),
      };

      await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
        "enunciado": enunciadoCtrl.text.trim(),
        "archivo_url": jsonEncode(jsonData),
      });

      _showError(null);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Guardado correctamente")),
      );

      Future.delayed(const Duration(milliseconds: 400), () {
        if (mounted) Navigator.pop(context);
      });
    } catch (e) {
      _showError("No se pudo guardar la pregunta. Intenta nuevamente.");
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
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1D2034),
        leading: const BackButton(color: Colors.white),
        title: const Text(
          "Editor: Seleccion (chips)",
          style: TextStyle(color: Colors.white),
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
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_errorMessage != null) _errorBox(_errorMessage!),
                _cardSection(
                  title: "Enunciado",
                  child: TextField(
                    controller: enunciadoCtrl,
                    decoration: const InputDecoration(
                      hintText: "Ej: Selecciona la respuesta correcta...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                    maxLines: 2,
                    onChanged: (_) => _showError(null),
                  ),
                ),
                const SizedBox(height: 12),
                _cardSection(
                  title: "Opciones",
                  subtitle: "Anade al menos dos opciones y marca la correcta.",
                  child: Column(
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            _agregarOpcion();
                            _showError(null);
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFFA200),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.add),
                          label: const Text("Agregar opcion"),
                        ),
                      ),
                      const SizedBox(height: 10),
                      ...List.generate(_opcionesCtrl.length, (i) {
                        return Container(
                          margin: EdgeInsets.only(top: i == 0 ? 0 : 10),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.black.withValues(alpha: 0.06),
                            ),
                          ),
                          child: Row(
                            children: [
                              Radio<int>(
                                value: i,
                                groupValue: _respuestaIndex,
                                activeColor: const Color(0xFFFFA200),
                                onChanged: (v) {
                                  _showError(null);
                                  setState(() => _respuestaIndex = v);
                                },
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: TextField(
                                  controller: _opcionesCtrl[i],
                                  decoration: InputDecoration(
                                    labelText: "Opcion ${i + 1}",
                                    filled: true,
                                    fillColor: Colors.white,
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                      borderSide: BorderSide.none,
                                    ),
                                  ),
                                  onChanged: (_) => _showError(null),
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  _showError(null);
                                  setState(() {
                                    if (_respuestaIndex == i) {
                                      _respuestaIndex = null;
                                    } else if (_respuestaIndex != null &&
                                        _respuestaIndex! > i) {
                                      _respuestaIndex = _respuestaIndex! - 1;
                                    }
                                    _opcionesCtrl.removeAt(i);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _cardSection(
                  title: "Retroalimentacion",
                  child: TextField(
                    controller: feedbackCtrl,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: "Ej: Piensa en el concepto clave...",
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onChanged: (_) => _showError(null),
                  ),
                ),
                const SizedBox(height: 18),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _guardar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFFA200),
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
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
            color: Colors.black.withValues(alpha: 0.05),
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
                color: Colors.black.withValues(alpha: 0.65),
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
