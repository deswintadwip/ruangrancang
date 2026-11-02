import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../models/pesanan_sketsa.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import '../sketsa/sketsa_detail_screen.dart';
import '../sketsa/sketsa_saya_screen.dart';
import 'admin_util.dart';

/// Admin: verifikasi pembayaran dan pantau pesanan sketsa.
class AdminSketsaPage extends StatefulWidget {
  const AdminSketsaPage({super.key});

  @override
  State<AdminSketsaPage> createState() => _AdminSketsaPageState();
}

class _AdminSketsaPageState extends State<AdminSketsaPage> {
  String _tab = 'Verifikasi';
  late final Stream<List<PesananSketsa>> _stream = PesananSketsaService.semua();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Sketsa Desain', style: AppTheme.heading(20)),
      ),
      body: StreamBuilder<List<PesananSketsa>>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final s = snap.data!;
          List<PesananSketsa> f(List<String> st) =>
              s.where((e) => st.contains(e.status)).toList();
          final peta = <String, List<PesananSketsa>>{
            'Verifikasi': f([StatusSketsa.menungguVerifikasi]),
            'Belum bayar': f([StatusSketsa.menungguPembayaran]),
            'Dikerjakan': f([StatusSketsa.dikerjakan]),
            'Selesai': f([StatusSketsa.selesai]),
            'Tolak/Batal': f([StatusSketsa.ditolak, StatusSketsa.dibatalkan]),
          };
          final tampil = peta[_tab] ?? const [];
          return Column(children: [
            const SizedBox(height: 4),
            TabHitung(
              tab: [
                ('Verifikasi', peta['Verifikasi']!.length),
                ('Belum bayar', 0),
                ('Dikerjakan', 0),
                ('Selesai', 0),
                ('Tolak/Batal', 0),
              ],
              aktif: _tab,
              onPilih: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tampil.isEmpty
                  ? const Center(
                      child: Text('Tidak ada pesanan.',
                          style: TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: tampil.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => KartuSketsa(
                        p: tampil[i],
                        judul: '${tampil[i].userNama} → ${tampil[i].arsitekNama}',
                        onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) =>
                                    SketsaDetailScreen(pesananId: tampil[i].id))),
                      ),
                    ),
            ),
          ]);
        },
      ),
    );
  }
}
