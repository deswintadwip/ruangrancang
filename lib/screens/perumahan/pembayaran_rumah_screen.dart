import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/status.dart';
import '../../models/pengaturan.dart';
import '../../models/pesanan_rumah.dart';
import '../../services/pengaturan_service.dart';
import '../../services/pesanan_rumah_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';

/// Pembayaran booking fee + status pesanan rumah (semua status di satu layar).
class PembayaranRumahScreen extends StatefulWidget {
  final String pesananId;
  const PembayaranRumahScreen({super.key, required this.pesananId});

  @override
  State<PembayaranRumahScreen> createState() => _PembayaranRumahScreenState();
}

class _PembayaranRumahScreenState extends State<PembayaranRumahScreen> {
  Timer? _timer;
  DateTime _sekarang = DateTime.now();
  Uint8List? _bukti;
  bool _mengirim = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sekarang = DateTime.now());
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _pilihBukti() async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 70);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      if (bytes.length > 650 * 1024) {
        _pesan('Gambar terlalu besar. Pilih foto yang lebih kecil.');
        return;
      }
      if (!mounted) return;
      setState(() => _bukti = bytes);
    } catch (_) {
      _pesan('Tidak bisa membuka galeri.');
    }
  }

  Future<void> _kirim(PesananRumah p) async {
    if (_bukti == null) return _pesan('Unggah bukti transfer dulu.');
    setState(() => _mengirim = true);
    try {
      await PesananRumahService.kirimBukti(p, base64Encode(_bukti!));
      if (!mounted) return;
      setState(() {
        _mengirim = false;
        _bukti = null;
      });
      _pesan('Bukti terkirim. Admin akan memverifikasi.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      _pesan('Gagal mengirim bukti. Coba lagi.');
    }
  }

  Future<void> _batalkan(PesananRumah p) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Batalkan pesanan?', style: AppTheme.heading(18)),
        content: const Text(
            'Kamu belum membayar, jadi tidak ada dana yang perlu dikembalikan. Unit akan dilepas kembali.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, batalkan',
                  style: TextStyle(color: AppColors.terakota))),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await PesananRumahService.batalkan(p);
      if (mounted) _pesan('Pesanan dibatalkan.');
    } catch (_) {
      _pesan('Gagal membatalkan. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Booking Rumah', style: AppTheme.heading(21)),
      ),
      body: StreamBuilder<PesananRumah?>(
        stream: PesananRumahService.satu(widget.pesananId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Gagal memuat pesanan.'));
          }
          if (!snap.hasData) {
            return snap.connectionState == ConnectionState.active
                ? const Center(child: Text('Pesanan tidak ditemukan.'))
                : const Center(child: CircularProgressIndicator());
          }
          return _isi(snap.data!);
        },
      ),
    );
  }

  Widget _isi(PesananRumah p) {
    final belumBayar = p.status == StatusPesananRumah.menungguPembayaran;
    final batas = p.batasBayar;
    final sisa = batas == null ? Duration.zero : batas.difference(_sekarang);
    final habis = belumBayar && batas != null && sisa.isNegative;

    int langkah = 0;
    if (p.status == StatusPesananRumah.menungguVerifikasi) langkah = 1;
    if (p.status == StatusPesananRumah.disetujui) langkah = 2;
    final gagal = p.status == StatusPesananRumah.ditolak ||
        p.status == StatusPesananRumah.dibatalkan;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              if (belumBayar) _hitungMundur(sisa, habis),
              if (p.status == StatusPesananRumah.dibatalkan)
                _kotak(
                    p.alasanBatal.isEmpty
                        ? 'Pesanan ini sudah dibatalkan.'
                        : 'Pesanan dibatalkan: ${p.alasanBatal}.',
                    const Color(0xFFF7E3DD),
                    const Color(0xFF7A3F32)),
              if (p.status == StatusPesananRumah.ditolak)
                _kotak(
                    p.alasanTolak.isEmpty
                        ? 'Pembayaran ditolak admin. Hubungi CS untuk bantuan.'
                        : 'Pembayaran ditolak admin: ${p.alasanTolak}',
                    const Color(0xFFF7E3DD),
                    const Color(0xFF7A3F32)),
              const SizedBox(height: 16),
              if (!gagal) _langkahStatus(langkah),
              const SizedBox(height: 16),
              _ringkasan(p),
              if (belumBayar && !habis) ..._bagianBayar(),
              if (p.status == StatusPesananRumah.menungguVerifikasi)
                _kotak(
                    'Bukti pembayaran sudah dikirim. Admin akan memverifikasi, biasanya dalam 1 x 24 jam. Kamu akan mendapat pemberitahuan setelahnya.',
                    const Color(0xFFE1EDFB),
                    const Color(0xFF1D4E89)),
              if (p.status == StatusPesananRumah.disetujui)
                _kotak(
                    'Booking fee terverifikasi. Unitmu sudah tertahan, tim kami akan menghubungimu untuk proses berikutnya.',
                    AppColors.sageMuda,
                    AppColors.primary),
            ],
          ),
        ),
        if (belumBayar && !habis) _barBawah(p),
      ],
    );
  }

  Widget _kotak(String teks, Color bg, Color fg) => Padding(
        padding: const EdgeInsets.only(top: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration:
              BoxDecoration(color: bg, borderRadius: BorderRadius.circular(14)),
          child: Text(teks,
              style: TextStyle(fontSize: 12.5, height: 1.55, color: fg)),
        ),
      );

  Widget _hitungMundur(Duration sisa, bool habis) {
    final s = habis ? Duration.zero : sisa;
    String dua(int n) => n.toString().padLeft(2, '0');
    Widget kotak(String t) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
              color: Colors.white, borderRadius: BorderRadius.circular(12)),
          child: Text(t,
              style: AppTheme.heading(34).copyWith(color: const Color(0xFF4D3C17))),
        );
    final titik = Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Text(':',
          style: AppTheme.heading(34).copyWith(color: const Color(0xFF4D3C17))),
    );
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
          color: const Color(0xFFF7EBD2), borderRadius: BorderRadius.circular(22)),
      child: Column(children: [
        Text(habis ? 'Waktu pembayaran habis' : 'Bayar booking fee dalam',
            style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B5322))),
        const SizedBox(height: 8),
        Row(mainAxisAlignment: MainAxisAlignment.center, children: [
          kotak(dua(s.inHours)),
          titik,
          kotak(dua(s.inMinutes.remainder(60))),
          titik,
          kotak(dua(s.inSeconds.remainder(60))),
        ]),
        const SizedBox(height: 8),
        const Text('Lewat batas waktu, pesanan dibatalkan dan unit dilepas.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 11.5, color: Color(0xFF6B5322))),
      ]),
    );
  }

  Widget _langkahStatus(int aktif) {
    const label = ['Menunggu bayar', 'Verifikasi admin', 'Disetujui'];
    Widget bulat(int i) {
      final selesai = i < aktif || (aktif == 2 && i == 2);
      final sekarang = i == aktif && !selesai;
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selesai
              ? AppColors.primary
              : (sekarang ? const Color(0xFFD9A441) : Colors.transparent),
          border: Border.all(
              color: (selesai || sekarang) ? AppColors.primary : const Color(0xFFC9BFAA),
              width: 3),
        ),
        child: selesai ? const Icon(Icons.check, size: 12, color: Colors.white) : null,
      );
    }

    Widget garis(int i) => Expanded(
          child: Container(
              height: 3,
              color: i < aktif ? AppColors.primary : const Color(0xFFC9BFAA)),
        );

    return Column(children: [
      Row(children: [bulat(0), garis(0), bulat(1), garis(1), bulat(2)]),
      const SizedBox(height: 6),
      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        for (var i = 0; i < 3; i++)
          Text(label[i],
              style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: i == aktif ? FontWeight.w700 : FontWeight.w400,
                  color: i == aktif ? AppColors.primary : AppColors.textMuted)),
      ]),
    ]);
  }

  Widget _ringkasan(PesananRumah p) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
                color: AppColors.sageMuda,
                borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.house_outlined, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(p.perumahanNama,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                Text('${p.tipe} · ${p.kota}',
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textMuted)),
              ],
            ),
          ),
        ]),
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 12),
          child: Divider(height: 1, color: AppColors.border),
        ),
        Row(children: [
          const Expanded(
              child: Text('Booking fee',
                  style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
          Text(formatRupiah(p.bookingFee),
              style: AppTheme.heading(20).copyWith(color: AppColors.primary)),
        ]),
      ]),
    );
  }

  List<Widget> _bagianBayar() {
    return [
      const SizedBox(height: 12),
      StreamBuilder<Pengaturan>(
        stream: PengaturanService.stream(),
        initialData: Pengaturan.bawaan,
        builder: (context, snap) {
          final s = snap.data ?? Pengaturan.bawaan;
          return Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Transfer ke',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${s.bankNama} · a.n. ${s.bankAtasNama}',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textMuted)),
                        Text(s.bankNomor,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: s.bankNomor));
                      if (mounted) _pesan('Nomor rekening disalin.');
                    },
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.primary),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(19)),
                    ),
                    child: const Text('Salin',
                        style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary)),
                  ),
                ]),
              ],
            ),
          );
        },
      ),
      const SizedBox(height: 12),
      GestureDetector(
        onTap: _pilihBukti,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFC9BFAA), width: 1.5),
          ),
          child: _bukti == null
              ? const Column(children: [
                  Icon(Icons.upload_outlined, size: 26, color: AppColors.primary),
                  SizedBox(height: 6),
                  Text('Unggah bukti transfer',
                      style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                  SizedBox(height: 2),
                  Text('JPG atau PNG, otomatis dikecilkan',
                      style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
                ])
              : Column(children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.memory(_bukti!, height: 180, fit: BoxFit.cover),
                  ),
                  const SizedBox(height: 8),
                  const Text('Ketuk untuk mengganti gambar',
                      style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ]),
        ),
      ),
    ];
  }

  Widget _barBawah(PesananRumah p) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _mengirim ? null : () => _batalkan(p),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: AppColors.terakota, width: 1.5),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Batalkan',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.terakota)),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: (_mengirim || _bukti == null) ? null : () => _kirim(p),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: _mengirim
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: Colors.white))
                : const Text('Kirim Bukti Pembayaran',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}
