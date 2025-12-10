class ChipSelectData {
  final List<String> opciones;
  final String correcta;
  final String retro;

  ChipSelectData({
    required this.opciones,
    required this.correcta,
    required this.retro,
  });

  factory ChipSelectData.fromJson(Map<String, dynamic> json) {
    return ChipSelectData(
      opciones: List<String>.from(json["opciones"] ?? []),
      correcta: json["respuesta_correcta"] ?? "",
      retro: json["feedback"] ?? "",
    );
  }
}
