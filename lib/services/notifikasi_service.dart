import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../models/notifikasi.dart';

class NotifikasiService {
  NotifikasiService._();

  static final _col = FirebaseFirestore.instance.collection(Koleksi.notifikasi);

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Notifikasi milik user yang login, terbaru di atas (diurutkan di aplikasi
  /// supaya tidak butuh index Firestore).
  static Stream<List<Notifikasi>> milikSaya() {
    final uid = _uid;
    if (uid == null) return Stream.value(const []);
    return _col.where('userId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(Notifikasi.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Jumlah yang belum dibaca (untuk titik merah di lonceng).
  static Stream<int> jumlahBelumDibaca() =>
      milikSaya().map((l) => l.where((n) => !n.isRead).length);

  static Future<void> tandaiDibaca(String id) =>
      _col.doc(id).update({'isRead': true});

  static Future<void> tandaiSemuaDibaca(List<Notifikasi> daftar) {
    final batch = FirebaseFirestore.instance.batch();
    for (final n in daftar.where((n) => !n.isRead)) {
      batch.update(_col.doc(n.id), {'isRead': true});
    }
    return batch.commit();
  }

  /// Kirim notifikasi ke user tertentu. Dipanggil dari aksi lain
  /// (booking, pembatalan, update arsitek, verifikasi admin, dst.).
  /// Kegagalan menulis notifikasi tidak boleh menggagalkan aksi utama.
  static Future<void> kirim({
    required String userId,
    required String type,
    required String refId,
    required String judul,
    required String isi,
  }) async {
    try {
      await _col.add({
        'userId': userId,
        'type': type,
        'refId': refId,
        'judul': judul,
        'isi': isi,
        'isRead': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (_) {}
  }

  /// Notifikasi untuk diri sendiri (akun yang sedang login).
  static Future<void> kirimKeSaya({
    required String type,
    required String refId,
    required String judul,
    required String isi,
  }) async {
    final uid = _uid;
    if (uid == null) return;
    await kirim(userId: uid, type: type, refId: refId, judul: judul, isi: isi);
  }
}