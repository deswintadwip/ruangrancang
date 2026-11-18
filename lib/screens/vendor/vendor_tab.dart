import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import '../../data/vendor_data.dart';
import '../../theme/app_theme.dart';
import '../../widgets/lencana_status.dart';
import 'permintaan_vendor_screen.dart';
import 'vendor_detail_screen.dart';

/// Tab Vendor Konstruksi: cari, saring per kategori, buka detail.
class VendorTab extends StatefulWidget {
  const VendorTab({super.key});

  @override
  State<VendorTab> createState() => _VendorTabState();
}

class _VendorTabState extends State<VendorTab> {
  String _kategori = 'Semua';
  String _cari = '';

  List<Vendor> get _hasil {
    final q = _cari.trim().toLowerCase();
    final list = DataVendor.semua.where((v) {
      if (_kategori != 'Semua' && v.jenis != _kategori) return false;
      if (q.isEmpty) return true;
      return v.nama.toLowerCase().contains(q) ||
          v.jenisLengkap.toLowerCase().contains(q) ||
          v.kota.toLowerCase().contains(q) ||
          v.layanan.any((l) => l.toLowerCase().contains(q));
    }).toList();
    list.sort((a, b) => b.rating.compareTo(a.rating));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    final hasil = _hasil;
    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          HeaderFoto(child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 12, 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Vendor Konstruksi',
                          style: AppTheme.heading(28)
                              .copyWith(color: AppColors.primary)),
                      const SizedBox(height: 4),
                      const Text(
                          'Kontraktor dan tukang terkurasi untuk mewujudkan desainmu.',
                          style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: AppColors.textMuted)),
                    ],
                  ),
                ),
                IconButton(
                  tooltip: 'Permintaan vendor saya',
                  onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const PermintaanVendorScreen())),
                  icon: const Icon(Icons.receipt_long_outlined,
                      color: AppColors.primary),
                ),
              ],
            ),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
            child: TextField(
              onChanged: (v) => setState(() => _cari = v),
              decoration: const InputDecoration(
                hintText: 'Cari vendor, jenis pekerjaan, atau kota',
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
                for (final k in ['Semua', ...DataVendor.kategori]) ...[
                  ChipPilihan(k,
                      terpilih: _kategori == k,
                      onTap: () => setState(() => _kategori = k)),
                  const SizedBox(width: 8),
                ],
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
            child: Text('${hasil.length} vendor ditemukan',
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textMuted)),
          ),
          Expanded(
            child: hasil.isEmpty
                ? const Center(
                    child: Text('Tidak ada vendor yang cocok.',
                        style: TextStyle(color: AppColors.textMuted)))
                : ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    itemCount: hasil.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, i) => _KartuVendor(v: hasil[i]),
                  ),
          ),
        ],
      ),
    );
  }
}

class _KartuVendor extends StatelessWidget {
  final Vendor v;
  const _KartuVendor({required this.v});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => VendorDetailScreen(vendor: v))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          children: [
            AvatarVendor(v: v, ukuran: 64),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(v.nama,
                      style: const TextStyle(
                          fontSize: 14.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text('${v.jenisLengkap} · ${v.kota}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                  const SizedBox(height: 6),
                  Row(children: [
                    const Icon(Icons.star_rounded,
                        size: 16, color: AppColors.coklatMuda),
                    const SizedBox(width: 3),
                    Text(v.rating.toString().replaceAll('.', ','),
                        style: const TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w600)),
                    const SizedBox(width: 10),
                    Text('${v.proyek} proyek',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                  ]),
                  const SizedBox(height: 4),
                  Text(v.harga,
                      style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.primary)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Kotak berinisial berwarna (pengganti logo vendor).
class AvatarVendor extends StatelessWidget {
  final Vendor v;
  final double ukuran;
  const AvatarVendor({super.key, required this.v, required this.ukuran});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ukuran,
      height: ukuran,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: v.warna,
        borderRadius: BorderRadius.circular(ukuran * 0.25),
      ),
      child: Text(v.inisial,
          style: AppTheme.heading(ukuran * 0.38).copyWith(
              color: AppColors.surface, fontWeight: FontWeight.w700)),
    );
  }
}
