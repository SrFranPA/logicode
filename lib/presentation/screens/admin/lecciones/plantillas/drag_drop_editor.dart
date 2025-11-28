import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DragDropEditor extends StatefulWidget {
  final String preguntaId;

  const DragDropEditor({super.key, required this.preguntaId});

  @override
  State<DragDropEditor> createState() => _DragDropEditorState();
}

class _DragDropEditorState extends State<DragDropEditor> {
  final _db = FirebaseFirestore.instance;

  final enunciadoCtrl = TextEditingController();
  List<TextEditingController> opciones = [];
  List<int> ordenCorrecto = [];

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc =
        await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

    if (!doc.exists) return;

    final data = doc.data()!;

    enunciadoCtrl.text = data["enunciado"] ?? "";

    final contenido = data["contenido"];
    if (contenido != null) {
      final ops = List<String>.from(contenido["opciones"] ?? []);
      final ord = List<int>.from(contenido["orden_correcto"] ?? []);

      opciones = ops.map((t) => TextEditingController(text: t)).toList();
      ordenCorrecto = ord;
    }

    if (opciones.isEmpty) {
      agregarOpcion();
      agregarOpcion();
    }

    setState(() {});
  }

  void agregarOpcion() {
    opciones.add(TextEditingController());
    ordenCorrecto = List.generate(opciones.length, (i) => i);
    setState(() {});
  }

  void guardar() async {
    final listaOpciones = opciones.map((c) => c.text).toList();

    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "enunciado": enunciadoCtrl.text.trim(),
      "contenido": {
        "opciones": listaOpciones,
        "orden_correcto": ordenCorrecto,
      },
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Drag & Drop guardado ✔")),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editor: Drag & Drop"),
        backgroundColor: Colors.orange,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: guardar,
          )
        ],
      ),
      backgroundColor: const Color(0xFFFDF7E2),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Enunciado",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: enunciadoCtrl,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: "Escribe la pregunta aquí...",
                ),
              ),

              const SizedBox(height: 20),
              const Text(
                "Opciones (ordénalas)",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),

              ReorderableListView(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex--;

                  final item = opciones.removeAt(oldIndex);
                  opciones.insert(newIndex, item);

                  ordenCorrecto =
                      List.generate(opciones.length, (i) => i);

                  setState(() {});
                },
                children: [
                  for (int i = 0; i < opciones.length; i++)
                    ListTile(
                      key: ValueKey(i),
                      title: TextField(
                        controller: opciones[i],
                        decoration: InputDecoration(
                          labelText: "Opción ${i + 1}",
                        ),
                      ),
                      trailing: const Icon(Icons.drag_handle),
                    )
                ],
              ),

              const SizedBox(height: 20),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                ),
                onPressed: agregarOpcion,
                icon: const Icon(Icons.add),
                label: const Text("Agregar opción"),
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
