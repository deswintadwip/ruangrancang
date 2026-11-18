import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';

/// Promo konsultasi gratis untuk pengguna baru.
/// Berhak kalau: (1) belum pernah memakai promo, dan (2) riwayat
/// konsultasinya masih kosong. Sketsa / rumah / vendor tidak dihitung.
class PromoService {
  PromoService._();

  /// Live: true selama user berhak konsultasi gratis.
  static Stream<bool> berhakKonsultasiGratis() async* {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      yield false;
      return;
    }
    try {
      final u = await FirebaseFirestore.instance
          .collection(Koleksi.users)
          .doc(uid)
          .get();
      if ((u.data() ?? {})['promoKonsultasiTerpakai'] == true) {
        yield false;
        return;
      }
    } catch (_) {
      yield false;
      return;
    }
    yield* FirebaseFirestore.instance
        .collection(Koleksi.konsultasi)
        .where('userId', isEqualTo: uid)
        .limit(1)
        .snapshots()
        .map((s) => s.docs.isEmpty)
        .handleError((_) => false);
  }
}
