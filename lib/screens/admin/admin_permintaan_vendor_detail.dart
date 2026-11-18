import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../data/vendor_data.dart';
import '../../models/permintaan_vendor.dart';
import '../../services/admin_vendor_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lencana_status.dart';
import '../vendor/permintaan_vendor_screen.dart' show gayaStatusVendor;
import 'admin_util.dart';

/// Detail permintaan vendor: pilih vendor, teruskan, lalu tandai kemajuannya.
class AdminPermintaanVendorDetail extends StatefulWidget {
  final String permintaanId;
  const AdminPermintaanVendorDetail({super.key, required this.permintaanId});

  @override
  State<AdminPermintaanVendorDetail> createState() =>
      _AdminPermintaanVendorDetailState();
}

class _AdminPermintaanVendorDetailState
    extends State<AdminPermintaanVendorDetail> {
  late final Stream<PermintaanVendor?> _stream;
  final _catatan = TextEditingController();
  String? _vendorId; // pilihan admin
  bool _awal = true;
  bool _sibuk = false;

  @override
  void initState() {
    super.initState();
    _stream = AdminVendorService.satu(widget.permintaanId);
  }

  @override
  void dispose() {
    _catatan.dispose();
    super.dispose();
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _jalankan(Future<void> Function() aksi, String sukses) async {
    setState(() => _sibuk = true);
    try {
      await aksi();
      if (mounted) _pesan(sukses);
    } catch (e) {
      debugPrint('ADMIN VENDOR ERROR: $e');
      if (mounted) _pesan('Gagal: $e');
    }
    if (mounted) setState(() => _sibuk = false);
  }

  /// Ringkasan siap tempel untuk dikirim ke PIC vendor.
  String _ringkasan(PermintaanVendor p) {
    final b = StringBuffer()
      ..writeln('Permintaan klien RuangRancang')
      ..writeln('Nama: ${p.userNama}')
      ..writeln('WhatsApp: ${p.userWa.isEmpty ? '-' : '+${p.userWa}'}')
      ..writeln('Pekerjaan: ${p.jenisPekerjaan}')
      ..writeln('Lokasi: ${p.kota.isEmpty ? '-' : p.kota}')
      ..writeln('Anggaran: ${p.anggaran.isEmpty ? '-' : p.anggaran}')
      ..writeln('Rencana mulai: ${p.rencanaMulai.isEmpty ? '-' : p.rencanaMulai}');
    if (p.deskripsi.isNotEmpty) b.writeln('Kebutuhan: ${p.deskripsi}');
    if (p.linkDesain.isNotEmpty) b.writeln('Desain: ${p.linkDesain}');
    return b.toString().trim();
  }

  Future<void> _salin(PermintaanVendor p) async {
    await Clipboard.setData(ClipboardData(text: _ringkasan(p)));
    if (mounted) _pesan('Ringkasan disalin. Tempel ke WhatsApp PIC vendor.');
  }

  Future<void> _teruskan(PermintaanVendor p) async {
    final v = DataVendor.byId(_vendorId);
    if (v == null) return _pesan('Pilih vendor dulu.');
    final ya = await konfirmasi(context,
        judul: 'Teruskan ke ${v.nama}?',
        isi: 'Klien akan mendapat notifikasi. Jangan lupa kirim ringkasan ke PIC vendor.',
        tombol: 'Teruskan');
    if (!ya) return;
    await _jalankan(
        () => AdminVendorService.teruskan(p, v, _catatan.text.trim()),
        'Diteruskan ke ${v.nama}.');
  }

  Future<void> _dihubungi(PermintaanVendor p) async {
    final ya = await konfirmasi(context,
        judul: 'Vendor sudah menghubungi klien?',
        isi: 'Status berubah menjadi Dihubungi dan klien diberi tahu.',
        tombol: 'Ya, tandai');
    if (!ya) return;
    await _jalankan(() => AdminVendorService.tandaiDihubungi(p), 'Ditandai dihubungi.');
  }

  Future<void> _selesai(PermintaanVendor p) async {
    final ya = await konfirmasi(context,
        judul: 'Tutup permintaan?',
        isi: 'Status berubah menjadi Selesai dan tidak bisa diubah lagi.',
        tombol: 'Tandai selesai');
    if (!ya) return;
    await _jalankan(() => AdminVendorService.tandaiSelesai(p), 'Permintaan selesai.');
  }

  Widget _tombol(String teks, VoidCallback onTap, {bool utama = false}) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: utama
            ? FilledButton(
                onPressed: _sibuk ? null : onTap,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(teks, style: const TextStyle(fontWeight: FontWeight.w600)),
              )
            : OutlinedButton(
                onPressed: _sibuk ? null : onTap,
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: Text(teks,
                    style: const TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Permintaan Vendor', style: AppTheme.heading(20)),
      ),
      body: StreamBuilder<PermintaanVendor?>(
        stream: _stream,
        builder: (context, snap) {
          if (snap.hasError) return const Center(child: Text('Gagal memuat data.'));
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final p = snap.data;
          if (p == null) return const Center(child: Text('Permintaan tidak ditemukan.'));
          if (_awal) {
            _awal = false;
            _vendorId = p.vendorId.isNotEmpty
                ? p.vendorId
                : (p.vendorDipilih.isNotEmpty ? p.vendorDipilih : null);
            _catatan.text = p.catatanAdmin;
          }
          return _isi(p);
        },
      ),
    );
  }

  Widget _isi(PermintaanVendor p) {
    final (label, bg, fg) = gayaStatusVendor(p.status);
    final baru = p.status == StatusPermintaanVendor.baru;
    // Usulan klien tampil paling atas.
    final vendors = [...DataVendor.semua]..sort((a, b) {
        int skor(Vendor v) =>
            (v.id == p.vendorDipilih ? 2 : 0) + (v.kota == p.kota ? 1 : 0);
        return skor(b).compareTo(skor(a));
      });
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
              Text('Masuk ${waktuLalu(p.createdAt)} · #${p.id.substring(0, 6).toUpperCase()}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              const Divider(height: 22),
              barisInfo('Pekerjaan', p.jenisPekerjaan),
              barisInfo('Lokasi', p.kota.isEmpty ? '-' : p.kota),
              barisInfo('Anggaran', p.anggaran.isEmpty ? '-' : p.anggaran),
              barisInfo('Rencana mulai', p.rencanaMulai.isEmpty ? '-' : p.rencanaMulai),
              if (p.vendorNamaDipilih.isNotEmpty)
                barisInfo('Usulan klien', p.vendorNamaDipilih),
              if (p.deskripsi.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(p.deskripsi, style: const TextStyle(fontSize: 12.5, height: 1.55)),
              ],
              if (p.linkDesain.isNotEmpty) ...[
                const SizedBox(height: 6),
                SelectableText('Desain: ${p.linkDesain}',
                    style: const TextStyle(fontSize: 12.5, color: AppColors.primary)),
              ],
              const SizedBox(height: 10),
              Row(children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _salin(p),
                    icon: const Icon(Icons.copy_outlined, size: 18),
                    label: const Text('Salin ringkasan'),
                  ),
                ),
              ]),
            ],
          ),
        ),

        if (baru)
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Pilih vendor', style: AppTheme.heading(16)),
                const SizedBox(height: 4),
                const Text('Vendor usulan klien dan yang sekota ada di atas.',
                    style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                for (final v in vendors)
                  InkWell(
                    borderRadius: BorderRadius.circular(14),
                    onTap: () => setState(() => _vendorId = v.id),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _vendorId == v.id ? AppColors.sageMuda : AppColors.background,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: _vendorId == v.id ? AppColors.primary : AppColors.border,
                            width: _vendorId == v.id ? 2 : 1),
                      ),
                      child: Row(children: [
                        Icon(
                            _vendorId == v.id
                                ? Icons.radio_button_checked
                                : Icons.radio_button_off,
                            color: AppColors.primary,
                            size: 22),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(v.nama,
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600)),
                              Text('${v.jenis} · ${v.kota}${v.id == p.vendorDipilih ? ' · usulan klien' : ''}',
                                  style: const TextStyle(
                                      fontSize: 11.5, color: AppColors.textMuted)),
                            ],
                          ),
                        ),
                        Text(v.rating.toStringAsFixed(1),
                            style: const TextStyle(
                                fontSize: 11.5, color: AppColors.textMuted)),
                      ]),
                    ),
                  ),
                const SizedBox(height: 4),
                const Text('Catatan untuk klien (tampil di halaman status)',
                    style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                const SizedBox(height: 6),
                TextField(
                  controller: _catatan,
                  minLines: 2,
                  maxLines: 4,
                  maxLength: 200,
                  decoration: const InputDecoration(
                      hintText: 'Contoh: vendor akan survei lokasi dulu'),
                ),
                _tombol('Teruskan ke vendor', () => _teruskan(p), utama: true),
              ],
            ),
          )
        else
          KartuAdmin(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Vendor', style: AppTheme.heading(16)),
                const SizedBox(height: 6),
                barisInfo('Diteruskan ke', p.vendorNama.isEmpty ? '-' : p.vendorNama, tebal: true),
                if (p.catatanAdmin.isNotEmpty) barisInfo('Catatan', p.catatanAdmin),
                if (p.status == StatusPermintaanVendor.diteruskan) ...[
                  const SizedBox(height: 6),
                  const Text(
                      'Kirim ringkasan ke PIC vendor, lalu tandai Dihubungi setelah vendor mengabari.',
                      style: TextStyle(fontSize: 12, height: 1.5, color: AppColors.textMuted)),
                  _tombol('Tandai dihubungi', () => _dihubungi(p), utama: true),
                ],
                if (p.status == StatusPermintaanVendor.dihubungi)
                  _tombol('Tandai selesai', () => _selesai(p), utama: true),
                if (p.status == StatusPermintaanVendor.diteruskan)
                  _tombol('Tutup tanpa menunggu (selesai)', () => _selesai(p)),
              ],
            ),
          ),
      ],
    );
  }
}
