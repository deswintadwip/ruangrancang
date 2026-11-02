import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/konsultasi.dart';
import '../../models/update_progres.dart';
import '../../services/konsultasi_service.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';
import 'arsitek_util.dart';
import 'tambah_update_screen.dart';

/// Detail satu konsultasi untuk arsitek: ringkasan klien, progres 5 tahap,
/// link Meet, dan tombol Tambah Update.
class ArsitekDetailScreen extends StatelessWidget {
  final String konsultasiId;
  const ArsitekDetailScreen({super.key, required this.konsultasiId});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Konsultasi?>(
      stream: KonsultasiService.satu(konsultasiId),
      builder: (context, snap) {
        final k = snap.data;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Detail Konsultasi'),
            backgroundColor: AppColors.background,
          ),
          body: snap.hasError
              ? const Center(child: Text('Tidak bisa memuat konsultasi.'))
              : k == null
              ? const Center(child: CircularProgressIndicator())
              : _Isi(k: k),
          bottomNavigationBar: k == null ||
              k.status != StatusKonsultasi.dikonfirmasi
              ? null
              : SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FilledButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              TambahUpdateScreen(konsultasi: k)),
                    ),
                    icon: const Icon(Icons.add, size: 20),
                    label: const Text('Tambah Update',
                        style: TextStyle(fontWeight: FontWeight.w700)),
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(50),
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16)),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                      'Klien langsung menerima notifikasi setiap ada update',
                      style: TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _Isi extends StatelessWidget {
  final Konsultasi k;
  const _Isi({required this.k});

  @override
  Widget build(BuildContext context) {
    final tahap = k.tahapSaatIni;
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
      children: [
        // Klien
        Row(children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(inisialNama(k.userNama),
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.userNama, style: AppTheme.heading(20)),
                Text(
                    '${tanggalLengkap(k.tanggal)} · ${k.jam} – ${k.jamSelesai}',
                    style: const TextStyle(
                        fontSize: 12.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ]),
        const SizedBox(height: 16),

        // Ringkasan brief
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Ringkasan brief', style: AppTheme.heading(15)),
              const SizedBox(height: 10),
              _baris('Luas', k.luas.isEmpty ? '-' : '${k.luas} m²'),
              _baris('Budget', k.budget.isEmpty ? '-' : k.budget),
              _baris('Gaya', k.gaya.isEmpty ? '-' : k.gaya),
              _baris('Metode', k.online ? 'Online (Google Meet)' : 'Studio'),
              if (k.catatan.isNotEmpty) _baris('Kebutuhan', k.catatan),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (k.online && k.status == StatusKonsultasi.dikonfirmasi)
          _KartuMeet(k: k),

        // Progres
        const SizedBox(height: 20),
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
      ],
    );
  }

  /// Update terbaru untuk satu tahap (list sudah terurut terbaru di atas).
  UpdateProgres? _terbaruUntuk(List<UpdateProgres> list, int tahap) {
    for (final u in list) {
      if (u.tahap == tahap) return u;
    }
    return null;
  }

  Widget _baris(String label, String isi) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(label,
              style: const TextStyle(
                  fontSize: 12.5, color: AppColors.textMuted)),
        ),
        Expanded(
          child: Text(isi,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  Widget _langkah(int t, int tahapSaatIni, UpdateProgres? u,
      {required bool terakhir}) {
    final selesai = t < tahapSaatIni || (t == tahapSaatIni && k.sudahSelesai);
    final berjalan = t == tahapSaatIni && !k.sudahSelesai;
    final warnaTitik = selesai
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
                decoration:
                BoxDecoration(shape: BoxShape.circle, color: warnaTitik),
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
                      child: Text('Sedang dikerjakan · belum ada catatan',
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

/// Link Google Meet: arsitek menempelkan link, bisa dibuka langsung.
class _KartuMeet extends StatelessWidget {
  final Konsultasi k;
  const _KartuMeet({required this.k});

  Future<void> _edit(BuildContext context) async {
    final c = TextEditingController(text: k.meetLink ?? '');
    final hasil = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Link Google Meet'),
        content: TextField(
          controller: c,
          keyboardType: TextInputType.url,
          decoration:
          const InputDecoration(hintText: 'https://meet.google.com/...'),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Batal')),
          FilledButton(
              onPressed: () => Navigator.pop(ctx, c.text.trim()),
              child: const Text('Simpan')),
        ],
      ),
    );
    if (hasil == null || hasil.isEmpty) return;
    if (!hasil.startsWith('http')) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Link harus diawali https://')));
      }
      return;
    }
    try {
      await UpdateService.simpanMeetLink(k.id, hasil);
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ada = (k.meetLink ?? '').isNotEmpty;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.sageMuda,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(children: [
        const Icon(Icons.videocam_outlined, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(ada ? k.meetLink! : 'Link Meet belum diisi',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 13)),
        ),
        if (ada)
          IconButton(
            tooltip: 'Buka',
            onPressed: () => launchUrl(Uri.parse(k.meetLink!),
                mode: LaunchMode.externalApplication),
            icon: const Icon(Icons.open_in_new, size: 20),
          ),
        TextButton(
          onPressed: () => _edit(context),
          child: Text(ada ? 'Ubah' : 'Isi'),
        ),
      ]),
    );
  }
}