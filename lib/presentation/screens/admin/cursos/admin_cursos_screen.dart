// lib/presentation/screens/admin/cursos/admin_cursos_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../blocs/admin_cursos/admin_cursos_cubit.dart';
import '../../../../data/models/curso_model.dart';

class AdminCursosScreen extends StatelessWidget {
  const AdminCursosScreen({super.key});

  // Confirmación de eliminar
  Future<bool> mostrarConfirmacionEliminar(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (_) => AlertDialog(
            backgroundColor: const Color(0xFFF4EEF8),
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
                    color: Color(0xFF6A4BC3),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF6A4BC3),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
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

  // Modal crear / editar
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

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFF8EEDA), Color(0xFFF2DFBF)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: Column(
        children: [
          Expanded(
            child: BlocBuilder<AdminCursosCubit, AdminCursosState>(
              builder: (_, state) {
                if (state is AdminCursosLoading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (state is AdminCursosLoaded) {
                  final cursos = state.cursos;

                  if (cursos.isEmpty) {
                    return const Center(child: Text("Sin datos"));
                  }

                  return ListView.separated(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: cursos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _itemCurso(context, cursos[i]),
                  );
                }

                return const Center(child: Text("Sin datos"));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => abrirModalCurso(context),
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  backgroundColor: const Color(0xFFFFA200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  "Agregar curso",
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _itemCurso(BuildContext context, CursoModel curso) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFBF5EA),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFFFA200),
                ),
                child: const Icon(Icons.menu_book, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      curso.nombre,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      curso.descripcion,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.black54,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        _chip("Orden ${curso.orden}"),
                        const SizedBox(width: 8),
                        _chip("ID ${curso.id}", color: const Color(0xFFE9ECF3)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  _circleBtn(
                    icon: Icons.edit,
                    color: const Color(0xFF6A7FDB),
                    onTap: () => abrirModalCurso(context, curso: curso),
                  ),
                  const SizedBox(height: 10),
                  _circleBtn(
                    icon: Icons.delete,
                    color: const Color(0xFFE57373),
                    onTap: () async {
                      final confirmar = await mostrarConfirmacionEliminar(context);
                      if (confirmar) {
                        context.read<AdminCursosCubit>().eliminarCurso(curso.id);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _chip(String text, {Color color = const Color(0xFFFFE4B8)}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: const TextStyle(
          color: Colors.black87,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _circleBtn(
      {required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        width: 34,
        decoration: BoxDecoration(
          color: color.withOpacity(0.16),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
