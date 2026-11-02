import 'package:flutter/material.dart';
import '../../models/konsultasi.dart';
import '../../models/pengaturan.dart';
import '../../services/konsultasi_service.dart';
import '../../models/ketersediaan.dart';
import '../../services/ketersediaan_service.dart';
import '../../services/pengaturan_service.dart';
import '../../theme/app_theme.dart';

const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

String _kunci(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Pilih tanggal & jam baru untuk sesi yang sudah dikonfirmasi.
/// Gratis 1 kali, dan tidak bisa kurang dari 6 jam sebelum sesi.
class JadwalUlangScreen extends StatefulWidget {
  final Konsultasi konsultasi;
  const JadwalUlangScreen({super.key, required this.konsultasi});

  @override
  State<JadwalUlangScreen> createState() => _JadwalUlangScreenState();
}

class _JadwalUlangScreenState extends State<JadwalUlangScreen> {
  late final List<DateTime> _hari;
  DateTime? _tanggal;
  String? _slot;
  Pengaturan _p = Pengaturan.bawaan;
  Ketersediaan? _kt;
  bool _menyimpan = false;

  @override
  void initState() {
    super.initState();
    final mulai = DateTime.now().add(const Duration(days: 1)); // minimal H-1
    _hari = List.generate(
        14, (i) => DateTime(mulai.year, mulai.month, mulai.day + i));
    _muat();
  }

  Future<void> _muat() async {
    final p = await PengaturanService.ambil();
    final kt = await KetersediaanService.untuk(widget.konsultasi.arsitekId, p);
    if (!mounted) return;
    setState(() {
      _p = p;
      _kt = kt;
      _tanggal ??= _hari.firstWhere(_buka, orElse: () => _hari.first);
    });
  }

  bool _buka(DateTime d) => _kt != null
      ? _kt!.hariBuka(d)
      : _p.hariOperasional.contains(d.weekday);

  void _pesan(String teks) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(teks)));
  }

  Future<void> _simpan() async {
    final k = widget.konsultasi;
    if (_tanggal == null || _slot == null) {
      _pesan('Pilih tanggal dan jam baru dulu.');
      return;
    }
    final mulai = _slot!.split('-').first.trim();
    final selesai = _slot!.split('-').last.trim();
    if (_kunci(_tanggal!) == k.tanggal && mulai == k.jam) {
      _pesan('Itu jadwal yang sama dengan sebelumnya.');
      return;
    }
    setState(() => _menyimpan = true);
    try {
      await KonsultasiService.jadwalUlang(
        k,
        tanggalBaru: _kunci(_tanggal!),
        jamBaru: mulai,
        jamSelesaiBaru: selesai,
      );
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jadwal berhasil diubah.')),
      );
    } on JadwalTerisi {
      if (!mounted) return;
      setState(() {
        _menyimpan = false;
        _slot = null;
      });
      _pesan('Jam itu baru saja dipesan orang lain. Pilih jam lain.');
    } catch (_) {
      if (!mounted) return;
      setState(() => _menyimpan = false);
      _pesan('Gagal mengubah jadwal. Coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final k = widget.konsultasi;
    final bulan = _tanggal ?? _hari.first;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textDark),
        title: Text('Jadwal Ulang', style: AppTheme.heading(19)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
              children: [
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(k.arsitekNama,
                          style: const TextStyle(
                              fontSize: 14.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 4),
                      Text('Jadwal sekarang: ${k.tanggal} · ${k.jam} – ${k.jamSelesai}',
                          style: const TextStyle(
                              fontSize: 12.5, color: AppColors.textMuted)),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Jadwal ulang gratis 1 kali per konsultasi. Setelah ini '
                        'jadwal tidak bisa diubah lagi, hanya bisa dibatalkan.',
                    style: TextStyle(
                        fontSize: 12.5, height: 1.5, color: Color(0xFF8A3F0B)),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24),
                  child: Row(children: [
                    Expanded(
                        child: Text('Pilih Tanggal Baru',
                            style: AppTheme.heading(17))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                          '${_bulanPanjang[bulan.month - 1]} ${bulan.year}',
                          style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary)),
                    ),
                  ]),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 106,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _hari.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 10),
                    itemBuilder: (_, i) => _gelembung(_hari[i]),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 24, bottom: 12),
                  child: Text('Pilih Jam Baru', style: AppTheme.heading(17)),
                ),
                if (_tanggal != null)
                  StreamBuilder<Set<String>>(
                    stream: KonsultasiService.jamTerisi(
                        k.arsitekId, _kunci(_tanggal!)),
                    builder: (context, snap) {
                      final terisi = snap.data ?? <String>{};
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final s in (_kt?.slotJam ?? _p.slotJam))
                            _chipJam(
                                s, terisi.contains(s.split('-').first.trim())),
                        ],
                      );
                    },
                  ),
                const SizedBox(height: 10),
                const Text('Jam yang dicoret sudah dipesan.',
                    style:
                    TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: const BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: FilledButton(
              onPressed: (_menyimpan || _slot == null) ? null : _simpan,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(52),
                backgroundColor: AppColors.primary,
                disabledBackgroundColor: AppColors.border,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _menyimpan
                  ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                      strokeWidth: 2.5, color: Colors.white))
                  : const Text('Simpan Jadwal Baru',
                  style:
                  TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _gelembung(DateTime d) {
    final buka = _buka(d);
    final dipilih = _tanggal != null && _kunci(_tanggal!) == _kunci(d);
    return Opacity(
      opacity: buka ? 1 : 0.45,
      child: GestureDetector(
        onTap: buka
            ? () => setState(() {
          _tanggal = d;
          _slot = null;
        })
            : null,
        child: Container(
          width: 62,
          decoration: BoxDecoration(
            color: dipilih ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
                color: dipilih ? AppColors.primary : AppColors.border),
            boxShadow: dipilih
                ? [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_hariPendek[d.weekday - 1],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dipilih ? Colors.white70 : AppColors.textMuted)),
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: dipilih ? Colors.white : AppColors.background,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('${d.day}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color:
                        dipilih ? AppColors.primary : AppColors.textDark)),
              ),
              Text(buka ? _bulanPendek[d.month - 1] : 'Libur',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: dipilih ? Colors.white70 : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipJam(String slot, bool terisi) {
    final dipilih = _slot == slot;
    final tampil = slot.split('-').map((e) => e.trim()).join(' – ');
    return GestureDetector(
      onTap: terisi ? null : () => setState(() => _slot = slot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: dipilih
              ? AppColors.primary
              : (terisi
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.surface),
          borderRadius: BorderRadius.circular(26),
          border:
          Border.all(color: dipilih ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          tampil,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: dipilih
                ? Colors.white
                : (terisi ? AppColors.textMuted : AppColors.textDark),
            decoration: terisi ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }
}