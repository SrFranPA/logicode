import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class DragDropEditor extends StatefulWidget {
  final String preguntaId;

  const DragDropEditor({super.key, required this.preguntaId});

  @override
  State<DragDropEditor> createState() => _DragDropEditorState();
}

class _DragDropEditorState extends State<DragDropEditor> {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final enunciadoCtrl = TextEditingController();
  final feedbackCorrectoCtrl = TextEditingController();
  final feedbackIncorrectoCtrl = TextEditingController();

  List<TextEditingController> opciones = [];
  List<int> ordenCorrecto = [];

  File? imagenPrincipal;
  String? urlImagenPrincipal;

  bool cargando = true;

  @override
  void initState() {
    super.initState();
    _loadExisting();
  }

  Future<void> _loadExisting() async {
    final doc = await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

    if (doc.exists) {
      final data = doc.data()!;
      enunciadoCtrl.text = data["enunciado"] ?? "";

      if (data["contenido"] != null) {
        final contenido = data["contenido"];

        urlImagenPrincipal = contenido["imagen_pregunta"];

        final ops = List<String>.from(contenido["opciones"] ?? []);
        final ord = List<int>.from(contenido["orden_correcto"] ?? []);

        opciones = ops.map((t) => TextEditingController(text: t)).toList();

        if (ord.isNotEmpty && ord.length == ops.length) {
          ordenCorrecto = ord;
        }

        feedbackCorrectoCtrl.text = contenido["feedback_correcto"] ?? "";
        feedbackIncorrectoCtrl.text = contenido["feedback_incorrecto"] ?? "";
      }
    }

    if (opciones.isEmpty) {
      agregarOpcion();
      agregarOpcion();
    }

    setState(() => cargando = false);
  }

  void agregarOpcion() {
    opciones.add(TextEditingController());
    ordenCorrecto = List.generate(opciones.length, (i) => i);
    setState(() {});
  }

  Future<String?> _subirImagen(File file, String nombre) async {
    final ref = _storage.ref().child("preguntas/${widget.preguntaId}/$nombre");
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> seleccionarImagen() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        imagenPrincipal = File(picked.path);
      });
    }
  }

  Future<void> guardar() async {
    final listaOpciones = opciones.map((c) => c.text.trim()).toList();

    if (enunciadoCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("El enunciado no puede estar vacío")),
      );
      return;
    }

    if (listaOpciones.where((t) => t.isNotEmpty).length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Debes ingresar al menos 2 opciones válidas")),
      );
      return;
    }

    String? imagenUrl = urlImagenPrincipal;
    if (imagenPrincipal != null) {
      imagenUrl = await _subirImagen(imagenPrincipal!, "imagen_pregunta.png");
    }

    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "enunciado": enunciadoCtrl.text.trim(),
      "contenido": {
        "imagen_pregunta": imagenUrl,
        "opciones": listaOpciones,
        "orden_correcto": List<int>.from(
          List.generate(listaOpciones.length, (i) => i),
        ),
        "feedback_correcto": feedbackCorrectoCtrl.text.trim(),
        "feedback_incorrecto": feedbackIncorrectoCtrl.text.trim(),
      },
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Drag & Drop guardado ✔")),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

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
              Row(
                children: [
                  const Text(
                    "Imagen principal:",
                    style: TextStyle(fontSize: 16),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: seleccionarImagen,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                    ),
                    child: const Text("Subir imagen"),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (urlImagenPrincipal != null)
                Image.network(urlImagenPrincipal!, height: 120),
              if (imagenPrincipal != null)
                Image.file(imagenPrincipal!, height: 120),

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

                  ordenCorrecto = List.generate(opciones.length, (i) => i);

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

              const SizedBox(height: 24),
              const Text(
                "Retroalimentación correcta",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: feedbackCorrectoCtrl,
                maxLines: 2,
              ),

              const SizedBox(height: 12),
              const Text(
                "Retroalimentación incorrecta",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              TextField(
                controller: feedbackIncorrectoCtrl,
                maxLines: 2,
              ),

              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}
