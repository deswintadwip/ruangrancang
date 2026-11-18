import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/konsultasi.dart';
import '../../services/auth_service.dart';
import '../../services/konsultasi_service.dart';
import '../../services/notifikasi_service.dart';
import '../../theme/app_theme.dart';
import '../notifikasi/notifikasi_screen.dart';
import 'arsitek_detail_screen.dart';
import 'arsitek_util.dart';

/// Beranda arsitek: sesi berikutnya, ringkasan angka, dan yang perlu update.
class ArsitekBerandaTab extends StatefulWidget {
  /// Membuka tab lain di cangkang (1 = Konsultasi).
  final ValueChanged<int> onOpenTab;
  const ArsitekBerandaTab({super.key, required this.onOpenTab});

  @override
  State<ArsitekBerandaTab> createState() => _ArsitekBerandaTabState();
}

class _ArsitekBerandaTabState extends State<ArsitekBerandaTab> {
  String _nama = '';

  @override
  void initState() {
    super.initState();
    _muatNama();
  }

  Future<void> _muatNama() async {
    final profil = await AuthService().getUserProfile();
    if (!mounted) return;
    setState(() => _nama = (profil?['nama'] as String?) ?? '');
  }

  String get _sapaan {
    final h = DateTime.now().hour;
    if (h < 11) return 'Selamat pagi,';
    if (h < 15) return 'Selamat siang,';
    if (h < 18) return 'Selamat sore,';
    return 'Selamat malam,';
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: StreamBuilder<List<Konsultasi>>(
        stream: KonsultasiService.milikArsitekSaya(),
        builder: (context, snap) {
          final semua = (snap.data ?? const <Konsultasi>[])
              .where(tampilDiArsitek)
              .toList();
          final aktif = semua
              .where((k) => k.status == StatusKonsultasi.dikonfirmasi)
              .toList();
          final sekarang = DateTime.now();
          final berikut = aktif.where((k) {
            final m = k.mulai;
            return m != null && m.isAfter(sekarang.subtract(const Duration(hours: 2)));
          }).toList();
          final sesi = berikut.isEmpty ? null : berikut.first;
          final perlu = aktif.where(perluUpdate).toList();
          final selesaiBulanIni = semua.where((k) {
            final d = DateTime.tryParse(k.tanggal);
            return k.status == StatusKonsultasi.selesai &&
                d != null &&
                d.year == sekarang.year &&
                d.month == sekarang.month;
          }).length;

          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            children: [
              _header(),
              const SizedBox(height: 18),
              if (!snap.hasData)
                const Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                )
              else ...[
                _kartuSesi(sesi),
                const SizedBox(height: 16),
                Row(children: [
                  _stat('${aktif.length}', 'Konsultasi aktif'),
                  const SizedBox(width: 10),
                  _stat('${perlu.length}', 'Perlu update',
                      sorot: perlu.isNotEmpty),
                  const SizedBox(width: 10),
                  _stat('$selesaiBulanIni', 'Selesai bulan ini'),
                ]),
                const SizedBox(height: 24),
                Row(children: [
                  Expanded(
                      child: Text('Perlu update', style: AppTheme.heading(18))),
                  GestureDetector(
                    onTap: () => widget.onOpenTab(1),
                    child: const Text('Lihat semua',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ]),
                const SizedBox(height: 12),
                if (perlu.isEmpty)
                  _kosong()
                else
                  for (final k in perlu.take(3)) _barisPerluUpdate(k),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _header() {
    return HeaderFoto(bulat: true, child: _headerIsi());
  }

  Widget _headerIsi() {
    return Row(children: [
      CircleAvatar(
        radius: 22,
        backgroundColor: AppColors.primary,
        child: Text(inisialNama(_nama),
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(_sapaan,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textMuted)),
            Text(_nama.isEmpty ? 'Arsitek' : _nama,
                style: AppTheme.heading(20)),
          ],
        ),
      ),
      StreamBuilder<int>(
        stream: NotifikasiService.jumlahBelumDibaca(),
        builder: (context, snap) {
          final n = snap.data ?? 0;
          return IconButton(
            tooltip: 'Notifikasi',
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const NotifikasiScreen()),
            ),
            icon: Badge(
              isLabelVisible: n > 0,
              label: Text(n > 9 ? '9+' : '$n'),
              backgroundColor: const Color(0xFFD9534F),
              child: const Icon(Icons.notifications_none, size: 26),
            ),
          );
        },
      ),
    ]);
  }

  Widget _kartuSesi(Konsultasi? k) {
    if (k == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Belum ada sesi terjadwal',
                style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
            SizedBox(height: 4),
            Text('Sesi yang sudah dikonfirmasi admin akan muncul di sini.',
                style: TextStyle(fontSize: 12.5, color: Colors.white70)),
          ],
        ),
      );
    }
    final m = k.mulai;
    final hariIni = m != null &&
        m.year == DateTime.now().year &&
        m.month == DateTime.now().month &&
        m.day == DateTime.now().day;
    final label =
        '${hariIni ? 'Hari ini · ' : ''}${tanggalLengkap(k.tanggal)}';
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            const Icon(Icons.calendar_today_outlined,
                size: 14, color: Colors.white70),
            const SizedBox(width: 6),
            Text(label,
                style: const TextStyle(fontSize: 12.5, color: Colors.white70)),
          ]),
          const SizedBox(height: 6),
          Text('Sesi berikutnya ${k.jam}',
              style: AppTheme.heading(22).copyWith(color: Colors.white)),
          const SizedBox(height: 14),
          Row(children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              child: Text(inisialNama(k.userNama),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.userNama,
                      style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                  Text(
                      '${k.jam} – ${k.jamSelesai} · ${k.online ? 'Online' : 'Studio'}'
                          '${k.gaya.isEmpty ? '' : ' · ${k.gaya}'}',
                      style: const TextStyle(
                          fontSize: 12, color: Colors.white70)),
                ],
              ),
            ),
          ]),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () => _mulaiSesi(k),
            icon: Icon(k.online ? Icons.videocam_outlined : Icons.apartment,
                size: 18, color: AppColors.primary),
            label: Text(k.online ? 'Mulai Sesi' : 'Lihat Detail Sesi',
                style: const TextStyle(
                    fontWeight: FontWeight.w700, color: AppColors.primary)),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(46),
              backgroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mulaiSesi(Konsultasi k) async {
    final link = k.meetLink ?? '';
    if (k.online && link.isNotEmpty) {
      final ok = await launchUrl(Uri.parse(link),
          mode: LaunchMode.externalApplication);
      if (!ok) _pesan('Tidak bisa membuka link Meet.');
      return;
    }
    // Link Meet belum ada (atau sesi studio): buka detail untuk mengisi/melihat.
    _bukaDetail(k);
  }

  void _bukaDetail(Konsultasi k) {
    Navigator.push(
      context,
      MaterialPageRoute(
          builder: (_) => ArsitekDetailScreen(konsultasiId: k.id)),
    );
  }

  Widget _stat(String angka, String label, {bool sorot = false}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: sorot ? const Color(0xFFF7E3DD) : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: sorot ? const Color(0xFFE8B7AA) : AppColors.border),
        ),
        child: Column(children: [
          Text(angka,
              style: AppTheme.heading(26).copyWith(
                  color: sorot ? const Color(0xFFB3392F) : AppColors.primary)),
          const SizedBox(height: 2),
          Text(label,
              textAlign: TextAlign.center,
              style:
              const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ]),
      ),
    );
  }

  Widget _barisPerluUpdate(Konsultasi k) {
    final u = k.updatedAt;
    final ket = u == null
        ? '${TahapKerja.namaTahap(k.tahapSaatIni)} · belum ada update sejak dikonfirmasi'
        : '${TahapKerja.namaTahap(k.tahapSaatIni)} · update terakhir ${waktuLalu(u)}';
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () => _bukaDetail(k),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.userNama,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 2),
                  Text(ket,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            Container(
              width: 34,
              height: 34,
              decoration: const BoxDecoration(
                  color: Color(0xFFD9A441), shape: BoxShape.circle),
              child: const Icon(Icons.edit_outlined,
                  size: 17, color: Colors.white),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _kosong() => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.sageMuda,
      borderRadius: BorderRadius.circular(18),
    ),
    child: const Text('Semua konsultasi sudah ter-update. Kerja bagus!',
        style: TextStyle(fontSize: 13, color: AppColors.primary)),
  );
}