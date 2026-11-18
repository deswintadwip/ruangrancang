import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/konsultasi.dart';
import '../../models/pesanan_sketsa.dart';
import '../../services/auth_service.dart';
import '../../services/konsultasi_service.dart';
import '../../services/notifikasi_service.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import '../notifikasi/notifikasi_screen.dart';
import 'arsitek_detail_screen.dart';
import 'arsitek_kerjaan_screen.dart';
import 'arsitek_util.dart';
import 'kerjaan_arsitek.dart';

/// Beranda arsitek: sesi berikutnya, ringkasan angka, pengingat kerjaan,
/// lalu daftar konsultasi & sketsa per kategori.
class ArsitekBerandaTab extends StatefulWidget {
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
        builder: (context, snapK) {
          return StreamBuilder<List<PesananSketsa>>(
            stream: PesananSketsaService.untukSaya(),
            builder: (context, snapS) {
              final memuat = !snapK.hasData || !snapS.hasData;
              final kList = (snapK.data ?? const <Konsultasi>[])
                  .where(tampilDiArsitek)
                  .toList();
              final sList = snapS.data ?? const <PesananSketsa>[];
              final sekarang = DateTime.now();

              final aktifK = kList
                  .where((k) => k.status == StatusKonsultasi.dikonfirmasi)
                  .toList();
              final berikut = aktifK.where((k) {
                final m = k.mulai;
                return m != null &&
                    m.isAfter(sekarang.subtract(const Duration(hours: 2)));
              }).toList()
                ..sort((a, b) =>
                    (a.mulai ?? DateTime(2100)).compareTo(b.mulai ?? DateTime(2100)));
              final sesi = berikut.isEmpty ? null : berikut.first;

              final items = [
                ...itemDariKonsultasi(kList),
                ...itemDariSketsa(sList),
              ];
              final pengingat = items.where((e) => e.aktif).toList()
                ..sort((a, b) {
                  if (a.mendesak != b.mendesak) return a.mendesak ? -1 : 1;
                  return a.waktuUrut.compareTo(b.waktuUrut);
                });
              final konsulItems = items
                  .where((e) => e.jenis == JenisKerjaan.konsultasi)
                  .toList()
                ..sort((a, b) => b.waktuUrut.compareTo(a.waktuUrut));
              final sketsaItems = items
                  .where((e) => e.jenis == JenisKerjaan.sketsa)
                  .toList()
                ..sort((a, b) => b.waktuUrut.compareTo(a.waktuUrut));

              bool bulanIni(DateTime? d) =>
                  d != null && d.year == sekarang.year && d.month == sekarang.month;
              final sketsaAktif =
                  sList.where((p) => p.status == StatusSketsa.dikerjakan).length;
              final selesaiBulanIni = kList.where((k) {
                final d = DateTime.tryParse(k.tanggal);
                return k.status == StatusKonsultasi.selesai && bulanIni(d);
              }).length +
                  sList
                      .where((p) =>
                  p.status == StatusSketsa.selesai &&
                      bulanIni(p.hasilAt ?? p.createdAt))
                      .length;

              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  _header(),
                  const SizedBox(height: 18),
                  if (memuat)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator()),
                    )
                  else ...[
                    _kartuSesi(sesi),
                    const SizedBox(height: 16),
                    Row(children: [
                      _stat('${aktifK.length}', 'Konsultasi aktif'),
                      const SizedBox(width: 10),
                      _stat('$sketsaAktif', 'Sketsa aktif'),
                      const SizedBox(width: 10),
                      _stat('$selesaiBulanIni', 'Selesai bln ini'),
                    ]),
                    const SizedBox(height: 22),
                    _pengingat(pengingat),
                    const SizedBox(height: 24),
                    _seksi('Konsultasi', konsulItems),
                    const SizedBox(height: 20),
                    _seksi('Sketsa', sketsaItems),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ───── Pengingat ─────
  Widget _pengingat(List<ItemKerjaan> items) {
    final tampil = items.take(5).toList();
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 12, 12),
            child: Row(children: [
              const Icon(Icons.notifications_active_outlined,
                  size: 20, color: AppColors.primary),
              const SizedBox(width: 8),
              Expanded(child: Text('Pengingat', style: AppTheme.heading(17))),
              GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const ArsitekKerjaanScreen()),
                ),
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: AppColors.sageMuda,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.sage),
                  ),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Text('Lihat semua',
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary)),
                    SizedBox(width: 4),
                    Icon(Icons.arrow_forward, size: 14, color: AppColors.primary),
                  ]),
                ),
              ),
            ]),
          ),
          const Divider(height: 1, color: AppColors.border),
          if (tampil.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Tidak ada kerjaan aktif. Mantap! 🎉',
                  style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            )
          else
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Column(children: [
                for (int i = 0; i < tampil.length; i++) ...[
                  if (i > 0) const Divider(height: 1, color: AppColors.border),
                  kartuKerjaan(context, tampil[i], datar: true),
                ],
              ]),
            ),
        ],
      ),
    );
  }

  // ───── Section per kategori ─────
  Widget _seksi(String judul, List<ItemKerjaan> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          Expanded(child: Text(judul, style: AppTheme.heading(18))),
          if (items.length > 3)
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                    builder: (_) => const ArsitekKerjaanScreen()),
              ),
              child: const Text('Lihat semua',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
            ),
        ]),
        const SizedBox(height: 12),
        if (items.isEmpty)
          _kosong('Belum ada $judul.')
        else
          for (final it in items.take(3)) kartuKerjaan(context, it),
      ],
    );
  }

  // ───── header ─────
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

  // ───── kartu sesi berikutnya ─────
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

  Widget _kosong(String teks) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: AppColors.sageMuda,
      borderRadius: BorderRadius.circular(18),
    ),
    child: Text(teks,
        style: const TextStyle(fontSize: 13, color: AppColors.primary)),
  );
}