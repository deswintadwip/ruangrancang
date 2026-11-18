import 'package:flutter/material.dart';
import '../../data/arsitek_data.dart';
import '../../models/proyek.dart';
import '../../services/notifikasi_service.dart';
import '../../services/proyek_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/header_foto.dart';
import '../../widgets/arsitek_sections.dart';
import '../../widgets/gambar_proyek.dart';
import '../../widgets/scroll_pass.dart';
import '../../services/promo_service.dart';
import 'beranda_kontak.dart';
import 'cari_screen.dart';
import 'hero_banner.dart';
import '../notifikasi/notifikasi_screen.dart';
import 'semua_proyek_page.dart';

/// Tab Beranda (dashboard user).
class BerandaTab extends StatefulWidget {
  final String nama;

  /// Dipanggil saat menu/tombol ingin membuka tab lain (1 = Konsultasi, dst.)
  final ValueChanged<int> onOpenTab;

  const BerandaTab({super.key, required this.nama, required this.onOpenTab});

  @override
  State<BerandaTab> createState() => _BerandaTabState();
}

class _BerandaTabState extends State<BerandaTab> {
  /// Foto banner yang bergeser otomatis
  static const _bannerImages = [
    'lib/images/rumahdashboard1.jpg',
    'lib/images/rumahdashboard2.jpg',
    'lib/images/rumahdashboard3.jpg',
    'lib/images/rumahdashboard4.jpg',
  ];

  /// Scroll halaman. Dipakai juga oleh ForwardWheel supaya roda mouse di atas
  /// carousel/hero tetap menggulung halaman (perbaikan scroll "nyangkut" di web).
  final ScrollController _scroll = ScrollController();

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: ListView(
        controller: _scroll,
        padding: EdgeInsets.zero, // footer sudah punya jarak sendiri
        children: [
          _buildHeader(context),
          ForwardWheel(
            parent: _scroll,
            child: HeroBanner(
              images: _bannerImages,
              onSearchTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const CariScreen()),
              ),
            ),
          ),
          StreamBuilder<bool>(
            stream: PromoService.berhakKonsultasiGratis(),
            builder: (context, snap) {
              if (snap.data != true) return const SizedBox(height: 16);
              return Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: InkWell(
                  borderRadius: BorderRadius.circular(16),
                  onTap: () => widget.onOpenTab(1),
                  child: Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFF1D6),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: const Color(0xFFD9A441)),
                    ),
                    child: Row(children: [
                      const Icon(Icons.card_giftcard, color: Color(0xFF8A5A00), size: 30),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('PROMO PENGGUNA BARU',
                                style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.6,
                                    color: Color(0xFF8A5A00))),
                            SizedBox(height: 2),
                            Text('Konsultasi pertamamu GRATIS!',
                                style: TextStyle(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF2B2A27))),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right, color: Color(0xFF8A5A00)),
                    ]),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _buildMenu(),
          const SizedBox(height: 20),
          const TopRekomendasi(),
          const SizedBox(height: 28),
          ValueListenableBuilder<int>(
            valueListenable: DataArsitek.versi,
            builder: (context, _, __) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                JudulBagian(
                  'Arsitek Pilihan',
                  kanan: Text('${DataArsitek.semua.length} arsitek · geser',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ),
                const SizedBox(height: 12),
                ForwardWheel(
                  parent: _scroll,
                  child: ArsitekCarousel(daftar: DataArsitek.semua),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          ForwardWheel(
            parent: _scroll,
            child: PerumahanPilihan(onBuka: () => widget.onOpenTab(3)),
          ),
          const SizedBox(height: 28),
          const CaraKerja(),
          const SizedBox(height: 28),
          _buildProyekHeader(context),
          const SizedBox(height: 8),
          ForwardWheel(parent: _scroll, child: _buildProyekList()),
          const SizedBox(height: 24),
          const KontakDarurat(),
          const SizedBox(height: 28),
          const BerandaFooter(),
        ],
      ),
    );
  }

  // ---------- Header: logo, lonceng, inisial nama ----------
  Widget _buildHeader(BuildContext context) {
    final nama = widget.nama;
    final initial = nama.isNotEmpty ? nama[0].toUpperCase() : '?';
    return HeaderFoto(child: Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 12, 16),
      child: Row(
        children: [
          const Icon(Icons.home_outlined, color: AppColors.primary, size: 38),
          const SizedBox(width: 8),
          Text('RuangRancang', style: AppTheme.heading(27)),
          const Spacer(),
          StreamBuilder<int>(
            stream: NotifikasiService.jumlahBelumDibaca(),
            builder: (context, snap) {
              final n = snap.data ?? 0;
              return IconButton(
                tooltip: 'Notifikasi',
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => const NotifikasiScreen()),
                ),
                icon: Badge(
                  isLabelVisible: n > 0,
                  label: Text(n > 9 ? '9+' : '$n'),
                  backgroundColor: const Color(0xFFD9534F),
                  child: const Icon(Icons.notifications_none),
                ),
              );
            },
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppColors.primary,
            child: Text(
              initial,
              style: const TextStyle(
                  color: Colors.white, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    ));
  }

  // ---------- 3 menu utama ----------
  Widget _buildMenu() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        children: [
          _menuCard(Icons.design_services_outlined, 'Konsultasi\nDesain', 1),
          const SizedBox(width: 12),
          _menuCard(Icons.engineering_outlined, 'Vendor\nKonstruksi', 2),
          const SizedBox(width: 12),
          _menuCard(Icons.house_outlined, 'Perumahan', 3),
        ],
      ),
    );
  }

  /// Satu kartu menu. tabIndex = nomor tab yang dibuka saat diketuk.
  Widget _menuCard(IconData icon, String label, int tabIndex) {
    return Expanded(
      child: Material(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => widget.onOpenTab(tabIndex),
          child: Container(
            height: 104,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: AppColors.primary, size: 28),
                const SizedBox(height: 8),
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------- Proyek Terbaru (live dari Firestore) ----------
  Widget _buildProyekHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 8),
      child: Row(
        children: [
          Text('Proyek Terbaru', style: AppTheme.heading(18)),
          const Spacer(),
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const SemuaProyekPage()),
            ),
            child: const Text(
              'Lihat Semua  →',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProyekList() {
    return SizedBox(
      height: 180,
      child: StreamBuilder<List<Proyek>>(
        stream: ProyekService.streamTampil(),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(
              child: Text('Gagal memuat proyek.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(
              child: Text('Belum ada proyek.',
                  style: TextStyle(color: AppColors.textMuted)),
            );
          }
          return ListView.separated(
            scrollDirection: Axis.horizontal, // geser ke samping
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, i) {
              final p = list[i];
              return SizedBox(
                width: 150,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: GambarProyek(p.gambar,
                          width: 150, height: 110, cacheWidth: 400),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      p.nama,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                    Text(
                      p.kota,
                      style: const TextStyle(
                          color: AppColors.textMuted, fontSize: 12),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}