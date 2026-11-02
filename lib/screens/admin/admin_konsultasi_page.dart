import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/konsultasi.dart';
import '../../services/admin_konsultasi_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/lencana_status.dart';
import 'admin_konsultasi_detail_page.dart';
import 'admin_ringkasan.dart';
import 'admin_util.dart';
import 'admin_widgets.dart';

/// Antrian konsultasi untuk admin: verifikasi pembayaran, sesi aktif, refund.
class AdminKonsultasiPage extends StatefulWidget {
  const AdminKonsultasiPage({super.key});

  @override
  State<AdminKonsultasiPage> createState() => _AdminKonsultasiPageState();
}

class _AdminKonsultasiPageState extends State<AdminKonsultasiPage> {
  String _tab = 'Verifikasi';
  late final Stream<List<Konsultasi>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = AdminKonsultasiService.semua();
  }

  static bool _cocok(String tab, Konsultasi k) {
    switch (tab) {
      case 'Verifikasi':
        return k.status == StatusKonsultasi.menungguVerifikasi;
      case 'Belum bayar':
        return k.status == StatusKonsultasi.menungguPembayaran;
      case 'Aktif':
        return k.status == StatusKonsultasi.dikonfirmasi;
      case 'Selesai':
        return k.status == StatusKonsultasi.selesai;
      case 'Batal':
        return k.status == StatusKonsultasi.dibatalkan ||
            k.status == StatusKonsultasi.ditolak;
      case 'Refund':
        return k.status == StatusKonsultasi.dibatalkan &&
            k.refundStatus == 'diproses';
      default:
        return true;
    }
  }

  @override
  Widget build(BuildContext context) {
    const tabs = ['Verifikasi', 'Belum bayar', 'Aktif', 'Selesai', 'Batal', 'Refund'];
    return Scaffold(
      backgroundColor: AppColors.background,
      body: StreamBuilder<List<Konsultasi>>(
      stream: _stream,
      builder: (context, snap) {
        final semua = snap.data ?? const <Konsultasi>[];
        final tampil = semua.where((k) => _cocok(_tab, k)).toList();
        // Refund diurutkan dari yang paling lama menunggu.
        if (_tab == 'Refund') {
          tampil.sort((a, b) => (a.createdAt ?? DateTime.now())
              .compareTo(b.createdAt ?? DateTime.now()));
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminPageHeader(
              icon: Icons.assignment_outlined,
              judul: 'Konsultasi',
              subjudul: 'Verifikasi pembayaran dan refund',
            ),
            TabHitung(
              tab: [
                for (final t in tabs)
                  (t, (t == 'Verifikasi' || t == 'Refund')
                      ? semua.where((k) => _cocok(t, k)).length
                      : 0),
              ],
              aktif: _tab,
              onPilih: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: snap.hasError
                  ? const Center(child: Text('Gagal memuat konsultasi.'))
                  : !snap.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : tampil.isEmpty
                          ? Center(
                              child: Text(
                                  _tab == 'Verifikasi'
                                      ? 'Tidak ada bukti yang perlu diverifikasi.'
                                      : 'Belum ada data di tab ini.',
                                  style: const TextStyle(color: AppColors.textMuted)))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                              itemCount: tampil.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 10),
                              itemBuilder: (_, i) =>
                                  _Baris(k: tampil[i], refund: _tab == 'Refund'),
                            ),
            ),
          ],
        );
      },
    ));
  }
}

class _Baris extends StatelessWidget {
  final Konsultasi k;
  final bool refund;
  const _Baris({required this.k, required this.refund});

  @override
  Widget build(BuildContext context) {
    final g = gayaStatusKonsultasi(k.status, refundStatus: k.refundStatus);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => AdminKonsultasiDetailPage(konsultasiId: k.id))),
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
                child: Text(k.userNama,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
              ),
              LencanaStatus(g.$1, latar: g.$2, huruf: g.$3),
            ]),
            const SizedBox(height: 4),
            Text('${k.arsitekNama} · ${tanggalPendek(k.tanggal)}, ${k.jam}',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                    refund
                        ? 'Refund ${k.refundPersen}% · ${formatRupiah(k.refundNominal)}'
                        : formatRupiah(k.harga),
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
                Text(waktuLalu(k.createdAt),
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
