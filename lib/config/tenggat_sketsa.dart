import '../models/pesanan_sketsa.dart';
import 'status.dart';

/// Perhitungan tenggat pengerjaan sketsa (dihitung di aplikasi, tanpa server).
///
/// Dasar waktu = `diverifikasiAt` (saat admin memverifikasi pembayaran, yaitu
/// saat pesanan mulai "dikerjakan").
/// - Target selesai : [targetHariKerja] hari kerja.
/// - Batas akhir    : [batasHariKerja] hari kerja (perpanjangan otomatis).
/// - Lewat batas & masih "dikerjakan" → dianggap TERLAMBAT.
class TenggatSketsa {
  TenggatSketsa._();

  static const targetHariKerja = 3;
  static const batasHariKerja = 5;

  /// Tambah [hari] hari kerja (lewati Sabtu & Minggu) dari [dari].
  static DateTime tambahHariKerja(DateTime dari, int hari) {
    var d = dari;
    var sisa = hari;
    while (sisa > 0) {
      d = d.add(const Duration(days: 1));
      if (d.weekday != DateTime.saturday && d.weekday != DateTime.sunday) {
        sisa--;
      }
    }
    return d;
  }

  /// Hanya relevan saat pesanan masih dikerjakan dan sudah diverifikasi.
  static bool berlaku(PesananSketsa p) =>
      p.status == StatusSketsa.dikerjakan && p.diverifikasiAt != null;

  /// Tanggal target selesai (null kalau belum diverifikasi).
  /// Ikut mundur kalau admin menambah waktu (tambahanHariKerja).
  static DateTime? target(PesananSketsa p) {
    final m = p.diverifikasiAt;
    return m == null
        ? null
        : tambahHariKerja(m, targetHariKerja + p.tambahanHariKerja);
  }

  /// Batas akhir sebelum dianggap terlambat (null kalau belum diverifikasi).
  /// Ikut mundur kalau admin menambah waktu (tambahanHariKerja).
  static DateTime? batas(PesananSketsa p) {
    final m = p.diverifikasiAt;
    return m == null
        ? null
        : tambahHariKerja(m, batasHariKerja + p.tambahanHariKerja);
  }

  /// True kalau sudah lewat batas akhir dan masih berstatus "dikerjakan".
  static bool terlambat(PesananSketsa p) {
    if (!berlaku(p)) return false;
    final b = batas(p);
    return b != null && DateTime.now().isAfter(b);
  }

  /// Sisa hari kalender sampai batas akhir (bisa negatif kalau sudah lewat).
  /// null kalau tidak berlaku.
  static int? sisaHari(PesananSketsa p) {
    final b = batas(p);
    if (b == null) return null;
    final kini = DateTime.now();
    return b.difference(DateTime(kini.year, kini.month, kini.day)).inDays;
  }
}