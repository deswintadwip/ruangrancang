import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/arsitek_data.dart';

/// Satu dokumen di koleksi `ulasan` (ID dokumen = ID konsultasi).
class UlasanKlien {
  final String id; // = konsultasiId
  final String userId;
  final String userNama;
  final String arsitekId;
  final int bintang; // 1 - 5
  final String isi;
  final String? balasan;
  final DateTime? createdAt;

  const UlasanKlien({
    required this.id,
    required this.userId,
    required this.userNama,
    required this.arsitekId,
    required this.bintang,
    required this.isi,
    this.balasan,
    this.createdAt,
  });

  factory UlasanKlien.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    final t = m['createdAt'];
    return UlasanKlien(
      id: d.id,
      userId: m['userId'] as String? ?? '',
      userNama: m['userNama'] as String? ?? '',
      arsitekId: m['arsitekId'] as String? ?? '',
      bintang: (m['bintang'] as num?)?.toInt() ?? 0,
      isi: m['isi'] as String? ?? '',
      balasan: m['balasan'] as String?,
      createdAt: t is Timestamp ? t.toDate() : null,
    );
  }

  /// "Rina Setiawan" -> "Rina S." (nama klien tidak ditampilkan penuh).
  String get namaSingkat {
    final kata = userNama.trim().split(RegExp(r'\s+'));
    if (kata.isEmpty || kata.first.isEmpty) return 'Klien';
    if (kata.length == 1) return kata.first;
    return '${kata.first} ${kata.last[0].toUpperCase()}.';
  }

  String get waktuRelatif {
    final t = createdAt;
    if (t == null) return 'Baru saja';
    final hari = DateTime.now().difference(t).inDays;
    if (hari < 1) return 'Hari ini';
    if (hari < 7) return '$hari hari lalu';
    if (hari < 30) return '${hari ~/ 7} minggu lalu';
    return '${hari ~/ 30} bulan lalu';
  }

  /// Diubah ke bentuk `Ulasan` yang dipakai tampilan detail arsitek.
  Ulasan keUlasan() => Ulasan(
    nama: namaSingkat,
    bintang: bintang.toDouble(),
    waktu: waktuRelatif,
    isi: isi,
    balasan: balasan,
  );
}