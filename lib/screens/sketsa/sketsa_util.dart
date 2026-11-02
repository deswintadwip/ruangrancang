import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../theme/app_theme.dart';

/// (label, latar, huruf) untuk status pesanan sketsa.
(String, Color, Color) gayaStatusSketsa(String status) {
  switch (status) {
    case StatusSketsa.menungguVerifikasi:
      return ('Menunggu verifikasi', const Color(0xFFF7EBD2), const Color(0xFF6E4F0E));
    case StatusSketsa.dikerjakan:
      return ('Sedang dikerjakan', const Color(0xFFDCE6EE), const Color(0xFF2C4A63));
    case StatusSketsa.selesai:
      return ('Selesai', AppColors.sageMuda, AppColors.primary);
    case StatusSketsa.ditolak:
      return ('Ditolak', const Color(0xFFF7E3DD), const Color(0xFF7A3F32));
    case StatusSketsa.dibatalkan:
      return ('Dibatalkan', const Color(0xFFF7E3DD), const Color(0xFF7A3F32));
    default:
      return ('Menunggu bayar', const Color(0xFFE8E3D8), const Color(0xFF4A463E));
  }
}

const _bln = ['Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun', 'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'];

String tglSketsa(DateTime? d) {
  if (d == null) return '-';
  final l = d.toLocal();
  return '${l.day} ${_bln[l.month - 1]} ${l.year}';
}

class LencanaStatusSketsa extends StatelessWidget {
  final String status;
  const LencanaStatusSketsa(this.status, {super.key});
  @override
  Widget build(BuildContext context) {
    final (t, bg, fg) = gayaStatusSketsa(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
      child: Text(t, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: fg)),
    );
  }
}
