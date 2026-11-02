import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../models/konsultasi.dart';
import '../models/ulasan_klien.dart';

class UlasanService {
  UlasanService._();

  static final _col = FirebaseFirestore.instance.collection(Koleksi.ulasan);

  /// Semua ulasan satu arsitek, terbaru di atas (live).
  static Stream<List<UlasanKlien>> untukArsitek(String arsitekId) {
    return _col.where('arsitekId', isEqualTo: arsitekId).snapshots().map((s) {
      final list = s.docs.map(UlasanKlien.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// ID konsultasi yang sudah saya ulas.
  static Stream<Set<String>> idDiulasSaya() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(<String>{});
    return _col
        .where('userId', isEqualTo: uid)
        .snapshots()
        .map((s) => s.docs.map((d) => d.id).toSet());
  }

  /// Apakah konsultasi ini sudah diulas.
  static Stream<bool> sudahDiulas(String konsultasiId) =>
      _col.doc(konsultasiId).snapshots().map((d) => d.exists);

  /// Kirim ulasan. ID dokumen = ID konsultasi, jadi maksimal satu per
  /// konsultasi, dan Firestore rules memastikan sesinya sudah selesai.
  static Future<void> kirim(Konsultasi k, int bintang, String isi) {
    return _col.doc(k.id).set({
      'konsultasiId': k.id,
      'userId': k.userId,
      'userNama': k.userNama,
      'arsitekId': k.arsitekId,
      'bintang': bintang,
      'isi': isi.trim(),
      'createdAt': FieldValue.serverTimestamp(),
    });
  }
}