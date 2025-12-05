// lib/blocs/admin_preguntas/admin_preguntas_state.dart
import '../../data/models/pregunta_model.dart';

abstract class AdminPreguntasState {}

class AdminPreguntasLoading extends AdminPreguntasState {}

class AdminPreguntasLoaded extends AdminPreguntasState {
  final List<Pregunta> preguntas;
  AdminPreguntasLoaded(this.preguntas);
}

class AdminPreguntasError extends AdminPreguntasState {
  final String message;
  AdminPreguntasError(this.message);
}
