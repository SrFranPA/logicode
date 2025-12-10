class OrdenarData {
  final List<String> elementos;
  final String retro;

  OrdenarData({
    required this.elementos,
    required this.retro,
  });

  factory OrdenarData.fromJson(Map<String, dynamic> json) {
    return OrdenarData(
      elementos: List<String>.from(json["elementos"] ?? []),
      retro: json["retroalimentacion"] ?? "",
    );
  }
}
