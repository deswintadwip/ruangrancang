import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// DATA SEMENTARA (statis) untuk tampilan Konsultasi.
/// Nanti dipindah ke Firestore koleksi `arsitek`; model di bawah ini
/// sengaja dibuat mirip supaya perpindahannya mudah.
/// ⚠️ Semua nama, kampus, dan nomor WA di sini CONTOH. Ganti dengan data asli.

/// Satu riwayat pendidikan.
class Pendidikan {
  final String judul; // "S1 Arsitektur"
  final String lembaga; // "Universitas Contoh · Lulus 2016"

  const Pendidikan(this.judul, this.lembaga);
}

/// Satu ulasan dari klien yang sudah menyelesaikan sesi.
class Ulasan {
  final String nama; // "Rina S."
  final double bintang; // 1.0 - 5.0
  final String waktu; // "2 minggu lalu"
  final String isi;
  final String? balasan; // balasan dari arsitek (boleh kosong)

  const Ulasan({
    required this.nama,
    required this.bintang,
    required this.waktu,
    required this.isi,
    this.balasan,
  });

  String get inisial => nama.isNotEmpty ? nama[0].toUpperCase() : '?';
}

/// Satu arsitek.
class Arsitek {
  final String id; // nanti = uid di koleksi `arsitek`
  final String nama;
  final String gelar; // "S.Ars."
  final String spesialis; // gaya utama, contoh "Minimalis Modern"
  final int pengalamanTahun;
  final double rating;
  final int jumlahProyek;
  final int jumlahUlasan;
  final String tentang; // biografi singkat
  final List<Pendidikan> pendidikan;
  final List<String> keahlian;
  final String jamPraktik; // "Senin – Sabtu · 09.00 – 17.00 WIB"
  final String wa; // format 62812..., tanpa + dan spasi
  final String? instagram; // alamat lengkap, null = tombol disembunyikan
  final String? linkedin;
  final String? website;
  final bool topRekomendasi;
  final Color warna; // warna latar placeholder (sebelum ada foto)
  final List<Ulasan> ulasan;

  /// Lokasi foto. File fotonya menyusul; kalau belum ada, tampilan otomatis
  /// memakai placeholder inisial.
  String get foto => 'lib/images/arsitek/arsitek1.jpg';

  const Arsitek({
    required this.id,
    required this.nama,
    required this.gelar,
    required this.spesialis,
    required this.pengalamanTahun,
    required this.rating,
    required this.jumlahProyek,
    required this.jumlahUlasan,
    required this.tentang,
    required this.pendidikan,
    required this.keahlian,
    required this.jamPraktik,
    required this.wa,
    required this.warna,
    required this.ulasan,
    this.instagram,
    this.linkedin,
    this.website,
    this.topRekomendasi = false,
  });

  /// Dua huruf depan untuk placeholder foto: "Ardhana Wiratama" → "AW"
  String get inisial {
    final kata = nama.trim().split(' ').where((k) => k.isNotEmpty).toList();
    if (kata.isEmpty) return '?';
    if (kata.length == 1) return kata[0][0].toUpperCase();
    return (kata[0][0] + kata[1][0]).toUpperCase();
  }

  /// Salinan dengan nama / spesialis dari Firestore.
  Arsitek dengan({String? nama, String? spesialis}) => Arsitek(
        id: id,
        nama: nama ?? this.nama,
        gelar: gelar,
        spesialis: spesialis ?? this.spesialis,
        pengalamanTahun: pengalamanTahun,
        rating: rating,
        jumlahProyek: jumlahProyek,
        jumlahUlasan: jumlahUlasan,
        tentang: tentang,
        pendidikan: pendidikan,
        keahlian: keahlian,
        jamPraktik: jamPraktik,
        wa: wa,
        warna: warna,
        ulasan: ulasan,
        instagram: instagram,
        linkedin: linkedin,
        website: website,
        topRekomendasi: topRekomendasi,
      );

  /// "Ardhana Wiratama, S.Ars."
  String get namaLengkap => gelar.isEmpty ? nama : '$nama, $gelar';
}

/// Tempat semua data + fungsi pencarian.
class DataArsitek {
  DataArsitek._();

  /// Daftar gaya untuk chip filter ("Semua" ditambahkan di layar).
  static const daftarGaya = [
    'Minimalis Modern',
    'Tropis',
    'Industrial',
    'Interior',
    'Skandinavia',
    'Japandi',
  ];

  /// Cari berdasarkan nama/gaya dan filter gaya (null = semua).
  static List<Arsitek> cari({String kata = '', String? gaya}) {
    final k = kata.trim().toLowerCase();
    return semua.where((a) {
      final cocokKata = k.isEmpty ||
          a.nama.toLowerCase().contains(k) ||
          a.spesialis.toLowerCase().contains(k);
      final cocokGaya = gaya == null || a.spesialis == gaya;
      return cocokKata && cocokGaya;
    }).toList();
  }

  /// Arsitek yang diberi label Top Rekomendasi.
  static List<Arsitek> get top =>
      semua.where((a) => a.topRekomendasi).toList();

  static Arsitek? byId(String id) {
    for (final a in semua) {
      if (a.id == id) return a;
    }
    return null;
  }

  /// Daftar yang dipakai layar. Awalnya data contoh; setelah login diganti
  /// dengan arsitek yang punya akun di Firestore (koleksi `arsitek`).
  static List<Arsitek> _aktif = _asli;
  static List<Arsitek> get semua => _aktif;

  /// Semua profil bawaan (tanpa filter akun), dipakai admin saat membuat akun.
  static List<Arsitek> get semuaProfil => _asli;

  /// Naik 1 setiap daftar berubah; layar yang menampilkan arsitek
  /// mendengarkan ini supaya ikut diperbarui.
  static final ValueNotifier<int> versi = ValueNotifier<int>(0);
  static StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _langganan;

  /// Mulai mendengarkan koleksi `arsitek` (live). Selesai setelah data
  /// pertama diterima (atau gagal), lalu terus memperbarui sendiri.
  /// Cocokkan lewat `profilId`: nama & spesialisasi mengikuti Firestore,
  /// akun nonaktif / belum ada akunnya disembunyikan. Kalau gagal atau
  /// kosong, tetap pakai data contoh.
  static Future<void> muatDariFirestore() async {
    await _langganan?.cancel();
    final pertama = Completer<void>();
    _langganan = FirebaseFirestore.instance.collection('arsitek').snapshots().listen(
      (s) {
        _terapkan(s);
        if (!pertama.isCompleted) pertama.complete();
      },
      onError: (_) {
        if (!pertama.isCompleted) pertama.complete();
      },
    );
    await pertama.future.timeout(const Duration(seconds: 6), onTimeout: () {});
  }

  /// Hentikan pendengar (dipanggil saat logout).
  static Future<void> berhenti() async {
    await _langganan?.cancel();
    _langganan = null;
    _aktif = _asli;
  }

  static void _terapkan(QuerySnapshot<Map<String, dynamic>> s) {
    final peta = <String, Map<String, dynamic>>{};
    for (final d in s.docs) {
      final m = d.data();
      final id = m['profilId'];
      if (id is String && id.isNotEmpty) peta[id] = m;
    }
    final hasil = <Arsitek>[];
    for (final a in _asli) {
      final m = peta[a.id];
      if (m == null || m['isActive'] == false) continue;
      final nama = m['nama'] as String?;
      final spes = m['spesialisasi'] as String?;
      hasil.add(a.dengan(
        nama: (nama == null || nama.isEmpty) ? null : nama,
        spesialis: (spes == null || spes.isEmpty || spes == 'Belum diisi')
            ? null
            : spes,
      ));
    }
    _aktif = hasil.isNotEmpty ? hasil : _asli;
    versi.value++;
  }

  static const _asli = <Arsitek>[
    Arsitek(
      id: 'arsitek_01',
      nama: 'Ardhana Wiratama',
      gelar: 'S.Ars.',
      spesialis: 'Minimalis Modern',
      pengalamanTahun: 9,
      rating: 4.9,
      jumlahProyek: 120,
      jumlahUlasan: 48,
      tentang:
      'Ardhana memulai karier sebagai arsitek residensial sejak 2017. '
          'Ia percaya rumah yang baik itu sederhana, terang, dan nyaman '
          'dihuni, dengan fokus pada garis bersih dan cahaya alami.',
      pendidikan: [
        Pendidikan('S1 Arsitektur', 'Universitas Contoh · Lulus 2016'),
        Pendidikan('Anggota IAI', 'Ikatan Arsitek Indonesia'),
      ],
      keahlian: ['Rumah 2 lantai', 'Fasad modern', 'Pencahayaan alami'],
      jamPraktik: 'Senin – Sabtu · 09.00 – 17.00 WIB',
      wa: '6281200000001',
      instagram: 'https://instagram.com/',
      linkedin: 'https://linkedin.com/',
      website: 'https://example.com/',
      topRekomendasi: true,
      warna: Color(0xFF3F6354),
      ulasan: [
        Ulasan(
          nama: 'Rina S.',
          bintang: 5.0,
          waktu: '2 minggu lalu',
          isi: 'Penjelasannya jelas dan sabar, desain rumah jadi terarah.',
          balasan: 'Terima kasih, Bu Rina. Semoga lancar pembangunannya.',
        ),
        Ulasan(
          nama: 'Budi P.',
          bintang: 4.5,
          waktu: '1 bulan lalu',
          isi: 'Banyak ide untuk lahan sempit. Recommended!',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_02',
      nama: 'Aqila Sofia Yaqutah Langkau',
      gelar: 'S.Ars.',
      spesialis: 'Tropis',
      pengalamanTahun: 7,
      rating: 4.8,
      jumlahProyek: 85,
      jumlahUlasan: 36,
      tentang:
      'Maya merancang rumah tropis yang adem tanpa bergantung pada AC. '
          'Ia terbiasa mengatur ventilasi silang, teritisan lebar, dan '
          'taman dalam untuk iklim Indonesia.',
      pendidikan: [
        Pendidikan('S1 Arsitektur', 'Universitas Contoh · Lulus 2018'),
        Pendidikan('Sertifikasi Green Building', 'Green Building Council'),
      ],
      keahlian: ['Ventilasi alami', 'Taman dalam', 'Rumah tapak'],
      jamPraktik: 'Senin – Jumat · 08.00 – 16.00 WIB',
      wa: '6281200000002',
      instagram: 'https://instagram.com/',
      topRekomendasi: true,
      warna: Color(0xFF5B7A52),
      ulasan: [
        Ulasan(
          nama: 'Dewi A.',
          bintang: 5.0,
          waktu: '3 minggu lalu',
          isi: 'Konsep tropisnya pas. Rumah jadi terasa sejuk.',
        ),
        Ulasan(
          nama: 'Hendra T.',
          bintang: 4.5,
          waktu: '2 bulan lalu',
          isi: 'Solusi ventilasinya cerdas, tapi estimasi biaya agak lama.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_03',
      nama: 'Meylia Nilamsari',
      gelar: 'S.T.',
      spesialis: 'Tropis',
      pengalamanTahun: 6,
      rating: 4.7,
      jumlahProyek: 64,
      jumlahUlasan: 29,
      tentang:
      'Sekar fokus pada hunian keluarga muda dengan budget terbatas. '
          'Ia pandai mengatur tata ruang agar lahan kecil tetap lega.',
      pendidikan: [
        Pendidikan('S1 Teknik Arsitektur', 'Universitas Contoh · Lulus 2019'),
      ],
      keahlian: ['Lahan sempit', 'Budget efisien', 'Tata ruang'],
      jamPraktik: 'Selasa – Sabtu · 10.00 – 18.00 WIB',
      wa: '6281200000003',
      instagram: 'https://instagram.com/',
      warna: Color(0xFF6F8F72),
      ulasan: [
        Ulasan(
          nama: 'Laras M.',
          bintang: 5.0,
          waktu: '1 minggu lalu',
          isi: 'Lahan 6x12 jadi terasa luas. Terima kasih Bu Sekar!',
        ),
        Ulasan(
          nama: 'Yoga R.',
          bintang: 4.5,
          waktu: '1 bulan lalu',
          isi: 'Ramah dan mudah dihubungi.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_04',
      nama: 'Thoriq Ziyad Rahman',
      gelar: 'S.Ars.',
      spesialis: 'Industrial',
      pengalamanTahun: 10,
      rating: 4.8,
      jumlahProyek: 140,
      jumlahUlasan: 52,
      tentang:
      'Dimas berpengalaman mengubah ruko dan gudang menjadi hunian dan '
          'kafe bergaya industrial dengan material ekspos yang kuat.',
      pendidikan: [
        Pendidikan('S1 Arsitektur', 'Universitas Contoh · Lulus 2015'),
        Pendidikan('Anggota IAI', 'Ikatan Arsitek Indonesia'),
      ],
      keahlian: ['Ruko & kafe', 'Material ekspos', 'Renovasi'],
      jamPraktik: 'Senin – Sabtu · 09.00 – 17.00 WIB',
      wa: '6281200000004',
      linkedin: 'https://linkedin.com/',
      warna: Color(0xFF6B5A4A),
      ulasan: [
        Ulasan(
          nama: 'Fikri A.',
          bintang: 5.0,
          waktu: '5 hari lalu',
          isi: 'Konsep industrialnya keren dan realistis untuk dibangun.',
        ),
        Ulasan(
          nama: 'Sinta K.',
          bintang: 4.5,
          waktu: '3 minggu lalu',
          isi: 'Detail material dijelaskan lengkap.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_05',
      nama: 'Ayu Paramitha',
      gelar: 'S.Ds.',
      spesialis: 'Interior',
      pengalamanTahun: 8,
      rating: 4.9,
      jumlahProyek: 110,
      jumlahUlasan: 44,
      tentang:
      'Ayu adalah desainer interior yang gemar memadukan warna hangat '
          'dan furnitur custom agar ruangan terasa personal.',
      pendidikan: [
        Pendidikan('S1 Desain Interior', 'Institut Contoh · Lulus 2017'),
      ],
      keahlian: ['Furnitur custom', 'Palet warna', 'Dapur & kamar'],
      jamPraktik: 'Senin – Jumat · 10.00 – 18.00 WIB',
      wa: '6281200000005',
      instagram: 'https://instagram.com/',
      website: 'https://example.com/',
      topRekomendasi: true,
      warna: Color(0xFF8A4F5E),
      ulasan: [
        Ulasan(
          nama: 'Nadya P.',
          bintang: 5.0,
          waktu: '4 hari lalu',
          isi: 'Pilihan warnanya cantik, kamar jadi nyaman banget.',
          balasan: 'Senang bisa membantu, Kak Nadya!',
        ),
        Ulasan(
          nama: 'Rangga D.',
          bintang: 5.0,
          waktu: '1 bulan lalu',
          isi: 'Sangat detail soal furnitur.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_06',
      nama: 'M. Ali Akbar',
      gelar: 'S.Ars.',
      spesialis: 'Skandinavia',
      pengalamanTahun: 5,
      rating: 4.6,
      jumlahProyek: 48,
      jumlahUlasan: 21,
      tentang:
      'Rizky menyukai ruang terang berwarna netral dengan sentuhan kayu '
          'alami. Cocok untuk apartemen dan rumah mungil.',
      pendidikan: [
        Pendidikan('S1 Arsitektur', 'Universitas Contoh · Lulus 2020'),
      ],
      keahlian: ['Apartemen', 'Palet netral', 'Furnitur kayu'],
      jamPraktik: 'Rabu – Minggu · 11.00 – 19.00 WIB',
      wa: '6281200000006',
      instagram: 'https://instagram.com/',
      warna: Color(0xFF5E7F96),
      ulasan: [
        Ulasan(
          nama: 'Citra W.',
          bintang: 4.5,
          waktu: '2 minggu lalu',
          isi: 'Apartemen 36 m² jadi lega dan rapi.',
        ),
        Ulasan(
          nama: 'Eko S.',
          bintang: 4.5,
          waktu: '2 bulan lalu',
          isi: 'Ide-ide simpel tapi efektif.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_07',
      nama: 'Nadia Rahma',
      gelar: 'S.Ars.',
      spesialis: 'Japandi',
      pengalamanTahun: 7,
      rating: 4.8,
      jumlahProyek: 72,
      jumlahUlasan: 33,
      tentang:
      'Nadia memadukan kesederhanaan Jepang dan kehangatan Skandinavia. '
          'Ruang yang ia rancang tenang, lapang, dan minim sekat.',
      pendidikan: [
        Pendidikan('S1 Arsitektur', 'Universitas Contoh · Lulus 2018'),
        Pendidikan('Workshop Desain Jepang', 'Studio Contoh, 2022'),
      ],
      keahlian: ['Ruang terbuka', 'Material alami', 'Taman kecil'],
      jamPraktik: 'Senin – Jumat · 09.00 – 17.00 WIB',
      wa: '6281200000007',
      instagram: 'https://instagram.com/',
      warna: Color(0xFF7A6F5D),
      ulasan: [
        Ulasan(
          nama: 'Mira L.',
          bintang: 5.0,
          waktu: '1 minggu lalu',
          isi: 'Rumahnya jadi tenang sekali. Sangat puas.',
        ),
        Ulasan(
          nama: 'Arif H.',
          bintang: 4.5,
          waktu: '1 bulan lalu',
          isi: 'Penjelasan konsepnya mudah dipahami.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_08',
      nama: 'Bagas Santoso',
      gelar: 'S.T.',
      spesialis: 'Minimalis Modern',
      pengalamanTahun: 12,
      rating: 4.7,
      jumlahProyek: 165,
      jumlahUlasan: 61,
      tentang:
      'Bagas berpengalaman 12 tahun merancang rumah 1 sampai 3 lantai '
          'dan sangat memahami perhitungan biaya serta perizinan.',
      pendidikan: [
        Pendidikan('S1 Teknik Arsitektur', 'Universitas Contoh · Lulus 2013'),
        Pendidikan('Anggota IAI', 'Ikatan Arsitek Indonesia'),
      ],
      keahlian: ['Estimasi biaya', 'Perizinan (PBG)', 'Rumah 3 lantai'],
      jamPraktik: 'Senin – Sabtu · 08.00 – 16.00 WIB',
      wa: '6281200000008',
      linkedin: 'https://linkedin.com/',
      warna: Color(0xFF4F5D75),
      ulasan: [
        Ulasan(
          nama: 'Tono W.',
          bintang: 5.0,
          waktu: '2 minggu lalu',
          isi: 'Estimasi biayanya akurat, tidak ada biaya tak terduga.',
        ),
        Ulasan(
          nama: 'Vina C.',
          bintang: 4.5,
          waktu: '1 bulan lalu',
          isi: 'Sangat membantu urusan PBG.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_09',
      nama: 'Intan Permatasari',
      gelar: 'S.Ars.',
      spesialis: 'Interior',
      pengalamanTahun: 6,
      rating: 4.7,
      jumlahProyek: 58,
      jumlahUlasan: 26,
      tentang:
      'Intan fokus pada interior ruang keluarga dan kamar anak, dengan '
          'perhatian pada keamanan material dan penyimpanan yang pintar.',
      pendidikan: [
        Pendidikan('S1 Desain Interior', 'Institut Contoh · Lulus 2019'),
      ],
      keahlian: ['Kamar anak', 'Storage pintar', 'Ruang keluarga'],
      jamPraktik: 'Selasa – Sabtu · 09.00 – 17.00 WIB',
      wa: '6281200000009',
      instagram: 'https://instagram.com/',
      warna: Color(0xFF9A6B7B),
      ulasan: [
        Ulasan(
          nama: 'Putri N.',
          bintang: 5.0,
          waktu: '6 hari lalu',
          isi: 'Kamar anak jadi rapi dan aman.',
        ),
        Ulasan(
          nama: 'Galih B.',
          bintang: 4.5,
          waktu: '1 bulan lalu',
          isi: 'Ide penyimpanannya kreatif.',
        ),
      ],
    ),
    Arsitek(
      id: 'arsitek_10',
      nama: 'Fajar Nugroho',
      gelar: 'S.Ars.',
      spesialis: 'Industrial',
      pengalamanTahun: 4,
      rating: 4.6,
      jumlahProyek: 35,
      jumlahUlasan: 15,
      tentang:
      'Fajar adalah arsitek muda yang cekatan membuat visualisasi 3D '
          'sehingga klien mudah membayangkan hasil akhir.',
      pendidikan: [
        Pendidikan('S1 Arsitektur', 'Universitas Contoh · Lulus 2021'),
      ],
      keahlian: ['Visualisasi 3D', 'Renovasi', 'Konsep cepat'],
      jamPraktik: 'Senin – Sabtu · 10.00 – 18.00 WIB',
      wa: '6281200000010',
      instagram: 'https://instagram.com/',
      warna: Color(0xFF7D5A3C),
      ulasan: [
        Ulasan(
          nama: 'Wulan S.',
          bintang: 4.5,
          waktu: '2 minggu lalu',
          isi: 'Visualisasi 3D-nya membantu sekali.',
        ),
        Ulasan(
          nama: 'Ilham F.',
          bintang: 4.5,
          waktu: '5 minggu lalu',
          isi: 'Cepat tanggap dan komunikatif.',
        ),
      ],
    ),
  ];
}