import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/status.dart';
import '../../data/arsitek_data.dart';
import '../../models/konsultasi.dart';
import '../../services/konsultasi_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/arsitek_foto.dart';
import '../../services/ulasan_service.dart';
import 'jadwal_ulang_screen.dart';
import 'pembayaran_screen.dart';
import 'ulasan_form_screen.dart';

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

String _tanggalIndo(String yyyyMmDd) {
  final d = DateTime.tryParse(yyyyMmDd);
  if (d == null) return yyyyMmDd;
  return '${d.day} ${_bulan[d.month - 1]} ${d.year}';
}

String _jamMenit(DateTime d) =>
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

/// Riwayat konsultasi user: tab Akan Datang, Selesai, Dibatalkan.
class RiwayatScreen extends StatelessWidget {
  /// 0 Akan Datang, 1 Selesai, 2 Dibatalkan
  final int tabAwal;
  const RiwayatScreen({super.key, this.tabAwal = 0});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      initialIndex: tabAwal,
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          iconTheme: const IconThemeData(color: AppColors.textDark),
          title: Text('Riwayat Konsultasi', style: AppTheme.heading(19)),
          bottom: const TabBar(
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            indicatorColor: AppColors.primary,
            indicatorWeight: 3,
            dividerColor: AppColors.border,
            labelStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
            unselectedLabelStyle:
            TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            tabs: [
              Tab(text: 'Akan Datang'),
              Tab(text: 'Selesai'),
              Tab(text: 'Dibatalkan'),
            ],
          ),
        ),
        body: StreamBuilder<List<Konsultasi>>(
          stream: KonsultasiService.milikSaya(),
          builder: (context, snap) {
            if (snap.hasError) {
              return _pesan(Icons.error_outline, 'Gagal memuat riwayat',
                  'Periksa koneksi, atau aturan Firestore belum mengizinkan baca.');
            }
            if (!snap.hasData) {
              return const Center(child: CircularProgressIndicator());
            }
            final semua = snap.data!;
            final akan = semua.where((k) => k.akanDatang).toList();
            final selesai =
            semua.where((k) => k.sudahSelesai).toList().reversed.toList();
            final batal =
            semua.where((k) => k.batal).toList().reversed.toList();
            return TabBarView(children: [
              _daftar(akan, 'Belum ada jadwal',
                  'Konsultasi yang kamu booking akan muncul di sini.'),
              _daftar(selesai, 'Belum ada yang selesai',
                  'Sesi yang sudah berlangsung tampil di sini.'),
              _daftar(batal, 'Tidak ada pembatalan',
                  'Konsultasi yang dibatalkan akan tercatat di sini.'),
            ]);
          },
        ),
      ),
    );
  }

  Widget _daftar(List<Konsultasi> list, String judul, String isi) {
    if (list.isEmpty) return _pesan(Icons.event_note_outlined, judul, isi);
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      itemCount: list.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _KartuKonsultasi(k: list[i]),
    );
  }

  Widget _pesan(IconData ikon, String judul, String isi) => Center(
    child: Padding(
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(ikon, size: 48, color: AppColors.textMuted),
          const SizedBox(height: 12),
          Text(judul, style: AppTheme.heading(18)),
          const SizedBox(height: 6),
          Text(isi,
              textAlign: TextAlign.center,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    ),
  );
}

class _KartuKonsultasi extends StatelessWidget {
  final Konsultasi k;
  const _KartuKonsultasi({required this.k});

  void _segera(BuildContext context, String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _bukaMeet(BuildContext context) async {
    final uri = Uri.tryParse(k.meetLink ?? '');
    if (uri == null) return;
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) _segera(context, 'Tidak bisa membuka link Meet.');
  }

  // (teks, warna latar, warna teks)
  (String, Color, Color) get _badge {
    switch (k.status) {
      case StatusKonsultasi.menungguPembayaran:
        return ('Menunggu Bayar', const Color(0xFFFFF1DE), const Color(0xFF9A5200));
      case StatusKonsultasi.menungguVerifikasi:
        return ('Diverifikasi', const Color(0xFFE1EDFB), const Color(0xFF1D4E89));
      case StatusKonsultasi.dikonfirmasi:
        return ('Dikonfirmasi', const Color(0xFFDDF3E4), const Color(0xFF1B6B3A));
      case StatusKonsultasi.selesai:
        return ('Selesai', AppColors.sageMuda, AppColors.primary);
      case StatusKonsultasi.ditolak:
        return ('Ditolak', const Color(0xFFF7E3DD), const Color(0xFFB3392F));
      default:
        return ('Dibatalkan', const Color(0xFFF7E3DD), const Color(0xFFB3392F));
    }
  }

  @override
  Widget build(BuildContext context) {
    final badge = _badge;
    final arsitek = DataArsitek.byId(k.arsitekId);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (arsitek != null)
              ArsitekFoto(
                arsitek: arsitek,
                width: 48,
                height: 48,
                borderRadius: BorderRadius.circular(14),
                fontSize: 17,
              )
            else
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.primary,
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: Text(
                  k.arsitekNama.isEmpty ? '?' : k.arsitekNama[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.arsitekNama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                  Text(k.spesialis,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: badge.$2,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(badge.$1,
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: badge.$3)),
            ),
          ]),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              _chip(Icons.calendar_today_outlined, _tanggalIndo(k.tanggal)),
              _chip(Icons.schedule, '${k.jam} – ${k.jamSelesai}'),
              Row(mainAxisSize: MainAxisSize.min, children: [
                Icon(k.online ? Icons.videocam_outlined : Icons.apartment,
                    size: 16, color: AppColors.primary),
                const SizedBox(width: 5),
                Text(k.online ? 'Online' : 'Studio',
                    style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
              ]),
            ],
          ),
          ..._aksi(context),
        ],
      ),
    );
  }

  Widget _chip(IconData ikon, String teks) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(ikon, size: 14, color: AppColors.textDark),
      const SizedBox(width: 6),
      Text(teks,
          style:
          const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w500)),
    ]),
  );

  String _teksBatal() {
    if (k.status == StatusKonsultasi.ditolak) {
      return 'Pembayaran ditolak admin. Hubungi CS bila ada pertanyaan.';
    }
    final oleh = switch (k.dibatalkanOleh) {
      'arsitek' => 'Dibatalkan oleh arsitek.',
      'sistem' => 'Dibatalkan otomatis karena melewati batas waktu bayar.',
      _ => 'Dibatalkan olehmu.',
    };
    if (k.refundNominal > 0) {
      final proses = k.refundStatus == 'selesai'
          ? 'Refund sudah dikirim.'
          : 'Refund sedang diproses admin, estimasi 1 sampai 3 hari kerja.';
      return '$oleh Refund ${k.refundPersen}% '
          '(${formatRupiah(k.refundNominal)}). $proses';
    }
    return '$oleh Tidak ada refund yang perlu diproses.';
  }

  void _jadwalUlang(BuildContext context) {
    final alasan = KonsultasiService.alasanTidakBisaJadwalUlang(k);
    if (alasan != null) {
      _segera(context, alasan);
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => JadwalUlangScreen(konsultasi: k)),
    );
  }

  Future<void> _batalkan(BuildContext context) async {
    final persen = KonsultasiService.hitungRefundPersen(k);
    final nominal = k.harga * persen ~/ 100;
    final yakin = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Batalkan konsultasi?', style: AppTheme.heading(20)),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: persen == 0
                    ? const Color(0xFFF7E3DD)
                    : AppColors.sageMuda,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    persen == 0
                        ? 'Tidak ada refund'
                        : 'Refund $persen% · ${formatRupiah(nominal)}',
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    persen == 100
                        ? 'Dibatalkan lebih dari 24 jam sebelum sesi.'
                        : persen == 50
                        ? 'Dibatalkan 6 sampai 24 jam sebelum sesi.'
                        : 'Dibatalkan kurang dari 6 jam sebelum sesi.',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Slot jadwal akan dibuka kembali. Refund diproses admin dalam '
                  '1 sampai 3 hari kerja.',
              style: TextStyle(
                  fontSize: 12.5, height: 1.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 18),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.primary),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tidak jadi',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton(
                  onPressed: () => Navigator.pop(ctx, true),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    backgroundColor: const Color(0xFFB3392F),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Ya, batalkan',
                      style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
    if (yakin != true) return;
    try {
      await KonsultasiService.batalkan(k,
          oleh: 'user', alasan: 'Dibatalkan oleh klien');
      if (context.mounted) {
        _segera(context, 'Konsultasi dibatalkan.');
      }
    } catch (_) {
      if (context.mounted) _segera(context, 'Gagal membatalkan. Coba lagi.');
    }
  }

  // Tombol/isi bawah kartu, tergantung status.
  List<Widget> _aksi(BuildContext context) {
    switch (k.status) {
      case StatusKonsultasi.menungguPembayaran:
        final b = k.batasBayar;
        return [
          if (b != null) ...[
            const SizedBox(height: 10),
            Row(children: [
              const Icon(Icons.timer_outlined,
                  size: 16, color: Color(0xFF9A5200)),
              const SizedBox(width: 6),
              Text(
                  'Bayar sebelum ${b.day} ${_bulan[b.month - 1]}, ${_jamMenit(b)}',
                  style: const TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9A5200))),
            ]),
          ],
          const SizedBox(height: 12),
          _tombolPenuh(
            'Lihat Rekening & Unggah Bukti',
            const Color(0xFFB45F06),
                () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => PembayaranScreen(konsultasiId: k.id)),
            ),
          ),
        ];
      case StatusKonsultasi.menungguVerifikasi:
        return [
          const SizedBox(height: 12),
          _info('Bukti pembayaran sudah dikirim. Admin akan memverifikasi, '
              'biasanya dalam 1 x 24 jam.'),
        ];
      case StatusKonsultasi.dikonfirmasi:
        final mulai = k.mulai;
        final aktifMeet = k.online &&
            (k.meetLink ?? '').isNotEmpty &&
            mulai != null &&
            DateTime.now().isAfter(mulai.subtract(const Duration(minutes: 15)));
        return [
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _tombolGaris('Jadwal Ulang', AppColors.primary,
                      () => _jadwalUlang(context)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _tombolGaris('Batalkan', const Color(0xFFB3392F),
                      () => _batalkan(context)),
            ),
          ]),
          const SizedBox(height: 10),
          Row(children: [
            if (k.online)
              Expanded(
                child: aktifMeet
                    ? FilledButton(
                  onPressed: () => _bukaMeet(context),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(44),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Buka Meet',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700)),
                )
                    : Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEDE8DD),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFFD7D0C2)),
                  ),
                  child: Text(
                    mulai == null
                        ? 'Link menyusul'
                        : 'Link aktif ${_jamMenit(mulai.subtract(const Duration(minutes: 15)))}',
                    style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMuted),
                  ),
                ),
              ),
          ]),
        ];
      case StatusKonsultasi.selesai:
        return [
          const SizedBox(height: 12),
          StreamBuilder<bool>(
            stream: UlasanService.sudahDiulas(k.id),
            builder: (context, snap) {
              if (snap.data == true) {
                return Container(
                  height: 44,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.sageMuda,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.check_circle,
                          size: 18, color: AppColors.primary),
                      SizedBox(width: 6),
                      Text('Ulasan terkirim',
                          style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ],
                  ),
                );
              }
              return _tombolPenuh(
                'Beri Ulasan',
                AppColors.primary,
                    () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => UlasanFormScreen(konsultasi: k)),
                ),
              );
            },
          ),
        ];
      default: // dibatalkan / ditolak
        return [
          const SizedBox(height: 12),
          _info(_teksBatal()),
        ];
    }
  }

  Widget _info(String teks) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColors.background,
      borderRadius: BorderRadius.circular(12),
    ),
    child: Text(teks,
        style: const TextStyle(
            fontSize: 12, height: 1.45, color: AppColors.textMuted)),
  );

  Widget _tombolPenuh(String teks, Color warna, VoidCallback onTap) =>
      FilledButton(
        onPressed: onTap,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          backgroundColor: warna,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: Text(teks,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
      );

  Widget _tombolGaris(String teks, Color warna, VoidCallback onTap,
      {IconData? ikon, double tinggi = 40}) =>
      OutlinedButton.icon(
        onPressed: onTap,
        icon: ikon == null
            ? const SizedBox.shrink()
            : Icon(ikon, size: 16, color: warna),
        label: Text(teks,
            style: TextStyle(
                fontSize: 12.5, fontWeight: FontWeight.w700, color: warna)),
        style: OutlinedButton.styleFrom(
          minimumSize: Size.fromHeight(tinggi),
          side: BorderSide(color: warna, width: 1.5),
          backgroundColor: Colors.white,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
}