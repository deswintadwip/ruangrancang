import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/status.dart';
import '../../models/pengaturan.dart';
import '../../models/pesanan_sketsa.dart';
import '../../services/auth_service.dart';
import '../../services/pengaturan_service.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../admin/admin_util.dart';
import 'sketsa_util.dart';

/// Detail pesanan sketsa. Satu layar untuk tiga peran:
/// user (bayar & unduh hasil), arsitek (kirim PDF), admin (verifikasi).
class SketsaDetailScreen extends StatefulWidget {
  final String pesananId;
  const SketsaDetailScreen({super.key, required this.pesananId});

  @override
  State<SketsaDetailScreen> createState() => _SketsaDetailScreenState();
}

class _SketsaDetailScreenState extends State<SketsaDetailScreen> {
  String _role = 'user';
  DateTime _sekarang = DateTime.now();
  Timer? _timer;
  Uint8List? _bukti; // bukti baru yang dipilih user
  Uint8List? _pdf; // PDF yang dipilih arsitek
  String _pdfNama = '';
  bool _sibuk = false;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _sekarang = DateTime.now());
    });
    AuthService().getUserProfile().then((p) {
      if (mounted) setState(() => _role = (p?['role'] as String?) ?? 'user');
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _jalankan(Future<void> Function() aksi, {String? sukses}) async {
    setState(() => _sibuk = true);
    try {
      await aksi();
      if (sukses != null) _pesan(sukses);
    } catch (e) {
      debugPrint('SKETSA AKSI ERROR: $e');
      _pesan('Gagal: ${e.toString().replaceFirst('Exception: ', '')}');
    } finally {
      if (mounted) setState(() => _sibuk = false);
    }
  }

  // ───────────── aksi user ─────────────

  Future<void> _pilihBukti() async {
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 1000, imageQuality: 70);
      if (x == null) return;
      final b = await x.readAsBytes();
      if (b.length > 400 * 1024) {
        return _pesan('Gambar terlalu besar. Pilih yang lebih kecil.');
      }
      setState(() => _bukti = b);
    } catch (_) {
      _pesan('Tidak bisa membuka galeri.');
    }
  }

  Future<void> _kirimBukti(PesananSketsa p) async {
    final b = _bukti;
    if (b == null) return _pesan('Pilih foto bukti transfer dulu.');
    await _jalankan(() async {
      await PesananSketsaService.kirimBukti(p, base64Encode(b));
      _bukti = null;
    }, sukses: 'Bukti terkirim. Admin akan memverifikasi.');
  }

  Future<void> _batalkan(PesananSketsa p, {required String oleh}) async {
    final alasan = await tanyaAlasan(context,
        judul: 'Batalkan pesanan?',
        petunjuk: 'Alasan pembatalan',
        tombol: 'Batalkan pesanan',
        wajib: false);
    if (alasan == null) return;
    await _jalankan(() => PesananSketsaService.batalkan(p, oleh: oleh, alasan: alasan),
        sukses: 'Pesanan dibatalkan.');
  }

  Future<void> _unduh(PesananSketsa p) async {
    if (!kIsWeb) {
      return _pesan('Pengunduhan saat ini tersedia lewat versi web.');
    }
    await _jalankan(() async {
      final bytes = await PesananSketsaService.ambilHasil(p);
      final nama = p.hasilNama.isEmpty ? 'sketsa.pdf' : p.hasilNama;
      await XFile.fromData(bytes, mimeType: 'application/pdf', name: nama).saveTo(nama);
    }, sukses: 'File sketsa diunduh.');
  }

  // ───────────── aksi arsitek ─────────────

  Future<void> _pilihPdf() async {
    try {
      final f = await openFile(acceptedTypeGroups: [
        const XTypeGroup(label: 'PDF', extensions: ['pdf'], mimeTypes: ['application/pdf']),
      ]);
      if (f == null) return;
      final b = await f.readAsBytes();
      if (b.length > PesananSketsaService.batasUkuranHasil) {
        return _pesan('Ukuran PDF maksimal 3 MB.');
      }
      setState(() {
        _pdf = b;
        _pdfNama = f.name;
      });
    } catch (_) {
      _pesan('Tidak bisa membuka file.');
    }
  }

  Future<void> _kirimHasil(PesananSketsa p) async {
    final b = _pdf;
    if (b == null) return _pesan('Pilih file PDF sketsa dulu.');
    await _jalankan(() async {
      await PesananSketsaService.kirimHasil(p, b, _pdfNama);
      _pdf = null;
    }, sukses: 'Sketsa terkirim ke klien.');
  }

  // ───────────── aksi admin ─────────────

  Future<void> _setujui(PesananSketsa p) async {
    final ya = await konfirmasi(context,
        judul: 'Setujui pembayaran?',
        isi: 'Pesanan akan diteruskan ke ${p.arsitekNama} untuk dikerjakan.',
        tombol: 'Setujui');
    if (!ya) return;
    await _jalankan(() => PesananSketsaService.setujui(p), sukses: 'Pembayaran disetujui.');
  }

  Future<void> _ulang(PesananSketsa p) async {
    final a = await tanyaAlasan(context,
        judul: 'Minta unggah ulang',
        petunjuk: 'Contoh: nominal tidak sesuai / foto buram',
        tombol: 'Kirim permintaan',
        warnaTombol: AppColors.primary);
    if (a == null) return;
    await _jalankan(() => PesananSketsaService.mintaUnggahUlang(p, a),
        sukses: 'Permintaan unggah ulang dikirim.');
  }

  Future<void> _tolak(PesananSketsa p) async {
    final a = await tanyaAlasan(context,
        judul: 'Tolak pembayaran',
        petunjuk: 'Alasan penolakan (dilihat klien)',
        tombol: 'Tolak');
    if (a == null) return;
    await _jalankan(() => PesananSketsaService.tolak(p, a), sukses: 'Pesanan ditolak.');
  }

  // ───────────── tampilan ─────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Sketsa Desain', style: AppTheme.heading(20)),
      ),
      body: StreamBuilder<PesananSketsa?>(
        stream: PesananSketsaService.satu(widget.pesananId),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting && !snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          if (p == null) {
            return const Center(
                child: Text('Pesanan tidak ditemukan.',
                    style: TextStyle(color: AppColors.textMuted)));
          }
          final bar = _barBawah(p);
          return Column(children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                children: [
                  _kepala(p),
                  const SizedBox(height: 14),
                  _stepper(p),
                  const SizedBox(height: 14),
                  ..._isiPeran(p),
                  const SizedBox(height: 6),
                  _ringkasan(p),
                  if (p.lampiran.isNotEmpty) _lampiran(p),
                ],
              ),
            ),
            if (bar != null) bar,
          ]);
        },
      ),
    );
  }

  Widget _kotak(Widget anak, {Color? warna}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: warna ?? AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: warna == null ? Border.all(color: AppColors.border) : null,
        ),
        child: anak,
      );

  Widget _kepala(PesananSketsa p) {
    return _kotak(Row(children: [
      Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Arsitek ${p.arsitekNama}',
              style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 2),
          Text(
              _role == 'user'
                  ? 'Dipesan ${tglSketsa(p.createdAt)}'
                  : 'Klien: ${p.userNama} · ${tglSketsa(p.createdAt)}',
              style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          const SizedBox(height: 8),
          Text(formatRupiah(p.harga),
              style: AppTheme.heading(20).copyWith(color: AppColors.primary)),
        ]),
      ),
      LencanaStatusSketsa(p.status),
    ]));
  }

  Widget _stepper(PesananSketsa p) {
    const langkah = ['Bayar', 'Verifikasi', 'Dikerjakan', 'Selesai'];
    final idx = switch (p.status) {
      StatusSketsa.menungguPembayaran => 0,
      StatusSketsa.menungguVerifikasi => 1,
      StatusSketsa.dikerjakan => 2,
      StatusSketsa.selesai => 3,
      _ => -1,
    };
    if (idx < 0) return const SizedBox.shrink();
    return Row(children: [
      for (var i = 0; i < langkah.length; i++) ...[
        Expanded(
          child: Column(children: [
            Container(
              width: 26,
              height: 26,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: i <= idx ? AppColors.primary : AppColors.border,
              ),
              child: i < idx || idx == 3
                  ? const Icon(Icons.check, size: 15, color: Colors.white)
                  : Text('${i + 1}',
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: i <= idx ? Colors.white : AppColors.textMuted)),
            ),
            const SizedBox(height: 5),
            Text(langkah[i],
                style: TextStyle(
                    fontSize: 11,
                    fontWeight: i == idx ? FontWeight.w700 : FontWeight.w400,
                    color: i <= idx ? AppColors.textDark : AppColors.textMuted)),
          ]),
        ),
      ],
    ]);
  }

  /// Bagian khusus peran/status.
  List<Widget> _isiPeran(PesananSketsa p) {
    final w = <Widget>[];

    if (p.status == StatusSketsa.ditolak || p.status == StatusSketsa.dibatalkan) {
      final alasan = p.status == StatusSketsa.ditolak ? p.alasanTolak : p.alasanBatal;
      w.add(_kotak(
          Text(
              '${p.status == StatusSketsa.ditolak ? 'Pesanan ditolak admin.' : 'Pesanan dibatalkan.'}'
              '${alasan.isEmpty ? '' : '\nAlasan: $alasan'}',
              style: const TextStyle(fontSize: 13, height: 1.5, color: Color(0xFF7A3F32))),
          warna: const Color(0xFFF7E3DD)));
      return w;
    }

    if (_role == 'user') {
      if (p.status == StatusSketsa.menungguPembayaran) {
        if (p.alasanTolak.isNotEmpty) {
          w.add(_kotak(
              Text(
                  'Bukti pembayaranmu belum bisa diverifikasi.\nAlasan: ${p.alasanTolak}\n'
                  'Silakan unggah bukti transfer yang baru.',
                  style: const TextStyle(fontSize: 12.5, height: 1.5, color: Color(0xFF6E4F0E))),
              warna: const Color(0xFFF7EBD2)));
        }
        w.add(_hitungMundur(p));
        w.add(_infoBank(p));
        w.add(_unggahBukti());
      } else if (p.status == StatusSketsa.menungguVerifikasi) {
        w.add(_kotak(
            const Text(
                'Bukti pembayaran sudah diterima. Admin sedang memverifikasi, '
                'kamu akan dapat notifikasi saat pesanan mulai dikerjakan.',
                style: TextStyle(fontSize: 13, height: 1.5)),
            warna: AppColors.sageMuda));
      } else if (p.status == StatusSketsa.dikerjakan) {
        w.add(_kotak(
            Text(
                '${p.arsitekNama} sedang mengerjakan sketsamu. '
                'Hasilnya berupa file PDF dan akan muncul di halaman ini, '
                'kamu juga akan dapat notifikasi.',
                style: const TextStyle(fontSize: 13, height: 1.5)),
            warna: AppColors.sageMuda));
      }
    }

    if (_role == 'admin' &&
        (p.status == StatusSketsa.menungguVerifikasi ||
            p.status == StatusSketsa.menungguPembayaran)) {
      w.add(_kotak(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Bukti transfer',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        BuktiTransfer(p.bukti),
      ])));
    }

    if (_role == 'arsitek' && p.status == StatusSketsa.dikerjakan) {
      w.add(_kotak(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        const Text('Kirim hasil sketsa',
            style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 4),
        const Text('Unggah satu file PDF (maksimal 3 MB) berisi gambar sketsa.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: _sibuk ? null : _pilihPdf,
          icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
          label: Text(_pdf == null ? 'Pilih file PDF' : '$_pdfNama (${(_pdf!.length / 1024).round()} KB)',
              overflow: TextOverflow.ellipsis),
          style: OutlinedButton.styleFrom(
            foregroundColor: AppColors.primary,
            minimumSize: const Size.fromHeight(46),
            side: const BorderSide(color: AppColors.primary),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ])));
    }

    if (p.adaHasil) {
      w.add(_kotak(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(p.hasilNama.isEmpty ? 'sketsa.pdf' : p.hasilNama,
                      style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                      overflow: TextOverflow.ellipsis),
                  Text('${(p.hasilUkuran / 1024).round()} KB · dikirim ${tglSketsa(p.hasilAt)}',
                      style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
                ]),
              ),
            ]),
            const SizedBox(height: 12),
            FilledButton.icon(
              onPressed: _sibuk ? null : () => _unduh(p),
              icon: const Icon(Icons.download_outlined, size: 18),
              label: const Text('Unduh Sketsa (PDF)'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                minimumSize: const Size.fromHeight(46),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ]),
          warna: AppColors.sageMuda));
    }
    return w;
  }

  Widget _hitungMundur(PesananSketsa p) {
    final batas = p.batasBayar;
    if (batas == null) return const SizedBox.shrink();
    final sisa = batas.difference(_sekarang);
    final habis = sisa.isNegative;
    final s = habis ? Duration.zero : sisa;
    String d2(int n) => n.toString().padLeft(2, '0');
    final teks = habis
        ? 'Waktu pembayaran habis'
        : 'Bayar dalam ${d2(s.inHours)}:${d2(s.inMinutes % 60)}:${d2(s.inSeconds % 60)}';
    return _kotak(
        Row(children: [
          Icon(Icons.timer_outlined,
              size: 20, color: habis ? const Color(0xFF7A3F32) : const Color(0xFF6E4F0E)),
          const SizedBox(width: 10),
          Text(teks,
              style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w700,
                  color: habis ? const Color(0xFF7A3F32) : const Color(0xFF6E4F0E))),
        ]),
        warna: habis ? const Color(0xFFF7E3DD) : const Color(0xFFF7EBD2));
  }

  Widget _infoBank(PesananSketsa p) {
    return StreamBuilder<Pengaturan>(
      stream: PengaturanService.stream(),
      builder: (context, snap) {
        final g = snap.data ?? Pengaturan.bawaan;
        return _kotak(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Transfer ke rekening',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          Text(g.bankNama, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          Row(children: [
            Expanded(
              child: Text(g.bankNomor,
                  style: AppTheme.heading(21).copyWith(letterSpacing: 1)),
            ),
            IconButton(
              tooltip: 'Salin',
              onPressed: () {
                Clipboard.setData(ClipboardData(text: g.bankNomor));
                _pesan('Nomor rekening disalin.');
              },
              icon: const Icon(Icons.copy_rounded, size: 18),
            ),
          ]),
          Text('a.n. ${g.bankAtasNama}', style: const TextStyle(fontSize: 12.5)),
          const Divider(height: 24),
          Row(children: [
            const Expanded(child: Text('Nominal transfer', style: TextStyle(fontSize: 13))),
            Text(formatRupiah(p.harga),
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
          ]),
        ]));
      },
    );
  }

  Widget _unggahBukti() {
    final b = _bukti;
    return _kotak(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Bukti transfer',
          style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      const SizedBox(height: 10),
      if (b != null)
        ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(b, height: 180, width: double.infinity, fit: BoxFit.cover))
      else
        const Text('Unggah foto atau tangkapan layar bukti transfer.',
            style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      const SizedBox(height: 10),
      OutlinedButton.icon(
        onPressed: _sibuk ? null : _pilihBukti,
        icon: const Icon(Icons.upload_outlined, size: 18),
        label: Text(b == null ? 'Pilih gambar' : 'Ganti gambar'),
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.primary,
          minimumSize: const Size.fromHeight(44),
          side: const BorderSide(color: AppColors.primary),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    ]));
  }

  Widget _baris(String k, String v) {
    if (v.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 122,
            child: Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted))),
        Expanded(child: Text(v, style: const TextStyle(fontSize: 13, height: 1.4))),
      ]),
    );
  }

  Widget _grup(String judul, List<Widget> isi) => _kotak(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(judul, style: AppTheme.heading(16)),
          const SizedBox(height: 6),
          ...isi,
        ]),
      );

  Widget _ringkasan(PesananSketsa p) {
    final ukuran = (p.panjang.isNotEmpty && p.lebar.isNotEmpty) ? '${p.panjang} × ${p.lebar} m' : '';
    return Column(children: [
      _grup('Data lahan', [
        _baris('Luas lahan', '${p.luasLahan} m²'),
        _baris('Ukuran', ukuran),
        _baris('Lokasi', p.kota),
        _baris('Arah hadap', p.arahHadap),
        _baris('Kontur', p.kontur),
        _baris('Kondisi', p.kondisiLahan),
      ]),
      _grup('Kebutuhan bangunan', [
        _baris('Jenis', p.jenisBangunan),
        _baris('Jumlah lantai', '${p.jumlahLantai}'),
        _baris('Luas bangunan', p.luasBangunan.isEmpty ? '' : '${p.luasBangunan} m²'),
        _baris('Kamar tidur', '${p.kamarTidur}'),
        _baris('Kamar mandi', '${p.kamarMandi}'),
        _baris('Penghuni', '${p.penghuni} orang'),
        _baris('Ruang tambahan', p.ruangTambahan.join(', ')),
      ]),
      _grup('Gaya dan preferensi', [
        _baris('Gaya', p.gaya),
        _baris('Material', p.material.join(', ')),
        _baris('Palet warna', p.palet),
        _baris('Kebutuhan khusus', p.kebutuhanKhusus.join(', ')),
        _baris('Budget', p.budget),
        _baris('Referensi', p.referensi),
        _baris('Catatan', p.catatan),
      ]),
    ]);
  }

  Widget _lampiran(PesananSketsa p) {
    return _kotak(Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text('Lampiran', style: AppTheme.heading(16)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (final s in p.lampiran)
          Builder(builder: (_) {
            try {
              final b = base64Decode(s);
              return GestureDetector(
                onTap: () => showDialog(
                  context: context,
                  builder: (_) => Dialog(
                    child: InteractiveViewer(child: Image.memory(b)),
                  ),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.memory(b, width: 96, height: 96, fit: BoxFit.cover),
                ),
              );
            } catch (_) {
              return const SizedBox.shrink();
            }
          }),
      ]),
    ]));
  }

  // ───────────── bar bawah ─────────────

  Widget? _barBawah(PesananSketsa p) {
    Widget? isi;
    FilledButton utama(String t, VoidCallback? f, {Color? warna}) => FilledButton(
          onPressed: _sibuk ? null : f,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            backgroundColor: warna ?? AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _sibuk
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : Text(t, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
        );
    OutlinedButton samping(String t, VoidCallback? f, {Color? warna}) => OutlinedButton(
          onPressed: _sibuk ? null : f,
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(50),
            foregroundColor: warna ?? const Color(0xFF7A3F32),
            side: BorderSide(color: warna ?? const Color(0xFFB3563F)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: Text(t, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
        );

    if (_role == 'user' && p.status == StatusSketsa.menungguPembayaran) {
      final habis = p.batasBayar != null && p.batasBayar!.isBefore(_sekarang);
      isi = Row(children: [
        Expanded(flex: 4, child: samping('Batalkan', () => _batalkan(p, oleh: 'user'))),
        const SizedBox(width: 10),
        Expanded(
            flex: 6,
            child: utama('Kirim Bukti', habis ? null : () => _kirimBukti(p))),
      ]);
    } else if (_role == 'user' && p.status == StatusSketsa.menungguVerifikasi) {
      isi = samping('Batalkan pesanan', () => _batalkan(p, oleh: 'user'));
    } else if (_role == 'arsitek' && p.status == StatusSketsa.dikerjakan) {
      isi = utama('Kirim Sketsa ke Klien', _pdf == null ? null : () => _kirimHasil(p));
    } else if (_role == 'admin' && p.status == StatusSketsa.menungguVerifikasi) {
      isi = Column(mainAxisSize: MainAxisSize.min, children: [
        utama('Setujui Pembayaran', () => _setujui(p)),
        const SizedBox(height: 8),
        Row(children: [
          Expanded(child: samping('Minta unggah ulang', () => _ulang(p), warna: AppColors.primary)),
          const SizedBox(width: 10),
          Expanded(child: samping('Tolak', () => _tolak(p))),
        ]),
      ]);
    }
    if (isi == null) return null;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: isi,
    );
  }
}
