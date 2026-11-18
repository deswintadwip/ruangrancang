import '../../widgets/header_foto.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/pesanan_rumah.dart';
import '../../services/admin_pesanan_rumah_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/lencana_status.dart';
import 'admin_pesanan_rumah_page.dart' show gayaStatusRumahAdmin;
import 'admin_util.dart';

/// Detail pesanan rumah: cek bukti booking fee lalu setujui atau tolak.
class AdminPesananRumahDetail extends StatefulWidget {
  final String pesananId;
  const AdminPesananRumahDetail({super.key, required this.pesananId});

  @override
  State<AdminPesananRumahDetail> createState() => _AdminPesananRumahDetailState();
}

class _AdminPesananRumahDetailState extends State<AdminPesananRumahDetail> {
  late final Stream<DocumentSnapshot<Map<String, dynamic>>> _stream;
  bool _sibuk = false;

  @override
  void initState() {
    super.initState();
    _stream = AdminPesananRumahService.mentah(widget.pesananId);
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _jalankan(Future<void> Function() aksi, String sukses) async {
    setState(() => _sibuk = true);
    try {
      await aksi();
      if (mounted) _pesan(sukses);
    } catch (e) {
      debugPrint('ADMIN RUMAH ERROR: $e');
      if (mounted) _pesan('Gagal: $e');
    }
    if (mounted) setState(() => _sibuk = false);
  }

  Future<void> _setujui(PesananRumah p) async {
    final ya = await konfirmasi(context,
        judul: 'Setujui booking fee?',
        isi: 'Unit ${p.tipe} di ${p.perumahanNama} dianggap tertahan untuk ${p.userNama}.',
        tombol: 'Setujui');
    if (!ya) return;
    await _jalankan(() => AdminPesananRumahService.setujui(p), 'Booking disetujui.');
  }

  Future<void> _tolak(PesananRumah p) async {
    final alasan = await tanyaAlasan(context,
        judul: 'Tolak pembayaran',
        petunjuk: 'Klien melihat alasan ini.',
        tombol: 'Tolak');
    if (alasan == null) return;
    await _jalankan(() => AdminPesananRumahService.tolak(p, alasan), 'Pembayaran ditolak.');
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
        title: Text('Detail Pesanan Rumah', style: AppTheme.heading(20)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Gagal memuat data.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists) {
            return const Center(child: Text('Pesanan tidak ditemukan.'));
          }
          final p = PesananRumah.fromDoc(snap.data!);
          final bukti = snap.data!.data()?['buktiBayar'] as String?;
          return _isi(p, bukti);
        },
      ),
    );
  }

  Widget _isi(PesananRumah p, String? bukti) {
    final (label, bg, fg) = gayaStatusRumahAdmin(p.status);
    final verifikasi = p.status == StatusPesananRumah.menungguVerifikasi;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        KartuAdmin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(p.userNama,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                LencanaStatus(label, latar: bg, huruf: fg),
              ]),
              const SizedBox(height: 4),
              Text('Dibuat ${waktuLalu(p.createdAt)} · #${p.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Divider(height: 22),
              barisInfo('Perumahan', p.perumahanNama),
              barisInfo('Kota', p.kota),
              barisInfo('Tipe', p.tipe),
              barisInfo('Harga unit', formatRupiah(p.hargaUnit)),
              barisInfo('Booking fee', formatRupiah(p.bookingFee), tebal: true),
            ],
          ),
        ),
        if (verifikasi)
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Bukti transfer', style: AppTheme.heading(16)),
                const SizedBox(height: 4),
                Text('Cocokkan nominal ${formatRupiah(p.bookingFee)} dengan mutasi rekening.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                BuktiTransfer(bukti),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: _sibuk ? null : () => _setujui(p),
                  style: FilledButton.styleFrom(
                    minimumSize: const Size.fromHeight(50),
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Setujui', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _sibuk ? null : () => _tolak(p),
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.terakota, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Tolak',
                      style: TextStyle(
                          fontWeight: FontWeight.w600, color: AppColors.terakota)),
                ),
              ],
            ),
          )
        else ...[
          if (p.status == StatusPesananRumah.ditolak && p.alasanTolak.isNotEmpty)
            KartuAdmin(child: barisInfo('Alasan ditolak', p.alasanTolak)),
          if (p.status == StatusPesananRumah.dibatalkan && p.alasanBatal.isNotEmpty)
            KartuAdmin(child: barisInfo('Alasan batal', p.alasanBatal)),
          if (bukti != null && bukti.isNotEmpty)
            KartuAdmin(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bukti transfer klien', style: AppTheme.heading(16)),
                  const SizedBox(height: 10),
                  BuktiTransfer(bukti),
                ],
              ),
            ),
        ],
      ],
    );
  }
}
