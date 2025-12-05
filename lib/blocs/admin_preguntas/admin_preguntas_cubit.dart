// lib/blocs/admin_preguntas/admin_preguntas_cubit.dart
import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../data/models/pregunta_model.dart';
import '../../data/repositories/pregunta_repository.dart';
import 'admin_preguntas_state.dart';

class AdminPreguntasCubit extends Cubit<AdminPreguntasState> {
  final PreguntaRepository repo;
  StreamSubscription<List<Pregunta>>? _sub;

  AdminPreguntasCubit(this.repo) : super(AdminPreguntasLoading()) {
    _sub = repo.watchPreguntas().listen(
      (preguntas) {
        emit(AdminPreguntasLoaded(preguntas));
      },
      onError: (e) => emit(AdminPreguntasError(e.toString())),
    );
  }

  Future<String?> crearPregunta({
    required String cursoId,
    required String tipo,
    required String dificultad,
  }) async {
    try {
      final id = await repo.createPregunta(
        cursoId: cursoId,
        tipo: tipo,
        dificultad: dificultad,
      );
      return id;
    } catch (e) {
      emit(AdminPreguntasError('Error creando pregunta: $e'));
      return null;
    }
  }

  Future<void> eliminarPregunta(String id) async {
    try {
      await repo.deletePregunta(id);
    } catch (e) {
      emit(AdminPreguntasError('Error eliminando pregunta: $e'));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
