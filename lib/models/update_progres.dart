import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu catatan progres di `konsultasi/{id}/update`.
class UpdateProgres {
  final String id;
  final int tahap; // 1-5, lihat TahapKerja
  final String catatan;
  final DateTime? createdAt;

  const UpdateProgres({
    required this.id,
    required this.tahap,
    required this.catatan,
    this.createdAt,
  });

  factory UpdateProgres.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final t = m['createdAt'];
    return UpdateProgres(
      id: d.id,
      tahap: (m['tahap'] as num?)?.toInt() ?? 1,
      catatan: m['catatan'] as String? ?? '',
      // Sesaat setelah ditulis, serverTimestamp masih null di perangkat sendiri.
      createdAt: t is Timestamp ? t.toDate() : DateTime.now(),
    );
  }
}