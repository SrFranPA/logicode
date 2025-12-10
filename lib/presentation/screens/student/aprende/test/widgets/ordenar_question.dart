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
  late List<String> current;

  bool locked = false;

  @override
  void initState() {
    super.initState();
    current = List<String>.from(widget.elementos);
  }

  void evaluar() {
    if (locked) return;

    final correcta =
        List.generate(widget.elementos.length,
            (i) => widget.elementos[i] == current[i])
            .every((x) => x);

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

        ReorderableListView(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          onReorder: (oldIndex, newIndex) {
            if (locked) return;

            if (newIndex > oldIndex) newIndex--;
            final item = current.removeAt(oldIndex);
            current.insert(newIndex, item);
            setState(() {});
          },
          children: [
            for (int i = 0; i < current.length; i++)
              Container(
                key: ValueKey(current[i]),
                margin: const EdgeInsets.symmetric(vertical: 6),
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(
                      color: Colors.black12,
                      blurRadius: 4,
                      offset: Offset(0, 2),
                    )
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.drag_indicator),
                    const SizedBox(width: 8),
                    Expanded(child: Text(current[i])),
                  ],
                ),
              ),
          ],
        ),

        const SizedBox(height: 18),

        Center(
          child: ElevatedButton(
            onPressed: locked ? null : evaluar,
            style: ElevatedButton.styleFrom(
              backgroundColor: locked ? Colors.grey : Colors.orange,
            ),
            child: const Text("Comprobar", style: TextStyle(color: Colors.white)),
          ),
        )
      ],
    );
  }
}
