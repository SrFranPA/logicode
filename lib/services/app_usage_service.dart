import 'package:cloud_firestore/cloud_firestore.dart';

class AppUsageService {
  AppUsageService({FirebaseFirestore? db}) : _db = db ?? FirebaseFirestore.instance;

  final FirebaseFirestore _db;

  Future<void> logDailyUsage(String uid) async {
    if (uid.isEmpty) return;
    final now = DateTime.now();
    final todayKey = _dayKey(now);
    final dayStart = DateTime(now.year, now.month, now.day);
    final userRef = _db.collection('usuarios').doc(uid);
    final usageRef = _db.collection('uso_app').doc(todayKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(userRef);
      final data = snap.data() ?? {};
      final lastDay = (data['ultima_actividad_dia'] ?? '').toString();

      if (lastDay != todayKey) {
        tx.set(
          usageRef,
          {
            'fecha': Timestamp.fromDate(dayStart),
            'conteo': FieldValue.increment(1),
          },
          SetOptions(merge: true),
        );
      }

      tx.set(
        userRef,
        {
          'ultima_actividad': Timestamp.fromDate(now),
          'ultima_actividad_dia': todayKey,
        },
        SetOptions(merge: true),
      );
    });
  }

  String _dayKey(DateTime date) {
    final y = date.year.toString().padLeft(4, '0');
    final m = date.month.toString().padLeft(2, '0');
    final d = date.day.toString().padLeft(2, '0');
    return '$y-$m-$d';
  }
}
