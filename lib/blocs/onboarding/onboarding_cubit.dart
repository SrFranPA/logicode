import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  /// 👉 Valores que el usuario ingresa en el flujo inicial
  String nombre = "";
  int edad = 0;

  OnboardingCubit() : super(OnboardingInitial());

  /// -------------------------
  /// GUARDAR NOMBRE
  /// -------------------------
  void setNombre(String value) {
    nombre = value;
    emit(OnboardingUpdated(nombre, edad));
  }

  /// -------------------------
  /// GUARDAR EDAD
  /// -------------------------
  void setEdad(int value) {
    edad = value;
    emit(OnboardingUpdated(nombre, edad));
  }
}
