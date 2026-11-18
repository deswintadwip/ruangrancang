import 'package:flutter/material.dart';
import '../config/status.dart';
import '../config/tahap.dart';
import '../models/konsultasi.dart';
import '../screens/arsitek/arsitek_detail_screen.dart';
import '../screens/arsitek/arsitek_util.dart';
import '../screens/konsultasi/lacak_screen.dart';
import '../models/pesanan_rumah.dart';
import '../models/pesanan_sketsa.dart';
import '../screens/perumahan/pembayaran_rumah_screen.dart';
import '../screens/sketsa/sketsa_detail_screen.dart';
import '../services/konsultasi_service.dart';
import '../services/pesanan_rumah_service.dart';
import '../services/pesanan_sketsa_service.dart';
import '../utils/format.dart';
import '../theme/app_theme.dart';

String _jam(DateTime? t) => t == null
    ? ''
    : '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

/// Kerangka bar hijau di atas menu bawah (gaya "lacak pesanan").
class _BarDasar extends StatelessWidget {
  final String inisial;
  final String judul;
  final String sub;
  final int tahap;
  final int segmen;
  final String tombol;
  final VoidCallback onTap;

  const _BarDasar({
    required this.inisial,
    required this.judul,
    required this.sub,
    required this.tahap,
    this.segmen = TahapKerja.jumlah,
    required this.tombol,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          decoration: BoxDecoration(
            color: AppColors.primary,
            borderRadius: BorderRadius.circular(22),
            boxShadow: const [
              BoxShadow(
                  color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4))
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: Colors.white.withValues(alpha: 0.18),
                  child: Text(inisial,
                      style: const TextStyle(
                          fontSize: 12,
                          color: Colors.white,
                          fontWeight: FontWeight.w700)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(judul,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 11.5, color: Colors.white70)),
                      Text(sub,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
                Container(
                  padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFD9A441),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(tombol,
                      style: const TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white)),
                ),
              ]),
              const SizedBox(height: 8),
              Row(children: [
                for (var i = 1; i <= segmen; i++)
                  Expanded(
                    child: Container(
                      height: 4,
                      margin: EdgeInsets.only(right: i == segmen ? 0 : 4),
                      decoration: BoxDecoration(
                        color: i <= tahap
                            ? const Color(0xFFD9A441)
                            : Colors.white.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Bar pelacak di Beranda USER: gabungan konsultasi, sketsa, dan booking rumah.
class TrackingBarUser extends StatelessWidget {
  const TrackingBarUser({super.key});

  @override
  Widget build(BuildContext context) {
    return const Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _BarSketsaUser(),
        _BarRumahUser(),
        _BarKonsultasiUser(),
      ],
    );
  }
}

/// Bar sketsa desain: bayar, verifikasi, dikerjakan, selesai.
class _BarSketsaUser extends StatelessWidget {
  const _BarSketsaUser();

  PesananSketsa? _pilih(List<PesananSketsa> semua) {
    for (final p in semua) {
      if (p.status == StatusSketsa.menungguPembayaran ||
          p.status == StatusSketsa.menungguVerifikasi ||
          p.status == StatusSketsa.dikerjakan) {
        return p;
      }
      // Yang sudah selesai tidak ditampilkan lagi (ada di Pesanan Sketsa).
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PesananSketsa>>(
      stream: PesananSketsaService.milikSaya(),
      builder: (context, snap) {
        final p = _pilih(snap.data ?? const []);
        if (p == null) return const SizedBox.shrink();
        late final String judul, sub, tombol;
        late final int tahap;
        switch (p.status) {
          case StatusSketsa.menungguPembayaran:
            judul = 'Sketsa Desain · menunggu pembayaran';
            sub = 'Bayar ${formatRupiah(p.harga)} · ${p.arsitekNama}';
            tombol = 'Bayar';
            tahap = 1;
          case StatusSketsa.menungguVerifikasi:
            judul = 'Pembayaran sedang diverifikasi admin';
            sub = 'Sketsa · ${p.arsitekNama}';
            tombol = 'Lacak';
            tahap = 2;
          case StatusSketsa.dikerjakan:
            judul = 'Arsitek sedang mengerjakan sketsa';
            sub = p.arsitekNama;
            tombol = 'Lacak';
            tahap = 3;
          default:
            return const SizedBox.shrink();
        }
        return _BarDasar(
          inisial: inisialNama(p.arsitekNama),
          judul: judul,
          sub: sub,
          tahap: tahap,
          segmen: 4,
          tombol: tombol,
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => SketsaDetailScreen(pesananId: p.id)),
          ),
        );
      },
    );
  }
}

/// Bar booking rumah yang belum selesai dibayar.
class _BarRumahUser extends StatelessWidget {
  const _BarRumahUser();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<PesananRumah>>(
      stream: PesananRumahService.milikSaya(),
      builder: (context, snap) {
        PesananRumah? p;
        for (final e in snap.data ?? const <PesananRumah>[]) {
          if (e.status == StatusPesananRumah.menungguPembayaran ||
              e.status == StatusPesananRumah.menungguVerifikasi) {
            p = e;
            break;
          }
        }
        if (p == null) return const SizedBox.shrink();
        final bayar = p.status == StatusPesananRumah.menungguPembayaran;
        final id = p.id;
        return _BarDasar(
          inisial: inisialNama(p.perumahanNama),
          judul: bayar
              ? 'Booking rumah · menunggu pembayaran'
              : 'Booking fee sedang diverifikasi admin',
          sub: '${p.perumahanNama} · ${p.tipe}',
          tahap: bayar ? 1 : 2,
          segmen: 3,
          tombol: bayar ? 'Bayar' : 'Lacak',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => PembayaranRumahScreen(pesananId: id)),
          ),
        );
      },
    );
  }
}

/// Bar konsultasi aktif milik user.
class _BarKonsultasiUser extends StatelessWidget {
  const _BarKonsultasiUser();

  Konsultasi? _pilih(List<Konsultasi> semua) {
    final aktif = semua
        .where((k) =>
            k.status == StatusKonsultasi.dikonfirmasi &&
            k.tahapSaatIni < TahapKerja.jumlah)
        .toList();
    if (aktif.isEmpty) return null;
    // Yang sudah dikerjakan arsitek lebih dulu, lalu sesi terdekat.
    for (final k in aktif) {
      if (k.tahapSaatIni >= 2) return k;
    }
    final sekarang = DateTime.now().subtract(const Duration(hours: 2));
    for (final k in aktif) {
      final m = k.mulai;
      if (m != null && m.isAfter(sekarang)) return k;
    }
    return aktif.first;
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Konsultasi>>(
      stream: KonsultasiService.milikSaya(),
      builder: (context, snap) {
        final k = _pilih(snap.data ?? const []);
        if (k == null) return const SizedBox.shrink();
        final t = k.tahapSaatIni;
        final judul = t >= 2 ? 'Arsitek sedang bekerja' : 'Sesi terjadwal';
        final sub = t >= 2
            ? '${TahapKerja.namaTahap(t)} · ${_jam(k.updatedAt)}'
            : '${tanggalPendek(k.tanggal).split(' ').take(2).join(' ')} · ${k.jam} · ${k.arsitekNama}';
        return _BarDasar(
          inisial: inisialNama(k.arsitekNama),
          judul: judul,
          sub: sub.endsWith(' · ') ? sub.substring(0, sub.length - 3) : sub,
          tahap: t,
          tombol: 'Lacak',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => LacakScreen(konsultasiId: k.id)),
          ),
        );
      },
    );
  }
}

/// Bar pelacak di Beranda ARSITEK: pekerjaan yang sedang berjalan.
class TrackingBarArsitek extends StatelessWidget {
  const TrackingBarArsitek({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<Konsultasi>>(
      stream: KonsultasiService.milikArsitekSaya(),
      builder: (context, snap) {
        final aktif = (snap.data ?? const <Konsultasi>[])
            .where((k) =>
        k.status == StatusKonsultasi.dikonfirmasi &&
            k.tahapSaatIni >= 2)
            .toList();
        if (aktif.isEmpty) return const SizedBox.shrink();
        // Yang paling lama belum di-update ditampilkan dulu.
        aktif.sort((a, b) => (a.updatedAt ?? DateTime(2000))
            .compareTo(b.updatedAt ?? DateTime(2000)));
        final k = aktif.first;
        final t = k.tahapSaatIni;
        return _BarDasar(
          inisial: inisialNama(k.userNama),
          judul: 'Sedang dikerjakan · ${aktif.length} aktif',
          sub: '${k.userNama} · Tahap $t/${TahapKerja.jumlah}',
          tahap: t,
          tombol: 'Update',
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
                builder: (_) => ArsitekDetailScreen(konsultasiId: k.id)),
          ),
        );
      },
    );
  }
}