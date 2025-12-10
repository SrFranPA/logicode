import 'package:flutter/material.dart';

class ChipSelectQuestionWidget extends StatefulWidget {
  final String enunciado;
  final List<String> opciones;
  final String correcta;
  final String retroalimentacion;

  final Function(bool, String) onResult;

  const ChipSelectQuestionWidget({
    super.key,
    required this.enunciado,
    required this.opciones,
    required this.correcta,
    required this.retroalimentacion,
    required this.onResult,
  });

  @override
  State<ChipSelectQuestionWidget> createState() =>
      _ChipSelectQuestionWidgetState();
}

class _ChipSelectQuestionWidgetState extends State<ChipSelectQuestionWidget> {
  String? seleccion;
  bool locked = false;

  void evaluar() {
    if (locked || seleccion == null) return;

    final correcta = seleccion == widget.correcta;

    widget.onResult(correcta, widget.retroalimentacion);

    setState(() => locked = true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.enunciado,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),

        Wrap(
          spacing: 10,
          children: widget.opciones.map((opt) {
            final activo = seleccion == opt;
            return ChoiceChip(
              label: Text(opt),
              selected: activo,
              onSelected: locked
                  ? null
                  : (v) {
                      setState(() => seleccion = opt);
                    },
              selectedColor: Colors.orange,
            );
          }).toList(),
        ),

        const SizedBox(height: 20),

        ElevatedButton(
          onPressed: locked ? null : evaluar,
          style: ElevatedButton.styleFrom(
            backgroundColor: locked ? Colors.grey : Colors.orange,
          ),
          child:
              const Text("Comprobar", style: TextStyle(color: Colors.white)),
        )
      ],
    );
  }
}
