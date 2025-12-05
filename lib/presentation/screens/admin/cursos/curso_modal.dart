// lib/presentation/screens/admin/cursos/curso_modal.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../blocs/admin_cursos/admin_cursos_cubit.dart';
import '../../../../data/models/curso_model.dart';

class CursoModal extends StatefulWidget {
  final CursoModel? curso;

  const CursoModal({super.key, this.curso});

  @override
  State<CursoModal> createState() => _CursoModalState();
}

class _CursoModalState extends State<CursoModal> {
  late TextEditingController idCtrl;
  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController ordenCtrl;

  @override
  void initState() {
    super.initState();

    idCtrl = TextEditingController(text: widget.curso?.id ?? "");
    nombreCtrl = TextEditingController(text: widget.curso?.nombre ?? "");
    descripcionCtrl = TextEditingController(text: widget.curso?.descripcion ?? "");
    ordenCtrl = TextEditingController(
      text: widget.curso?.orden.toString() ?? "",
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool editMode = widget.curso != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              editMode ? "Editar curso" : "Nuevo curso",
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 20),

            if (!editMode)
              TextField(
                controller: idCtrl,
                decoration: const InputDecoration(
                  labelText: "ID (ej: estr_repe)",
                ),
              ),

            const SizedBox(height: 12),

            TextField(
              controller: nombreCtrl,
              decoration: const InputDecoration(labelText: "Nombre"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: descripcionCtrl,
              decoration: const InputDecoration(labelText: "Descripción"),
            ),

            const SizedBox(height: 12),

            TextField(
              controller: ordenCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: "Orden"),
            ),

            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                child: Text(
                  editMode ? "Guardar cambios" : "Crear curso",
                  style: const TextStyle(color: Colors.white),
                ),
                onPressed: () {
                  final id = editMode ? widget.curso!.id : idCtrl.text.trim();

                  if (id.isEmpty || nombreCtrl.text.trim().isEmpty) return;

                  final curso = CursoModel(
                    id: id,
                    nombre: nombreCtrl.text.trim(),
                    descripcion: descripcionCtrl.text.trim(),
                    orden: int.tryParse(ordenCtrl.text.trim()) ?? 0,
                  );

                  if (editMode) {
                    context.read<AdminCursosCubit>().editarCurso(curso);
                  } else {
                    context.read<AdminCursosCubit>().crearCurso(curso);
                  }

                  Navigator.pop(context);
                },
              ),
            )
          ],
        ),
      ),
    );
  }
}
