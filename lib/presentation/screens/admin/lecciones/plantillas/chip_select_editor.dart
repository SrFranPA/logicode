import 'dart:io';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';

class ChipSelectEditor extends StatefulWidget {
  final String preguntaId;

  const ChipSelectEditor({super.key, required this.preguntaId});

  @override
  State<ChipSelectEditor> createState() => _ChipSelectEditorState();
}

class _ChipSelectEditorState extends State<ChipSelectEditor> {
  final _db = FirebaseFirestore.instance;
  final _storage = FirebaseStorage.instance;

  final tituloCtrl = TextEditingController();
  bool cargando = true;

  File? imagenPregunta;
  String? urlImagenPregunta;

  List<Map<String, dynamic>> opciones = [];
  String? respuestaCorrecta;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  // -----------------------------------------------------------
  // CARGAR DATOS EXISTENTES
  // -----------------------------------------------------------
  Future<void> _cargarDatos() async {
    final doc = await _db.collection("banco_preguntas").doc(widget.preguntaId).get();

    if (doc.exists) {
      tituloCtrl.text = doc["enunciado"] ?? "";

      if (doc.data()!.containsKey("contenido")) {
        final c = doc["contenido"];

        urlImagenPregunta = c["imagen_pregunta"];

        opciones = List<Map<String, dynamic>>.from(
          c["opciones"]?.map((e) => Map<String, dynamic>.from(e)) ?? [],
        );

        respuestaCorrecta = c["respuesta_correcta"];
      }
    }

    setState(() => cargando = false);
  }

  // -----------------------------------------------------------
  // SUBIR IMAGEN A STORAGE
  // -----------------------------------------------------------
  Future<String?> _subirImagen(File file, String nombre) async {
    final ref = _storage.ref().child("preguntas/${widget.preguntaId}/$nombre");

    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  // -----------------------------------------------------------
  // GUARDAR EN FIRESTORE
  // -----------------------------------------------------------
  Future<void> _guardar() async {
    if (tituloCtrl.text.trim().isEmpty) {
      _msg("El enunciado no puede estar vacío");
      return;
    }
    if (opciones.length < 2) {
      _msg("Debes ingresar al menos 2 opciones");
      return;
    }
    if (respuestaCorrecta == null) {
      _msg("Marca la respuesta correcta");
      return;
    }

    // Subir imagen principal si existe
    String? imagenPrincipalUrl = urlImagenPregunta;

    if (imagenPregunta != null) {
      imagenPrincipalUrl = await _subirImagen(imagenPregunta!, "imagen_pregunta.png");
    }

    await _db.collection("banco_preguntas").doc(widget.preguntaId).update({
      "enunciado": tituloCtrl.text.trim(),
      "contenido": {
        "imagen_pregunta": imagenPrincipalUrl,
        "opciones": opciones,
        "respuesta_correcta": respuestaCorrecta,
      }
    });

    _msg("Guardado correctamente");
  }

  void _msg(String txt) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(txt)));
  }

  // -----------------------------------------------------------
  // AGREGAR OPCIÓN
  // -----------------------------------------------------------
  void _agregarOpcion() {
    final textoCtrl = TextEditingController();
    File? img;

    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Nueva opción"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: textoCtrl, decoration: const InputDecoration(labelText: "Texto")),

            const SizedBox(height: 10),

            ElevatedButton(
              onPressed: () async {
                final picker = ImagePicker();
                final p = await picker.pickImage(source: ImageSource.gallery);

                if (p != null) {
                  img = File(p.path);
                }
              },
              child: const Text("Seleccionar imagen (opcional)"),
            )
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancelar"),
          ),
          ElevatedButton(
            onPressed: () async {
              String? url;

              if (img != null) {
                url = await _subirImagen(img!, "opcion_${DateTime.now()}.png");
              }

              setState(() {
                opciones.add({
                  "texto": textoCtrl.text,
                  "img": url,
                });
              });

              Navigator.pop(context);
            },
            child: const Text("Agregar"),
          ),
        ],
      ),
    );
  }

  // -----------------------------------------------------------
  // UI PRINCIPAL
  // -----------------------------------------------------------
  @override
  Widget build(BuildContext context) {
    if (cargando) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: BackButton(color: Colors.white),
        title: const Text("Editor: Chip Select"),
        backgroundColor: Colors.orange,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Enunciado
            TextField(
              controller: tituloCtrl,
              decoration: const InputDecoration(labelText: "Enunciado de la pregunta"),
            ),

            const SizedBox(height: 20),

            // IMAGEN PRINCIPAL
            Row(
              children: [
                const Text("Imagen principal: "),
                ElevatedButton(
                  onPressed: _seleccionarImagenPrincipal,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("Subir imagen"),
                ),
              ],
            ),

            if (urlImagenPregunta != null)
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Image.network(urlImagenPregunta!, height: 100),
              ),

            const SizedBox(height: 20),

            Row(
              children: [
                const Text("Opciones:"),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _agregarOpcion,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text("Agregar opción"),
                )
              ],
            ),

            const SizedBox(height: 10),

            Expanded(
              child: ListView.builder(
                itemCount: opciones.length,
                itemBuilder: (_, i) {
                  final op = opciones[i];

                  return ListTile(
                    leading: Radio(
                      value: op["texto"],
                      groupValue: respuestaCorrecta,
                      onChanged: (v) => setState(() => respuestaCorrecta = v),
                    ),
                    title: Text(op["texto"]),
                    subtitle: op["img"] != null
                        ? Image.network(op["img"], height: 50)
                        : null,
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () => setState(() => opciones.removeAt(i)),
                    ),
                  );
                },
              ),
            ),

            ElevatedButton(
              onPressed: _guardar,
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              child: const Text("Guardar"),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _seleccionarImagenPrincipal() async {
    final picker = ImagePicker();
    final p = await picker.pickImage(source: ImageSource.gallery);

    if (p != null) {
      setState(() => imagenPregunta = File(p.path));
    }
  }
}
