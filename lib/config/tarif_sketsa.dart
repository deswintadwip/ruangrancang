/// Tarif sketsa desain berdasarkan luas lahan (m²).
/// Ubah angka di sini kalau tarifnya berubah.
class TarifSketsa {
  TarifSketsa._();

  /// (batas atas m², harga). Urut dari kecil ke besar.
  static const tingkat = <(int, int)>[
    (50, 300000),
    (100, 450000),
    (200, 650000),
    (500, 850000),
    (1000, 1500000),
  ];

  /// Harga untuk lahan di atas batas terakhir.
  static const hargaDiAtas = 2500000;

  static int hitung(int luasLahan) {
    for (final (batas, harga) in tingkat) {
      if (luasLahan <= batas) return harga;
    }
    return hargaDiAtas;
  }

  /// Harga terendah, untuk teks "mulai dari".
  static int get hargaMulai => tingkat.first.$2;

  /// Nama tingkat untuk ditampilkan, contoh "51–100 m²".
  static String namaTingkat(int luasLahan) {
    var awal = 0;
    for (final (batas, _) in tingkat) {
      if (luasLahan <= batas) {
        return awal == 0 ? 'sampai $batas m²' : '${awal + 1}–$batas m²';
      }
      awal = batas;
    }
    return 'di atas $awal m²';
  }
}
