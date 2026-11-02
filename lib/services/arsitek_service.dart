import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';

class ArsitekService {
  ArsitekService._();

  /// ID yang dipakai di field `arsitekId` pada konsultasi milik arsitek ini.
  /// Selalu berisi UID akun. Kalau dokumen `arsitek/{uid}` punya field
  /// `profilId` (misalnya "arsitek_01", ID dari data contoh), itu ikut
  /// dimasukkan. Jembatan sementara sampai daftar arsitek pindah ke Firestore.
  static Future<List<String>> idSaya() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return [];
    final ids = <String>[uid];
    try {
      final d = await FirebaseFirestore.instance
          .collection(Koleksi.arsitek)
          .doc(uid)
          .get();
      final p = d.data()?['profilId'];
      if (p is String && p.isNotEmpty && p != uid) ids.add(p);
    } catch (_) {}
    return ids;
  }
}