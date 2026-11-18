import 'package:flutter/material.dart';
import '../../models/konsultasi.dart';
import '../../models/pesanan_sketsa.dart';
import '../../services/konsultasi_service.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import 'kerjaan_arsitek.dart';

/// Daftar SEMUA kerjaan arsitek (konsultasi + sketsa), dipisah berjalan/selesai.
class ArsitekKerjaanScreen extends StatelessWidget {
  const ArsitekKerjaanScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Semua Kerjaan', style: AppTheme.heading(20)),
      ),
      body: StreamBuilder<List<Konsultasi>>(
        stream: KonsultasiService.milikArsitekSaya(),
        builder: (context, snapK) {
          return StreamBuilder<List<PesananSketsa>>(
            stream: PesananSketsaService.untukSaya(),
            builder: (context, snapS) {
              if (!snapK.hasData || !snapS.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final items = [
                ...itemDariKonsultasi(snapK.data!),
                ...itemDariSketsa(snapS.data!),
              ];
              final aktif = items.where((e) => e.aktif).toList()
                ..sort((a, b) {
                  if (a.mendesak != b.mendesak) return a.mendesak ? -1 : 1;
                  return a.waktuUrut.compareTo(b.waktuUrut);
                });
              final selesai = items.where((e) => !e.aktif).toList()
                ..sort((a, b) => b.waktuUrut.compareTo(a.waktuUrut));

              if (items.isEmpty) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('Belum ada kerjaan.',
                        style: TextStyle(color: AppColors.textMuted)),
                  ),
                );
              }
              return ListView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
                children: [
                  if (aktif.isNotEmpty) ...[
                    Text('Sedang berjalan (${aktif.length})',
                        style: AppTheme.heading(16)),
                    const SizedBox(height: 10),
                    for (final it in aktif) kartuKerjaan(context, it),
                    const SizedBox(height: 16),
                  ],
                  if (selesai.isNotEmpty) ...[
                    Text('Selesai (${selesai.length})',
                        style: AppTheme.heading(16)),
                    const SizedBox(height: 10),
                    for (final it in selesai) kartuKerjaan(context, it),
                  ],
                ],
              );
            },
          );
        },
      ),
    );
  }
}
