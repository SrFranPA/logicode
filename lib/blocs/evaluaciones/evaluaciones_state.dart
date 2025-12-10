import 'package:equatable/equatable.dart';

abstract class EvaluacionesState extends Equatable {
  const EvaluacionesState();

  @override
  List<Object?> get props => [];
}

class EvaluacionesInitial extends EvaluacionesState {}

class EvaluacionEnviando extends EvaluacionesState {}

class EvaluacionEnviada extends EvaluacionesState {}

class EvaluacionError extends EvaluacionesState {
  final String message;

  const EvaluacionError(this.message);

  @override
  List<Object?> get props => [message];
}
