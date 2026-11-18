import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import '../../models/notifikasi.dart';
import '../../services/konsultasi_service.dart';
import '../../services/notifikasi_service.dart';
import '../../theme/app_theme.dart';
import '../arsitek/arsitek_detail_screen.dart';
import '../konsultasi/lacak_screen.dart';
import '../konsultasi/riwayat_screen.dart';
import '../konsultasi/ulasan_form_screen.dart';
import '../perumahan/pembayaran_rumah_screen.dart';
import '../sketsa/sketsa_detail_screen.dart';
import '../vendor/permintaan_detail_screen.dart';

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

/// Pengelompokan filter chip.
const _kelompok = {
  'Konsultasi': ['booking', 'pengingat', 'progres', 'hasil', 'revisi', 'selesai', 'batal'],
  'Pembayaran': ['pembayaran', 'refund'],
  'Sketsa': ['sketsa'],
  'Ulasan': ['ulasan'],
  'Vendor & Rumah': ['vendor', 'rumah'],
};

/// Halaman notifikasi user (dibuka dari ikon lonceng di Beranda).
class NotifikasiScreen extends StatefulWidget {
  const NotifikasiScreen({super.key});

  @override
  State<NotifikasiScreen> createState() => _NotifikasiScreenState();
}

class _NotifikasiScreenState extends State<NotifikasiScreen> {
  String _filter = 'Semua';

  // (ikon, warna latar, warna ikon)
  (IconData, Color, Color) _gaya(String type) {
    switch (type) {
      case 'progres':
        return (Icons.format_list_bulleted, AppColors.primary, Colors.white);
      case 'pengingat':
        return (Icons.schedule, const Color(0xFFD9A441), Colors.white);
      case 'pembayaran':
        return (Icons.check, const Color(0xFFE3ECF6), const Color(0xFF3C4F66));
      case 'booking':
        return (Icons.calendar_today_outlined, AppColors.primary, Colors.white);
      case 'hasil':
        return (Icons.description_outlined, AppColors.primary, Colors.white);
      case 'selesai':
        return (Icons.task_alt, AppColors.sageMuda, AppColors.primary);
      case 'refund':
        return (Icons.sync, const Color(0xFFF7E3DD), const Color(0xFF7A3F32));
      case 'batal':
        return (Icons.close, const Color(0xFFF7E3DD), const Color(0xFFB3392F));
      case 'vendor':
        return (Icons.engineering_outlined, const Color(0xFFDCE6EE), const Color(0xFF2C4A63));
      case 'rumah':
        return (Icons.house_outlined, AppColors.sageMuda, AppColors.primary);
      case 'sketsa':
        return (Icons.draw_outlined, AppColors.primary, Colors.white);
      case 'ulasan':
        return (Icons.star_rounded, const Color(0xFFF7EBD2), const Color(0xFFB45F06));
      default:
        return (Icons.notifications_none, AppColors.sageMuda, AppColors.primary);
    }
  }

  /// Teks tujuan yang tampil di tiap kartu.
  String _tujuan(String type) {
    switch (type) {
      case 'progres':
      case 'hasil':
        return 'Buka: Lacak Konsultasi';
      case 'revisi':
        return 'Buka: Detail Konsultasi';
      case 'booking':
      case 'pembayaran':
      case 'pengingat':
        return 'Buka: Riwayat, Akan Datang';
      case 'selesai':
        return 'Buka: Riwayat, Selesai';
      case 'refund':
      case 'batal':
        return 'Buka: Riwayat, Dibatalkan';
      case 'vendor':
        return 'Buka: Detail Permintaan Vendor';
      case 'rumah':
        return 'Buka: Booking Rumah';
      case 'sketsa':
        return 'Buka: Detail Sketsa Desain';
      case 'ulasan':
        return 'Buka: Form Ulasan';
      default:
        return 'Buka';
    }
  }

  Future<void> _bukaFormUlasan(String konsultasiId) async {
    final k = await KonsultasiService.satu(konsultasiId).first;
    if (!mounted) return;
    if (k == null) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Konsultasi tidak ditemukan.')));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => UlasanFormScreen(konsultasi: k)),
    );
  }

  void _buka(Notifikasi n) {
    if (!n.isRead) NotifikasiService.tandaiDibaca(n.id);
    if (n.type == 'ulasan') {
      _bukaFormUlasan(n.refId);
      return;
    }
    if (n.type == 'sketsa') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => SketsaDetailScreen(pesananId: n.refId)),
      );
      return;
    }
    if (n.type == 'vendor') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PermintaanDetailScreen(permintaanId: n.refId)),
      );
      return;
    }
    if (n.type == 'rumah') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => PembayaranRumahScreen(pesananId: n.refId)),
      );
      return;
    }
    int? tab;
    switch (n.type) {
      case 'booking':
      case 'pembayaran':
      case 'pengingat':
        tab = 0;
      case 'selesai':
        tab = 1;
      case 'refund':
      case 'batal':
        tab = 2;
    }
    if (tab != null) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => RiwayatScreen(tabAwal: tab!)),
      );
      return;
    }
    if (n.type == 'revisi') {
      Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ArsitekDetailScreen(konsultasiId: n.refId)),
      );
      return;
    }
    if (n.type == 'progres' || n.type == 'hasil') {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LacakScreen(konsultasiId: n.refId)),
      );
    }
  }

  String _waktu(DateTime? t, {required bool tampilTanggal}) {
    if (t == null) return '';
    final jam =
        '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    return tampilTanggal ? '${t.day} ${_bulan[t.month - 1]} · $jam' : jam;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Notifikasi', style: AppTheme.heading(19)),
      ),
      body: StreamBuilder<List<Notifikasi>>(
        stream: NotifikasiService.milikSaya(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Gagal memuat notifikasi.'));
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final semua = snap.data!;
          final belum = semua.where((n) => !n.isRead).length;
          final tampil = _filter == 'Semua'
              ? semua
              : semua.where((n) => _kelompok[_filter]!.contains(n.type)).toList();
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                child: Row(children: [
                  Expanded(
                    child: Text(
                        belum == 0 ? 'Semua sudah dibaca' : '$belum belum dibaca',
                        style: const TextStyle(
                            fontSize: 12.5, color: AppColors.textMuted)),
                  ),
                  TextButton(
                    onPressed: belum == 0
                        ? null
                        : () => NotifikasiService.tandaiSemuaDibaca(semua),
                    child: const Text('Tandai semua dibaca',
                        style: TextStyle(
                            fontSize: 12.5, fontWeight: FontWeight.w600)),
                  ),
                ]),
              ),
              SizedBox(
                height: 38,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  children: [
                    for (final f in ['Semua', ..._kelompok.keys]) _chip(f),
                  ],
                ),
              ),
              Expanded(
                child: tampil.isEmpty
                    ? _kosong()
                    : ListView(
                  padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                  children: _daftarBergrup(tampil),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chip(String label) {
    final aktif = _filter == label;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => setState(() => _filter = label),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? AppColors.primary : Colors.white,
            borderRadius: BorderRadius.circular(18),
            border:
            Border.all(color: aktif ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                  color: aktif ? Colors.white : AppColors.textMuted)),
        ),
      ),
    );
  }

  List<Widget> _daftarBergrup(List<Notifikasi> list) {
    final sekarang = DateTime.now();
    final hariIni = DateTime(sekarang.year, sekarang.month, sekarang.day);
    String grup(Notifikasi n) {
      final t = n.createdAt ?? sekarang;
      final tgl = DateTime(t.year, t.month, t.day);
      final selisih = hariIni.difference(tgl).inDays;
      if (selisih <= 0) return 'HARI INI';
      if (selisih == 1) return 'KEMARIN';
      return 'SEBELUMNYA';
    }

    final hasil = <Widget>[];
    String? terakhir;
    for (final n in list) {
      final g = grup(n);
      if (g != terakhir) {
        hasil.add(Padding(
          padding: EdgeInsets.only(top: terakhir == null ? 0 : 16, bottom: 8),
          child: Text(g,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                  color: AppColors.textMuted)),
        ));
        terakhir = g;
      }
      hasil.add(Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: _kartu(n, g),
      ));
    }
    return hasil;
  }

  Widget _kartu(Notifikasi n, String grup) {
    final gaya = _gaya(n.type);
    return GestureDetector(
      onTap: () => _buka(n),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: n.isRead ? AppColors.surface : const Color(0xFFE4EFE7),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: n.isRead ? AppColors.border : const Color(0xFFBCD6C4)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: gaya.$2, shape: BoxShape.circle),
              child: Icon(gaya.$1, size: 20, color: gaya.$3),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(n.judul,
                          style: const TextStyle(
                              fontSize: 13.5, fontWeight: FontWeight.w700)),
                    ),
                    if (!n.isRead)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                            color: Color(0xFFD9534F), shape: BoxShape.circle),
                      ),
                  ]),
                  const SizedBox(height: 2),
                  Text(n.isi,
                      style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: n.isRead
                              ? AppColors.textMuted
                              : const Color(0xFF3E4739))),
                  const SizedBox(height: 6),
                  Row(children: [
                    Text(_waktu(n.createdAt, tampilTanggal: grup == 'SEBELUMNYA'),
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.textMuted)),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: n.isRead ? AppColors.background : Colors.white,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(_tujuan(n.type),
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                                color: AppColors.primary)),
                      ),
                    ),
                  ]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _kosong() => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_none,
              size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('Belum ada notifikasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Kabar tentang booking, pembayaran, dan progres '
              'konsultasimu muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    ),
  );
}