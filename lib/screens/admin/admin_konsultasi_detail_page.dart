import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/konsultasi.dart';
import '../../services/admin_konsultasi_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/lencana_status.dart';
import 'admin_util.dart';

/// Detail satu konsultasi untuk admin, dengan tombol aksi sesuai status.
class AdminKonsultasiDetailPage extends StatefulWidget {
  final String konsultasiId;
  const AdminKonsultasiDetailPage({super.key, required this.konsultasiId});

  @override
  State<AdminKonsultasiDetailPage> createState() =>
      _AdminKonsultasiDetailPageState();
}

class _AdminKonsultasiDetailPageState extends State<AdminKonsultasiDetailPage> {
  bool _sibuk = false;

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _jalankan(Future<void> Function() aksi, String sukses) async {
    setState(() => _sibuk = true);
    try {
      await aksi();
      if (mounted) _pesan(sukses);
    } catch (e) {
      debugPrint('ADMIN KONSULTASI ERROR: $e');
      if (mounted) _pesan('Gagal: $e');
    }
    if (mounted) setState(() => _sibuk = false);
  }

  Future<void> _setujui(Konsultasi k) async {
    final ya = await konfirmasi(context,
        judul: 'Setujui pembayaran?',
        isi: 'Jadwal ${k.userNama} dengan ${k.arsitekNama} akan dikonfirmasi dan '
            'keduanya diberi notifikasi.',
        tombol: 'Setujui');
    if (!ya) return;
    await _jalankan(() => AdminKonsultasiService.setujui(k), 'Pembayaran disetujui.');
  }

  Future<void> _ulang(Konsultasi k) async {
    final alasan = await tanyaAlasan(context,
        judul: 'Minta unggah ulang',
        petunjuk: 'Klien akan melihat alasan ini dan bisa mengunggah bukti baru.',
        tombol: 'Kirim',
        warnaTombol: AppColors.primary);
    if (alasan == null) return;
    await _jalankan(() => AdminKonsultasiService.mintaUnggahUlang(k, alasan),
        'Klien diminta mengunggah ulang.');
  }

  Future<void> _tolak(Konsultasi k) async {
    final alasan = await tanyaAlasan(context,
        judul: 'Tolak permanen',
        petunjuk: 'Jadwal dilepas kembali dan pesanan ditutup. Klien melihat alasan ini.',
        tombol: 'Tolak');
    if (alasan == null) return;
    await _jalankan(() => AdminKonsultasiService.tolakPermanen(k, alasan),
        'Pembayaran ditolak.');
  }

  Future<void> _batalkan(Konsultasi k) async {
    final persen = AdminKonsultasiService.persenRefundAdmin(k);
    final alasan = await tanyaAlasan(context,
        judul: 'Batalkan konsultasi',
        petunjuk: persen > 0
            ? 'Refund $persen% (${formatRupiah(k.harga * persen ~/ 100)}) akan dicatat. Jadwal dilepas dan klien serta arsitek diberi tahu.'
            : 'Belum ada pembayaran, jadi tidak ada refund. Jadwal dilepas.',
        tombol: 'Batalkan');
    if (alasan == null) return;
    await _jalankan(() => AdminKonsultasiService.batalkan(k, alasan),
        'Konsultasi dibatalkan.');
  }

  Future<void> _refundSelesai(Konsultasi k) async {
    final catatan = await tanyaAlasan(context,
        judul: 'Refund selesai',
        petunjuk: 'Catat bank atau referensi transfer (opsional). Klien diberi tahu.',
        tombol: 'Tandai selesai',
        wajib: false,
        warnaTombol: AppColors.primary);
    if (catatan == null) return;
    await _jalankan(() => AdminKonsultasiService.tandaiRefundSelesai(k, catatan),
        'Refund ditandai selesai.');
  }

  Widget _tombol(String teks, VoidCallback? onTap,
      {bool utama = false, Color? warna}) {
    final c = warna ?? AppColors.primary;
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: utama
          ? FilledButton(
              onPressed: _sibuk ? null : onTap,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: c,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(teks, style: const TextStyle(fontWeight: FontWeight.w600)),
            )
          : OutlinedButton(
              onPressed: _sibuk ? null : onTap,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size.fromHeight(48),
                side: BorderSide(color: c, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(teks,
                  style: TextStyle(fontWeight: FontWeight.w600, color: c)),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Detail Konsultasi', style: AppTheme.heading(20)),
      ),
      body: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
        stream: AdminKonsultasiService.mentah(widget.konsultasiId),
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Gagal memuat data.'));
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          if (!snap.data!.exists) {
            return const Center(child: Text('Konsultasi tidak ditemukan.'));
          }
          final doc = snap.data!;
          final k = Konsultasi.fromDoc(doc);
          final m = doc.data() ?? {};
          return _isi(k, m);
        },
      ),
    );
  }

  Widget _isi(Konsultasi k, Map<String, dynamic> m) {
    final g = gayaStatusKonsultasi(k.status, refundStatus: k.refundStatus);
    final alasanTolak = m['alasanTolak'] as String? ?? '';
    final catatanRefund = m['catatanRefund'] as String? ?? '';
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        KartuAdmin(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(
                  child: Text(k.userNama,
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                ),
                LencanaStatus(g.$1, latar: g.$2, huruf: g.$3),
              ]),
              const SizedBox(height: 4),
              Text('Dibuat ${waktuLalu(k.createdAt)} · #${k.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Divider(height: 22),
              barisInfo('Arsitek', k.arsitekNama),
              barisInfo('Jadwal', '${tanggalLengkap(k.tanggal)}, ${k.jam}–${k.jamSelesai}'),
              barisInfo('Metode', k.online ? 'Online' : 'Studio'),
              barisInfo('Harga', formatRupiah(k.harga), tebal: true),
            ],
          ),
        ),
        if (k.luas.isNotEmpty || k.budget.isNotEmpty || k.gaya.isNotEmpty || k.catatan.isNotEmpty)
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Rencana proyek klien', style: AppTheme.heading(16)),
                const SizedBox(height: 8),
                if (k.luas.isNotEmpty) barisInfo('Luas', '${k.luas} m²'),
                if (k.budget.isNotEmpty) barisInfo('Budget', k.budget),
                if (k.gaya.isNotEmpty) barisInfo('Gaya', k.gaya),
                if (k.catatan.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Text(k.catatan, style: const TextStyle(fontSize: 12.5, height: 1.55)),
                ],
              ],
            ),
          ),

        // ---------- Verifikasi pembayaran ----------
        if (k.status == StatusKonsultasi.menungguVerifikasi)
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Bukti transfer', style: AppTheme.heading(16)),
                const SizedBox(height: 4),
                Text('Cocokkan nominal ${formatRupiah(k.harga)} dengan mutasi rekening.',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                BuktiTransfer(m['buktiBayar'] as String?),
                const SizedBox(height: 6),
                _tombol('Setujui pembayaran', () => _setujui(k), utama: true),
                _tombol('Minta unggah ulang', () => _ulang(k)),
                _tombol('Tolak permanen', () => _tolak(k), warna: AppColors.terakota),
              ],
            ),
          ),

        if (k.status == StatusKonsultasi.menungguPembayaran) ...[
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Belum membayar', style: AppTheme.heading(16)),
                const SizedBox(height: 4),
                Text(
                    k.batasBayar == null
                        ? 'Menunggu klien mengunggah bukti.'
                        : 'Batas bayar: ${k.batasBayar!.day}/${k.batasBayar!.month} '
                            '${k.batasBayar!.hour.toString().padLeft(2, '0')}.${k.batasBayar!.minute.toString().padLeft(2, '0')}. '
                            'Lewat batas ini pesanan dibatalkan otomatis.',
                    style: const TextStyle(fontSize: 12.5, height: 1.5)),
                if (alasanTolak.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Alasan unggah ulang: $alasanTolak',
                      style: const TextStyle(fontSize: 12.5, color: Color(0xFF6E4F0E))),
                ],
                _tombol('Batalkan pesanan', () => _batalkan(k), warna: AppColors.terakota),
              ],
            ),
          ),
        ],

        // ---------- Sesi aktif ----------
        if (k.status == StatusKonsultasi.dikonfirmasi)
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Sesi terkonfirmasi', style: AppTheme.heading(16)),
                const SizedBox(height: 4),
                Text('Tahap sekarang: ${TahapKerja.namaTahap(k.tahapSaatIni)}',
                    style: const TextStyle(fontSize: 12.5)),
                _tombol('Batalkan konsultasi', () => _batalkan(k),
                    warna: AppColors.terakota),
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text(
                      'Jika admin yang membatalkan, klien mendapat refund 100%.',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ),
              ],
            ),
          ),

        // ---------- Dibatalkan / ditolak ----------
        if (k.status == StatusKonsultasi.dibatalkan || k.status == StatusKonsultasi.ditolak)
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(k.status == StatusKonsultasi.ditolak ? 'Pembayaran ditolak' : 'Dibatalkan',
                    style: AppTheme.heading(16)),
                const SizedBox(height: 6),
                if (k.status == StatusKonsultasi.dibatalkan) ...[
                  barisInfo('Dibatalkan oleh', k.dibatalkanOleh.isEmpty ? '-' : k.dibatalkanOleh),
                  barisInfo('Alasan', k.alasanBatal.isEmpty ? '-' : k.alasanBatal),
                  barisInfo('Refund', '${k.refundPersen}% · ${formatRupiah(k.refundNominal)}',
                      tebal: true),
                  barisInfo(
                      'Status refund',
                      k.refundStatus == 'diproses'
                          ? 'Diproses'
                          : k.refundStatus == 'selesai'
                              ? 'Selesai'
                              : 'Tidak ada refund'),
                  if (catatanRefund.isNotEmpty) barisInfo('Catatan', catatanRefund),
                ] else
                  barisInfo('Alasan', alasanTolak.isEmpty ? '-' : alasanTolak),
                if (k.status == StatusKonsultasi.dibatalkan && k.refundStatus == 'diproses') ...[
                  const SizedBox(height: 8),
                  const Text(
                      'Transfer refund ke klien, lalu tandai selesai.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMuted)),
                  _tombol('Tandai refund selesai', () => _refundSelesai(k), utama: true),
                ],
              ],
            ),
          ),
        if (k.status == StatusKonsultasi.dibatalkan || k.status == StatusKonsultasi.dikonfirmasi || k.status == StatusKonsultasi.selesai)
          if ((m['buktiBayar'] as String?)?.isNotEmpty ?? false)
            KartuAdmin(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bukti transfer klien', style: AppTheme.heading(16)),
                  const SizedBox(height: 10),
                  BuktiTransfer(m['buktiBayar'] as String?),
                ],
              ),
            ),
      ],
    );
  }
}
