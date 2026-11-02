import 'package:flutter/material.dart';
import '../../data/arsitek_data.dart';
import '../../models/konsultasi.dart';
import '../../services/ulasan_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arsitek_foto.dart';

/// Form ulasan untuk satu konsultasi yang sudah selesai.
class UlasanFormScreen extends StatefulWidget {
  final Konsultasi konsultasi;
  const UlasanFormScreen({super.key, required this.konsultasi});

  @override
  State<UlasanFormScreen> createState() => _UlasanFormScreenState();
}

class _UlasanFormScreenState extends State<UlasanFormScreen> {
  int _bintang = 0;
  final _isi = TextEditingController();
  bool _mengirim = false;

  static const _label = {
    1: 'Kurang puas',
    2: 'Cukup',
    3: 'Baik',
    4: 'Puas',
    5: 'Sangat puas',
  };

  @override
  void dispose() {
    _isi.dispose();
    super.dispose();
  }

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _kirim() async {
    if (_bintang == 0) {
      _pesan('Pilih jumlah bintang dulu.');
      return;
    }
    if (_isi.text.trim().length < 10) {
      _pesan('Tulis ulasan minimal 10 karakter.');
      return;
    }
    setState(() => _mengirim = true);
    try {
      await UlasanService.kirim(widget.konsultasi, _bintang, _isi.text);
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Terima kasih, ulasanmu terkirim.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      _pesan('Gagal mengirim. Mungkin kamu sudah mengulas sesi ini.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.konsultasi;
    final a = DataArsitek.byId(k.arsitekId);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Tulis Ulasan', style: AppTheme.heading(19)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(children: [
                    if (a != null)
                      ArsitekFoto(
                        arsitek: a,
                        width: 54,
                        height: 54,
                        borderRadius: BorderRadius.circular(14),
                        fontSize: 20,
                      ),
                    if (a != null) const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(k.arsitekNama,
                              style: const TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text('Sesi ${k.tanggal} · ${k.jam} – ${k.jamSelesai}',
                              style: const TextStyle(
                                  fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
                    ),
                  ]),
                ),
                const SizedBox(height: 24),
                Center(
                  child: Text('Bagaimana sesinya?',
                      style: AppTheme.heading(18)),
                ),
                const SizedBox(height: 14),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    for (int i = 1; i <= 5; i++)
                      IconButton(
                        onPressed: () => setState(() => _bintang = i),
                        iconSize: 40,
                        tooltip: '$i bintang',
                        icon: Icon(
                          i <= _bintang
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: i <= _bintang
                              ? const Color(0xFFF5B301)
                              : AppColors.border,
                        ),
                      ),
                  ],
                ),
                SizedBox(
                  height: 20,
                  child: Center(
                    child: Text(_label[_bintang] ?? '',
                        style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ),
                const SizedBox(height: 18),
                TextField(
                  controller: _isi,
                  minLines: 5,
                  maxLines: 7,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: 'Ceritakan pengalamanmu',
                    alignLabelWithHint: true,
                    filled: true,
                    fillColor: AppColors.surface,
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColors.border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                          color: AppColors.primary, width: 1.5),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Ulasanmu tampil dengan label "Klien terverifikasi" dan '
                      'nama singkatmu, misalnya Rina S.',
                  style: TextStyle(
                      fontSize: 11.5, height: 1.5, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: FilledButton(
              onPressed: _mengirim ? null : _kirim,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _mengirim
                  ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                  : const Text('Kirim Ulasan',
                  style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }
}