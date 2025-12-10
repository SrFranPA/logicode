class FillBlankData {
  final List<String> blanks;
  final String retro;

  FillBlankData({
    required this.blanks,
    required this.retro,
  });

  factory FillBlankData.fromJson(Map<String, dynamic> json) {
    return FillBlankData(
      blanks: List<String>.from(json["blanks"] ?? []),
      retro: json["retroalimentacion"] ?? "",
    );
  }
}
