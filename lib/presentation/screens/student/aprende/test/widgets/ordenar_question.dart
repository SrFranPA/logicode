// lib/presentation/screens/student/aprende/test/widgets/ordenar_question.dart

import 'package:flutter/material.dart';

class OrdenarQuestionWidget extends StatefulWidget {
  final String enunciado;
  final List<String> elementos;
  final String retroalimentacion;
  final Function(bool, String) onResult;

  const OrdenarQuestionWidget({
    super.key,
    required this.enunciado,
    required this.elementos,
    required this.retroalimentacion,
    required this.onResult,
  });

  @override
  State<OrdenarQuestionWidget> createState() => _OrdenarQuestionWidgetState();
}

class _OrdenarQuestionWidgetState extends State<OrdenarQuestionWidget> {
  late List<String> desordenados;
  late List<String> correctos;

  bool locked = false; // Una vez respondido, ya no se puede mover
  bool moved = false;  // Para activar el botón "Comprobar"

  @override
  void initState() {
    super.initState();
    correctos = List<String>.from(widget.elementos);
    desordenados = List<String>.from(widget.elementos)..shuffle();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (locked) return;

    // FIX: esto habilita "Comprobar"
    setState(() => moved = true);

    if (newIndex > oldIndex) newIndex--;
    final item = desordenados.removeAt(oldIndex);
    desordenados.insert(newIndex, item);
  }

  void _comprobar() {
    if (locked) return;

    final correcto = _listasIguales(desordenados, correctos);

    setState(() {
      locked = true;
    });

    widget.onResult(correcto, widget.retroalimentacion);
  }

  bool _listasIguales(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.enunciado,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),

        const SizedBox(height: 16),

        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: _onReorder,
          children: [
            for (int i = 0; i < desordenados.length; i++)
              Container(
                key: ValueKey(desordenados[i]),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
                decoration: BoxDecoration(
                  color: locked ? Colors.grey.shade300 : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.shade300),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_handle),
                    const SizedBox(width: 10),
                    Expanded(child: Text(desordenados[i])),
                  ],
                ),
              )
          ],
        ),

        const SizedBox(height: 20),

        Center(
          child: ElevatedButton(
            onPressed: (!locked && moved) ? _comprobar : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: (!locked && moved)
                  ? Colors.orange
                  : Colors.grey.shade400,
              padding:
                  const EdgeInsets.symmetric(horizontal: 40, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Comprobar",
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
        ),
      ],
    );
  }
}
