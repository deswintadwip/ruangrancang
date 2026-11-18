import 'package:flutter/material.dart';
import '../../models/konsultasi.dart';
import '../../models/pesanan_sketsa.dart';
import '../../services/admin_arsitek_service.dart';
import '../../services/admin_konsultasi_service.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import 'admin_widgets.dart';

/// Admin: ringkasan satu arsitek — tanggal cuti + pekerjaan yang ia tangani
/// (konsultasi & sketsa). Read-only; data diambil dari koleksi yang memang
/// sudah boleh dibaca admin, jadi tidak perlu ubah Firestore Rules.
class AdminArsitekDetailPage extends StatelessWidget {
  final AkunArsitek a;
  const AdminArsitekDetailPage({super.key, required this.a});

  /// konsultasi/sketsa menyimpan arsitekId berupa UID atau profilId
  /// ("arsitek_01"), jadi cocokkan ke dua-duanya.
  bool _milikDia(String arsitekId) =>
      arsitekId == a.uid ||
          (a.profilId.isNotEmpty && arsitekId == a.profilId);

  @override
  Widget build(BuildContext context) {
    final cuti = [...a.cuti]..sort();

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminPageHeader(
            icon: Icons.architecture_outlined,
            judul: a.nama,
            subjudul: a.profilId.isEmpty ? 'belum terhubung' : a.profilId,
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
              children: [
                // ---------- Info singkat ----------
                AdminSection(
                  icon: Icons.badge_outlined,
                  judul: 'Info',
                  children: [
                    _info('Nama', a.nama),
                    _info('Profil', a.profilId.isEmpty ? '-' : a.profilId),
                    _info('Spesialisasi',
                        a.spesialisasi.isEmpty ? '-' : a.spesialisasi),
                    _info('Status', a.aktif ? 'Aktif' : 'Nonaktif'),
                  ],
                ),

                // ---------- Cuti / libur ----------
                AdminSection(
                  icon: Icons.beach_access_outlined,
                  judul: 'Cuti / libur (${cuti.length})',
                  children: [
                    if (cuti.isEmpty)
                      const Text('Belum ada tanggal cuti.',
                          style: TextStyle(color: AppColors.textMuted))
                    else
                      for (final c in cuti) _barisTanggal(_tglId(c)),
                  ],
                ),

                // ---------- Konsultasi yang ditangani ----------
                StreamBuilder<List<Konsultasi>>(
                  stream: AdminKonsultasiService.semua(),
                  builder: (context, snap) {
                    final punya = (snap.data ?? const <Konsultasi>[])
                        .where((k) => _milikDia(k.arsitekId))
                        .toList()
                      ..sort((x, y) => y.tanggal.compareTo(x.tanggal));
                    return AdminSection(
                      icon: Icons.event_note_outlined,
                      judul: 'Konsultasi ditangani (${punya.length})',
                      children: [
                        if (!snap.hasData)
                          _memuat()
                        else if (punya.isEmpty)
                          const Text('Belum ada konsultasi.',
                              style: TextStyle(color: AppColors.textMuted))
                        else
                          for (final k in punya)
                            _barisKerja(
                              judul:
                              k.userNama.isEmpty ? '(tanpa nama)' : k.userNama,
                              sub: '${_tglId(k.tanggal)} · ${k.jam}',
                              status: k.status,
                            ),
                      ],
                    );
                  },
                ),

                // ---------- Sketsa yang dikerjakan ----------
                StreamBuilder<List<PesananSketsa>>(
                  stream: PesananSketsaService.semua(),
                  builder: (context, snap) {
                    final punya = (snap.data ?? const <PesananSketsa>[])
                        .where((p) => _milikDia(p.arsitekId))
                        .toList()
                      ..sort((x, y) => (y.createdAt ?? DateTime(2000))
                          .compareTo(x.createdAt ?? DateTime(2000)));
                    return AdminSection(
                      icon: Icons.draw_outlined,
                      judul: 'Sketsa dikerjakan (${punya.length})',
                      children: [
                        if (!snap.hasData)
                          _memuat()
                        else if (punya.isEmpty)
                          const Text('Belum ada pesanan sketsa.',
                              style: TextStyle(color: AppColors.textMuted))
                        else
                          for (final p in punya)
                            _barisKerja(
                              judul:
                              p.userNama.isEmpty ? '(tanpa nama)' : p.userNama,
                              sub: '${p.luasLahan} m²'
                                  '${p.createdAt == null ? '' : ' · ${_tglTanggal(p.createdAt!)}'}',
                              status: p.status,
                            ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------- potongan tampilan ----------
  Widget _memuat() => const Padding(
    padding: EdgeInsets.all(8),
    child: Center(child: CircularProgressIndicator()),
  );

  Widget _info(String k, String v) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(k,
              style: const TextStyle(
                  color: AppColors.textMuted, fontSize: 13)),
        ),
        Expanded(
          child: Text(v,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w600)),
        ),
      ],
    ),
  );

  Widget _barisTanggal(String teks) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Row(
      children: [
        const Icon(Icons.event_busy_outlined,
            size: 18, color: AppColors.primary),
        const SizedBox(width: 10),
        Text(teks, style: const TextStyle(fontSize: 13.5)),
      ],
    ),
  );

  Widget _barisKerja({
    required String judul,
    required String sub,
    required String status,
  }) =>
      Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(judul,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                          fontSize: 13.5, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(sub,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textMuted)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            _chipStatus(status),
          ],
        ),
      );

  Widget _chipStatus(String s) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
    decoration: BoxDecoration(
      color: AppColors.sageMuda,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Text(s.replaceAll('_', ' '),
        style: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            color: AppColors.primary)),
  );
}

// ---------- bantu tanggal (tanpa paket intl) ----------
const _bulanId = [
  '', 'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

/// "2026-11-18" -> "18 Nov 2026"
String _tglId(String kunci) {
  final p = kunci.split('-');
  if (p.length != 3) return kunci;
  final m = int.tryParse(p[1]) ?? 0;
  final d = int.tryParse(p[2]) ?? 0;
  if (m < 1 || m > 12) return kunci;
  return '$d ${_bulanId[m]} ${p[0]}';
}

String _tglTanggal(DateTime d) => '${d.day} ${_bulanId[d.month]} ${d.year}';