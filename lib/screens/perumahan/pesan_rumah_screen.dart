import 'package:flutter/material.dart';
import '../../data/perumahan_data.dart';
import '../../models/pengaturan.dart';
import '../../services/auth_service.dart';
import '../../services/pengaturan_service.dart';
import '../../services/pesanan_rumah_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/gambar_proyek.dart';
import 'pembayaran_rumah_screen.dart';

/// Konfirmasi pesanan: ringkasan unit + booking fee, lalu buat pesanan.
class PesanRumahScreen extends StatefulWidget {
  final Perumahan perumahan;
  final TipeRumah tipe;
  const PesanRumahScreen(
      {super.key, required this.perumahan, required this.tipe});

  @override
  State<PesanRumahScreen> createState() => _PesanRumahScreenState();
}

class _PesanRumahScreenState extends State<PesanRumahScreen> {
  bool _setuju = false;
  bool _membuat = false;
  String _nama = '';

  @override
  void initState() {
    super.initState();
    AuthService().getUserProfile().then((p) {
      if (mounted) setState(() => _nama = p?['nama'] as String? ?? '');
    });
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _buat() async {
    if (!_setuju) return _pesan('Centang persetujuan dulu.');
    setState(() => _membuat = true);
    try {
      final id = await PesananRumahService.buat(
        userNama: _nama,
        perumahan: widget.perumahan,
        tipe: widget.tipe,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
            builder: (_) => PembayaranRumahScreen(pesananId: id)),
      );
    } catch (e) {
      debugPrint('BUAT PESANAN RUMAH ERROR: $e');
      if (!mounted) return;
      setState(() => _membuat = false);
      _pesan('Gagal membuat pesanan. Coba lagi.');
    }
  }

  Widget _baris(String k, String v, {bool tebal = false}) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 5),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(k,
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
            const SizedBox(width: 16),
            Flexible(
              child: Text(v,
                  textAlign: TextAlign.right,
                  style: TextStyle(
                      fontSize: tebal ? 15 : 13,
                      fontWeight: tebal ? FontWeight.w700 : FontWeight.w600)),
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = widget.perumahan;
    final t = widget.tipe;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Konfirmasi Pesanan', style: AppTheme.heading(21)),
      ),
      body: StreamBuilder<Pengaturan>(
        stream: PengaturanService.stream(),
        initialData: Pengaturan.bawaan,
        builder: (context, snap) {
          final s = snap.data ?? Pengaturan.bawaan;
          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Row(children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: GambarProyek(p.foto.first,
                              width: 76, height: 76, cacheWidth: 250),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.nama, style: AppTheme.heading(18)),
                              Text('${t.nama} · ${p.kota}',
                                  style: const TextStyle(
                                      fontSize: 12, color: AppColors.textMuted)),
                              const SizedBox(height: 4),
                              Text(
                                  '${t.kamarTidur} KT · ${t.kamarMandi} KM · ${t.luasBangunan}/${t.luasTanah} m²',
                                  style: const TextStyle(fontSize: 12)),
                            ],
                          ),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.surface,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Column(children: [
                        _baris('Harga unit', formatRupiah(t.harga)),
                        _baris('Serah terima', p.serahTerima),
                        const Divider(height: 22, color: AppColors.border),
                        _baris('Booking fee', formatRupiah(s.bookingFeeRumah),
                            tebal: true),
                      ]),
                    ),
                    const SizedBox(height: 14),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                          color: AppColors.sageMuda,
                          borderRadius: BorderRadius.circular(16)),
                      child: Text(
                          '1. Bayar booking fee lewat transfer dalam ${s.batasBayarJam} jam.\n'
                          '2. Unggah bukti transfer, admin memverifikasi.\n'
                          '3. Setelah disetujui, tim kami menghubungimu untuk proses berikutnya.\n'
                          'Pesanan yang tidak dibayar sampai batas waktu dibatalkan otomatis.',
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.7,
                              color: AppColors.primary)),
                    ),
                    const SizedBox(height: 14),
                    InkWell(
                      onTap: () => setState(() => _setuju = !_setuju),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Checkbox(
                            value: _setuju,
                            activeColor: AppColors.primary,
                            onChanged: (v) => setState(() => _setuju = v ?? false),
                          ),
                          const Expanded(
                            child: Padding(
                              padding: EdgeInsets.only(top: 12),
                              child: Text(
                                  'Saya sudah membaca rincian di atas dan setuju melanjutkan pemesanan.',
                                  style: TextStyle(fontSize: 12, height: 1.55)),
                            ),
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
                child: ElevatedButton(
                  onPressed: (_membuat || _nama.isEmpty) ? null : _buat,
                  child: _membuat
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2.5, color: Colors.white))
                      : const Text('Buat Pesanan'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
