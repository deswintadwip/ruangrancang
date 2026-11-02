import 'pengaturan.dart';

/// Hari, jam, dan tanggal cuti yang diatur seorang arsitek.
/// Selalu berada DI DALAM batas pengaturan admin (hari operasional & slot jam).
class Ketersediaan {
  final List<int> hariKerja; // 1 = Senin ... 7 = Minggu
  final List<String> slotJam; // contoh "09:00-11:00"
  final List<String> cuti; // "yyyy-MM-dd"

  const Ketersediaan({
    required this.hariKerja,
    required this.slotJam,
    required this.cuti,
  });

  static String kunci(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  /// Apakah tanggal ini bisa dipesan (hari kerja dan bukan cuti)?
  bool hariBuka(DateTime d) =>
      hariKerja.contains(d.weekday) && !cuti.contains(kunci(d));

  /// Dari dokumen `arsitek/{uid}` (boleh null). Field yang belum pernah
  /// diatur arsitek mengikuti pengaturan admin.
  factory Ketersediaan.dari(Map<String, dynamic>? m, Pengaturan p) {
    final h = (m?['hariKerja'] as List?)?.map((e) => (e as num).toInt()).toList();
    final s = (m?['slotJam'] as List?)?.map((e) => e.toString()).toList();
    final c = (m?['cuti'] as List?)?.map((e) => e.toString()).toList() ?? [];
    return Ketersediaan(
      hariKerja: p.hariOperasional.where((x) => h == null || h.contains(x)).toList(),
      slotJam: p.slotJam.where((x) => s == null || s.contains(x)).toList(),
      cuti: c,
    );
  }
}