import 'package:flutter/material.dart';
import '../../data/perumahan_data.dart';
import '../../models/pengaturan.dart';
import '../../services/pengaturan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/gambar_proyek.dart';
import 'pesan_rumah_screen.dart';

/// Detail perumahan: foto, tipe rumah (pilih satu), fasilitas, booking fee.
class PerumahanDetailScreen extends StatefulWidget {
  final Perumahan perumahan;
  const PerumahanDetailScreen({super.key, required this.perumahan});

  @override
  State<PerumahanDetailScreen> createState() => _PerumahanDetailScreenState();
}

class _PerumahanDetailScreenState extends State<PerumahanDetailScreen> {
  int _foto = 0;
  int _tipe = 0;

  Widget _judul(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t, style: AppTheme.heading(18)),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.perumahan;
    final t = p.tipe[_tipe];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(children: [
                  SizedBox(
                    height: 260,
                    child: PageView.builder(
                      itemCount: p.foto.length,
                      onPageChanged: (i) => setState(() => _foto = i),
                      itemBuilder: (_, i) => GambarProyek(p.foto[i],
                          width: double.infinity, cacheWidth: 900),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: IconButton(
                          tooltip: 'Kembali',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < p.foto.length; i++)
                          Container(
                            width: i == _foto ? 18 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _foto
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.nama, style: AppTheme.heading(26)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(p.alamat,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.textMuted)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('Pengembang: ${p.pengembang}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                      _judul('Tentang'),
                      Text(p.deskripsi,
                          style: const TextStyle(fontSize: 13, height: 1.65)),
                      const SizedBox(height: 6),
                      Text('Serah terima: ${p.serahTerima}',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w500)),
                      _judul('Pilih tipe rumah'),
                      for (var i = 0; i < p.tipe.length; i++) ...[
                        _KartuTipe(
                          tipe: p.tipe[i],
                          terpilih: i == _tipe,
                          onTap: () => setState(() => _tipe = i),
                        ),
                        const SizedBox(height: 10),
                      ],
                      _judul('Fasilitas'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final f in p.fasilitas)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(f, style: const TextStyle(fontSize: 12.5)),
                          ),
                      ]),
                      const SizedBox(height: 20),
                      StreamBuilder<Pengaturan>(
                        stream: PengaturanService.stream(),
                        initialData: Pengaturan.bawaan,
                        builder: (context, snap) {
                          final s = snap.data ?? Pengaturan.bawaan;
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                                color: AppColors.sageMuda,
                                borderRadius: BorderRadius.circular(16)),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.info_outline,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                      'Booking fee ${formatRupiah(s.bookingFeeRumah)} untuk menahan unit. Dibayar lewat transfer dalam ${s.batasBayarJam} jam setelah pesanan dibuat, lalu diverifikasi admin.',
                                      style: const TextStyle(
                                          fontSize: 12,
                                          height: 1.55,
                                          color: AppColors.primary)),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.nama,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    Text(formatRupiah(t.harga),
                        style: AppTheme.heading(17)
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              SizedBox(
                width: 170,
                child: ElevatedButton(
                  onPressed: t.sisaUnit == 0
                      ? null
                      : () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PesanRumahScreen(perumahan: p, tipe: t))),
                  child: Text(t.sisaUnit == 0 ? 'Habis' : 'Booking Rumah'),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}

class _KartuTipe extends StatelessWidget {
  final TipeRumah tipe;
  final bool terpilih;
  final VoidCallback onTap;
  const _KartuTipe(
      {required this.tipe, required this.terpilih, required this.onTap});

  Widget _info(IconData i, String t) => Padding(
        padding: const EdgeInsets.only(right: 14),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Icon(i, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(t, style: const TextStyle(fontSize: 12)),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: terpilih ? AppColors.sageMuda : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: terpilih ? AppColors.primary : AppColors.border,
              width: terpilih ? 2 : 1),
        ),
        child: Row(children: [
          Icon(terpilih ? Icons.radio_button_checked : Icons.radio_button_off,
              color: terpilih ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(tipe.nama,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                      tipe.sisaUnit == 0
                          ? 'Habis'
                          : 'Sisa ${tipe.sisaUnit} unit',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: tipe.sisaUnit <= 3
                              ? AppColors.terakota
                              : AppColors.textMuted)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _info(Icons.bed_outlined, '${tipe.kamarTidur} KT'),
                  _info(Icons.bathtub_outlined, '${tipe.kamarMandi} KM'),
                  _info(Icons.square_foot, '${tipe.luasBangunan}/${tipe.luasTanah} m²'),
                ]),
                const SizedBox(height: 6),
                Text(formatRupiah(tipe.harga),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}
