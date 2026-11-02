import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/permintaan_vendor.dart';
import '../../services/admin_vendor_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lencana_status.dart';
import '../vendor/permintaan_vendor_screen.dart' show gayaStatusVendor;
import 'admin_permintaan_vendor_detail.dart';
import 'admin_util.dart';
import 'admin_ringkasan.dart';
import 'admin_widgets.dart';

/// Antrian permintaan vendor untuk admin.
class AdminVendorPage extends StatefulWidget {
  const AdminVendorPage({super.key});

  @override
  State<AdminVendorPage> createState() => _AdminVendorPageState();
}

class _AdminVendorPageState extends State<AdminVendorPage> {
  String _tab = 'Baru';
  late final Stream<List<PermintaanVendor>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = AdminVendorService.semua();
  }

  static bool _cocok(String tab, PermintaanVendor p) {
    switch (tab) {
      case 'Baru':
        return p.status == StatusPermintaanVendor.baru;
      case 'Diteruskan':
        return p.status == StatusPermintaanVendor.diteruskan;
      case 'Dihubungi':
        return p.status == StatusPermintaanVendor.dihubungi;
      case 'Selesai':
        return p.status == StatusPermintaanVendor.selesai;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Baru', 'Diteruskan', 'Dihubungi', 'Selesai', 'Semua'];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<PermintaanVendor>>(
        stream: _stream,
        builder: (context, snap) {
          final semua = snap.data ?? const <PermintaanVendor>[];
          final tampil = semua.where((p) => _cocok(_tab, p)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminPageHeader(
                icon: Icons.engineering_outlined,
                judul: 'Vendor',
                subjudul: 'Permintaan dari klien',
              ),
              TabHitung(
                tab: [
                  for (final t in tabs)
                    (t, t == 'Semua' ? 0 : semua.where((p) => _cocok(t, p)).length),
                ],
                aktif: _tab,
                onPilih: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: snap.hasError
                    ? const Center(child: Text('Gagal memuat permintaan.'))
                    : !snap.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : tampil.isEmpty
                            ? const Center(
                                child: Text('Belum ada permintaan di tab ini.',
                                    style: TextStyle(color: AppColors.textMuted)))
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                                itemCount: tampil.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) => _Baris(p: tampil[i]),
                              ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Baris extends StatelessWidget {
  final PermintaanVendor p;
  const _Baris({required this.p});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = gayaStatusVendor(p.status);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AdminPermintaanVendorDetail(permintaanId: p.id))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AdminColors.line.withValues(alpha: 0.7)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Expanded(
                child: Text(p.userNama,
                    style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
              LencanaStatus(label, latar: bg, huruf: fg),
            ]),
            const SizedBox(height: 4),
            Text('${p.jenisPekerjaan}${p.kota.isEmpty ? '' : ' · ${p.kota}'}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            if (p.deskripsi.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(p.deskripsi,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)),
            ],
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(p.anggaran.isEmpty ? '-' : p.anggaran,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                Text(waktuLalu(p.createdAt),
                    style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
