import 'package:flutter/material.dart';
import '../../config/tahap.dart';
import '../../models/konsultasi.dart';
import '../../services/update_service.dart';
import '../../theme/app_theme.dart';

/// Form "Tambah Update": pilih tahap (tidak boleh mundur) + catatan.
class TambahUpdateScreen extends StatefulWidget {
  final Konsultasi konsultasi;
  const TambahUpdateScreen({super.key, required this.konsultasi});

  @override
  State<TambahUpdateScreen> createState() => _TambahUpdateScreenState();
}

class _TambahUpdateScreenState extends State<TambahUpdateScreen> {
  late int _tahap;
  bool _tandaiSelesai = true;
  bool _mengirim = false;
  final _catatan = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Default: tahap berikutnya (maksimal 5).
    final sekarang = widget.konsultasi.tahapSaatIni;
    _tahap = sekarang < TahapKerja.jumlah ? sekarang + 1 : sekarang;
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _kirim() async {
    final teks = _catatan.text.trim();
    if (teks.isEmpty) {
      _pesan('Tulis catatan singkat untuk klien dulu ya.');
      return;
    }
    setState(() => _mengirim = true);
    try {
      await UpdateService.tambah(
        widget.konsultasi,
        tahap: _tahap,
        catatan: teks,
        selesai: _tahap == TahapKerja.jumlah && _tandaiSelesai,
      );
      if (!mounted) return;
      Navigator.pop(context, true);
    } catch (e) {
      debugPrint('UPDATE ERROR: $e');
      if (!mounted) return;
      setState(() => _mengirim = false);
      _pesan('Gagal mengirim update: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.konsultasi;
    final minTahap = k.tahapSaatIni;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tambah Update'),
        backgroundColor: AppColors.background,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
        children: [
          Text('Klien: ${k.userNama}',
              style: const TextStyle(
                  fontSize: 13.5, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          Text('Tahap pengerjaan', style: AppTheme.heading(16)),
          const SizedBox(height: 10),
          for (var t = 1; t <= TahapKerja.jumlah; t++) _opsiTahap(t, minTahap),
          const SizedBox(height: 18),
          Text('Catatan untuk klien', style: AppTheme.heading(16)),
          const SizedBox(height: 10),
          TextField(
            controller: _catatan,
            minLines: 4,
            maxLines: 7,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Contoh: Sketsa denah lantai 1 sudah selesai, '
                  'sedang menyusun tampak depan.',
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppColors.border),
              ),
            ),
          ),
          if (_tahap == TahapKerja.jumlah) ...[
            const SizedBox(height: 6),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.primary,
              value: _tandaiSelesai,
              onChanged: (v) => setState(() => _tandaiSelesai = v),
              title: const Text('Tandai konsultasi selesai',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              subtitle: const Text(
                  'Klien bisa memberi ulasan setelah konsultasi selesai.',
                  style: TextStyle(fontSize: 12)),
            ),
          ],
          const SizedBox(height: 12),
          FilledButton(
            onPressed: _mengirim ? null : _kirim,
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(50),
              backgroundColor: AppColors.primary,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _mengirim
                ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white))
                : const Text('Kirim Update',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          const SizedBox(height: 10),
          const Center(
            child: Text('Klien langsung menerima notifikasi.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ),
        ],
      ),
    );
  }

  Widget _opsiTahap(int t, int minTahap) {
    final bisa = t >= minTahap;
    final dipilih = _tahap == t;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GestureDetector(
        onTap: bisa ? () => setState(() => _tahap = t) : null,
        child: Opacity(
          opacity: bisa ? 1 : 0.45,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: dipilih ? AppColors.sageMuda : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                  color: dipilih ? AppColors.primary : AppColors.border,
                  width: dipilih ? 1.6 : 1),
            ),
            child: Row(children: [
              CircleAvatar(
                radius: 12,
                backgroundColor:
                dipilih ? AppColors.primary : AppColors.border,
                child: Text('$t',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: dipilih ? Colors.white : AppColors.textDark)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(TahapKerja.namaTahap(t),
                    style: TextStyle(
                        fontSize: 14,
                        fontWeight:
                        dipilih ? FontWeight.w700 : FontWeight.w500)),
              ),
              if (t == minTahap)
                const Text('saat ini',
                    style:
                    TextStyle(fontSize: 11, color: AppColors.textMuted)),
            ]),
          ),
        ),
      ),
    );
  }
}