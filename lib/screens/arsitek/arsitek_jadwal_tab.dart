import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import '../../config/tahap.dart';
import '../../models/ketersediaan.dart';
import '../../models/pengaturan.dart';
import '../../services/ketersediaan_service.dart';
import '../../services/pengaturan_service.dart';
import '../../theme/app_theme.dart';

/// Tab "Jadwal" arsitek: hari kerja, jam praktik, dan tanggal cuti.
/// Berlaku untuk booking BARU; sesi yang sudah dikonfirmasi tidak berubah.
class ArsitekJadwalTab extends StatefulWidget {
  const ArsitekJadwalTab({super.key});

  @override
  State<ArsitekJadwalTab> createState() => _ArsitekJadwalTabState();
}

class _ArsitekJadwalTabState extends State<ArsitekJadwalTab> {
  static const _namaHari = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];

  Pengaturan _p = Pengaturan.bawaan;
  bool _siap = false;
  Set<int>? _hari; // draf lokal (null = belum diisi dari Firestore)
  Set<String>? _slot;
  bool _menyimpan = false;
  Ketersediaan? _tersimpan;

  @override
  void initState() {
    super.initState();
    PengaturanService.ambil().then((p) {
      if (!mounted) return;
      setState(() {
        _p = p;
        _siap = true;
      });
    });
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  bool get _berubah =>
      _tersimpan != null &&
          _hari != null &&
          _slot != null &&
          (!_samaSet(_hari!, _tersimpan!.hariKerja.toSet()) ||
              !_samaSet(_slot!, _tersimpan!.slotJam.toSet()));

  bool _samaSet<T>(Set<T> a, Set<T> b) =>
      a.length == b.length && a.containsAll(b);

  Future<void> _simpan() async {
    setState(() => _menyimpan = true);
    try {
      await KetersediaanService.simpanJadwal(
        hariKerja: _hari!.toList()..sort(),
        slotJam: _p.slotJam.where(_slot!.contains).toList(),
      );
      _pesan('Jadwal tersimpan. Berlaku untuk booking baru.');
    } catch (e) {
      _pesan('Gagal menyimpan: $e');
    }
    if (mounted) setState(() => _menyimpan = false);
  }

  Future<void> _tambahCuti() async {
    final besok = DateTime.now().add(const Duration(days: 1));
    final d = await showDatePicker(
      context: context,
      initialDate: besok,
      firstDate: besok,
      lastDate: DateTime.now().add(const Duration(days: 180)),
      helpText: 'Pilih tanggal cuti',
    );
    if (d == null) return;
    try {
      final pesan = await KetersediaanService.tambahCuti(d);
      if (pesan != null) _pesan(pesan);
    } catch (e) {
      _pesan('Gagal menambah cuti: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: !_siap
          ? const Center(child: CircularProgressIndicator())
          : StreamBuilder<Ketersediaan>(
        stream: KetersediaanService.saya(_p),
        builder: (context, snap) {
          if (snap.hasError) {
            return Center(
                child: Text('Tidak bisa memuat jadwal: ${snap.error}'));
          }
          final kt = snap.data;
          if (kt == null) {
            return const Center(child: CircularProgressIndicator());
          }
          _tersimpan = kt;
          _hari ??= kt.hariKerja.toSet();
          _slot ??= kt.slotJam.toSet();
          final cuti = [...kt.cuti]..sort();
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            children: [
              HeaderFoto(
                  bulat: true,
                  child: SizedBox(
                      width: double.infinity,
                      child: Text('Ketersediaan', style: AppTheme.heading(28)))),
              const SizedBox(height: 2),
              const Text('Atur kapan klien bisa memesan sesi denganmu',
                  style: TextStyle(
                      fontSize: 12.5, color: AppColors.textMuted)),
              const SizedBox(height: 22),
              Text('Hari kerja', style: AppTheme.heading(16)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (var d = 1; d <= 7; d++) _chipHari(d),
              ]),
              const SizedBox(height: 4),
              const Text('Hari yang pudar ditutup oleh admin.',
                  style: TextStyle(
                      fontSize: 11.5, color: AppColors.textMuted)),
              const SizedBox(height: 22),
              Text('Jam praktik', style: AppTheme.heading(16)),
              const SizedBox(height: 10),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final s in _p.slotJam) _chipSlot(s),
              ]),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: (_berubah && !_menyimpan) ? _simpan : null,
                style: FilledButton.styleFrom(
                  minimumSize: const Size.fromHeight(48),
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _menyimpan
                    ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white))
                    : const Text('Simpan Jadwal',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
              const SizedBox(height: 26),
              Row(children: [
                Expanded(
                    child: Text('Cuti / libur',
                        style: AppTheme.heading(16))),
                TextButton.icon(
                  onPressed: _tambahCuti,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Tambah'),
                ),
              ]),
              if (cuti.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 4),
                  child: Text('Belum ada tanggal cuti.',
                      style: TextStyle(
                          fontSize: 13, color: AppColors.textMuted)),
                )
              else
                for (final c in cuti) _barisCuti(c),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.sageMuda,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Text(
                    'Perubahan hanya berlaku untuk booking baru. '
                        'Sesi yang sudah dikonfirmasi tidak berubah. '
                        'Untuk memindahkan atau membatalkannya, hubungi '
                        'admin.',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.primary)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _chipHari(int d) {
    final dibuka = _p.hariOperasional.contains(d);
    final pilih = _hari!.contains(d);
    return Opacity(
      opacity: dibuka ? 1 : 0.4,
      child: _chip(_namaHari[d - 1], pilih,
          dibuka ? () => setState(() => pilih ? _hari!.remove(d) : _hari!.add(d)) : null),
    );
  }

  Widget _chipSlot(String s) {
    final pilih = _slot!.contains(s);
    return _chip(s, pilih,
            () => setState(() => pilih ? _slot!.remove(s) : _slot!.add(s)));
  }

  Widget _chip(String label, bool aktif, VoidCallback? onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: aktif ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border:
          Border.all(color: aktif ? AppColors.primary : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 13,
                fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                color: aktif ? Colors.white : AppColors.textDark)),
      ),
    );
  }

  Widget _barisCuti(String kunci) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 6, 6, 6),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(children: [
          const Icon(Icons.beach_access_outlined,
              size: 18, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(tanggalLengkap(kunci),
                style: const TextStyle(
                    fontSize: 13.5, fontWeight: FontWeight.w600)),
          ),
          IconButton(
            tooltip: 'Hapus',
            icon: const Icon(Icons.close, size: 18),
            onPressed: () => KetersediaanService.hapusCuti(kunci),
          ),
        ]),
      ),
    );
  }
}