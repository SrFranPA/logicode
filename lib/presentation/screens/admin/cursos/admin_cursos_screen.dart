// lib/presentation/screens/admin/cursos/admin_cursos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/admin_cursos/admin_cursos_cubit.dart';
import '../../../../data/models/curso_model.dart';

class AdminCursosScreen extends StatelessWidget {
  const AdminCursosScreen({super.key});

  // ====================================================
  // CONFIRMACIÓN DE ELIMINAR (DISEÑO MODERNO)
  // ====================================================
  Future<bool> mostrarConfirmacionEliminar(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFFF4EEF8), // Lavanda suave
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            title: const Text(
              "Confirmar eliminación",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: const Text(
              "¿Seguro que deseas eliminar este curso? Esta acción no se puede deshacer.",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
              ),
            ),
            actionsAlignment: MainAxisAlignment.end,
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  "Cancelar",
                  style: TextStyle(
                    color: Color(0xFF6A4BC3), // Morado suave
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              // Botón Eliminar moderno
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6A4BC3),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: Color(0xFF6A4BC3),
                      width: 1.4,
                    ),
                  ),
                ),
                child: const Text(
                  "Eliminar",
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ) ??
        false;
  }

  // ====================================================
  // MODAL CREAR / EDITAR CURSO
  // ====================================================
  void abrirModalCurso(BuildContext context, {CursoModel? curso}) {
    final idCtrl = TextEditingController(text: curso?.id ?? '');
    final nombreCtrl = TextEditingController(text: curso?.nombre ?? '');
    final descCtrl = TextEditingController(text: curso?.descripcion ?? '');
    final ordenCtrl =
        TextEditingController(text: curso?.orden.toString() ?? '');

    final esEdicion = curso != null;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFFF7F0FF),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (_) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 20,
            right: 20,
            top: 30,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                esEdicion ? "Editar curso" : "Nuevo curso",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 20),

              // ID
              TextField(
                controller: idCtrl,
                enabled: !esEdicion,
                decoration: InputDecoration(
                  labelText: "ID (ej: estr_repe)",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Nombre
              TextField(
                controller: nombreCtrl,
                decoration: InputDecoration(
                  labelText: "Nombre",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Descripción
              TextField(
                controller: descCtrl,
                decoration: InputDecoration(
                  labelText: "Descripción",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 12),

              // Orden
              TextField(
                controller: ordenCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "Orden",
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Botón guardar
              SizedBox(
                width: double.infinity,
                height: 55,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFA200),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () {
                    final repo = context.read<AdminCursosCubit>();

                    final nuevo = CursoModel(
                      id: idCtrl.text.trim(),
                      nombre: nombreCtrl.text.trim(),
                      descripcion: descCtrl.text.trim(),
                      orden: int.tryParse(ordenCtrl.text.trim()) ?? 0,
                    );

                    if (esEdicion) {
                      repo.editarCurso(nuevo);
                    } else {
                      repo.crearCurso(nuevo);
                    }

                    Navigator.pop(context);
                  },
                  child: Text(
                    esEdicion ? "Guardar cambios" : "Crear curso",
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 25),
            ],
          ),
        );
      },
    );
  }

  // ====================================================
  // ITEM LISTA CURSO
  // ====================================================
  Widget _itemCurso(BuildContext context, CursoModel curso) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(curso.nombre),
        subtitle: Text("Orden: ${curso.orden}"),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => abrirModalCurso(context, curso: curso),
            ),
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () async {
                final confirmar = await mostrarConfirmacionEliminar(context);
                if (confirmar) {
                  context.read<AdminCursosCubit>().eliminarCurso(curso.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ====================================================
  // PANTALLA PRINCIPAL
  // ====================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDF7E2),
      appBar: AppBar(
        backgroundColor: Colors.orange,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Gestión de cursos",
          style: TextStyle(color: Colors.white),
        ),
      ),

      // BODY
      body: BlocBuilder<AdminCursosCubit, AdminCursosState>(
        builder: (_, state) {
          if (state is AdminCursosLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is AdminCursosLoaded) {
            final cursos = state.cursos;

            return Padding(
              padding: const EdgeInsets.only(bottom: 90),
              child: ListView.builder(
                itemCount: cursos.length,
                itemBuilder: (_, i) => _itemCurso(context, cursos[i]),
              ),
            );
          }

          return const Center(child: Text("Sin datos"));
        },
      ),

      // BOTÓN FLOTANTE CENTRADO
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: SizedBox(
        width: 65,
        height: 65,
        child: FloatingActionButton(
          backgroundColor: const Color(0xFFFFA200),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(50),
          ),
          onPressed: () => abrirModalCurso(context),
          child: const Icon(
            Icons.add,
            size: 30,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}
