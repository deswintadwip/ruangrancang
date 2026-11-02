import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/arsitek_data.dart';
import '../../config/status.dart';
import '../../models/konsultasi.dart';
import '../../models/pengaturan.dart';
import '../../models/ulasan_klien.dart';
import '../../services/konsultasi_service.dart';
import '../../services/ulasan_service.dart';
import '../../services/pengaturan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/arsitek_foto.dart';
import '../../config/tarif_sketsa.dart';
import '../sketsa/sketsa_form_screen.dart';
import 'booking_screen.dart';
import 'ulasan_form_screen.dart';

/// Detail satu arsitek: bio, pendidikan, ulasan, sosmed, tombol WhatsApp & Booking.
class DetailArsitekScreen extends StatelessWidget {
  final Arsitek arsitek;
  const DetailArsitekScreen({super.key, required this.arsitek});

  Future<void> _buka(BuildContext context, Uri uri, String gagal) async {
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(gagal)));
    }
  }

  Uri? _linkLuar(String? alamat) {
    if (alamat == null || alamat.trim().isEmpty) return null;
    final a = alamat.trim();
    return Uri.tryParse(a.startsWith('http') ? a : 'https://$a');
  }

  @override
  Widget build(BuildContext context) {
    final a = arsitek;
    return StreamBuilder<List<UlasanKlien>>(
      stream: UlasanService.untukArsitek(a.id),
      builder: (context, snap) {
        final r = _Ringkas.dari(a, snap.data ?? const []);
        return _halaman(context, a, r);
      },
    );
  }

  Widget _halaman(BuildContext context, Arsitek a, _Ringkas r) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                _fotoDanStatistik(context, a, r),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 34, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.nama, style: AppTheme.heading(26)),
                      const SizedBox(height: 4),
                      Text('${a.gelar} · Arsitek ${a.spesialis}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                      _judul('Tentang'),
                      Text(a.tentang,
                          style: const TextStyle(
                              fontSize: 14,
                              height: 1.65,
                              color: Color(0xFF5C564A))),
                      _judul('Pendidikan'),
                      for (final p in a.pendidikan) _kartuPendidikan(p),
                      _judul('Keahlian'),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final k in a.keahlian)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(k,
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w500)),
                            ),
                        ],
                      ),
                      _judul('Jam Praktik'),
                      _kotak(Row(children: [
                        const Icon(Icons.schedule,
                            size: 20, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                            child: Text(a.jamPraktik,
                                style: const TextStyle(fontSize: 14))),
                      ])),
                      _bagianUlasan(context, a, r),
                      _judul('Ikuti & Hubungi'),
                      _sosmed(context, a),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ],
            ),
          ),
          _barBawah(context),
        ],
      ),
    );
  }

  // ── Foto besar + 3 kartu statistik yang menimpa foto ──
  Widget _fotoDanStatistik(BuildContext context, Arsitek a, _Ringkas r) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 42),
          child: ClipRRect(
            borderRadius:
            const BorderRadius.vertical(bottom: Radius.circular(36)),
            child: SizedBox(
              height: 360,
              width: double.infinity,
              child: ArsitekFoto(
                arsitek: a,
                width: double.infinity,
                height: 360,
                borderRadius: BorderRadius.zero,
                fontSize: 96,
              ),
            ),
          ),
        ),
        Positioned(
          top: MediaQuery.of(context).padding.top + 12,
          left: 16,
          child: CircleAvatar(
            radius: 21,
            backgroundColor: Colors.white.withValues(alpha: 0.92),
            child: IconButton(
              tooltip: 'Kembali',
              icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
              onPressed: () => Navigator.pop(context),
            ),
          ),
        ),
        if (a.topRekomendasi)
          Positioned(
            top: MediaQuery.of(context).padding.top + 18,
            right: 16,
            child: Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
              decoration: BoxDecoration(
                color: const Color(0xFFF5B301),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Text('TOP REKOMENDASI',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ),
        Positioned(
          left: 20,
          right: 20,
          bottom: 0,
          child: Row(
            children: [
              _stat(Icons.workspace_premium_outlined,
                  '${a.pengalamanTahun} thn', 'Pengalaman'),
              const SizedBox(width: 10),
              _stat(Icons.star_rounded, r.rating.toStringAsFixed(1), 'Rating',
                  warnaIkon: const Color(0xFFF5B301)),
              const SizedBox(width: 10),
              _stat(Icons.home_work_outlined, '${a.jumlahProyek}+', 'Proyek'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _stat(IconData ikon, String nilai, String label, {Color? warnaIkon}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.08),
                blurRadius: 14,
                offset: const Offset(0, 6)),
          ],
        ),
        child: Column(
          children: [
            Icon(ikon, size: 22, color: warnaIkon ?? AppColors.primary),
            const SizedBox(height: 6),
            Text(nilai,
                style:
                const TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }

  Widget _judul(String teks) => Padding(
    padding: const EdgeInsets.only(top: 24, bottom: 10),
    child: Text(teks, style: AppTheme.heading(17)),
  );

  Widget _kotak(Widget isi) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: AppColors.border),
    ),
    child: isi,
  );

  Widget _kartuPendidikan(Pendidikan p) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.10),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school_outlined,
              size: 20, color: AppColors.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.judul,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              const SizedBox(height: 1),
              Text(p.lembaga,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
      ]),
    ),
  );

  // ── Ulasan ──
  Widget _bagianUlasan(BuildContext context, Arsitek a, _Ringkas r) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _judul('Ulasan Klien'),
        _aksiUlasan(context, a),
        const SizedBox(height: 12),
        _kotak(Row(children: [
          Column(children: [
            Text(r.rating.toStringAsFixed(1),
                style: AppTheme.heading(42).copyWith(height: 1)),
            const SizedBox(height: 6),
            Row(children: [
              for (int i = 1; i <= 5; i++)
                Icon(
                  r.rating >= i
                      ? Icons.star_rounded
                      : (r.rating >= i - 0.5
                      ? Icons.star_half_rounded
                      : Icons.star_outline_rounded),
                  size: 16,
                  color: const Color(0xFFF5B301),
                ),
            ]),
            const SizedBox(height: 6),
            Text('${r.jumlah} ulasan terverifikasi',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ]),
          const SizedBox(width: 18),
          Expanded(
            child: Column(children: [
              for (int b = 5; b >= 1; b--) _batang(r.daftar, b),
            ]),
          ),
        ])),
        for (final u in r.daftar.take(3)) _kartuUlasan(u),
      ],
    );
  }

  /// Teks / tombol di bawah judul "Ulasan Klien":
  /// belum pernah konsul -> info; sudah selesai tapi belum diulas -> tombol.
  Widget _aksiUlasan(BuildContext context, Arsitek a) {
    return StreamBuilder<List<Konsultasi>>(
      stream: KonsultasiService.milikSaya(),
      builder: (context, snapK) {
        return StreamBuilder<Set<String>>(
          stream: UlasanService.idDiulasSaya(),
          builder: (context, snapU) {
            final selesai = (snapK.data ?? const <Konsultasi>[])
                .where((k) =>
            k.arsitekId == a.id &&
                k.status == StatusKonsultasi.selesai)
                .toList();
            final diulas = snapU.data ?? <String>{};
            final belum = selesai.where((k) => !diulas.contains(k.id)).toList();

            if (selesai.isEmpty) {
              return const Text('Ulasan terbuka setelah sesi selesai.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted));
            }
            if (belum.isEmpty) {
              return const Text('Terima kasih, kamu sudah mengulas arsitek ini.',
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted));
            }
            return Align(
              alignment: Alignment.centerLeft,
              child: OutlinedButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) =>
                          UlasanFormScreen(konsultasi: belum.first)),
                ),
                icon: const Icon(Icons.edit_outlined,
                    size: 16, color: AppColors.primary),
                label: const Text('Tulis Ulasan',
                    style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primary)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20)),
                ),
              ),
            );
          },
        );
      },
    );
  }

  // Batang distribusi dihitung dari daftar ulasan contoh yang ada.
  Widget _batang(List<Ulasan> daftar, int bintang) {
    final total = daftar.isEmpty ? 1 : daftar.length;
    final jumlah = daftar.where((u) => u.bintang.round() == bintang).length;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        SizedBox(
            width: 10,
            child: Text('$bintang',
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted))),
        const SizedBox(width: 8),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(3),
            child: LinearProgressIndicator(
              value: jumlah / total,
              minHeight: 6,
              backgroundColor: AppColors.border,
              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
            ),
          ),
        ),
      ]),
    );
  }

  Widget _kartuUlasan(Ulasan u) => Padding(
    padding: const EdgeInsets.only(top: 10),
    child: _kotak(Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          CircleAvatar(
            radius: 19,
            backgroundColor: AppColors.primary,
            child: Text(u.inisial,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(u.nama,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text.rich(TextSpan(
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted),
                  children: [
                    TextSpan(text: '${u.waktu} · '),
                    const TextSpan(
                      text: 'Klien terverifikasi',
                      style: TextStyle(
                          color: Color(0xFF1B7F4B),
                          fontWeight: FontWeight.w700),
                    ),
                  ],
                )),
              ],
            ),
          ),
          const Icon(Icons.star_rounded,
              size: 16, color: Color(0xFFF5B301)),
          const SizedBox(width: 3),
          Text(u.bintang.toStringAsFixed(1),
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w700)),
        ]),
        const SizedBox(height: 10),
        Text(u.isi,
            style: const TextStyle(
                fontSize: 13, height: 1.55, color: Color(0xFF5C564A))),
        if (u.balasan != null) ...[
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.background,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text('Balasan arsitek: ${u.balasan}',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ],
    )),
  );

  // ── Sosmed: tombol yang datanya kosong disembunyikan ──
  Widget _sosmed(BuildContext context, Arsitek a) {
    final daftar = <(String, IconData, Uri?)>[
      ('Instagram', Icons.camera_alt_outlined, _linkLuar(a.instagram)),
      ('LinkedIn', Icons.work_outline, _linkLuar(a.linkedin)),
      ('Website', Icons.language, _linkLuar(a.website)),
    ].where((e) => e.$3 != null).toList();

    if (daftar.isEmpty) {
      return const Text(
          'Arsitek ini belum menambahkan tautan.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted));
    }
    return Row(children: [
      for (int i = 0; i < daftar.length; i++) ...[
        if (i > 0) const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _buka(context, daftar[i].$3!,
                'Tidak bisa membuka ${daftar[i].$1}.'),
            icon: Icon(daftar[i].$2, size: 18, color: AppColors.textDark),
            label: Text(daftar[i].$1,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textDark)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
              backgroundColor: AppColors.surface,
              side: const BorderSide(color: AppColors.border),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(24)),
            ),
          ),
        ),
      ],
    ]);
  }

  // ── Bar bawah: biaya (dari Pengaturan admin) + WhatsApp + Booking ──
  Widget _barBawah(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 16 + MediaQuery.of(context).padding.bottom * 0.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => BookingScreen(arsitek: arsitek)),
            ),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Booking Konsultasi',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => SketsaFormScreen(arsitek: arsitek)),
            ),
            icon: const Icon(Icons.draw_outlined,
                size: 18, color: AppColors.primary),
            label: const Text('Pesan Sketsa Desain',
                style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

/// Ringkasan rating & daftar ulasan yang ditampilkan.
/// Kalau sudah ada ulasan asli dari Firestore, itu yang dipakai.
/// Kalau belum, tampil data contoh (hanya selama masa pengembangan).
class _Ringkas {
  final double rating;
  final int jumlah;
  final List<Ulasan> daftar;
  const _Ringkas(this.rating, this.jumlah, this.daftar);

  factory _Ringkas.dari(Arsitek a, List<UlasanKlien> live) {
    if (live.isEmpty) return _Ringkas(a.rating, a.jumlahUlasan, a.ulasan);
    final total = live.fold<double>(0, (s, u) => s + u.bintang);
    return _Ringkas(
        total / live.length, live.length, live.map((u) => u.keUlasan()).toList());
  }
}