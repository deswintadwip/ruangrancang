import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/permintaan_vendor.dart';
import '../../services/vendor_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lencana_status.dart';
import 'permintaan_detail_screen.dart';

/// (label, latar, huruf) untuk status permintaan vendor.
(String, Color, Color) gayaStatusVendor(String status) {
  switch (status) {
    case StatusPermintaanVendor.diteruskan:
      return ('Diteruskan', const Color(0xFFDCE6EE), const Color(0xFF2C4A63));
    case StatusPermintaanVendor.dihubungi:
      return ('Dihubungi', AppColors.sageMuda, AppColors.primary);
    case StatusPermintaanVendor.selesai:
      return ('Selesai', const Color(0xFFE8E3D8), const Color(0xFF4A463E));
    default:
      return ('Baru', const Color(0xFFF7EBD2), const Color(0xFF6E4F0E));
  }
}

/// Daftar permintaan vendor milik user (Semua / Aktif / Selesai).
class PermintaanVendorScreen extends StatefulWidget {
  const PermintaanVendorScreen({super.key});

  @override
  State<PermintaanVendorScreen> createState() => _PermintaanVendorScreenState();
}

class _PermintaanVendorScreenState extends State<PermintaanVendorScreen> {
  String _tab = 'Semua';
  late final Stream<List<PermintaanVendor>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = VendorService.milikSaya();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Permintaan Vendor', style: AppTheme.heading(21)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              for (final t in ['Semua', 'Aktif', 'Selesai']) ...[
                ChipPilihan(t,
                    terpilih: _tab == t, onTap: () => setState(() => _tab = t)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<PermintaanVendor>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Gagal memuat permintaan.'));
                }
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final list = snap.data!
                    .where((p) =>
                        _tab == 'Semua' || (_tab == 'Aktif' ? p.aktif : !p.aktif))
                    .toList();
                if (list.isEmpty) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(32),
                      child: Text(
                          'Belum ada permintaan. Pilih vendor lalu tekan Hubungi Vendor.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _Kartu(p: list[i]),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _Kartu extends StatelessWidget {
  final PermintaanVendor p;
  const _Kartu({required this.p});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = gayaStatusVendor(p.status);
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => PermintaanDetailScreen(permintaanId: p.id))),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.jenisPekerjaan,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w600)),
                      const SizedBox(height: 2),
                      Text(p.namaVendorTampil,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                LencanaStatus(label, latar: bg, huruf: fg),
              ],
            ),
            const SizedBox(height: 10),
            Text(p.deskripsi,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 12.5, height: 1.55)),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text('${p.kota} · ${p.anggaran}',
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted)),
                ),
                Text(waktuLalu(p.createdAt),
                    style: const TextStyle(
                        fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
