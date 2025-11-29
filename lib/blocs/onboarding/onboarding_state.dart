class OnboardingState {
  final String nombre;
  final int? edad;

  OnboardingState({
    this.nombre = "",
    this.edad,
  });

  OnboardingState copyWith({
    String? nombre,
    int? edad,
  }) {
    return OnboardingState(
      nombre: nombre ?? this.nombre,
      edad: edad ?? this.edad,
    );
    }
}
