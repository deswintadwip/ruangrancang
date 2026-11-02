import '../../config/status.dart';
import '../../models/konsultasi.dart';

/// Kelompok tampilan konsultasi di sisi arsitek.
enum KategoriKonsultasi { selesai, aktif, terjadwal, perluUpdate }

/// Konsultasi dianggap "perlu update" kalau pekerjaannya sudah berjalan
/// (tahap 2-4) dan arsitek belum update sama sekali, atau sudah >= 2 hari.
bool perluUpdate(Konsultasi k) {
  if (k.status != StatusKonsultasi.dikonfirmasi) return false;
  final t = k.tahapSaatIni;
  if (t < 2 || t >= 5) return false;
  final u = k.updatedAt;
  return u == null || DateTime.now().difference(u).inDays >= 2;
}

KategoriKonsultasi kategoriDari(Konsultasi k) {
  if (k.status == StatusKonsultasi.selesai) return KategoriKonsultasi.selesai;
  if (k.tahapSaatIni <= 1) return KategoriKonsultasi.terjadwal;
  if (perluUpdate(k)) return KategoriKonsultasi.perluUpdate;
  return KategoriKonsultasi.aktif;
}

/// Hanya konsultasi yang sudah dibayar yang relevan untuk arsitek.
bool tampilDiArsitek(Konsultasi k) =>
    k.status == StatusKonsultasi.dikonfirmasi ||
        k.status == StatusKonsultasi.selesai;

String inisialNama(String nama) {
  final kata = nama.trim().split(RegExp(r'\s+')).where((e) => e.isNotEmpty);
  if (kata.isEmpty) return '?';
  final list = kata.toList();
  if (list.length == 1) return list.first[0].toUpperCase();
  return (list.first[0] + list.last[0]).toUpperCase();
}