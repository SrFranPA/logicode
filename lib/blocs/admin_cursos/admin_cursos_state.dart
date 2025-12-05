// lib/blocs/admin_cursos/admin_cursos_state.dart

part of 'admin_cursos_cubit.dart';

abstract class AdminCursosState {}

class AdminCursosInitial extends AdminCursosState {}

class AdminCursosLoading extends AdminCursosState {}

class AdminCursosLoaded extends AdminCursosState {
  final List<CursoModel> cursos;
  AdminCursosLoaded(this.cursos);
}

class AdminCursosError extends AdminCursosState {
  final String error;
  AdminCursosError(this.error);
}
