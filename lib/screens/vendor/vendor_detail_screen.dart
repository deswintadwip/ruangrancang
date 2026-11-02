import 'package:flutter/material.dart';
import '../../data/vendor_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/gambar_proyek.dart';
import 'vendor_form_screen.dart';
import 'vendor_tab.dart';

/// Profil lengkap satu vendor + tombol Hubungi Vendor.
class VendorDetailScreen extends StatelessWidget {
  final Vendor vendor;
  const VendorDetailScreen({super.key, required this.vendor});

  Widget _stat(String nilai, String label) => Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(children: [
            Text(nilai,
                style:
                    const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textMuted)),
          ]),
        ),
      );

  Widget _judul(String t) => Padding(
        padding: const EdgeInsets.only(top: 22, bottom: 10),
        child: Text(t, style: AppTheme.heading(18)),
      );

  Widget _baris(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(width: 16),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final v = vendor;
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(height: 190, color: AppColors.primary),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: CircleAvatar(
                          backgroundColor: AppColors.surface,
                          child: IconButton(
                            tooltip: 'Kembali',
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.arrow_back,
                                color: AppColors.textDark),
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      left: 20,
                      bottom: -38,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(26)),
                        child: AvatarVendor(v: v, ukuran: 84),
                      ),
                    ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 50, 20, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(v.nama, style: AppTheme.heading(24)),
                      const SizedBox(height: 4),
                      Text('${v.jenisLengkap} · ${v.kota}',
                          style: const TextStyle(
                              fontSize: 13, color: AppColors.textMuted)),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 5),
                        decoration: BoxDecoration(
                            color: AppColors.sageMuda,
                            borderRadius: BorderRadius.circular(14)),
                        child: const Row(mainAxisSize: MainAxisSize.min, children: [
                          Icon(Icons.verified_outlined,
                              size: 15, color: AppColors.primary),
                          SizedBox(width: 6),
                          Text('Terverifikasi RuangRancang',
                              style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                  color: AppColors.primary)),
                        ]),
                      ),
                      const SizedBox(height: 18),
                      Row(children: [
                        _stat(v.rating.toString().replaceAll('.', ','), 'Rating'),
                        const SizedBox(width: 10),
                        _stat('${v.proyek}', 'Proyek'),
                        const SizedBox(width: 10),
                        _stat(v.respon, 'Respons'),
                      ]),
                      _judul('Tentang'),
                      Text(v.tentang,
                          style: const TextStyle(fontSize: 13, height: 1.65)),
                      _judul('Layanan'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final l in v.layanan)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(l, style: const TextStyle(fontSize: 12.5)),
                          ),
                      ]),
                      _judul('Portofolio'),
                      Row(children: [
                        for (var i = 0; i < v.portofolio.length; i++) ...[
                          if (i > 0) const SizedBox(width: 8),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(14),
                              child: AspectRatio(
                                aspectRatio: 1,
                                child: GambarProyek(v.portofolio[i],
                                    cacheWidth: 300),
                              ),
                            ),
                          ),
                        ],
                      ]),
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(children: [
                          _baris('Estimasi biaya', v.harga),
                          _baris('Area layanan', v.area),
                          _baris('Jam kerja', v.jamKerja),
                          const SizedBox(height: 6),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                                'Biaya hanya perkiraan. Harga pasti ditentukan vendor setelah survei lokasi.',
                                style: TextStyle(
                                    fontSize: 11.5,
                                    height: 1.5,
                                    color: AppColors.textMuted)),
                          ),
                        ]),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton(
                onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => VendorFormScreen(vendor: v))),
                child: const Text('Hubungi Vendor'),
              ),
              const SizedBox(height: 8),
              const Text(
                  'Kontak vendor dibagikan setelah admin meneruskan permintaanmu.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
            ]),
          ),
        ],
      ),
    );
  }
}
