import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import 'permintaan_vendor_screen.dart';

/// Layar sukses setelah permintaan vendor terkirim.
class VendorTerkirimScreen extends StatelessWidget {
  final String permintaanId;
  const VendorTerkirimScreen({super.key, required this.permintaanId});

  Widget _langkah(int n, String judul, String isi, {bool aktif = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aktif ? AppColors.primary : AppColors.border,
            ),
            child: Text('$n',
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: aktif ? Colors.white : AppColors.textDark)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    style: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w600)),
                Text(isi,
                    style: const TextStyle(
                        fontSize: 12, height: 1.5, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 20),
          child: Column(
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: const BoxDecoration(
                    shape: BoxShape.circle, color: AppColors.sageMuda),
                child: const Icon(Icons.check,
                    size: 44, color: AppColors.primary),
              ),
              const SizedBox(height: 22),
              Text('Permintaan terkirim',
                  style: AppTheme.heading(28).copyWith(color: AppColors.primary)),
              const SizedBox(height: 10),
              const Text(
                  'Admin akan meninjau kebutuhanmu dan meneruskannya ke vendor yang cocok. Kamu akan dapat notifikasi di setiap tahap.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                      fontSize: 13.5, height: 1.65, color: AppColors.textMuted)),
              const SizedBox(height: 28),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 4),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Apa yang terjadi selanjutnya',
                        style: AppTheme.heading(17)),
                    const SizedBox(height: 14),
                    _langkah(1, 'Admin meninjau', 'Biasanya dalam 1 hari kerja.',
                        aktif: true),
                    _langkah(2, 'Diteruskan ke vendor',
                        'Nama dan nomor WhatsApp-mu dibagikan ke vendor.'),
                    _langkah(3, 'Vendor menghubungimu',
                        'Lewat WhatsApp, untuk jadwal survei dan penawaran.'),
                  ],
                ),
              ),
              const Spacer(),
              ElevatedButton(
                onPressed: () => Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const PermintaanVendorScreen())),
                child: const Text('Lihat Permintaanku'),
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: () => Navigator.popUntil(context, (r) => r.isFirst),
                child: const Text('Kembali ke Vendor',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.primary)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
