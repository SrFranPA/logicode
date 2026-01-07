import 'package:cloud_firestore/cloud_firestore.dart';

class AppConfigService {
  static const String _configDocPath = 'config/app';

  final FirebaseFirestore _db;

  AppConfigService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  /// Observa el flag global para ocultar la nota del pretest/diagnostico.
  Stream<bool> watchOcultarNotaPretest() {
    return _db.doc(_configDocPath).snapshots().map((snapshot) {
      final data = snapshot.data();
      if (data == null) return false;
      return data['ocultar_nota_pretest'] == true;
    });
  }

  /// Guarda el flag para ocultar o mostrar la nota del pretest/diagnostico.
  Future<void> setOcultarNotaPretest(bool ocultar) {
    return _db.doc(_configDocPath).set(
      {
        'ocultar_nota_pretest': ocultar,
      },
      SetOptions(merge: true),
    );
  }
}
