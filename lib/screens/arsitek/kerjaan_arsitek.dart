import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../config/tahap.dart';
import '../../config/tenggat_sketsa.dart';
import '../../models/konsultasi.dart';
import '../../models/pesanan_sketsa.dart';
import '../../theme/app_theme.dart';
import '../sketsa/sketsa_detail_screen.dart';
import 'arsitek_detail_screen.dart';
import 'arsitek_util.dart';

/// Satu "kerjaan" arsitek yang disatukan dari konsultasi & sketsa, supaya bisa
/// ditampilkan seragam di dashboard dan layar "Semua Kerjaan".
enum JenisKerjaan { konsultasi, sketsa }

class ItemKerjaan {
  final JenisKerjaan jenis;
  final String id;
  final String klien;
  final String tipeLabel; // "Konsultasi" / "Sketsa desain"
  final String detail; // info ringkas (jadwal / luas / tenggat)
  final String statusLabel; // "Selesai", "Dikerjakan", "Terlambat", dll
  final bool aktif; // true = masih berjalan, false = selesai
  final bool mendesak; // perlu update / terlambat
  final DateTime waktuUrut;

  const ItemKerjaan({
    required this.jenis,
    required this.id,
    required this.klien,
    required this.tipeLabel,
    required this.detail,
    required this.statusLabel,
    required this.aktif,
    required this.mendesak,
    required this.waktuUrut,
  });

  IconData get ikon => jenis == JenisKerjaan.sketsa
      ? Icons.draw_outlined
      : Icons.event_outlined;
}

const _bln = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
String _tglSingkat(DateTime d) => '${d.day} ${_bln[d.month]}';

/// Konsultasi → item kerjaan (hanya yang relevan: dikonfirmasi / selesai).
List<ItemKerjaan> itemDariKonsultasi(List<Konsultasi> list) {
  final hasil = <ItemKerjaan>[];
  for (final k in list.where(tampilDiArsitek)) {
    if (k.status == StatusKonsultasi.dikonfirmasi) {
      hasil.add(ItemKerjaan(
        jenis: JenisKerjaan.konsultasi,
        id: k.id,
        klien: k.userNama,
        tipeLabel: 'Konsultasi',
        detail: '${tanggalLengkap(k.tanggal)} · ${k.jam}',
        statusLabel: perluUpdate(k) ? 'Perlu update' : 'Dikonfirmasi',
        aktif: true,
        mendesak: perluUpdate(k),
        waktuUrut: k.mulai ?? DateTime.now(),
      ));
    } else if (k.status == StatusKonsultasi.selesai) {
      hasil.add(ItemKerjaan(
        jenis: JenisKerjaan.konsultasi,
        id: k.id,
        klien: k.userNama,
        tipeLabel: 'Konsultasi',
        detail: tanggalLengkap(k.tanggal),
        statusLabel: 'Selesai',
        aktif: false,
        mendesak: false,
        waktuUrut: k.mulai ?? DateTime(2000),
      ));
    }
  }
  return hasil;
}

/// Sketsa → item kerjaan (dikerjakan / selesai).
List<ItemKerjaan> itemDariSketsa(List<PesananSketsa> list) {
  final hasil = <ItemKerjaan>[];
  for (final p in list) {
    if (p.status == StatusSketsa.dikerjakan) {
      final telat = TenggatSketsa.terlambat(p);
      final batas = TenggatSketsa.batas(p);
      hasil.add(ItemKerjaan(
        jenis: JenisKerjaan.sketsa,
        id: p.id,
        klien: p.userNama,
        tipeLabel: 'Sketsa desain',
        detail: '${p.luasLahan} m²'
            '${batas == null ? '' : ' · tenggat ${_tglSingkat(batas)}'}',
        statusLabel: telat ? 'Terlambat' : 'Dikerjakan',
        aktif: true,
        mendesak: telat,
        waktuUrut: p.diverifikasiAt ?? DateTime.now(),
      ));
    } else if (p.status == StatusSketsa.selesai) {
      hasil.add(ItemKerjaan(
        jenis: JenisKerjaan.sketsa,
        id: p.id,
        klien: p.userNama,
        tipeLabel: 'Sketsa desain',
        detail: '${p.luasLahan} m²',
        statusLabel: 'Selesai',
        aktif: false,
        mendesak: false,
        waktuUrut: p.hasilAt ?? p.createdAt ?? DateTime(2000),
      ));
    }
  }
  return hasil;
}

void bukaKerjaan(BuildContext context, ItemKerjaan it) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => it.jenis == JenisKerjaan.sketsa
          ? SketsaDetailScreen(pesananId: it.id)
          : ArsitekDetailScreen(konsultasiId: it.id),
    ),
  );
}

/// Lencana status kecil di kanan kartu.
Widget _lencana(ItemKerjaan it) {
  Color bg;
  Color fg;
  if (it.mendesak) {
    bg = const Color(0xFFF7E3DD);
    fg = const Color(0xFFB3392F);
  } else if (!it.aktif) {
    bg = AppColors.sage;
    fg = AppColors.primary;
  } else {
    bg = AppColors.sageMuda;
    fg = AppColors.primary;
  }
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
    child: Text(it.statusLabel,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
  );
}

/// Baris satu kerjaan. [datar] = tanpa border/latar (untuk di dalam kartu lain).
Widget kartuKerjaan(BuildContext context, ItemKerjaan it, {bool datar = false}) {
  final isi = Row(children: [
    Container(
      width: 40,
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(it.ikon, size: 20, color: AppColors.primary),
    ),
    const SizedBox(width: 12),
    Expanded(
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(it.klien,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
            const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
        const SizedBox(height: 2),
        Text('${it.tipeLabel} · ${it.detail}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
      ]),
    ),
    const SizedBox(width: 8),
    _lencana(it),
  ]);

  if (datar) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => bukaKerjaan(context, it),
      child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10), child: isi),
    );
  }
  return Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: GestureDetector(
      onTap: () => bukaKerjaan(context, it),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: it.mendesak ? const Color(0xFFE8B7AA) : AppColors.border),
        ),
        child: isi,
      ),
    ),
  );
}