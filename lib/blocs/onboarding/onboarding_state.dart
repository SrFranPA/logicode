abstract class OnboardingState {}

class OnboardingInitial extends OnboardingState {}

class OnboardingUpdated extends OnboardingState {
  final String nombre;
  final int edad;

  OnboardingUpdated(this.nombre, this.edad);
}
