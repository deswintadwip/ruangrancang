import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../data/arsitek_data.dart';
import '../../models/konsultasi.dart';
import '../../models/update_progres.dart';
import '../../services/konsultasi_service.dart';
import '../../services/ulasan_service.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arsitek_foto.dart';
import 'ulasan_form_screen.dart';

/// "Lacak Konsultasi" untuk user: progres 5 tahap + catatan dari arsitek.
class LacakScreen extends StatelessWidget {
  final String konsultasiId;
  const LacakScreen({super.key, required this.konsultasiId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Konsultasi?>(
      stream: KonsultasiService.satu(konsultasiId),
      builder: (context, snap) {
        final k = snap.data;
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
            title: const Text('Lacak Konsultasi'),
            backgroundColor: AppColors.background,
          ),
          body: snap.hasError
              ? const Center(child: Text('Tidak bisa memuat konsultasi.'))
              : k == null
              ? const Center(child: CircularProgressIndicator())
              : _Isi(k: k),
        );
      },
    );
  }
}

class _Isi extends StatelessWidget {
  final Konsultasi k;
  const _Isi({required this.k});

  Future<void> _bukaMeet(BuildContext context) async {
    final ok = await launchUrl(Uri.parse(k.meetLink!),
        mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak bisa membuka link Meet.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final tahap = k.tahapSaatIni;
    final a = DataArsitek.byId(k.arsitekId);
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Arsitek + jadwal
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(children: [
            if (a != null)
              ArsitekFoto(
                arsitek: a,
                width: 56,
                height: 56,
                borderRadius: BorderRadius.circular(16),
                fontSize: 18,
              )
            else
              CircleAvatar(
                radius: 28,
                backgroundColor: AppColors.primary,
                child: Text(
                    k.arsitekNama.isEmpty
                        ? '?'
                        : k.arsitekNama[0].toUpperCase(),
                    style: const TextStyle(color: Colors.white)),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(k.arsitekNama, style: AppTheme.heading(18)),
                  const SizedBox(height: 2),
                  Text(
                      '${tanggalLengkap(k.tanggal)} · ${k.jam} – ${k.jamSelesai}',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted)),
                  Text(k.online ? 'Online · Google Meet' : 'Datang ke Studio',
                      style: const TextStyle(
                          fontSize: 12.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ]),
        ),
        const SizedBox(height: 14),
        _aksiMeet(context),

        const SizedBox(height: 18),
        Row(children: [
          Expanded(child: Text('Progres', style: AppTheme.heading(18))),
          Text('$tahap dari ${TahapKerja.jumlah} tahap',
              style: const TextStyle(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary)),
        ]),
        const SizedBox(height: 10),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: tahap / TahapKerja.jumlah,
            minHeight: 8,
            backgroundColor: AppColors.border,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(height: 16),
        StreamBuilder<List<UpdateProgres>>(
          stream: UpdateService.untuk(k.id),
          builder: (context, snap) {
            final list = snap.data ?? const <UpdateProgres>[];
            return Column(children: [
              for (var t = 1; t <= TahapKerja.jumlah; t++)
                _langkah(t, tahap, _terbaruUntuk(list, t),
                    terakhir: t == TahapKerja.jumlah),
            ]);
          },
        ),

        if (k.sudahSelesai) ...[
          const SizedBox(height: 8),
          StreamBuilder<bool>(
            stream: UlasanService.sudahDiulas(k.id),
            builder: (context, snap) {
              if (snap.data == true) {
                return Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.sageMuda,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Text('Terima kasih, ulasanmu sudah terkirim.',
                      style: TextStyle(fontSize: 13, color: AppColors.primary)),
                );
              }
              return FilledButton.icon(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (_) => UlasanFormScreen(konsultasi: k)),
                ),
                icon: const Icon(Icons.star_rounded, size: 20),
                label: const Text('Beri Ulasan',
                    style: TextStyle(fontWeight: FontWeight.w700)),
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                ),
              );
            },
          ),
        ],
      ],
    );
  }

  /// Tombol Meet: aktif 15 menit sebelum sesi (sama seperti di Riwayat).
  Widget _aksiMeet(BuildContext context) {
    if (!k.online || k.status != StatusKonsultasi.dikonfirmasi) {
      return const SizedBox.shrink();
    }
    final mulai = k.mulai;
    final ada = (k.meetLink ?? '').isNotEmpty;
    final aktif = ada &&
        mulai != null &&
        DateTime.now().isAfter(mulai.subtract(const Duration(minutes: 15)));
    if (aktif) {
      return FilledButton.icon(
        onPressed: () => _bukaMeet(context),
        icon: const Icon(Icons.videocam_outlined, size: 20),
        label: const Text('Buka Meet',
            style: TextStyle(fontWeight: FontWeight.w700)),
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(48),
          backgroundColor: AppColors.primary,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      );
    }
    final teks = !ada
        ? 'Link Meet akan dikirim arsitek sebelum sesi'
        : mulai == null
        ? 'Link menyusul'
        : 'Link Meet aktif 15 menit sebelum sesi';
    return Container(
      height: 46,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: const Color(0xFFEDE8DD),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFD7D0C2)),
      ),
      child: Text(teks,
          style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textMuted)),
    );
  }

  UpdateProgres? _terbaruUntuk(List<UpdateProgres> list, int tahap) {
    for (final u in list) {
      if (u.tahap == tahap) return u;
    }
    return null;
  }

  Widget _langkah(int t, int tahapSaatIni, UpdateProgres? u,
      {required bool terakhir}) {
    final selesai = t < tahapSaatIni || (t == tahapSaatIni && k.sudahSelesai);
    final berjalan = t == tahapSaatIni && !k.sudahSelesai;
    final warna = selesai
        ? AppColors.primary
        : berjalan
        ? const Color(0xFFD9A441)
        : AppColors.border;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 30,
            child: Column(children: [
              Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(shape: BoxShape.circle, color: warna),
                child: selesai
                    ? const Icon(Icons.check, size: 14, color: Colors.white)
                    : null,
              ),
              if (!terakhir)
                Expanded(
                  child: Container(
                    width: 2,
                    color: selesai ? AppColors.primary : AppColors.border,
                  ),
                ),
            ]),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16, left: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(TahapKerja.namaTahap(t),
                      style: TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: (selesai || berjalan)
                              ? AppColors.textDark
                              : AppColors.textMuted)),
                  if (u != null) ...[
                    const SizedBox(height: 2),
                    Text(waktuLalu(u.createdAt),
                        style: const TextStyle(
                            fontSize: 11.5, color: AppColors.textMuted)),
                    const SizedBox(height: 4),
                    Text(u.catatan, style: const TextStyle(fontSize: 13)),
                  ] else if (berjalan)
                    const Padding(
                      padding: EdgeInsets.only(top: 2),
                      child: Text('Sedang dikerjakan arsitek',
                          style: TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}