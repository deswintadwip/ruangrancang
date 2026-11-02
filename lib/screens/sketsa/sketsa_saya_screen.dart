import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../models/pesanan_sketsa.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'sketsa_detail_screen.dart';
import 'sketsa_util.dart';

/// Daftar pesanan sketsa milik user.
class SketsaSayaScreen extends StatelessWidget {
  const SketsaSayaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Pesanan Sketsa', style: AppTheme.heading(20)),
      ),
      body: StreamBuilder<List<PesananSketsa>>(
        stream: PesananSketsaService.milikSaya(),
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final list = snap.data!;
          if (list.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(32),
                child: Text(
                    'Belum ada pesanan sketsa.\nBuka profil arsitek lalu pilih "Pesan Sketsa Desain".',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted, height: 1.5)),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
            itemCount: list.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (_, i) => KartuSketsa(
              p: list[i],
              judul: 'Arsitek ${list[i].arsitekNama}',
              onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => SketsaDetailScreen(pesananId: list[i].id))),
            ),
          );
        },
      ),
    );
  }
}

/// Kartu ringkas satu pesanan (dipakai user, arsitek, admin).
class KartuSketsa extends StatelessWidget {
  final PesananSketsa p;
  final String judul;
  final VoidCallback onTap;
  const KartuSketsa({super.key, required this.p, required this.judul, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final idx = switch (p.status) {
      StatusSketsa.menungguPembayaran => 1,
      StatusSketsa.menungguVerifikasi => 2,
      StatusSketsa.dikerjakan => 3,
      StatusSketsa.selesai => 4,
      _ => 0,
    };
    final ket = switch (p.status) {
      StatusSketsa.menungguPembayaran => 'Menunggu pembayaran',
      StatusSketsa.menungguVerifikasi => 'Pembayaran sedang diproses admin',
      StatusSketsa.dikerjakan => 'Sketsa sedang dikerjakan arsitek',
      StatusSketsa.selesai => 'Sketsa selesai, siap diunduh',
      _ => '',
    };
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(18),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(children: [
          Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(judul,
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 3),
              Text('Lahan ${p.luasLahan} m² · ${p.kota} · ${tglSketsa(p.createdAt)}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                  overflow: TextOverflow.ellipsis),
              const SizedBox(height: 8),
              Text(formatRupiah(p.harga),
                  style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
            ]),
          ),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            LencanaStatusSketsa(p.status),
            if (p.adaHasil) ...[
              const SizedBox(height: 8),
              const Icon(Icons.picture_as_pdf_outlined, size: 18, color: AppColors.primary),
            ],
          ]),
        ]),
          if (idx > 0) ...[
            const SizedBox(height: 12),
            Row(children: [
              for (var i = 1; i <= 4; i++)
                Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i == 4 ? 0 : 4),
                    decoration: BoxDecoration(
                      color: i <= idx ? AppColors.primary : AppColors.border,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
            ]),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(ket,
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted)),
            ),
          ],
        ]),
      ),
    );
  }
}
