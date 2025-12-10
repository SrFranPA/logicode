import 'pregunta_model.dart';
import 'tipos_preguntas/sort_data.dart';
import 'tipos_preguntas/chip_select_data.dart';
import 'tipos_preguntas/fill_blank_data.dart';

class PreguntaParser {
  static dynamic parse(Pregunta p) {
    final json = p.decodeArchivo();

    switch (p.tipo) {
      case "ordenar":
        return OrdenarData.fromJson(json);

      case "chip_select":
        return ChipSelectData.fromJson(json);

      case "completa_espacio":
        return FillBlankData.fromJson(json);

      default:
        throw "Tipo no soportado: ${p.tipo}";
    }
  }
}
