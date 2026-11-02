import 'package:flutter/material.dart';
import '../../data/perumahan_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/gambar_proyek.dart';
import '../../widgets/lencana_status.dart';
import 'perumahan_detail_screen.dart';
import 'pesanan_rumah_screen.dart';

/// Tab Perumahan: cari dan saring per kota, buka detail.
class PerumahanTab extends StatefulWidget {
  const PerumahanTab({super.key});

  @override
  State<PerumahanTab> createState() => _PerumahanTabState();
}

class _PerumahanTabState extends State<PerumahanTab> {
  String _kota = 'Semua';
  String _cari = '';

  List<Perumahan> get _hasil {
    final q = _cari.trim().toLowerCase();
    return DataPerumahan.semua.where((p) {
      if (_kota != 'Semua' && p.kota != _kota) return false;
      if (q.isEmpty) return true;
      return p.nama.toLowerCase().contains(q) ||
          p.kota.toLowerCase().contains(q) ||
          p.alamat.toLowerCase().contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil;
    final kotaList = DataPerumahan.semua.map((p) => p.kota).toSet().toList();
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Perumahan',
                          style: AppTheme.heading(28)
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 4),
                      const Text('Temukan rumah impianmu dan amankan unitnya dengan booking fee.',
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Pesanan rumah saya',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PesananRumahScreen())),
                  icon: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.primary),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _cari = v),
              decoration: const InputDecoration(
                hintText: 'Cari perumahan atau kota',
                prefixIcon: Icon(Icons.search),
              ),
            ),
          ),
          SizedBox(
            height: 38,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                for (final k in ['Semua', ...kotaList]) ...[
                  ChipPilihan(k,
                      terpilih: _kota == k,
                      onTap: () => setState(() => _kota = k)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text('${hasil.length} perumahan ditemukan',
                style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: hasil.isEmpty
                ? const Center(
                    child: Text('Tidak ada perumahan yang cocok.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: hasil.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemBuilder: (_, i) => _KartuPerumahan(p: hasil[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KartuPerumahan extends StatelessWidget {
  final Perumahan p;
  const _KartuPerumahan({required this.p});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => PerumahanDetailScreen(perumahan: p))),
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(children: [
              SizedBox(
                height: 170,
                width: double.infinity,
                child: GambarProyek(p.foto.first, cacheWidth: 800),
              ),
              Positioned(
                left: 12,
                top: 12,
                child: LencanaStatus('${p.totalSisa} unit tersedia',
                    latar: AppColors.surface, huruf: AppColors.primary),
              ),
            ]),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(p.nama, style: AppTheme.heading(20)),
                  const SizedBox(height: 4),
                  Row(children: [
                    const Icon(Icons.place_outlined,
                        size: 15, color: AppColors.textMuted),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(p.alamat,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Mulai ${formatRupiah(p.hargaMulai)}',
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: AppColors.primary)),
                      Text('${p.tipe.length} tipe',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
