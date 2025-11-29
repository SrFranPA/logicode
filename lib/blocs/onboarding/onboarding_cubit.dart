import 'package:flutter_bloc/flutter_bloc.dart';
import 'onboarding_state.dart';

class OnboardingCubit extends Cubit<OnboardingState> {
  OnboardingCubit() : super(OnboardingState());

  void setNombre(String nombre) {
    emit(state.copyWith(nombre: nombre));
  }

  void setEdad(int edad) {
    emit(state.copyWith(edad: edad));
  }
}
