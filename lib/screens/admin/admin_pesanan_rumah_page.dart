import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/pesanan_rumah.dart';
import '../../services/admin_pesanan_rumah_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/lencana_status.dart';
import 'admin_pesanan_rumah_detail.dart';
import 'admin_ringkasan.dart';
import 'admin_util.dart';
import 'admin_widgets.dart';

/// (label, latar, huruf) status pesanan rumah di panel admin.
(String, Color, Color) gayaStatusRumahAdmin(String status) {
  switch (status) {
    case StatusPesananRumah.menungguVerifikasi:
      return ('Perlu verifikasi', const Color(0xFFF7EBD2), const Color(0xFF6E4F0E));
    case StatusPesananRumah.disetujui:
      return ('Disetujui', AppColors.sageMuda, AppColors.primary);
    case StatusPesananRumah.ditolak:
      return ('Ditolak', const Color(0xFFF7E3DD), const Color(0xFF7A3F32));
    case StatusPesananRumah.dibatalkan:
      return ('Dibatalkan', const Color(0xFFE8E3D8), const Color(0xFF4A463E));
    default:
      return ('Menunggu bayar', const Color(0xFFE8E3D8), const Color(0xFF4A463E));
  }
}

/// Antrian pesanan rumah (verifikasi booking fee).
class AdminPesananRumahPage extends StatefulWidget {
  const AdminPesananRumahPage({super.key});

  @override
  State<AdminPesananRumahPage> createState() => _AdminPesananRumahPageState();
}

class _AdminPesananRumahPageState extends State<AdminPesananRumahPage> {
  String _tab = 'Verifikasi';
  late final Stream<List<PesananRumah>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = AdminPesananRumahService.semua();
  }

  static bool _cocok(String tab, PesananRumah p) {
    switch (tab) {
      case 'Verifikasi':
        return p.status == StatusPesananRumah.menungguVerifikasi;
      case 'Belum bayar':
        return p.status == StatusPesananRumah.menungguPembayaran;
      case 'Disetujui':
        return p.status == StatusPesananRumah.disetujui;
      case 'Ditolak':
        return p.status == StatusPesananRumah.ditolak;
      case 'Batal':
        return p.status == StatusPesananRumah.dibatalkan;
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Verifikasi', 'Belum bayar', 'Disetujui', 'Ditolak', 'Batal', 'Semua'];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<PesananRumah>>(
        stream: _stream,
        builder: (context, snap) {
          final semua = snap.data ?? const <PesananRumah>[];
          final tampil = semua.where((p) => _cocok(_tab, p)).toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminPageHeader(
                icon: Icons.house_outlined,
                judul: 'Perumahan',
                subjudul: 'Verifikasi booking fee',
              ),
              TabHitung(
                tab: [
                  for (final t in tabs)
                    (t, (t == 'Verifikasi' || t == 'Belum bayar') ? semua.where((p) => _cocok(t, p)).length : 0),
                ],
                aktif: _tab,
                onPilih: (t) => setState(() => _tab = t),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: snap.hasError
                    ? const Center(child: Text('Gagal memuat pesanan.'))
                    : !snap.hasData
                        ? const Center(child: CircularProgressIndicator())
                        : tampil.isEmpty
                            ? const Center(
                                child: Text('Belum ada pesanan di tab ini.',
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
  final PesananRumah p;
  const _Baris({required this.p});

  @override
  Widget build(BuildContext context) {
    final (label, bg, fg) = gayaStatusRumahAdmin(p.status);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AdminPesananRumahDetail(pesananId: p.id))),
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
            Text('${p.perumahanNama} · ${p.tipe}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Booking fee ${formatRupiah(p.bookingFee)}',
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
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
