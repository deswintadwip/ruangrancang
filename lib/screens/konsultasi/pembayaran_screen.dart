import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/status.dart';
import '../../data/arsitek_data.dart';
import '../../models/konsultasi.dart';
import '../../models/pengaturan.dart';
import '../../services/konsultasi_service.dart';
import '../../services/pengaturan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/arsitek_foto.dart';

const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

/// Layar pembayaran: hitung mundur, info rekening, unggah bukti transfer.
class PembayaranScreen extends StatefulWidget {
  final String konsultasiId;
  const PembayaranScreen({super.key, required this.konsultasiId});

  @override
  State<PembayaranScreen> createState() => _PembayaranScreenState();
}

class _PembayaranScreenState extends State<PembayaranScreen> {
  Timer? _timer;
  DateTime _sekarang = DateTime.now();
  Uint8List? _bukti; // gambar pilihan user (sudah dikecilkan oleh picker)
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

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _pilihBukti() async {
    try {
      final x = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1000,
        imageQuality: 70,
      );
      if (x == null) return;
      final bytes = await x.readAsBytes();
      // Dokumen Firestore maksimal 1 MiB; base64 membesar sekitar 33%.
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

  Future<void> _kirim(Konsultasi k) async {
    if (_bukti == null) {
      _pesan('Unggah bukti transfer dulu.');
      return;
    }
    setState(() => _mengirim = true);
    try {
      await KonsultasiService.kirimBukti(k.id, base64Encode(_bukti!));
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

  Future<void> _batalkan(Konsultasi k) async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Batalkan pesanan?', style: AppTheme.heading(18)),
        content: const Text(
            'Jadwal akan dibuka kembali. Kamu belum membayar, jadi tidak ada '
                'refund yang perlu diproses.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Tidak')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, batalkan',
                  style: TextStyle(color: Color(0xFFB3392F)))),
        ],
      ),
    );
    if (yakin != true) return;
    try {
      await KonsultasiService.batalkan(k,
          oleh: 'user', alasan: 'Dibatalkan sebelum pembayaran');
      if (!mounted) return;
      Navigator.pop(context);
      _pesan('Pesanan dibatalkan.');
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
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Pembayaran', style: AppTheme.heading(19)),
      ),
      body: StreamBuilder<Konsultasi?>(
        stream: KonsultasiService.satu(widget.konsultasiId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Gagal memuat pesanan.'));
          }
          if (!snap.hasData) {
            return snap.connectionState == ConnectionState.active
                ? const Center(child: Text('Pesanan tidak ditemukan.'))
                : const Center(child: CircularProgressIndicator());
          }
          final k = snap.data!;
          return _isi(k);
        },
      ),
    );
  }

  Widget _isi(Konsultasi k) {
    final belumBayar = k.status == StatusKonsultasi.menungguPembayaran;
    final batas = k.batasBayar;
    final sisa = batas == null ? Duration.zero : batas.difference(_sekarang);
    final habis = belumBayar && batas != null && sisa.isNegative;

    // posisi langkah: 0 menunggu bayar, 1 verifikasi, 2 dikonfirmasi
    int langkah = 0;
    if (k.status == StatusKonsultasi.menungguVerifikasi) langkah = 1;
    if (k.status == StatusKonsultasi.dikonfirmasi ||
        k.status == StatusKonsultasi.selesai) {
      langkah = 2;
    }

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 24),
            children: [
              if (belumBayar && k.alasanTolak.isNotEmpty && !habis)
                _bannerUlang(k.alasanTolak),
              if (belumBayar) _hitungMundur(sisa, habis),
              if (k.batal) _kartuBatal(k),
              const SizedBox(height: 16),
              if (!k.batal) _langkahStatus(langkah),
              const SizedBox(height: 16),
              _ringkasan(k),
              if (belumBayar && !habis) ..._bagianBayar(),
              if (k.status == StatusKonsultasi.menungguVerifikasi)
                _infoBiru('Bukti pembayaran sudah dikirim. Admin akan '
                    'memverifikasi, biasanya dalam 1 x 24 jam. Kamu akan '
                    'mendapat pemberitahuan setelah dikonfirmasi.'),
              if (k.status == StatusKonsultasi.dikonfirmasi)
                _infoBiru('Pembayaran terverifikasi. Jadwal konsultasimu '
                    'sudah dikonfirmasi.'),
            ],
          ),
        ),
        if (belumBayar && !habis) _barBawah(k),
      ],
    );
  }

  Widget _hitungMundur(Duration sisa, bool habis) {
    final s = habis ? Duration.zero : sisa;
    String dua(int n) => n.toString().padLeft(2, '0');
    final jam = dua(s.inHours);
    final menit = dua(s.inMinutes.remainder(60));
    final detik = dua(s.inSeconds.remainder(60));
    Widget kotak(String t) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(t,
          style: AppTheme.heading(34).copyWith(color: const Color(0xFF4D3C17))),
    );
    final titik = Text(':',
        style: AppTheme.heading(34).copyWith(color: const Color(0xFF4D3C17)));
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF7EBD2),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        children: [
          Text(habis ? 'Waktu pembayaran habis' : 'Selesaikan pembayaran dalam',
              style: const TextStyle(fontSize: 12.5, color: Color(0xFF6B5322))),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              kotak(jam),
              const SizedBox(width: 8),
              titik,
              const SizedBox(width: 8),
              kotak(menit),
              const SizedBox(width: 8),
              titik,
              const SizedBox(width: 8),
              kotak(detik),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            habis
                ? 'Pesanan akan dibatalkan otomatis dan jadwal dibuka kembali.'
                : 'Lewat batas waktu, pesanan dibatalkan dan slot dibuka kembali.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11.5, color: Color(0xFF6B5322)),
          ),
        ],
      ),
    );
  }

  Widget _kartuBatal(Konsultasi k) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF7E3DD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
          k.status == StatusKonsultasi.ditolak
              ? 'Pembayaran ditolak admin.'
                  '${k.alasanTolak.isEmpty ? '' : '\nAlasan: ${k.alasanTolak}'}'
                  '\nJadwal sudah dibuka kembali.'
              : 'Pesanan ini sudah dibatalkan. Jadwal sudah dibuka kembali.'
                  '${k.alasanBatal.isEmpty ? '' : '\nAlasan: ${k.alasanBatal}'}',
          style: const TextStyle(
              fontSize: 13, height: 1.5, color: Color(0xFF7A3F32))),
    );
  }

  /// Muncul saat admin meminta bukti diunggah ulang.
  Widget _bannerUlang(String alasan) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF7EBD2),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
              'Bukti pembayaranmu belum bisa diverifikasi.\nAlasan: $alasan\n'
              'Silakan unggah bukti transfer yang baru.',
              style: const TextStyle(
                  fontSize: 12.5, height: 1.5, color: Color(0xFF6E4F0E))),
        ),
      );

  Widget _langkahStatus(int aktif) {
    const label = ['Menunggu bayar', 'Verifikasi admin', 'Dikonfirmasi'];
    Widget bulat(int i) {
      final selesai = i < aktif;
      final sekarang = i == aktif;
      return Container(
        width: 20,
        height: 20,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: selesai
              ? AppColors.primary
              : (sekarang ? const Color(0xFFD9A441) : Colors.transparent),
          border: Border.all(
              color: (selesai || sekarang)
                  ? AppColors.primary
                  : const Color(0xFFC9BFAA),
              width: 3),
        ),
        child: selesai
            ? const Icon(Icons.check, size: 12, color: Colors.white)
            : null,
      );
    }

    Widget garis(int i) => Expanded(
      child: Container(
        height: 3,
        color: i < aktif ? AppColors.primary : const Color(0xFFC9BFAA),
      ),
    );

    return Column(
      children: [
        Row(children: [bulat(0), garis(0), bulat(1), garis(1), bulat(2)]),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            for (int i = 0; i < 3; i++)
              Text(label[i],
                  style: TextStyle(
                      fontSize: 10.5,
                      fontWeight:
                      i == aktif ? FontWeight.w700 : FontWeight.w400,
                      color: i == aktif
                          ? (i == 0
                          ? const Color(0xFFB45F06)
                          : AppColors.primary)
                          : AppColors.textMuted)),
          ],
        ),
      ],
    );
  }

  Widget _ringkasan(Konsultasi k) {
    final a = DataArsitek.byId(k.arsitekId);
    final d = DateTime.tryParse(k.tanggal);
    final tgl = d == null
        ? k.tanggal
        : '${_hariPendek[d.weekday - 1]}, ${d.day} ${_bulanPendek[d.month - 1]}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(children: [
        Row(children: [
          if (a != null)
            ArsitekFoto(
              arsitek: a,
              width: 44,
              height: 44,
              borderRadius: BorderRadius.circular(22),
              fontSize: 15,
            ),
          if (a != null) const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(k.arsitekNama,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 1),
                Text(
                    '$tgl · ${k.jam} – ${k.jamSelesai} · ${k.online ? 'Online' : 'Studio'}',
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
              child: Text('Total',
                  style:
                  TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700))),
          Text(formatRupiah(k.harga),
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
          final p = snap.data ?? Pengaturan.bawaan;
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
                    style:
                    TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Row(children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('${p.bankNama} · a.n. ${p.bankAtasNama}',
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textMuted)),
                        const SizedBox(height: 1),
                        Text(p.bankNomor,
                            style: const TextStyle(
                                fontSize: 17,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                      ],
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: p.bankNomor));
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
            Icon(Icons.upload_outlined,
                size: 26, color: AppColors.primary),
            SizedBox(height: 6),
            Text('Unggah bukti transfer',
                style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
            SizedBox(height: 2),
            Text('JPG atau PNG, otomatis dikecilkan',
                style: TextStyle(
                    fontSize: 11, color: AppColors.textMuted)),
          ])
              : Column(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_bukti!,
                  height: 180, fit: BoxFit.cover),
            ),
            const SizedBox(height: 8),
            const Text('Ketuk untuk mengganti gambar',
                style: TextStyle(
                    fontSize: 11.5, color: AppColors.textMuted)),
          ]),
        ),
      ),
    ];
  }

  Widget _infoBiru(String teks) => Padding(
    padding: const EdgeInsets.only(top: 14),
    child: Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFE1EDFB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Text(teks,
          style: const TextStyle(
              fontSize: 12.5, height: 1.5, color: Color(0xFF1D4E89))),
    ),
  );

  Widget _barBawah(Konsultasi k) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Row(children: [
        Expanded(
          flex: 1,
          child: OutlinedButton(
            onPressed: _mengirim ? null : () => _batalkan(k),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              side: const BorderSide(color: Color(0xFFB3392F), width: 1.5),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: const Text('Batalkan',
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFFB3392F))),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          flex: 2,
          child: FilledButton(
            onPressed: (_mengirim || _bukti == null) ? null : () => _kirim(k),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(52),
              backgroundColor: AppColors.primary,
              disabledBackgroundColor: AppColors.border,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
            ),
            child: _mengirim
                ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                    strokeWidth: 2.5, color: Colors.white))
                : const Text('Kirim Bukti Pembayaran',
                style:
                TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
          ),
        ),
      ]),
    );
  }
}