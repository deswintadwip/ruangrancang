import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';

/// Satu dokumen di koleksi `konsultasi`.
/// Field wajib untuk Dashboard Admin: userNama, tanggal, jam, harga, status, createdAt.
class Konsultasi {
  final String id;
  final String userId;
  final String userNama;
  final String arsitekId;
  final String arsitekNama;
  final String spesialis;
  final String tanggal; // "2026-10-28"
  final String jam; // jam mulai, "09:00"
  final String jamSelesai; // "11:00"
  final String metode; // 'online' | 'studio'
  final int harga;
  final String status; // lihat StatusKonsultasi
  final String luas; // m², dari form proyek
  final String budget;
  final String gaya;
  final String catatan;
  final int jadwalUlang; // berapa kali sudah jadwal ulang
  final String dibatalkanOleh; // 'user' | 'arsitek' | 'sistem'
  final String alasanBatal;
  final String alasanTolak; // alasan admin meminta unggah ulang / menolak bukti
  final int refundPersen;
  final int refundNominal;
  final String refundStatus; // 'tidak_ada' | 'diproses' | 'selesai'
  final String refundBank;
  final String refundRekening;
  final String refundAtasNama;
  final int tahap; // 0 = belum diatur, 1-5 lihat TahapKerja
  final DateTime? updatedAt; // update progres terakhir dari arsitek
  final String? meetLink;
  final DateTime? batasBayar;
  final DateTime? createdAt;

  const Konsultasi({
    required this.id,
    required this.userId,
    required this.userNama,
    required this.arsitekId,
    required this.arsitekNama,
    required this.spesialis,
    required this.tanggal,
    required this.jam,
    required this.jamSelesai,
    required this.metode,
    required this.harga,
    required this.status,
    this.luas = '',
    this.budget = '',
    this.gaya = '',
    this.catatan = '',
    this.jadwalUlang = 0,
    this.dibatalkanOleh = '',
    this.alasanBatal = '',
    this.alasanTolak = '',
    this.refundPersen = 0,
    this.refundNominal = 0,
    this.refundStatus = '',
    this.refundBank = '',
    this.refundRekening = '',
    this.refundAtasNama = '',
    this.tahap = 0,
    this.updatedAt,
    this.meetLink,
    this.batasBayar,
    this.createdAt,
  });

  factory Konsultasi.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    DateTime? waktu(dynamic v) => v is Timestamp ? v.toDate() : null;
    return Konsultasi(
      id: d.id,
      userId: m['userId'] as String? ?? '',
      userNama: m['userNama'] as String? ?? '',
      arsitekId: m['arsitekId'] as String? ?? '',
      arsitekNama: m['arsitekNama'] as String? ?? '',
      spesialis: m['spesialis'] as String? ?? '',
      tanggal: m['tanggal'] as String? ?? '',
      jam: m['jam'] as String? ?? '',
      jamSelesai: m['jamSelesai'] as String? ?? '',
      metode: m['metode'] as String? ?? 'online',
      harga: (m['harga'] as num?)?.toInt() ?? 0,
      status: m['status'] as String? ?? StatusKonsultasi.menungguPembayaran,
      luas: m['luas'] as String? ?? '',
      budget: m['budget'] as String? ?? '',
      gaya: m['gaya'] as String? ?? '',
      catatan: m['catatan'] as String? ?? '',
      jadwalUlang: (m['jadwalUlang'] as num?)?.toInt() ?? 0,
      dibatalkanOleh: m['dibatalkanOleh'] as String? ?? '',
      alasanBatal: m['alasanBatal'] as String? ?? '',
      alasanTolak: m['alasanTolak'] as String? ?? '',
      refundPersen: (m['refundPersen'] as num?)?.toInt() ?? 0,
      refundNominal: (m['refundNominal'] as num?)?.toInt() ?? 0,
      refundStatus: m['refundStatus'] as String? ?? '',
      refundBank: m['refundBank'] as String? ?? '',
      refundRekening: m['refundRekening'] as String? ?? '',
      refundAtasNama: m['refundAtasNama'] as String? ?? '',
      tahap: (m['tahap'] as num?)?.toInt() ?? 0,
      updatedAt: waktu(m['updatedAt']),
      meetLink: m['meetLink'] as String?,
      batasBayar: waktu(m['batasBayar']),
      createdAt: waktu(m['createdAt']),
    );
  }

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'userNama': userNama,
    'arsitekId': arsitekId,
    'arsitekNama': arsitekNama,
    'spesialis': spesialis,
    'tanggal': tanggal,
    'jam': jam,
    'jamSelesai': jamSelesai,
    'metode': metode,
    'harga': harga,
    'status': status,
    'luas': luas,
    'budget': budget,
    'gaya': gaya,
    'catatan': catatan,
    'syaratDisetujui': true,
    'jadwalUlang': 0,
    'meetLink': meetLink,
    'batasBayar':
    batasBayar == null ? null : Timestamp.fromDate(batasBayar!),
    'createdAt': FieldValue.serverTimestamp(),
  };

  /// Waktu mulai sesi (gabungan tanggal + jam).
  DateTime? get mulai => DateTime.tryParse('$tanggal $jam:00');

  bool get online => metode == 'online';

  /// Nomor tahap yang dipakai tampilan (1-5), turunan dari status bila
  /// arsitek belum mengatur tahap.
  int get tahapSaatIni {
    if (status == StatusKonsultasi.selesai) return 5;
    return tahap > 0 ? tahap : 1;
  }

  /// Kelompok tab Riwayat.
  bool get akanDatang =>
      status == StatusKonsultasi.menungguPembayaran ||
          status == StatusKonsultasi.menungguVerifikasi ||
          status == StatusKonsultasi.dikonfirmasi;
  bool get sudahSelesai => status == StatusKonsultasi.selesai;
  bool get batal =>
      status == StatusKonsultasi.dibatalkan ||
          status == StatusKonsultasi.ditolak;
}