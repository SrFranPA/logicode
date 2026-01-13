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
  late List<_OrdenItem> correctos;
  late List<_OrdenItem> desordenados;

  bool locked = false; // Una vez respondido, ya no se puede mover

  @override
  void initState() {
    super.initState();
    correctos = List.generate(
      widget.elementos.length,
      (i) => _OrdenItem(id: 'item_$i', texto: widget.elementos[i]),
    );
    desordenados = List<_OrdenItem>.from(correctos)..shuffle();
  }

  void _onReorder(int oldIndex, int newIndex) {
    if (locked) return;

    if (newIndex > oldIndex) newIndex--;
    final item = desordenados.removeAt(oldIndex);
    desordenados.insert(newIndex, item);
    setState(() {});
  }

  void _comprobar() {
    if (locked) return;

    final correcto = _listasIguales(desordenados, correctos);

    setState(() {
      locked = true;
    });

    widget.onResult(correcto, widget.retroalimentacion);
  }

  bool _listasIguales(List<_OrdenItem> a, List<_OrdenItem> b) {
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id) return false;
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

        const SizedBox(height: 6),
        const Text(
          'Arrastra las opciones usando las dos líneas al costado.',
          style: TextStyle(
            fontSize: 12,
            color: Color(0xFF6B7280),
            fontWeight: FontWeight.w600,
          ),
        ),

        const SizedBox(height: 16),

        ReorderableListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          proxyDecorator: (child, index, animation) {
            return Material(
              color: Colors.transparent,
              child: Transform.scale(
                scale: 0.98,
                child: child,
              ),
            );
          },
          onReorder: _onReorder,
          itemCount: desordenados.length,
          itemBuilder: (context, i) {
            final item = desordenados[i];
            return Container(
              key: ValueKey(item.id),
              margin: const EdgeInsets.symmetric(vertical: 6),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: locked ? Colors.grey.shade200 : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFF2B46D)),
                boxShadow: const [
                  BoxShadow(
                    color: Color(0x14000000),
                    blurRadius: 6,
                    offset: Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                children: [
                  ReorderableDragStartListener(
                    index: i,
                    child: const Icon(Icons.drag_handle, color: Color(0xFFE07A1E)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item.texto,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1F2A44),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),

        const SizedBox(height: 20),

        Center(
          child: ElevatedButton(
            onPressed: locked ? null : _comprobar,
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  !locked ? const Color(0xFFE07A1E) : Colors.grey.shade400,
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

class _OrdenItem {
  final String id;
  final String texto;

  const _OrdenItem({required this.id, required this.texto});
}
