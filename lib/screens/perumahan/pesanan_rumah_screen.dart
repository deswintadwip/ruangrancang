import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/pesanan_rumah.dart';
import '../../services/pesanan_rumah_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/lencana_status.dart';
import 'pembayaran_rumah_screen.dart';

(String, Color, Color) _gaya(String status) {
  switch (status) {
    case StatusPesananRumah.menungguVerifikasi:
      return ('Verifikasi admin', const Color(0xFFDCE6EE), const Color(0xFF2C4A63));
    case StatusPesananRumah.disetujui:
      return ('Disetujui', AppColors.sageMuda, AppColors.primary);
    case StatusPesananRumah.ditolak:
      return ('Ditolak', const Color(0xFFF7E3DD), const Color(0xFF7A3F32));
    case StatusPesananRumah.dibatalkan:
      return ('Dibatalkan', const Color(0xFFE8E3D8), const Color(0xFF4A463E));
    default:
      return ('Menunggu bayar', const Color(0xFFF7EBD2), const Color(0xFF6E4F0E));
  }
}

/// Daftar pesanan rumah milik user (Semua / Aktif / Riwayat).
class PesananRumahScreen extends StatefulWidget {
  const PesananRumahScreen({super.key});

  @override
  State<PesananRumahScreen> createState() => _PesananRumahScreenState();
}

class _PesananRumahScreenState extends State<PesananRumahScreen> {
  String _tab = 'Semua';
  late final Stream<List<PesananRumah>> _stream;

  @override
  void initState() {
    super.initState();
    _stream = PesananRumahService.milikSaya();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Pesanan Rumah', style: AppTheme.heading(21)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
            child: Row(children: [
              for (final t in ['Semua', 'Aktif', 'Riwayat']) ...[
                ChipPilihan(t,
                    terpilih: _tab == t, onTap: () => setState(() => _tab = t)),
                const SizedBox(width: 8),
              ],
            ]),
          ),
          Expanded(
            child: StreamBuilder<List<PesananRumah>>(
              stream: _stream,
              builder: (context, snap) {
                if (snap.hasError) {
                  return const Center(child: Text('Gagal memuat pesanan.'));
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
                          'Belum ada pesanan. Pilih perumahan lalu tekan Booking Rumah.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: AppColors.textMuted)),
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final p = list[i];
                    final (label, bg, fg) = _gaya(p.status);
                    return InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) =>
                                  PembayaranRumahScreen(pesananId: p.id))),
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
                                      Text(p.perumahanNama,
                                          style: AppTheme.heading(18)),
                                      Text('${p.tipe} · ${p.kota}',
                                          style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textMuted)),
                                    ],
                                  ),
                                ),
                                LencanaStatus(label, latar: bg, huruf: fg),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Booking fee ${formatRupiah(p.bookingFee)}',
                                    style: const TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: AppColors.primary)),
                                Text(waktuLalu(p.createdAt),
                                    style: const TextStyle(
                                        fontSize: 11.5,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
