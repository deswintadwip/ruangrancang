/// Tipe rumah dalam satu perumahan.
class TipeRumah {
  final String nama; // "Tipe 36/72"
  final int luasBangunan; // m²
  final int luasTanah; // m²
  final int kamarTidur;
  final int kamarMandi;
  final int harga; // rupiah
  final int sisaUnit;

  const TipeRumah({
    required this.nama,
    required this.luasBangunan,
    required this.luasTanah,
    required this.kamarTidur,
    required this.kamarMandi,
    required this.harga,
    required this.sisaUnit,
  });
}

/// Satu proyek perumahan. Data sementara (statis); nanti dipindah ke
/// Firestore lewat layar admin Perumahan. Semua isi adalah CONTOH FIKTIF.
class Perumahan {
  final String id;
  final String nama;
  final String kota;
  final String alamat;
  final String pengembang;
  final String deskripsi;
  final String serahTerima;
  final List<String> foto; // path aset
  final List<TipeRumah> tipe;
  final List<String> fasilitas;

  const Perumahan({
    required this.id,
    required this.nama,
    required this.kota,
    required this.alamat,
    required this.pengembang,
    required this.deskripsi,
    required this.serahTerima,
    required this.foto,
    required this.tipe,
    required this.fasilitas,
  });

  int get hargaMulai =>
      tipe.map((t) => t.harga).reduce((a, b) => a < b ? a : b);
  int get totalSisa => tipe.fold(0, (s, t) => s + t.sisaUnit);
}

class DataPerumahan {
  DataPerumahan._();

  static const semua = <Perumahan>[
    Perumahan(
      id: 'perumahan_01',
      nama: 'Griya Asri',
      kota: 'Depok',
      alamat: 'Jl. Raya Contoh No. 10, Sawangan, Depok',
      pengembang: 'PT Griya Cipta Lestari',
      deskripsi:
          'Klaster tenang 15 menit dari stasiun, dengan taman bermain, jalan lebar, dan keamanan 24 jam. Cocok untuk keluarga muda.',
      serahTerima: '12 bulan setelah akad',
      foto: [
        'lib/images/dashboardperumahan1.jpg',
        'lib/images/rumahdashboard1.jpg',
        'lib/images/rumahdashboard2.jpg',
      ],
      tipe: [
        TipeRumah(nama: 'Tipe 36/72', luasBangunan: 36, luasTanah: 72, kamarTidur: 2, kamarMandi: 1, harga: 685000000, sisaUnit: 8),
        TipeRumah(nama: 'Tipe 45/84', luasBangunan: 45, luasTanah: 84, kamarTidur: 3, kamarMandi: 2, harga: 820000000, sisaUnit: 5),
        TipeRumah(nama: 'Tipe 60/105', luasBangunan: 60, luasTanah: 105, kamarTidur: 3, kamarMandi: 2, harga: 1050000000, sisaUnit: 2),
      ],
      fasilitas: ['Keamanan 24 jam', 'One gate system', 'Taman bermain', 'Masjid', 'Jogging track', 'Carport'],
    ),
    Perumahan(
      id: 'perumahan_02',
      nama: 'Taman Cendana',
      kota: 'Bogor',
      alamat: 'Jl. Cendana Raya No. 5, Cibinong, Bogor',
      pengembang: 'PT Cendana Bumi Sejahtera',
      deskripsi:
          'Hunian berudara sejuk dengan konsep taman di setiap blok. Dekat gerbang tol dan pusat belanja.',
      serahTerima: '10 bulan setelah akad',
      foto: [
        'lib/images/dashboardperumahan2.jpg',
        'lib/images/rumahdashboard3.jpg',
        'lib/images/rumahdashboard4.jpg',
      ],
      tipe: [
        TipeRumah(nama: 'Tipe 30/60', luasBangunan: 30, luasTanah: 60, kamarTidur: 2, kamarMandi: 1, harga: 520000000, sisaUnit: 12),
        TipeRumah(nama: 'Tipe 42/78', luasBangunan: 42, luasTanah: 78, kamarTidur: 3, kamarMandi: 2, harga: 690000000, sisaUnit: 6),
      ],
      fasilitas: ['Keamanan 24 jam', 'Taman blok', 'Area komersial', 'Drainase terpadu', 'Carport'],
    ),
    Perumahan(
      id: 'perumahan_03',
      nama: 'Bukit Hijau',
      kota: 'Tangerang',
      alamat: 'Jl. Bukit Hijau Boulevard, Serpong, Tangerang',
      pengembang: 'PT Hijau Karya Properti',
      deskripsi:
          'Kawasan hijau dengan danau buatan dan akses cepat ke kawasan perkantoran. Rumah dua lantai dengan desain modern tropis.',
      serahTerima: '14 bulan setelah akad',
      foto: [
        'lib/images/dashboardperumahan3.jpg',
        'lib/images/rumahdashboard1.jpg',
        'lib/images/rumahdashboard4.jpg',
      ],
      tipe: [
        TipeRumah(nama: 'Tipe 55/90', luasBangunan: 55, luasTanah: 90, kamarTidur: 3, kamarMandi: 2, harga: 1250000000, sisaUnit: 4),
        TipeRumah(nama: 'Tipe 72/120', luasBangunan: 72, luasTanah: 120, kamarTidur: 4, kamarMandi: 3, harga: 1680000000, sisaUnit: 3),
      ],
      fasilitas: ['Danau buatan', 'Clubhouse', 'Kolam renang', 'Keamanan 24 jam', 'Jogging track', 'Carport 2 mobil'],
    ),
  ];

  static Perumahan? byId(String? id) {
    for (final p in semua) {
      if (p.id == id) return p;
    }
    return null;
  }
}
