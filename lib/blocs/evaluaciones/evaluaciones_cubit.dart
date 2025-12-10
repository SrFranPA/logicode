import 'package:bloc/bloc.dart';
import 'evaluaciones_state.dart';
import '../../data/repositories/evaluaciones_repository.dart';

class EvaluacionesCubit extends Cubit<EvaluacionesState> {
  final EvaluacionesRepository _repo;

  EvaluacionesCubit(this._repo) : super(EvaluacionesInitial());

  Future<void> registrarResultado({
    required String uid,
    required String tipo, // 'pre' | 'post'
    required int puntajeObtenido,
    required int puntajeMinimo,
    required int puntajeMaximo,
    required int numPreguntas,
    required List<String> bancoPreguntasIds,
    Map<String, dynamic>? detalle,
  }) async {
    emit(EvaluacionEnviando());
    try {
      await _repo.registrarEvaluacion(
        uid: uid,
        tipo: tipo,
        puntajeObtenido: puntajeObtenido,
        puntajeMinimo: puntajeMinimo,
        puntajeMaximo: puntajeMaximo,
        numPreguntas: numPreguntas,
        bancoPreguntasIds: bancoPreguntasIds,
        detalle: detalle,
      );
      emit(EvaluacionEnviada());
    } catch (e) {
      emit(EvaluacionError(e.toString()));
    }
  }

  void reset() => emit(EvaluacionesInitial());
}
