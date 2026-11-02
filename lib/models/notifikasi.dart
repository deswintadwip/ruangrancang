import 'package:cloud_firestore/cloud_firestore.dart';

/// Satu dokumen di koleksi `notifikasi`.
/// type: booking | pembayaran | pengingat | progres | hasil | selesai |
///       ulasan | refund | batal
/// refId: ID konsultasi yang terkait (untuk tujuan saat diketuk).
class Notifikasi {
  final String id;
  final String userId;
  final String type;
  final String refId;
  final String judul;
  final String isi;
  final bool isRead;
  final DateTime? createdAt;

  const Notifikasi({
    required this.id,
    required this.userId,
    required this.type,
    required this.refId,
    required this.judul,
    required this.isi,
    required this.isRead,
    this.createdAt,
  });

  factory Notifikasi.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final t = m['createdAt'];
    return Notifikasi(
      id: d.id,
      userId: m['userId'] as String? ?? '',
      type: m['type'] as String? ?? '',
      refId: m['refId'] as String? ?? '',
      judul: m['judul'] as String? ?? '',
      isi: m['isi'] as String? ?? '',
      isRead: m['isRead'] as bool? ?? false,
      createdAt: t is Timestamp ? t.toDate() : null,
    );
  }
}