import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../../../data/models/pregunta_model.dart';

import 'ordenar_question.dart';
import 'fill_blank_question.dart';
import 'chip_select_question.dart';

String normalizarTipo(String t) {
  t = t.trim().toLowerCase();

  if (t.contains("orden")) return "ordenar";
  if (t.contains("chip")) return "seleccion_chips";
  if (t.contains("fill") || t.contains("blank") || t.contains("espacio")) {
    return "completa_espacio";
  }

  return t;
}

Widget buildQuestionWidget({
  required Pregunta pregunta,
  required Function(bool correcta, String retro) onResult,
}) {
  Map<String, dynamic> data = {};
  try {
    final raw = pregunta.archivoUrl ?? "{}";
    final decoded = jsonDecode(raw);
    if (decoded is Map<String, dynamic>) {
      data = decoded;
    }
  } catch (_) {
    data = {};
  }

  final rawTipo = data["tipo"]?.toString() ?? pregunta.tipo;
  final tipo = normalizarTipo(rawTipo);

  print("TIPO RECIBIDO -> $rawTipo / NORMALIZADO -> $tipo");

  switch (tipo) {
    case "ordenar":
      return OrdenarQuestionWidget(
        enunciado: pregunta.enunciado,
        elementos: _asStringList(data["elementos"]),
        retroalimentacion: data["retroalimentacion"] ?? "",
        onResult: onResult,
      );

    case "completa_espacio":
      return FillBlankQuestionWidget(
        enunciado: pregunta.enunciado,
        blanks: _asStringList(data["blanks"]),
        opcionesExtra: _asStringList(data["opciones"]) + _asStringList(data["distractores"]),
        retroalimentacion: data["retroalimentacion"] ?? "",
        onResult: onResult,
      );

    case "seleccion_chips":
      return ChipSelectQuestionWidget(
        enunciado: pregunta.enunciado,
        opciones: _asStringList(data["opciones"]),
        correcta: data["respuesta_correcta"]?.toString() ?? "",
        retroalimentacion: data["feedback"] ?? data["retroalimentacion"] ?? "",
        onResult: onResult,
      );

    default:
      return _UnsupportedQuestion(onSkip: () => onResult(false, "Tipo no soportado"));
  }
}

List<String> _asStringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  return <String>[];
}

class _UnsupportedQuestion extends StatelessWidget {
  final VoidCallback onSkip;
  const _UnsupportedQuestion({required this.onSkip});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            "No se puede mostrar esta pregunta.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red),
          ),
        ),
        ElevatedButton(
          onPressed: onSkip,
          child: const Text("Omitir"),
        ),
      ],
    );
  }
}
