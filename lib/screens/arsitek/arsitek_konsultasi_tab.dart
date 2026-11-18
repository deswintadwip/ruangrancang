import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import '../../config/tahap.dart';
import '../../models/konsultasi.dart';
import '../../services/konsultasi_service.dart';
import '../../theme/app_theme.dart';
import 'arsitek_detail_screen.dart';
import 'arsitek_util.dart';

/// Daftar konsultasi arsitek dalam bentuk timeline, dengan filter.
class ArsitekKonsultasiTab extends StatefulWidget {
  const ArsitekKonsultasiTab({super.key});

  @override
  State<ArsitekKonsultasiTab> createState() => _ArsitekKonsultasiTabState();
}

class _ArsitekKonsultasiTabState extends State<ArsitekKonsultasiTab> {
  String _filter = 'Semua';
  static const _daftarFilter = ['Semua', 'Aktif', 'Terjadwal', 'Selesai'];

  bool _lolos(Konsultasi k) {
    final kat = kategoriDari(k);
    switch (_filter) {
      case 'Aktif':
        return kat == KategoriKonsultasi.aktif ||
            kat == KategoriKonsultasi.perluUpdate;
      case 'Terjadwal':
        return kat == KategoriKonsultasi.terjadwal;
      case 'Selesai':
        return kat == KategoriKonsultasi.selesai;
      default:
        return true;
    }
  }

  // (warna kartu, warna tepi, warna titik)
  (Color, Color, Color) _warna(KategoriKonsultasi kat) {
    switch (kat) {
      case KategoriKonsultasi.selesai:
        return (AppColors.sageMuda, const Color(0xFFBCD6C4), AppColors.primary);
      case KategoriKonsultasi.aktif:
        return (const Color(0xFFF7EBD2), const Color(0xFFE5D3A5), const Color(0xFFD9A441));
      case KategoriKonsultasi.terjadwal:
        return (const Color(0xFFE1EAF6), const Color(0xFFBFD0E8), const Color(0xFF6A9AD0));
      case KategoriKonsultasi.perluUpdate:
        return (const Color(0xFFF7E3DD), const Color(0xFFE8B7AA), const Color(0xFFD9847A));
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderFoto(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Konsultasi Saya', style: AppTheme.heading(24)),
                const SizedBox(height: 2),
                const Text('Pantau dan perbarui progres tiap klien',
                    style:
                    TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          )),
          const SizedBox(height: 14),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [for (final f in _daftarFilter) _chip(f)],
            ),
          ),
          const SizedBox(height: 14),
          Expanded(
            child: StreamBuilder<List<Konsultasi>>(
              stream: KonsultasiService.milikArsitekSaya(),
              builder: (context, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!
                    .where(tampilDiArsitek)
                    .where(_lolos)
                    .toList()
                  ..sort((a, b) => (a.mulai ?? DateTime.now())
                      .compareTo(b.mulai ?? DateTime.now()));
                if (list.isEmpty) return _kosong();
                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: list.length,
                  itemBuilder: (context, i) =>
                      _baris(list[i], terakhir: i == list.length - 1),
                );
              },
            ),
          ),
        ],
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
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(19),
            border:
            Border.all(color: aktif ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 13,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                  color: aktif ? Colors.white : AppColors.textDark)),
        ),
      ),
    );
  }

  Widget _baris(Konsultasi k, {required bool terakhir}) {
    final kat = kategoriDari(k);
    final w = _warna(kat);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(
              children: [
                const SizedBox(height: 18),
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: kat == KategoriKonsultasi.selesai
                        ? AppColors.primary
                        : AppColors.background,
                    border: Border.all(color: AppColors.primary, width: 3),
                  ),
                  child: kat == KategoriKonsultasi.aktif ||
                      kat == KategoriKonsultasi.perluUpdate
                      ? Center(
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          shape: BoxShape.circle, color: w.$3),
                    ),
                  )
                      : null,
                ),
                if (!terakhir)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 2),
                      color: const Color(0xFFC9BFAA),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _kartu(k, kat, w),
            ),
          ),
        ],
      ),
    );
  }

  Widget _kartu(Konsultasi k, KategoriKonsultasi kat, (Color, Color, Color) w) {
    String pil;
    Color pilWarna;
    switch (kat) {
      case KategoriKonsultasi.selesai:
        pil = 'Selesai';
        pilWarna = AppColors.primary;
      case KategoriKonsultasi.terjadwal:
        final d = DateTime.tryParse(k.tanggal);
        pil = d == null ? 'Terjadwal' : 'Mulai: ${tanggalPendek(k.tanggal).split(' ').take(2).join(' ')}, ${k.jam}';
        pilWarna = AppColors.primary;
      case KategoriKonsultasi.perluUpdate:
        pil = TahapKerja.namaTahap(k.tahapSaatIni);
        pilWarna = const Color(0xFFB3392F);
      case KategoriKonsultasi.aktif:
        pil = TahapKerja.namaTahap(k.tahapSaatIni);
        pilWarna = const Color(0xFFB45F06);
    }

    String bawah;
    switch (kat) {
      case KategoriKonsultasi.selesai:
        bawah = '${TahapKerja.jumlah} dari ${TahapKerja.jumlah} tahap';
      case KategoriKonsultasi.terjadwal:
        bawah = k.online ? 'Online · Google Meet' : 'Datang ke Studio';
      default:
        bawah = k.updatedAt == null
            ? 'Belum ada update'
            : '${k.tahapSaatIni} dari ${TahapKerja.jumlah} tahap · update ${waktuLalu(k.updatedAt)}';
    }

    final detail = [
      if (k.luas.isNotEmpty) '${k.luas} m²',
      if (k.gaya.isNotEmpty) k.gaya,
    ].join(' · ');

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
            builder: (_) => ArsitekDetailScreen(konsultasiId: k.id)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: w.$1,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: w.$2),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                      child: Text(k.userNama,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 15, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: pilWarna,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(pil,
                          style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ),
                  ]),
                  if (detail.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(detail,
                        style: const TextStyle(
                            fontSize: 12, color: Color(0xFF4A4639))),
                  ],
                  const SizedBox(height: 8),
                  Row(children: [
                    const Icon(Icons.calendar_today_outlined,
                        size: 14, color: Color(0xFF4A4639)),
                    const SizedBox(width: 6),
                    Text(
                        '${tanggalPendek(k.tanggal)} · ${k.jam} – ${k.jamSelesai}',
                        style: const TextStyle(fontSize: 12.5)),
                  ]),
                  const SizedBox(height: 4),
                  Text(bawah,
                      style: const TextStyle(
                          fontSize: 12, color: Color(0xFF4A4639))),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: w.$3, shape: BoxShape.circle),
              child: const Icon(Icons.arrow_forward,
                  size: 18, color: Colors.white),
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
          Icon(Icons.inbox_outlined, size: 48, color: AppColors.textMuted),
          SizedBox(height: 12),
          Text('Belum ada konsultasi',
              style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('Konsultasi yang sudah dibayar dan dikonfirmasi admin '
              'muncul di sini.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    ),
  );
}