import 'package:flutter/material.dart';
import '../data/arsitek_data.dart';
import '../screens/konsultasi/detail_arsitek_screen.dart';
import '../theme/app_theme.dart';
import 'arsitek_foto.dart';

void bukaDetailArsitek(BuildContext context, Arsitek a) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => DetailArsitekScreen(arsitek: a)),
  );
}

Widget _pilPutih(Widget child) => Container(
  padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
  decoration: BoxDecoration(
    color: Colors.white.withValues(alpha: 0.92),
    borderRadius: BorderRadius.circular(16),
  ),
  child: child,
);

/// Judul bagian + teks kecil di kanan (dipakai bersama).
class JudulBagian extends StatelessWidget {
  final String judul;
  final Widget? kanan;
  const JudulBagian(this.judul, {super.key, this.kanan});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
      child: Row(
        children: [
          Expanded(child: Text(judul, style: AppTheme.heading(18))),
          if (kanan != null) kanan!,
        ],
      ),
    );
  }
}

/// 3 arsitek dengan rating tertinggi (kotak kecil berfoto).
class TopRekomendasi extends StatelessWidget {
  const TopRekomendasi({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<int>(
        valueListenable: DataArsitek.versi,
        builder: (context, _, __) => _isi(context),
      );

  Widget _isi(BuildContext context) {
    final top = DataArsitek.top.take(3).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JudulBagian(
          'Top Rekomendasi',
          kanan: Row(children: [
            Icon(Icons.star, size: 14, color: Color(0xFFF5B301)),
            SizedBox(width: 4),
            Text('Rating tertinggi',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (int i = 0; i < top.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(child: _tile(context, top[i], i + 1)),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _tile(BuildContext context, Arsitek a, int urut) {
    return GestureDetector(
      onTap: () => bukaDetailArsitek(context, a),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Stack(
            children: [
              ArsitekFoto(
                arsitek: a,
                width: double.infinity,
                height: 116,
                borderRadius: BorderRadius.circular(18),
                fontSize: 30,
              ),
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF5B301),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text('TOP $urut',
                      style: const TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w700)),
                ),
              ),
              Positioned(
                left: 8,
                bottom: 8,
                child: _pilPutih(Row(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.star, size: 11, color: Color(0xFFF5B301)),
                  const SizedBox(width: 2),
                  Text(a.rating.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 11, fontWeight: FontWeight.w700)),
                ])),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(a.nama,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          Text(a.spesialis,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style:
              const TextStyle(fontSize: 11, color: AppColors.textMuted)),
        ],
      ),
    );
  }
}

/// Carousel kartu arsitek yang bisa digeser + titik indikator.
class ArsitekCarousel extends StatefulWidget {
  final List<Arsitek> daftar;
  const ArsitekCarousel({super.key, required this.daftar});

  @override
  State<ArsitekCarousel> createState() => _ArsitekCarouselState();
}

class _ArsitekCarouselState extends State<ArsitekCarousel> {
  final _ctrl = PageController(viewportFraction: 0.78);
  int _halaman = 0;

  @override
  void didUpdateWidget(covariant ArsitekCarousel old) {
    super.didUpdateWidget(old);
    if (old.daftar.length != widget.daftar.length) {
      _halaman = 0;
      if (_ctrl.hasClients) _ctrl.jumpToPage(0);
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final daftar = widget.daftar;
    if (daftar.isEmpty) return const SizedBox.shrink();
    return Column(
      children: [
        SizedBox(
          height: 420,
          child: PageView.builder(
            controller: _ctrl,
            itemCount: daftar.length,
            onPageChanged: (i) => setState(() => _halaman = i),
            itemBuilder: (context, i) {
              return AnimatedBuilder(
                animation: _ctrl,
                builder: (context, child) {
                  double jarak = (_halaman - i).toDouble();
                  if (_ctrl.hasClients && _ctrl.position.haveDimensions) {
                    jarak = (_ctrl.page ?? _halaman.toDouble()) - i;
                  }
                  final skala = (1 - jarak.abs() * 0.12).clamp(0.85, 1.0);
                  return Center(
                    child:
                    Transform.scale(scale: skala.toDouble(), child: child),
                  );
                },
                child: _kartu(context, daftar[i]),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (int i = 0; i < daftar.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _halaman ? 22 : 7,
                height: 7,
                decoration: BoxDecoration(
                  color: i == _halaman ? AppColors.primary : AppColors.border,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ],
        ),
      ],
    );
  }

  Widget _kartu(BuildContext context, Arsitek a) {
    return GestureDetector(
      onTap: () => bukaDetailArsitek(context, a),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.12),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 8, 8, 0),
              child: Stack(
                children: [
                  ArsitekFoto(
                    arsitek: a,
                    width: double.infinity,
                    height: 236,
                    borderRadius: BorderRadius.circular(22),
                    fontSize: 56,
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: _pilPutih(Row(mainAxisSize: MainAxisSize.min, children: [
                      const Icon(Icons.star, size: 14, color: Color(0xFFF5B301)),
                      const SizedBox(width: 3),
                      Text(a.rating.toStringAsFixed(1),
                          style: const TextStyle(
                              fontSize: 12, fontWeight: FontWeight.w700)),
                    ])),
                  ),
                  Positioned(
                    left: 10,
                    bottom: 10,
                    child: _pilPutih(Text('${a.pengalamanTahun} thn',
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w700))),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(a.nama,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700)),
                          Text(a.gelar,
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.10),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(a.spesialis,
                                style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary)),
                          ),
                          const SizedBox(height: 6),
                          Text('${a.jumlahProyek}+ proyek',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                    Container(
                      width: 42,
                      height: 42,
                      decoration: const BoxDecoration(
                          color: AppColors.primary, shape: BoxShape.circle),
                      child: const Icon(Icons.arrow_forward,
                          color: Colors.white, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// "Cara kerjanya": 3 langkah singkat.
class CaraKerja extends StatelessWidget {
  const CaraKerja({super.key});

  @override
  Widget build(BuildContext context) {
    const langkah = [
      (Icons.search, 'Pilih', 'Geser dan pilih arsitek yang cocok'),
      (Icons.calendar_today_outlined, 'Jadwalkan',
      'Tentukan tanggal, jam, dan metode'),
      (Icons.chat_bubble_outline, 'Ngobrol', 'Diskusi langsung di sesi konsultasi'),
    ];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const JudulBagian('Cara kerjanya'),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (int i = 0; i < langkah.length; i++) ...[
                if (i > 0) const SizedBox(width: 10),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(langkah[i].$1,
                              size: 18, color: AppColors.primary),
                        ),
                        const SizedBox(height: 10),
                        Text(langkah[i].$2,
                            style: const TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w700)),
                        const SizedBox(height: 2),
                        Text(langkah[i].$3,
                            style: const TextStyle(
                                fontSize: 11,
                                height: 1.4,
                                color: AppColors.textMuted)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

/// Strip foto "Perumahan Pilihan". Data sementara (statis);
/// nanti diganti data asli dari tab Perumahan (Anggota 4).
class PerumahanPilihan extends StatelessWidget {
  /// Dipanggil saat foto / "Lihat semua" diketuk (buka tab Perumahan).
  final VoidCallback onBuka;
  const PerumahanPilihan({super.key, required this.onBuka});

  static const _item = [
    ('lib/images/dashboardperumahan1.jpg', 'Griya Asri', 'Depok'),
    ('lib/images/dashboardperumahan2.jpg', 'Taman Cendana', 'Bogor'),
    ('lib/images/dashboardperumahan3.jpg', 'Bukit Hijau', 'Tangerang'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        JudulBagian(
          'Perumahan Pilihan',
          kanan: GestureDetector(
            onTap: onBuka,
            child: const Row(children: [
              Text('Lihat semua',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary)),
              SizedBox(width: 4),
              Icon(Icons.arrow_forward, size: 16, color: AppColors.primary),
            ]),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 224,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: _item.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final (foto, nama, kota) = _item[i];
              return GestureDetector(
                onTap: onBuka,
                child: SizedBox(
                  width: 156,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(22),
                        child: Stack(
                          children: [
                            Image.asset(
                              foto,
                              width: 156,
                              height: 190,
                              fit: BoxFit.cover,
                              cacheWidth: 500,
                              errorBuilder: (_, __, ___) => Container(
                                width: 156,
                                height: 190,
                                color: AppColors.sageMuda,
                                child: const Icon(Icons.home_work_outlined,
                                    color: AppColors.primary, size: 36),
                              ),
                            ),
                            Positioned(
                              left: 10,
                              bottom: 10,
                              child: _pilPutih(Text(kota,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600))),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(nama,
                          style: const TextStyle(
                              fontSize: 13, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, 0),
          child: Text('Ketuk foto untuk membuka tab Perumahan.',
              style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
        ),
      ],
    );
  }
}