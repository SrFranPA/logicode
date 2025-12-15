import 'package:flutter/material.dart';

class FillBlankQuestionWidget extends StatefulWidget {
  final String enunciado;
  final List<String> blanks;
  final List<String> opcionesExtra;
  final String retroalimentacion;
  final Function(bool, String) onResult;

  const FillBlankQuestionWidget({
    super.key,
    required this.enunciado,
    required this.blanks,
    this.opcionesExtra = const [],
    required this.retroalimentacion,
    required this.onResult,
  });

  @override
  State<FillBlankQuestionWidget> createState() => _FillBlankQuestionWidgetState();
}

class _FillBlankQuestionWidgetState extends State<FillBlankQuestionWidget> {
  late List<String?> _slots;
  late List<String> _pool;
  bool locked = false;

  @override
  void initState() {
    super.initState();
    _slots = List<String?>.filled(widget.blanks.length, null);
    _pool = _buildPool();
  }

  List<String> _buildPool() {
    final set = <String>{...widget.blanks, ...widget.opcionesExtra};
    if (set.length == widget.blanks.length) {
      set.addAll(['Opcion extra 1', 'Opcion extra 2']);
    }
    final list = set.toList()..shuffle();
    return list;
  }

  void evaluar() {
    if (locked) return;

    final completa = !_slots.contains(null);
    final correcta = completa &&
        List.generate(_slots.length, (i) => _slots[i]?.trim() == widget.blanks[i].trim())
            .every((ok) => ok);

    widget.onResult(correcta, widget.retroalimentacion);

    setState(() => locked = true);
  }

  void _reset() {
    setState(() {
      locked = false;
      _slots = List<String?>.filled(widget.blanks.length, null);
      _pool = _buildPool();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.enunciado,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: List.generate(
            _slots.length,
            (i) => DragTarget<String>(
              builder: (context, candidate, rejected) {
                final hasValue = _slots[i] != null;
                return GestureDetector(
                  onTap: locked || _slots[i] == null
                      ? null
                      : () {
                          setState(() {
                            _pool.add(_slots[i]!);
                            _slots[i] = null;
                          });
                        },
                  child: Container(
                    width: 120,
                    height: 42,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: hasValue ? const Color(0xFFFFF4E8) : Colors.white,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: candidate.isNotEmpty
                            ? const Color(0xFFFFA451)
                            : Colors.black.withOpacity(0.12),
                      ),
                    ),
                    child: hasValue
                        ? Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.drag_indicator, size: 16, color: Color(0xFFAA6A2A)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  _slots[i]!,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF3A2A1A),
                                  ),
                                ),
                              ),
                            ],
                          )
                        : Text(
                            'Arrastra',
                            style: TextStyle(
                              color: Colors.black.withOpacity(0.4),
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                );
              },
              onWillAccept: (_) => !locked && _slots[i] == null,
              onAccept: (value) {
                setState(() {
                  _slots[i] = value;
                  _pool.remove(value);
                });
              },
            ),
          ),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _pool
              .map(
                (opt) => Draggable<String>(
                  data: opt,
                  feedback: _Chip(opt, dragging: true),
                  childWhenDragging: _Chip(opt, ghost: true),
                  child: _Chip(opt),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            Expanded(
              child: ElevatedButton(
                onPressed: locked ? null : evaluar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: locked ? Colors.grey : Colors.orange,
                ),
                child: const Text("Comprobar", style: TextStyle(color: Colors.white)),
              ),
            ),
            const SizedBox(width: 10),
            if (locked)
              OutlinedButton(
                onPressed: _reset,
                child: const Text('Reintentar'),
              ),
          ],
        )
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final bool dragging;
  final bool ghost;

  const _Chip(this.label, {this.dragging = false, this.ghost = false});

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: ghost ? 0.3 : 1,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: dragging ? const Color(0xFFFFD9B3) : const Color(0xFFFFF4E8),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFFFA451).withOpacity(0.5)),
          boxShadow: dragging
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  )
                ]
              : null,
        ),
        child: Text(
          label,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF3A2A1A),
          ),
        ),
      ),
    );
  }
}
