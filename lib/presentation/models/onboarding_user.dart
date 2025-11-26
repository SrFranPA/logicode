class OnboardingUser {
  final String nombre;
  final int edad;
  final String? telefono;

  OnboardingUser({
    required this.nombre,
    required this.edad,
    this.telefono,
  });

  Map<String, dynamic> toMap() {
    return {
      'nombre': nombre,
      'edad': edad,
      'telefono': telefono,
    };
  }
}
