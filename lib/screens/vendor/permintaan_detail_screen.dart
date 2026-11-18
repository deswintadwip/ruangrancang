import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/app_info.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../models/permintaan_vendor.dart';
import '../../services/status_berubah.dart';
import '../../services/vendor_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lencana_status.dart';
import 'permintaan_vendor_screen.dart';

/// Detail satu permintaan vendor: ringkasan, timeline, catatan admin.
class PermintaanDetailScreen extends StatelessWidget {
  final String permintaanId;
  const PermintaanDetailScreen({super.key, required this.permintaanId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Detail Permintaan', style: AppTheme.heading(21)),
      ),
      body: StreamBuilder<PermintaanVendor?>(
        stream: VendorService.satu(permintaanId),
        builder: (context, snap) {
          if (snap.hasError) {
            return const Center(child: Text('Gagal memuat permintaan.'));
          }
          if (!snap.hasData) {
            return snap.connectionState == ConnectionState.active
                ? const Center(child: Text('Permintaan tidak ditemukan.'))
                : const Center(child: CircularProgressIndicator());
          }
          return _Isi(p: snap.data!);
        },
      ),
    );
  }
}

class _Isi extends StatefulWidget {
  final PermintaanVendor p;
  const _Isi({required this.p});

  @override
  State<_Isi> createState() => _IsiState();
}

class _IsiState extends State<_Isi> {
  bool _menyimpan = false;

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _chatAdmin() async {
    final p = widget.p;
    final uri = Uri.https('wa.me', '/${AppInfo.whatsapp}', {
      'text': 'Halo admin RuangRancang, saya mau menanyakan permintaan vendor '
          '"${p.jenisPekerjaan}" (#${p.id.substring(0, 6).toUpperCase()}).',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) _pesan('Tidak bisa membuka WhatsApp.');
  }

  Future<void> _selesai() async {
    final yakin = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text('Tandai selesai?', style: AppTheme.heading(18)),
        content: const Text(
            'Lakukan ini setelah kesepakatan dengan vendor tuntas. Permintaan yang sudah selesai tidak bisa dibuka lagi.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Belum')),
          TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Ya, selesai')),
        ],
      ),
    );
    if (yakin != true) return;
    setState(() => _menyimpan = true);
    try {
      await VendorService.tandaiSelesai(widget.p);
    } catch (e) {
      _pesan(e is StatusBerubah
          ? e.toString()
          : 'Gagal memperbarui status. Coba lagi.');
    }
    if (mounted) setState(() => _menyimpan = false);
  }

  Widget _kartu(Widget anak) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: anak,
      );

  Widget _chip(String t) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
            color: AppColors.background,
            borderRadius: BorderRadius.circular(14)),
        child: Text(t, style: const TextStyle(fontSize: 11.5)),
      );

  /// Satu baris timeline. [waktu] null = belum tercapai.
  Widget _langkah(String judul, DateTime? waktu, {required bool terakhir, String? ket}) {
    final tercapai = waktu != null;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(children: [
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: tercapai ? AppColors.primary : Colors.transparent,
                border: Border.all(
                    color: tercapai ? AppColors.primary : const Color(0xFFC9BFAA),
                    width: 2),
              ),
              child: tercapai
                  ? const Icon(Icons.check, size: 13, color: Colors.white)
                  : null,
            ),
            if (!terakhir)
              Expanded(
                child: Container(
                    width: 2,
                    color: tercapai ? AppColors.primary : const Color(0xFFC9BFAA)),
              ),
          ]),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: terakhir ? 0 : 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: tercapai ? AppColors.textDark : AppColors.textMuted)),
                  Text(tercapai ? _waktu(waktu) : (ket ?? ''),
                      style: const TextStyle(
                          fontSize: 11.5, color: AppColors.textMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  static const _bln = [
    'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
    'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
  ];
  String _waktu(DateTime? t) {
    if (t == null) return '';
    final j = t.hour.toString().padLeft(2, '0');
    final m = t.minute.toString().padLeft(2, '0');
    return '${t.day} ${_bln[t.month - 1]} $j.$m';
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.p;
    final (label, bg, fg) = gayaStatusVendor(p.status);
    final dihubungi = p.status == StatusPermintaanVendor.dihubungi;
    final selesai = p.status == StatusPermintaanVendor.selesai;
    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
            children: [
              _kartu(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(p.jenisPekerjaan,
                                style: const TextStyle(
                                    fontSize: 15, fontWeight: FontWeight.w600)),
                            Text(
                                'Diajukan ${waktuLalu(p.createdAt)} · #${p.id.substring(0, 6).toUpperCase()}',
                                style: const TextStyle(
                                    fontSize: 12, color: AppColors.textMuted)),
                          ],
                        ),
                      ),
                      LencanaStatus(label, latar: bg, huruf: fg),
                    ],
                  ),
                  const Divider(height: 24, color: AppColors.border),
                  Text(p.namaVendorTampil,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 10),
                  Text(p.deskripsi,
                      style: const TextStyle(fontSize: 12.5, height: 1.6)),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    if (p.kota.isNotEmpty) _chip(p.kota),
                    if (p.anggaran.isNotEmpty) _chip(p.anggaran),
                    if (p.rencanaMulai.isNotEmpty) _chip('Mulai ${p.rencanaMulai}'),
                  ]),
                ],
              )),
              const SizedBox(height: 14),
              _kartu(Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Perkembangan', style: AppTheme.heading(17)),
                  const SizedBox(height: 14),
                  _langkah('Permintaan diajukan', p.createdAt, terakhir: false),
                  _langkah('Diteruskan ke vendor', p.diteruskanAt,
                      terakhir: false, ket: 'Menunggu admin meninjau'),
                  _langkah('Vendor sudah menghubungimu', p.dihubungiAt,
                      terakhir: false, ket: 'Lewat WhatsApp'),
                  _langkah('Selesai', p.selesaiAt,
                      terakhir: true,
                      ket: 'Tandai selesai setelah kesepakatan tuntas'),
                ],
              )),
              if (p.catatanAdmin.trim().isNotEmpty) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                      color: const Color(0xFFF7EBD2),
                      borderRadius: BorderRadius.circular(16)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Catatan dari admin',
                          style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF6E4F0E))),
                      const SizedBox(height: 4),
                      Text(p.catatanAdmin,
                          style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.55,
                              color: Color(0xFF4A3A12))),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        if (!selesai)
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              ElevatedButton.icon(
                onPressed: _chatAdmin,
                icon: const Icon(Icons.chat_outlined, size: 20),
                label: const Text('Chat Admin di WhatsApp'),
              ),
              if (dihubungi) ...[
                const SizedBox(height: 8),
                OutlinedButton(
                  onPressed: _menyimpan ? null : _selesai,
                  style: OutlinedButton.styleFrom(
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Tandai Selesai',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary)),
                ),
              ],
            ]),
          ),
      ],
    );
  }
}
