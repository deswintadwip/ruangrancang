import 'dart:math';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/perumahan_data.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/gambar_proyek.dart';

/// Detail perumahan lengkap: foto, pilihan tipe, spesifikasi teknis unit, denah,
/// fasilitas, peta lokasi, estimasi cicilan KPR, benefit cash, promo, dan WA marketing.
class PerumahanDetailScreen extends StatefulWidget {
  final Perumahan perumahan;
  const PerumahanDetailScreen({super.key, required this.perumahan});

  @override
  State<PerumahanDetailScreen> createState() => _PerumahanDetailScreenState();
}

class _PerumahanDetailScreenState extends State<PerumahanDetailScreen> {
  int _foto = 0;
  int _tipe = 0;
  int _tenorTahun = 20;

  Widget _judul(String t) => Padding(
    padding: const EdgeInsets.only(top: 22, bottom: 10),
    child: Text(t, style: AppTheme.heading(18)),
  );

  // Hitung estimasi cicilan KPR (DP 10%, asumsi bunga 6.5% / tahun)
  int _hitungCicilanBulanan(num harga) {
    final double hargaDouble = harga.toDouble();
    final double dp = hargaDouble * 0.10;
    final double pokok = hargaDouble - dp;
    if (pokok <= 0) return 0;

    const double bungaBulanan = 0.065 / 12;
    final int totalBulan = _tenorTahun * 12;
    final double faktor = pow(1 + bungaBulanan, totalBulan).toDouble();
    return ((pokok * bungaBulanan * faktor) / (faktor - 1)).round();
  }

  Map<String, dynamic> _getDetailEkstra(Perumahan p, TipeRumah t) {
    final bool isDuaLantai = t.luasBangunan >= 50;
    return {
      'lantai': isDuaLantai ? '2 Lantai' : '1 Lantai',
      'carport': isDuaLantai ? '2 Mobil' : '1 Mobil',
      'listrik': isDuaLantai ? '2.200 Watt' : '1.300 Watt',
      'sertifikat': 'SHM (Sertifikat Hak Milik)',
      'sumberAir': 'PDAM / Sumur Bor',
      'denahUrl':
      'https://images.unsplash.com/photo-1600566753376-12c8ab7fb75b?auto=format&fit=crop&w=900&q=80',
      'nomorWa': '6281234567890', // Ganti dengan nomor WA marketing resmi
      'benefitCash': [
        'Potongan harga langsung / Cashback hingga Rp25.000.000',
        'Gratis biaya legalitas lengkap (AJB, BBN, dan BPHTB)',
        'Prioritas pilih posisi kavling strategis (Hook / Dekat Taman)',
      ],
      'promoMenarik':
      'Promo Bulan Ini: Booking Fee cukup Rp5 Juta langsung kunci unit! Gratis Canopy, Smart Door Lock, & Bebas Biaya Proses KPR (Kuota Terbatas).',
    };
  }

  Future<void> _bukaGoogleMaps(Perumahan p) async {
    final String query = Uri.encodeComponent('${p.nama}, ${p.alamat}');
    final Uri mapsUrl =
    Uri.parse('https://www.google.com/maps/search/?api=1&query=$query');

    if (!await launchUrl(mapsUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Tidak dapat membuka Google Maps.')),
        );
      }
    }
  }

  Future<void> _hubungiMarketingWA(
      Perumahan p, TipeRumah t, String nomorWa) async {
    final int cicilan = _hitungCicilanBulanan(t.harga);
    final String pesan = 'Halo Kak Marketing ${p.nama},\n\n'
        'Saya melihat informasi perumahan di aplikasi RuangRancang dan tertarik dengan unit:\n'
        '• Perumahan: *${p.nama}*\n'
        '• Tipe: *${t.nama}* (LB ${t.luasBangunan}m² / LT ${t.luasTanah}m², ${t.kamarTidur} KT, ${t.kamarMandi} KM)\n'
        '• Harga Unit: *${formatRupiah(t.harga)}*\n'
        '• Simulasi KPR: Tenor $_tenorTahun Tahun (Est. ${formatRupiah(cicilan)}/bln)\n\n'
        'Saya ingin menanyakan detail promo, rincian pembayaran, dan jadwal survei lokasi. Terima kasih.';

    final Uri waUrl = Uri.parse(
      'https://wa.me/$nomorWa?text=${Uri.encodeComponent(pesan)}',
    );

    if (!await launchUrl(waUrl, mode: LaunchMode.externalApplication)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
                'Tidak dapat membuka WhatsApp. Pastikan aplikasi WhatsApp terpasang.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.perumahan;
    final t = p.tipe[_tipe];
    final ekstra = _getDetailEkstra(p, t);
    final int estimasiCicilan = _hitungCicilanBulanan(t.harga);
    final int estimasiDp = (t.harga * 0.10).round();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
              children: [
                // 1. GALERI FOTO UTAMA
                Stack(children: [
                  SizedBox(
                    height: 260,
                    child: PageView.builder(
                      itemCount: p.foto.length,
                      onPageChanged: (i) => setState(() => _foto = i),
                      itemBuilder: (_, i) => GambarProyek(p.foto[i],
                          width: double.infinity, cacheWidth: 900),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: CircleAvatar(
                        backgroundColor: AppColors.surface,
                        child: IconButton(
                          tooltip: 'Kembali',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.arrow_back,
                              color: AppColors.textDark),
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 12,
                    left: 0,
                    right: 0,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (var i = 0; i < p.foto.length; i++)
                          Container(
                            width: i == _foto ? 18 : 7,
                            height: 7,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              color: i == _foto
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.55),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                      ],
                    ),
                  ),
                ]),

                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 2. HEADER NAMA, ALAMAT & DESKRIPSI
                      Text(p.nama, style: AppTheme.heading(26)),
                      const SizedBox(height: 4),
                      Row(children: [
                        const Icon(Icons.place_outlined,
                            size: 16, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(p.alamat,
                              style: const TextStyle(
                                  fontSize: 12.5, color: AppColors.textMuted)),
                        ),
                      ]),
                      const SizedBox(height: 4),
                      Text('Pengembang: ${p.pengembang}',
                          style: const TextStyle(
                              fontSize: 12, color: AppColors.textMuted)),

                      _judul('Tentang'),
                      Text(p.deskripsi,
                          style: const TextStyle(fontSize: 13, height: 1.65)),
                      const SizedBox(height: 6),
                      Text('Serah terima: ${p.serahTerima}',
                          style: const TextStyle(
                              fontSize: 12.5, fontWeight: FontWeight.w500)),

                      // 3. PILIH TIPE RUMAH
                      _judul('Pilih tipe rumah'),
                      for (var i = 0; i < p.tipe.length; i++) ...[
                        _KartuTipe(
                          tipe: p.tipe[i],
                          terpilih: i == _tipe,
                          onTap: () => setState(() => _tipe = i),
                        ),
                        const SizedBox(height: 10),
                      ],

                      // 4. SPESIFIKASI DETAIL UNIT (DINAMIS SESUAI TIPE)
                      _judul('Spesifikasi Detail (${t.nama})'),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Expanded(
                                    child: _itemSpec(Icons.square_foot,
                                        'Luas Tanah', '${t.luasTanah} m²')),
                                Expanded(
                                    child: _itemSpec(Icons.home_work_outlined,
                                        'Luas Bangunan', '${t.luasBangunan} m²')),
                              ],
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            Row(
                              children: [
                                Expanded(
                                    child: _itemSpec(Icons.bed_outlined,
                                        'Kamar Tidur', '${t.kamarTidur} Kamar')),
                                Expanded(
                                    child: _itemSpec(Icons.bathtub_outlined,
                                        'Kamar Mandi', '${t.kamarMandi} Kamar')),
                              ],
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            Row(
                              children: [
                                Expanded(
                                    child: _itemSpec(Icons.layers_outlined,
                                        'Jumlah Lantai', ekstra['lantai'])),
                                Expanded(
                                    child: _itemSpec(
                                        Icons.directions_car_outlined,
                                        'Carport',
                                        ekstra['carport'])),
                              ],
                            ),
                            const Divider(height: 20, color: AppColors.border),
                            Row(
                              children: [
                                Expanded(
                                    child: _itemSpec(Icons.bolt_outlined,
                                        'Daya Listrik', ekstra['listrik'])),
                                Expanded(
                                    child: _itemSpec(Icons.verified_outlined,
                                        'Legalitas', ekstra['sertifikat'])),
                              ],
                            ),
                          ],
                        ),
                      ),

                      // 5. GAMBAR DENAH RUMAH
                      _judul('Denah Rumah (${t.nama})'),
                      Container(
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(15)),
                              child: Image.network(
                                ekstra['denahUrl'],
                                height: 185,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 185,
                                  color: AppColors.sageMuda,
                                  child: const Center(
                                    child: Text('Ilustrasi Denah Ruangan',
                                        style: TextStyle(
                                            color: AppColors.primary,
                                            fontSize: 12.5)),
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(12),
                              child: Text(
                                'Tata ruang ${t.nama}: ${t.kamarTidur} Kamar Tidur, ${t.kamarMandi} Kamar Mandi, Ruang Tamu & Keluarga, Dapur, Taman, dan ${ekstra['carport']}.',
                                style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textMuted,
                                    height: 1.5),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 6. FASILITAS
                      _judul('Fasilitas'),
                      Wrap(spacing: 8, runSpacing: 8, children: [
                        for (final f in p.fasilitas)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 7),
                            decoration: BoxDecoration(
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Text(f, style: const TextStyle(fontSize: 12.5)),
                          ),
                      ]),

                      // 7. PETA & ALAMAT LOKASI
                      _judul('Lokasi & Peta Perumahan'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(Icons.location_on_outlined,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    p.alamat,
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                        height: 1.45),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              child: OutlinedButton.icon(
                                onPressed: () => _bukaGoogleMaps(p),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: AppColors.primary,
                                  side: const BorderSide(
                                      color: AppColors.primary),
                                  padding:
                                  const EdgeInsets.symmetric(vertical: 11),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                                icon: const Icon(Icons.map_outlined, size: 18),
                                label: const Text(
                                  'Buka Peta di Google Maps',
                                  style: TextStyle(
                                      fontSize: 12.5,
                                      fontWeight: FontWeight.w600),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // 8. ESTIMASI HARGA CICILAN KPR
                      _judul('Estimasi Cicilan KPR'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Pilih Tenor KPR:',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600)),
                                Text('Est. DP 10%: ${formatRupiah(estimasiDp)}',
                                    style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textMuted)),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [10, 15, 20].map((tahun) {
                                final bool aktif = _tenorTahun == tahun;
                                return Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    child: InkWell(
                                      onTap: () =>
                                          setState(() => _tenorTahun = tahun),
                                      borderRadius: BorderRadius.circular(10),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(
                                            vertical: 8),
                                        decoration: BoxDecoration(
                                          color: aktif
                                              ? AppColors.primary
                                              : AppColors.background,
                                          borderRadius:
                                          BorderRadius.circular(10),
                                          border: Border.all(
                                              color: aktif
                                                  ? AppColors.primary
                                                  : AppColors.border),
                                        ),
                                        child: Center(
                                          child: Text(
                                            '$tahun Tahun',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: aktif
                                                  ? Colors.white
                                                  : AppColors.textDark,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                            const Divider(height: 22, color: AppColors.border),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text('Estimasi Angsuran / Bulan',
                                    style: TextStyle(
                                        fontSize: 12.5,
                                        color: AppColors.textMuted)),
                                Text(
                                  formatRupiah(estimasiCicilan),
                                  style: AppTheme.heading(17)
                                      .copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              '*Simulasi perhitungan awal (suku bunga est. 6.5%). Rincian resmi dibantu marketing.',
                              style: TextStyle(
                                  fontSize: 11, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),

                      // 9. BENEFIT BAYAR CASH
                      _judul('Benefit Pembayaran Cash'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Column(
                          children: [
                            for (final benefit
                            in (ekstra['benefitCash'] as List<String>))
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Icon(Icons.check_circle_outline,
                                        size: 17, color: AppColors.primary),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Text(
                                        benefit,
                                        style: const TextStyle(
                                            fontSize: 12.5, height: 1.45),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),

                      // 10. PROMO & PENAWARAN MENARIK
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppColors.sageMuda,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.25)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.local_offer_outlined,
                                    size: 18, color: AppColors.primary),
                                const SizedBox(width: 8),
                                Text(
                                  'Penawaran & Promo Spesial',
                                  style: AppTheme.heading(15)
                                      .copyWith(color: AppColors.primary),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text(
                              ekstra['promoMenarik'],
                              style: const TextStyle(
                                fontSize: 12.5,
                                height: 1.55,
                                color: AppColors.primary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // STICKY BOTTOM BAR: HUBUNGI MARKETING (WHATSAPP)
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: Row(children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(t.nama,
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.textMuted)),
                    Text(formatRupiah(t.harga),
                        style: AppTheme.heading(17)
                            .copyWith(color: AppColors.primary)),
                  ],
                ),
              ),
              SizedBox(
                width: 185,
                child: ElevatedButton.icon(
                  onPressed: t.sisaUnit == 0
                      ? null
                      : () => _hubungiMarketingWA(p, t, ekstra['nomorWa']),
                  icon: t.sisaUnit == 0
                      ? const SizedBox.shrink()
                      : const Icon(Icons.chat_outlined, size: 17),
                  label: Text(
                    t.sisaUnit == 0 ? 'Habis' : 'Hubungi Marketing',
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _itemSpec(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textMuted)),
              const SizedBox(height: 2),
              Text(value,
                  style: const TextStyle(
                      fontSize: 12.5, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _KartuTipe extends StatelessWidget {
  final TipeRumah tipe;
  final bool terpilih;
  final VoidCallback onTap;
  const _KartuTipe(
      {required this.tipe, required this.terpilih, required this.onTap});

  Widget _info(IconData i, String t) => Padding(
    padding: const EdgeInsets.only(right: 14),
    child: Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(i, size: 15, color: AppColors.textMuted),
      const SizedBox(width: 4),
      Text(t, style: const TextStyle(fontSize: 12)),
    ]),
  );

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: terpilih ? AppColors.sageMuda : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: terpilih ? AppColors.primary : AppColors.border,
              width: terpilih ? 2 : 1),
        ),
        child: Row(children: [
          Icon(terpilih ? Icons.radio_button_checked : Icons.radio_button_off,
              color: terpilih ? AppColors.primary : AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text(tipe.nama,
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.w600)),
                  const Spacer(),
                  Text(
                      tipe.sisaUnit == 0
                          ? 'Habis'
                          : 'Sisa ${tipe.sisaUnit} unit',
                      style: TextStyle(
                          fontSize: 11.5,
                          color: tipe.sisaUnit <= 3
                              ? AppColors.terakota
                              : AppColors.textMuted)),
                ]),
                const SizedBox(height: 6),
                Row(children: [
                  _info(Icons.bed_outlined, '${tipe.kamarTidur} KT'),
                  _info(Icons.bathtub_outlined, '${tipe.kamarMandi} KM'),
                  _info(Icons.square_foot,
                      '${tipe.luasBangunan}/${tipe.luasTanah} m²'),
                ]),
                const SizedBox(height: 6),
                Text(formatRupiah(tipe.harga),
                    style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ],
            ),
          ),
        ]),
      ),
    );
  }
}