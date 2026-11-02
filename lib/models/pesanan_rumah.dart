import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';

DateTime? _w(dynamic v) => v is Timestamp ? v.toDate() : null;

/// Satu dokumen di koleksi `pesanan_rumah`.
/// Field wajib kesepakatan kelompok: userNama, perumahanNama, bookingFee,
/// status, createdAt.
class PesananRumah {
  final String id;
  final String userId;
  final String userNama;
  final String perumahanId;
  final String perumahanNama;
  final String kota;
  final String tipe;
  final int hargaUnit;
  final int bookingFee;
  final String status; // StatusPesananRumah
  final String alasanTolak; // diisi admin saat menolak
  final String alasanBatal;
  final DateTime? batasBayar;
  final DateTime? createdAt;

  const PesananRumah({
    required this.id,
    required this.userId,
    required this.userNama,
    required this.perumahanId,
    required this.perumahanNama,
    required this.bookingFee,
    required this.status,
    this.kota = '',
    this.tipe = '',
    this.hargaUnit = 0,
    this.alasanTolak = '',
    this.alasanBatal = '',
    this.batasBayar,
    this.createdAt,
  });

  bool get aktif =>
      status == StatusPesananRumah.menungguPembayaran ||
      status == StatusPesananRumah.menungguVerifikasi;

  factory PesananRumah.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    String s(String k) => m[k] as String? ?? '';
    return PesananRumah(
      id: d.id,
      userId: s('userId'),
      userNama: s('userNama'),
      perumahanId: s('perumahanId'),
      perumahanNama: s('perumahanNama'),
      kota: s('kota'),
      tipe: s('tipe'),
      hargaUnit: (m['hargaUnit'] as num?)?.toInt() ?? 0,
      bookingFee: (m['bookingFee'] as num?)?.toInt() ?? 0,
      status: m['status'] as String? ?? StatusPesananRumah.menungguPembayaran,
      alasanTolak: s('alasanTolak'),
      alasanBatal: s('alasanBatal'),
      batasBayar: _w(m['batasBayar']),
      createdAt: m.containsKey('createdAt')
          ? (_w(m['createdAt']) ?? DateTime.now())
          : null,
    );
  }
}
