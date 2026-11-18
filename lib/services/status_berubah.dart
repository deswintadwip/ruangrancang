import 'package:cloud_firestore/cloud_firestore.dart';

/// Dilempar kalau status dokumen sudah berbeda dari yang diharapkan
/// (misalnya admin menyetujui pesanan yang baru saja dibatalkan user).
class StatusBerubah implements Exception {
  final String sekarang;
  StatusBerubah(this.sekarang);

  @override
  String toString() =>
      'Pesanan sudah berubah (status sekarang: $sekarang). '
      'Muat ulang lalu coba lagi.';
}

typedef DocSnap = DocumentSnapshot<Map<String, dynamic>>;

/// Ubah dokumen HANYA kalau status terbarunya (dibaca di dalam transaksi)
/// termasuk [dari]. Kalau tidak, dilempar [StatusBerubah] dan tidak ada
/// yang ditulis. [hapus] opsional: dokumen lain yang ikut dihapus
/// (misalnya slot jadwal).
Future<DocSnap> ubahBilaStatus(
  DocumentReference<Map<String, dynamic>> ref, {
  required List<String> dari,
  required Map<String, dynamic> Function(DocSnap d) ubah,
  List<DocumentReference> Function(DocSnap d)? hapus,
}) {
  return FirebaseFirestore.instance.runTransaction((tx) async {
    final snap = await tx.get(ref);
    if (!snap.exists) throw StatusBerubah('tidak ditemukan');
    final status = (snap.data() ?? {})['status'] as String? ?? '';
    if (!dari.contains(status)) throw StatusBerubah(status);
    final data = ubah(snap);
    final lain = hapus == null ? const <DocumentReference>[] : hapus(snap);
    tx.update(ref, data);
    for (final h in lain) {
      tx.delete(h);
    }
    return snap;
  });
}
