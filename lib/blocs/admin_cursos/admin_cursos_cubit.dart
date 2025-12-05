// lib/blocs/admin_cursos/admin_cursos_cubit.dart

import 'package:flutter_bloc/flutter_bloc.dart';
import '../../data/repositories/curso_repository.dart';
import '../../data/models/curso_model.dart';

part 'admin_cursos_state.dart';

class AdminCursosCubit extends Cubit<AdminCursosState> {
  final CursoRepository repo;

  AdminCursosCubit(this.repo) : super(AdminCursosInitial()) {
    _init();
  }

  void _init() {
    emit(AdminCursosLoading());
    repo.watchCursos().listen((cursos) {
      emit(AdminCursosLoaded(cursos));
    });
  }

  Future<void> crearCurso(CursoModel curso) async {
    try {
      await repo.createCurso(curso);
    } catch (e) {
      emit(AdminCursosError(e.toString()));
    }
  }

  Future<void> editarCurso(CursoModel curso) async {
    try {
      await repo.updateCurso(curso);
    } catch (e) {
      emit(AdminCursosError(e.toString()));
    }
  }

  Future<void> eliminarCurso(String id) async {
    try {
      await repo.deleteCurso(id);
    } catch (e) {
      emit(AdminCursosError(e.toString()));
    }
  }
}
