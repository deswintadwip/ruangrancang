import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';

DateTime? _w(dynamic v) => v is Timestamp ? v.toDate() : null;

/// Satu dokumen di koleksi `permintaan_vendor`.
/// Field wajib kesepakatan kelompok: userNama, jenisPekerjaan, status, createdAt.
class PermintaanVendor {
  final String id;
  final String userId;
  final String userNama;
  final String userWa;
  final String jenisPekerjaan;
  final String kota;
  final String anggaran;
  final String rencanaMulai;
  final String deskripsi;
  final String linkDesain;
  final String vendorDipilih; // id vendor yang dibuka user (usulan)
  final String vendorNamaDipilih;
  final String vendorId; // diisi admin saat meneruskan
  final String vendorNama;
  final String status; // StatusPermintaanVendor
  final String catatanAdmin;
  final DateTime? createdAt;
  final DateTime? diteruskanAt;
  final DateTime? dihubungiAt;
  final DateTime? selesaiAt;

  const PermintaanVendor({
    required this.id,
    required this.userId,
    required this.userNama,
    required this.jenisPekerjaan,
    required this.status,
    this.userWa = '',
    this.kota = '',
    this.anggaran = '',
    this.rencanaMulai = '',
    this.deskripsi = '',
    this.linkDesain = '',
    this.vendorDipilih = '',
    this.vendorNamaDipilih = '',
    this.vendorId = '',
    this.vendorNama = '',
    this.catatanAdmin = '',
    this.createdAt,
    this.diteruskanAt,
    this.dihubungiAt,
    this.selesaiAt,
  });

  bool get aktif => status != StatusPermintaanVendor.selesai;

  /// Nama vendor yang ditampilkan ke user.
  String get namaVendorTampil {
    if (vendorNama.isNotEmpty) return vendorNama;
    if (vendorNamaDipilih.isNotEmpty) return '$vendorNamaDipilih (usulanmu)';
    return 'Admin akan memilihkan vendor';
  }

  factory PermintaanVendor.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    String s(String k) => m[k] as String? ?? '';
    return PermintaanVendor(
      id: d.id,
      userId: s('userId'),
      userNama: s('userNama'),
      userWa: s('userWa'),
      jenisPekerjaan: s('jenisPekerjaan'),
      kota: s('kota'),
      anggaran: s('anggaran'),
      rencanaMulai: s('rencanaMulai'),
      deskripsi: s('deskripsi'),
      linkDesain: s('linkDesain'),
      vendorDipilih: s('vendorDipilih'),
      vendorNamaDipilih: s('vendorNamaDipilih'),
      vendorId: s('vendorId'),
      vendorNama: s('vendorNama'),
      status: m['status'] as String? ?? StatusPermintaanVendor.baru,
      catatanAdmin: s('catatanAdmin'),
      createdAt: m.containsKey('createdAt')
          ? (_w(m['createdAt']) ?? DateTime.now())
          : null,
      diteruskanAt: _w(m['diteruskanAt']),
      dihubungiAt: _w(m['dihubungiAt']),
      selesaiAt: _w(m['selesaiAt']),
    );
  }
}
