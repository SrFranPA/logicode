import 'package:flutter/material.dart';

class FillBlankQuestionWidget extends StatefulWidget {
  final String enunciado;
  final List<String> blanks;
  final String retroalimentacion;
  final Function(bool, String) onResult;

  const FillBlankQuestionWidget({
    super.key,
    required this.enunciado,
    required this.blanks,
    required this.retroalimentacion,
    required this.onResult,
  });

  @override
  State<FillBlankQuestionWidget> createState() =>
      _FillBlankQuestionWidgetState();
}

class _FillBlankQuestionWidgetState extends State<FillBlankQuestionWidget> {
  late List<TextEditingController> controllers;
  bool locked = false;

  @override
  void initState() {
    super.initState();
    controllers = List.generate(
        widget.blanks.length, (_) => TextEditingController());
  }

  void evaluar() {
    if (locked) return;

    bool correcta = true;

    for (int i = 0; i < widget.blanks.length; i++) {
      if (controllers[i].text.trim() != widget.blanks[i].trim()) {
        correcta = false;
        break;
      }
    }

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

        Column(
          children: List.generate(widget.blanks.length, (i) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: TextField(
                controller: controllers[i],
                enabled: !locked,
                decoration: const InputDecoration(
                  filled: true,
                  fillColor: Colors.white,
                  hintText: "Completa aquí",
                ),
              ),
            );
          }),
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
