import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';

DateTime? _w(dynamic v) => v is Timestamp ? v.toDate() : null;

/// Satu dokumen di koleksi `pesanan_sketsa`.
class PesananSketsa {
  final String id;
  final String userId;
  final String userNama;
  final String arsitekId;
  final String arsitekNama;

  // Data lahan
  final int luasLahan;
  final String panjang;
  final String lebar;
  final String kota;
  final String arahHadap;
  final String kontur;
  final String kondisiLahan;

  // Kebutuhan bangunan
  final String jenisBangunan;
  final int jumlahLantai;
  final String luasBangunan;
  final int kamarTidur;
  final int kamarMandi;
  final int penghuni;
  final List<String> ruangTambahan;
  final List<String> material;
  final List<String> kebutuhanKhusus;

  // Gaya & catatan
  final String gaya;
  final String palet;
  final String budget;
  final String referensi;
  final String catatan;
  final List<String> lampiran; // base64

  // Pembayaran & status
  final int harga;
  final String status;
  final String alasanTolak;
  final String alasanBatal;
  final String bukti; // base64 bukti transfer
  final DateTime? batasBayar;
  final DateTime? createdAt;

  // Hasil
  final String hasilNama;
  final int hasilUkuran;
  final int hasilBagian;
  final DateTime? hasilAt;

  // Revisi & permintaan data
  final bool butuhData; // arsitek minta klien melengkapi data
  final String alasanMinta;
  final String dataPerbaikan;
  final int revisiDipakai; // 0 atau 1 (jatah revisi gratis: 1x)
  final String alasanRevisi;

  const PesananSketsa({
    required this.id,
    required this.userId,
    required this.userNama,
    required this.arsitekId,
    required this.arsitekNama,
    required this.luasLahan,
    required this.harga,
    required this.status,
    this.panjang = '',
    this.lebar = '',
    this.kota = '',
    this.arahHadap = '',
    this.kontur = '',
    this.kondisiLahan = '',
    this.jenisBangunan = '',
    this.jumlahLantai = 1,
    this.luasBangunan = '',
    this.kamarTidur = 0,
    this.kamarMandi = 0,
    this.penghuni = 0,
    this.ruangTambahan = const [],
    this.material = const [],
    this.kebutuhanKhusus = const [],
    this.gaya = '',
    this.palet = '',
    this.budget = '',
    this.referensi = '',
    this.catatan = '',
    this.lampiran = const [],
    this.alasanTolak = '',
    this.alasanBatal = '',
    this.bukti = '',
    this.batasBayar,
    this.createdAt,
    this.hasilNama = '',
    this.hasilUkuran = 0,
    this.hasilBagian = 0,
    this.hasilAt,
    this.butuhData = false,
    this.alasanMinta = '',
    this.dataPerbaikan = '',
    this.revisiDipakai = 0,
    this.alasanRevisi = '',
  });

  bool get adaHasil => hasilBagian > 0;

  factory PesananSketsa.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    String s(String k) => m[k] as String? ?? '';
    int n(String k, [int def = 0]) => (m[k] as num?)?.toInt() ?? def;
    List<String> l(String k) =>
        (m[k] as List?)?.map((e) => e.toString()).toList() ?? const [];
    return PesananSketsa(
      id: d.id,
      userId: s('userId'),
      userNama: s('userNama'),
      arsitekId: s('arsitekId'),
      arsitekNama: s('arsitekNama'),
      luasLahan: n('luasLahan'),
      harga: n('harga'),
      status: m['status'] as String? ?? StatusSketsa.menungguPembayaran,
      panjang: s('panjang'),
      lebar: s('lebar'),
      kota: s('kota'),
      arahHadap: s('arahHadap'),
      kontur: s('kontur'),
      kondisiLahan: s('kondisiLahan'),
      jenisBangunan: s('jenisBangunan'),
      jumlahLantai: n('jumlahLantai', 1),
      luasBangunan: s('luasBangunan'),
      kamarTidur: n('kamarTidur'),
      kamarMandi: n('kamarMandi'),
      penghuni: n('penghuni'),
      ruangTambahan: l('ruangTambahan'),
      material: l('material'),
      kebutuhanKhusus: l('kebutuhanKhusus'),
      gaya: s('gaya'),
      palet: s('palet'),
      budget: s('budget'),
      referensi: s('referensi'),
      catatan: s('catatan'),
      lampiran: l('lampiran'),
      alasanTolak: s('alasanTolak'),
      alasanBatal: s('alasanBatal'),
      bukti: s('buktiBayar'),
      batasBayar: _w(m['batasBayar']),
      createdAt: _w(m['createdAt']),
      hasilNama: s('hasilNama'),
      hasilUkuran: n('hasilUkuran'),
      hasilBagian: n('hasilBagian'),
      hasilAt: _w(m['hasilAt']),
      butuhData: m['butuhData'] == true,
      alasanMinta: s('alasanMinta'),
      dataPerbaikan: s('dataPerbaikan'),
      revisiDipakai: n('revisiDipakai'),
      alasanRevisi: s('alasanRevisi'),
    );
  }
}
