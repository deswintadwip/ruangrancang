import 'package:flutter/material.dart';
import '../../data/arsitek_data.dart';
import '../../data/perumahan_data.dart';
import '../../data/vendor_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/arsitek_foto.dart';
import '../../widgets/header_foto.dart';
import '../konsultasi/detail_arsitek_screen.dart';
import '../perumahan/perumahan_detail_screen.dart';
import '../vendor/vendor_detail_screen.dart';

/// Pencarian di Beranda: arsitek, perumahan, dan vendor sekaligus.
class CariScreen extends StatefulWidget {
  const CariScreen({super.key});

  @override
  State<CariScreen> createState() => _CariScreenState();
}

class _CariScreenState extends State<CariScreen> {
  final _c = TextEditingController();
  String _kata = '';

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  bool _cocok(String kata, List<String> bidang) =>
      bidang.any((b) => b.toLowerCase().contains(kata));

  @override
  Widget build(BuildContext context) {
    final k = _kata.trim().toLowerCase();
    final arsitek = k.isEmpty
        ? <Arsitek>[]
        : DataArsitek.semua
            .where((a) => _cocok(k, [a.nama, a.spesialis, ...a.keahlian]))
            .toList();
    final rumah = k.isEmpty
        ? <Perumahan>[]
        : DataPerumahan.semua
            .where((p) => _cocok(k, [p.nama, p.kota, p.pengembang]))
            .toList();
    final vendor = k.isEmpty
        ? <Vendor>[]
        : DataVendor.semua
            .where((v) => _cocok(k, [v.nama, v.jenis, v.jenisLengkap, v.kota, v.area]))
            .toList();
    final kosong = arsitek.isEmpty && rumah.isEmpty && vendor.isEmpty;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
        title: Text('Cari', style: AppTheme.heading(22)),
        centerTitle: true,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
          child: TextField(
            controller: _c,
            autofocus: true,
            onChanged: (v) => setState(() => _kata = v),
            decoration: InputDecoration(
              hintText: 'Cari arsitek, gaya, vendor, atau perumahan...',
              hintStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
              prefixIcon: const Icon(Icons.search, color: AppColors.textMuted),
              suffixIcon: _kata.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () {
                        _c.clear();
                        setState(() => _kata = '');
                      }),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
              enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: AppColors.border)),
            ),
          ),
        ),
        Expanded(
          child: k.isEmpty
              ? _pesan(Icons.search, 'Ketik untuk mencari',
                  'Nama arsitek, gaya (mis. Minimalis), nama vendor, atau kota perumahan.')
              : kosong
                  ? _pesan(Icons.search_off, 'Tidak ada hasil', 'Coba kata kunci lain.')
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                      children: [
                        if (arsitek.isNotEmpty) ...[
                          _judul('Arsitek (${arsitek.length})'),
                          for (final a in arsitek)
                            _baris(
                              depan: ArsitekFoto(
                                  arsitek: a,
                                  width: 48,
                                  height: 48,
                                  borderRadius: BorderRadius.circular(24),
                                  fontSize: 16),
                              judul: a.namaLengkap,
                              sub: a.spesialis,
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => DetailArsitekScreen(arsitek: a))),
                            ),
                        ],
                        if (rumah.isNotEmpty) ...[
                          _judul('Perumahan (${rumah.length})'),
                          for (final p in rumah)
                            _baris(
                              depan: _ikon(Icons.house_outlined),
                              judul: p.nama,
                              sub: '${p.kota} · ${p.pengembang}',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => PerumahanDetailScreen(perumahan: p))),
                            ),
                        ],
                        if (vendor.isNotEmpty) ...[
                          _judul('Vendor (${vendor.length})'),
                          for (final v in vendor)
                            _baris(
                              depan: _ikon(Icons.engineering_outlined),
                              judul: v.nama,
                              sub: '${v.jenisLengkap} · ${v.kota}',
                              onTap: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                      builder: (_) => VendorDetailScreen(vendor: v))),
                            ),
                        ],
                      ],
                    ),
        ),
      ]),
    );
  }

  Widget _ikon(IconData i) => Container(
        width: 48,
        height: 48,
        decoration:
            BoxDecoration(color: AppColors.sageMuda, borderRadius: BorderRadius.circular(24)),
        child: Icon(i, color: AppColors.primary),
      );

  Widget _judul(String t) => Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(t, style: AppTheme.heading(17)),
      );

  Widget _baris(
          {required Widget depan,
          required String judul,
          required String sub,
          required VoidCallback onTap}) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(children: [
              depan,
              const SizedBox(width: 12),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  Text(sub,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                ]),
              ),
              const Icon(Icons.chevron_right, color: AppColors.textMuted),
            ]),
          ),
        ),
      );

  Widget _pesan(IconData i, String t, String s) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            Icon(i, size: 48, color: AppColors.primary),
            const SizedBox(height: 10),
            Text(t, style: AppTheme.heading(18)),
            const SizedBox(height: 6),
            Text(s,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ]),
        ),
      );
}
