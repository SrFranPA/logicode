import 'dart:convert';
import 'package:flutter/material.dart';

import '../../../../../../data/models/pregunta_model.dart';

import 'ordenar_question.dart';
import 'fill_blank_question.dart';
import 'chip_select_question.dart';

/// Normaliza cualquier tipo raro a uno de los válidos
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
  final data = jsonDecode(pregunta.archivoUrl ?? "{}");

  final rawTipo = data["tipo"]?.toString() ?? pregunta.tipo;
  final tipo = normalizarTipo(rawTipo);

  print("TIPO RECIBIDO → $rawTipo / NORMALIZADO → $tipo");

  switch (tipo) {
    case "ordenar":
      return OrdenarQuestionWidget(
        enunciado: pregunta.enunciado,
        elementos: List<String>.from(data["elementos"] ?? []),
        retroalimentacion: data["retroalimentacion"] ?? "",
        onResult: onResult,
      );

    case "completa_espacio":
      return FillBlankQuestionWidget(
        enunciado: pregunta.enunciado,
        blanks: List<String>.from(data["blanks"] ?? []),
        retroalimentacion: data["retroalimentacion"] ?? "",
        onResult: onResult,
      );

    case "seleccion_chips":
      return ChipSelectQuestionWidget(
        enunciado: pregunta.enunciado,
        opciones: List<String>.from(data["opciones"] ?? []),
        correcta: data["respuesta_correcta"] ?? "",
        retroalimentacion: data["feedback"] ?? data["retroalimentacion"] ?? "",
        onResult: onResult,
      );

    default:
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(
          child: Text(
            "❌ Tipo no soportado",
            style: TextStyle(fontSize: 20, color: Colors.red),
          ),
        ),
      );
  }
}
