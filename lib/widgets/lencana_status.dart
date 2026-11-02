import 'package:flutter/material.dart';

/// Lencana status kecil (dipakai Vendor & Perumahan).
class LencanaStatus extends StatelessWidget {
  final String teks;
  final Color latar;
  final Color huruf;
  const LencanaStatus(this.teks,
      {super.key, required this.latar, required this.huruf});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration:
          BoxDecoration(color: latar, borderRadius: BorderRadius.circular(14)),
      child: Text(teks,
          style: TextStyle(
              fontSize: 11.5, fontWeight: FontWeight.w600, color: huruf)),
    );
  }
}

/// Chip pilihan (terpilih = hijau tua).
class ChipPilihan extends StatelessWidget {
  final String teks;
  final bool terpilih;
  final VoidCallback onTap;
  const ChipPilihan(this.teks,
      {super.key, required this.terpilih, required this.onTap});

  @override
  Widget build(BuildContext context) {
    const hijau = Color(0xFF2F4A3F);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(19),
      child: Container(
        height: 38,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: terpilih ? hijau : const Color(0xFFFBF8F2),
          borderRadius: BorderRadius.circular(19),
          border: Border.all(
              color: terpilih ? hijau : const Color(0xFFE3DCCF)),
        ),
        child: Text(teks,
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: terpilih ? Colors.white : const Color(0xFF2B2A27))),
      ),
    );
  }
}
