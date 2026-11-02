/// Tahap pengerjaan sebuah konsultasi (dipakai sisi arsitek DAN sisi user).
/// Field `tahap` di dokumen konsultasi menyimpan nomor tahap saat ini (1-5).
class TahapKerja {
  TahapKerja._();

  static const nama = [
    'Terkonfirmasi',
    'Persiapan',
    'Sesi Konsultasi',
    'Penyusunan Hasil',
    'Hasil Terkirim',
  ];

  static const jumlah = 5;

  /// Nama tahap untuk nomor 1-5 (di luar itu dibulatkan ke rentang).
  static String namaTahap(int nomor) =>
      nama[(nomor.clamp(1, jumlah)) - 1];
}

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
const _hari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

/// "2 hari lalu", "3 jam lalu", "baru saja".
String waktuLalu(DateTime? t) {
  if (t == null) return '';
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'baru saja';
  if (d.inHours < 1) return '${d.inMinutes} menit lalu';
  if (d.inDays < 1) return '${d.inHours} jam lalu';
  return '${d.inDays} hari lalu';
}

/// "28 Okt 2026" dari "2026-10-28".
String tanggalPendek(String yyyyMmDd) {
  final d = DateTime.tryParse(yyyyMmDd);
  if (d == null) return yyyyMmDd;
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}

/// "Rab, 28 Okt 2026" dari "2026-10-28".
String tanggalLengkap(String yyyyMmDd) {
  final d = DateTime.tryParse(yyyyMmDd);
  if (d == null) return yyyyMmDd;
  return '${_hari[d.weekday - 1]}, ${d.day} ${_bulan[d.month - 1]} ${d.year}';
}