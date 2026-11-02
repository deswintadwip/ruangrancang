import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../config/status.dart';
import '../../theme/app_theme.dart';

/// (label, latar, huruf) untuk status konsultasi di panel admin.
(String, Color, Color) gayaStatusKonsultasi(String status, {String refundStatus = ''}) {
  switch (status) {
    case StatusKonsultasi.menungguVerifikasi:
      return ('Perlu verifikasi', const Color(0xFFF7EBD2), const Color(0xFF6E4F0E));
    case StatusKonsultasi.dikonfirmasi:
      return ('Dikonfirmasi', AppColors.sageMuda, AppColors.primary);
    case StatusKonsultasi.selesai:
      return ('Selesai', const Color(0xFFE8E3D8), const Color(0xFF4A463E));
    case StatusKonsultasi.ditolak:
      return ('Ditolak', const Color(0xFFF7E3DD), const Color(0xFF7A3F32));
    case StatusKonsultasi.dibatalkan:
      return refundStatus == 'diproses'
          ? ('Refund diproses', const Color(0xFFDCE6EE), const Color(0xFF2C4A63))
          : ('Dibatalkan', const Color(0xFFF7E3DD), const Color(0xFF7A3F32));
    default:
      return ('Menunggu bayar', const Color(0xFFE8E3D8), const Color(0xFF4A463E));
  }
}

/// Tombol-tombol tab berbentuk chip dengan angka.
class TabHitung extends StatelessWidget {
  final List<(String, int)> tab;
  final String aktif;
  final ValueChanged<String> onPilih;
  const TabHitung(
      {super.key, required this.tab, required this.aktif, required this.onPilih});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          for (final (nama, jumlah) in tab) ...[
            InkWell(
              onTap: () => onPilih(nama),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: aktif == nama ? AppColors.primary : Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                      color: aktif == nama
                          ? AppColors.primary
                          : const Color(0xFFADBD9C)),
                ),
                child: Row(children: [
                  Text(nama,
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: aktif == nama ? Colors.white : AppColors.textDark)),
                  if (jumlah > 0) ...[
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                      decoration: BoxDecoration(
                        color: aktif == nama
                            ? Colors.white.withValues(alpha: 0.25)
                            : const Color(0xFFF7EBD2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text('$jumlah',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: aktif == nama
                                  ? Colors.white
                                  : const Color(0xFF6E4F0E))),
                    ),
                  ],
                ]),
              ),
            ),
            const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }
}

/// Gambar bukti transfer dari base64. Ketuk untuk memperbesar.
class BuktiTransfer extends StatelessWidget {
  final String? base64Gambar;
  const BuktiTransfer(this.base64Gambar, {super.key});

  @override
  Widget build(BuildContext context) {
    final s = base64Gambar;
    Uint8List? bytes;
    if (s != null && s.isNotEmpty) {
      try {
        bytes = base64Decode(s);
      } catch (_) {}
    }
    if (bytes == null) {
      return Container(
        height: 90,
        alignment: Alignment.center,
        decoration: BoxDecoration(
            color: AppColors.background, borderRadius: BorderRadius.circular(12)),
        child: const Text('Belum ada bukti transfer.',
            style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
      );
    }
    final data = bytes;
    return GestureDetector(
      onTap: () => showDialog(
        context: context,
        builder: (_) => Dialog(
          backgroundColor: Colors.black,
          insetPadding: const EdgeInsets.all(12),
          child: InteractiveViewer(child: Image.memory(data)),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Image.memory(data, height: 220, width: double.infinity, fit: BoxFit.cover),
      ),
    );
  }
}

/// Buka chat WhatsApp. [noHp] boleh berawalan 0, 62, atau tanpa awalan.
Future<void> bukaWhatsApp(BuildContext context, String noHp, String teks) async {
  var n = noHp.replaceAll(RegExp(r'\D'), '');
  if (n.startsWith('0')) n = n.substring(1);
  if (!n.startsWith('62')) n = '62$n';
  final ok = await launchUrl(Uri.https('wa.me', '/$n', {'text': teks}),
      mode: LaunchMode.externalApplication);
  if (!ok && context.mounted) {
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Tidak bisa membuka WhatsApp.')));
  }
}

/// Nomor HP user dari koleksi users (null kalau tidak ada).
Future<String?> noHpUser(String uid) async {
  try {
    final d = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final n = d.data()?['noHp'] as String?;
    return (n == null || n.isEmpty) ? null : n;
  } catch (_) {
    return null;
  }
}

/// Dialog meminta alasan (wajib diisi). Mengembalikan teks, atau null kalau batal.
Future<String?> tanyaAlasan(BuildContext context,
    {required String judul,
    required String petunjuk,
    required String tombol,
    bool wajib = true,
    Color warnaTombol = const Color(0xFFB3563F)}) {
  final c = TextEditingController();
  return showDialog<String>(
    context: context,
    builder: (ctx) {
      String? galat;
      return StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(judul, style: AppTheme.heading(18)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(petunjuk,
                  style: const TextStyle(fontSize: 12.5, height: 1.5)),
              const SizedBox(height: 10),
              TextField(
                controller: c,
                minLines: 2,
                maxLines: 4,
                maxLength: 200,
                decoration: InputDecoration(hintText: 'Tulis alasan', errorText: galat),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx), child: const Text('Batal')),
            TextButton(
              onPressed: () {
                final t = c.text.trim();
                if (wajib && t.length < 5) {
                  setS(() => galat = 'Minimal 5 karakter');
                  return;
                }
                Navigator.pop(ctx, t);
              },
              child: Text(tombol, style: TextStyle(color: warnaTombol)),
            ),
          ],
        ),
      );
    },
  );
}

/// Dialog konfirmasi ya/tidak.
Future<bool> konfirmasi(BuildContext context,
    {required String judul, required String isi, required String tombol}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(judul, style: AppTheme.heading(18)),
      content: Text(isi, style: const TextStyle(fontSize: 13, height: 1.5)),
      actions: [
        TextButton(
            onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
        TextButton(
            onPressed: () => Navigator.pop(ctx, true), child: Text(tombol)),
      ],
    ),
  );
  return r == true;
}

/// Kartu putih untuk isi detail admin.
class KartuAdmin extends StatelessWidget {
  final Widget child;
  final EdgeInsets margin;
  const KartuAdmin(
      {super.key, required this.child, this.margin = const EdgeInsets.only(bottom: 14)});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: margin,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFADBD9C).withValues(alpha: 0.6)),
      ),
      child: child,
    );
  }
}

/// Baris "label ......... nilai".
Widget barisInfo(String k, String v, {bool tebal = false}) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(k, style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          const SizedBox(width: 16),
          Flexible(
            child: Text(v,
                textAlign: TextAlign.right,
                style: TextStyle(
                    fontSize: tebal ? 14.5 : 12.5, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
