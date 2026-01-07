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
            backgroundColor: const Color.fromARGB(255, 255, 255, 255),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(26),
            ),
            title: const Text(
              'Confirmar eliminación',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.black,
              ),
            ),
            content: const Text(
              '¿Seguro que deseas eliminar este curso? Esta acción no se puede deshacer.',
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
                  'Cancelar',
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
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                    side: const BorderSide(
                      color: Color(0xFF6A4BC3),
                      width: 1.4,
                    ),
                  ),
                ),
                child: const Text(
                  'Eliminar',
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

  void abrirPantallaCurso(BuildContext context, {CursoModel? curso}) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CursoFormScreen(curso: curso),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
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
                    return const Center(child: Text('Sin datos'));
                  }

                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    itemCount: cursos.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _itemCurso(context, cursos[i]),
                  );
                }

                return const Center(child: Text('Sin datos'));
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 18),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton.icon(
                onPressed: () => abrirPantallaCurso(context),
                style: ElevatedButton.styleFrom(
                  elevation: 4,
                  backgroundColor: const Color(0xFFFFA200),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
                icon: const Icon(Icons.add, color: Colors.white),
                label: const Text(
                  'Agregar curso',
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
        color: const Color.fromARGB(255, 255, 255, 254),
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
                        _chip('Orden ${curso.orden}'),
                        const SizedBox(width: 8),
                        _chip('ID ${curso.id}', color: const Color(0xFFE9ECF3)),
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
                    onTap: () => abrirPantallaCurso(context, curso: curso),
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

  Widget _circleBtn({
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
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

class _CursoFormScreen extends StatefulWidget {
  final CursoModel? curso;

  const _CursoFormScreen({this.curso});

  @override
  State<_CursoFormScreen> createState() => _CursoFormScreenState();
}

class _CursoFormScreenState extends State<_CursoFormScreen> {
  late TextEditingController idCtrl;
  late TextEditingController nombreCtrl;
  late TextEditingController descripcionCtrl;
  late TextEditingController ordenCtrl;

  @override
  void initState() {
    super.initState();
    idCtrl = TextEditingController(text: widget.curso?.id ?? '');
    nombreCtrl = TextEditingController(text: widget.curso?.nombre ?? '');
    descripcionCtrl = TextEditingController(text: widget.curso?.descripcion ?? '');
    ordenCtrl = TextEditingController(text: widget.curso?.orden.toString() ?? '');
  }

  @override
  void dispose() {
    idCtrl.dispose();
    nombreCtrl.dispose();
    descripcionCtrl.dispose();
    ordenCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final esEdicion = widget.curso != null;

    return Scaffold(
      backgroundColor: const Color(0xFFFCF8F2),
      appBar: AppBar(
        backgroundColor: const Color(0xFF283347),
        foregroundColor: Colors.white,
        title: Text(esEdicion ? 'Editar curso' : 'Nuevo curso'),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Color(0xFFFCF8F2), Color(0xFFEFE3CF)],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2433),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.18),
                      blurRadius: 12,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      height: 54,
                      width: 54,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(Icons.menu_book, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            esEdicion ? 'Editar curso' : 'Crear nuevo curso',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            esEdicion
                                ? 'Actualiza la información del curso.'
                                : 'Completa los datos básicos para publicar el curso.',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.8),
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.black.withOpacity(0.05)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    TextField(
                      controller: idCtrl,
                      enabled: !esEdicion,
                      decoration: InputDecoration(
                        labelText: 'ID (ej: estr_repe)',
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: nombreCtrl,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: true,
                      enableSuggestions: true,
                      decoration: InputDecoration(
                        labelText: 'Nombre',
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: descripcionCtrl,
                      keyboardType: TextInputType.text,
                      textCapitalization: TextCapitalization.sentences,
                      autocorrect: true,
                      enableSuggestions: true,
                      decoration: InputDecoration(
                        labelText: 'Descripción',
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
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
                        labelText: 'Orden (no repetir)',
                        filled: true,
                        fillColor: const Color(0xFFF5F6FA),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFF283347)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Cancelar',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFFFA200),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      onPressed: () {
                        final id = idCtrl.text.trim();
                        final nombre = nombreCtrl.text.trim();
                        if (id.isEmpty || nombre.isEmpty) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Completa los campos obligatorios.')),
                          );
                          return;
                        }

                        final repo = context.read<AdminCursosCubit>();
                        int orden = int.tryParse(ordenCtrl.text.trim()) ?? -1;
                        final existentes = (repo.state is AdminCursosLoaded)
                            ? (repo.state as AdminCursosLoaded).cursos
                            : <CursoModel>[];

                        final usados = existentes
                            .where((c) => !esEdicion || c.id != id)
                            .map((c) => c.orden)
                            .toSet();
                        while (orden <= 0 || usados.contains(orden)) {
                          orden++;
                        }

                        final nuevo = CursoModel(
                          id: id,
                          nombre: nombre,
                          descripcion: descripcionCtrl.text.trim(),
                          orden: orden,
                        );

                        if (esEdicion) {
                          repo.editarCurso(nuevo);
                        } else {
                          repo.crearCurso(nuevo);
                        }

                        Navigator.pop(context);
                      },
                      child: Text(
                        esEdicion ? 'Guardar cambios' : 'Crear curso',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
