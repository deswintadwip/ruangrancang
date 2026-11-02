import 'package:flutter/material.dart';
import '../../data/arsitek_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arsitek_sections.dart';
import '../sketsa/sketsa_saya_screen.dart';
import 'riwayat_screen.dart';

/// Tab Konsultasi (sisi user): cari arsitek, filter gaya, geser kartu.
class KonsultasiTab extends StatefulWidget {
  const KonsultasiTab({super.key});

  @override
  State<KonsultasiTab> createState() => _KonsultasiTabState();
}

class _KonsultasiTabState extends State<KonsultasiTab> {
  final _searchCtrl = TextEditingController();
  String _kata = '';
  String? _gaya; // null = Semua

  void _segarkan() {
    if (mounted) setState(() {});
  }

  @override
  void initState() {
    super.initState();
    DataArsitek.versi.addListener(_segarkan);
  }

  @override
  void dispose() {
    DataArsitek.versi.removeListener(_segarkan);
    _searchCtrl.dispose();
    super.dispose();
  }

  void _terapkanFilter({String? kata, String? gaya, bool resetGaya = false}) {
    setState(() {
      if (kata != null) _kata = kata;
      if (resetGaya) {
        _gaya = null;
      } else if (gaya != null) {
        _gaya = gaya;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasil = DataArsitek.cari(kata: _kata, gaya: _gaya);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.only(bottom: 24),
          children: [
            // ── Header ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Halo!',
                            style: TextStyle(
                                fontSize: 13, color: AppColors.textMuted)),
                        const SizedBox(height: 2),
                        Text('Temukan arsitekmu',
                            style: AppTheme.heading(24)),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      tooltip: 'Pesanan sketsa',
                      icon: const Icon(Icons.draw_outlined,
                          color: AppColors.textDark, size: 22),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const SketsaSayaScreen()),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.border),
                    ),
                    child: IconButton(
                      tooltip: 'Riwayat konsultasi',
                      icon: const Icon(Icons.history,
                          color: AppColors.textDark, size: 22),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const RiwayatScreen()),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pencarian ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: TextField(
                controller: _searchCtrl,
                onChanged: (v) => _terapkanFilter(kata: v),
                decoration: InputDecoration(
                  hintText: 'Cari nama arsitek atau gaya desain',
                  hintStyle: const TextStyle(
                      fontSize: 13.5, color: AppColors.textMuted),
                  prefixIcon:
                  const Icon(Icons.search, color: AppColors.textMuted),
                  suffixIcon: _kata.isEmpty
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.close, size: 18),
                    onPressed: () {
                      _searchCtrl.clear();
                      _terapkanFilter(kata: '');
                    },
                  ),
                  filled: true,
                  fillColor: AppColors.surface,
                  contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(color: AppColors.border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(28),
                    borderSide: const BorderSide(
                        color: AppColors.primary, width: 1.5),
                  ),
                ),
              ),
            ),

            // ── Chip gaya ──
            SizedBox(
              height: 38,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                children: [
                  _chip('Semua', _gaya == null,
                          () => _terapkanFilter(resetGaya: true)),
                  for (final g in DataArsitek.daftarGaya)
                    _chip(g, _gaya == g, () => _terapkanFilter(gaya: g)),
                ],
              ),
            ).withTopPadding(12),

            // ── Judul carousel ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Text('Arsitek Pilihan',
                        style: AppTheme.heading(18)),
                  ),
                  Text('${hasil.length} arsitek · geser',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward,
                      size: 16, color: AppColors.textMuted),
                ],
              ),
            ),

            // ── Carousel ──
            if (hasil.isEmpty)
              _kosong()
            else
              ArsitekCarousel(daftar: hasil),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, bool aktif, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: aktif ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(19),
            border: Border.all(
                color: aktif ? AppColors.primary : AppColors.border),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 13,
              fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
              color: aktif ? Colors.white : AppColors.textDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _kosong() => Padding(
    padding: const EdgeInsets.fromLTRB(20, 48, 20, 24),
    child: Column(
      children: [
        const Icon(Icons.search_off,
            size: 48, color: AppColors.textMuted),
        const SizedBox(height: 12),
        Text('Arsitek tidak ditemukan', style: AppTheme.heading(18)),
        const SizedBox(height: 6),
        const Text('Coba kata kunci lain atau pilih gaya "Semua".',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
      ],
    ),
  );
}

extension _Pad on Widget {
  Widget withTopPadding(double v) =>
      Padding(padding: EdgeInsets.only(top: v), child: this);
}