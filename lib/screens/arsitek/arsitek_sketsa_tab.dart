import '../../widgets/header_foto.dart';
import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../models/pesanan_sketsa.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import '../admin/admin_util.dart';
import '../sketsa/sketsa_detail_screen.dart';
import '../sketsa/sketsa_saya_screen.dart';

/// Tab "Sketsa" untuk arsitek: pesanan yang sudah dibayar dan perlu dikerjakan.
class ArsitekSketsaTab extends StatefulWidget {
  const ArsitekSketsaTab({super.key});

  @override
  State<ArsitekSketsaTab> createState() => _ArsitekSketsaTabState();
}

class _ArsitekSketsaTabState extends State<ArsitekSketsaTab> {
  String _tab = 'Dikerjakan';
  late final Stream<List<PesananSketsa>> _stream = PesananSketsaService.untukSaya();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text('Sketsa Desain', style: AppTheme.heading(22)),
      ),
      body: StreamBuilder<List<PesananSketsa>>(
        stream: _stream,
        builder: (context, snap) {
          if (!snap.hasData) return const Center(child: CircularProgressIndicator());
          final semua = snap.data!;
          final kerja = semua.where((e) => e.status == StatusSketsa.dikerjakan).toList();
          final selesai = semua.where((e) => e.status == StatusSketsa.selesai).toList();
          final tampil = _tab == 'Dikerjakan' ? kerja : selesai;
          return Column(children: [
            const SizedBox(height: 4),
            TabHitung(
              tab: [('Dikerjakan', kerja.length), ('Selesai', 0)],
              aktif: _tab,
              onPilih: (t) => setState(() => _tab = t),
            ),
            const SizedBox(height: 12),
            Expanded(
              child: tampil.isEmpty
                  ? Center(
                      child: Text(
                          _tab == 'Dikerjakan'
                              ? 'Belum ada sketsa yang harus dikerjakan.'
                              : 'Belum ada sketsa yang selesai.',
                          style: const TextStyle(color: AppColors.textMuted)))
                  : ListView.separated(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                      itemCount: tampil.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 12),
                      itemBuilder: (_, i) => KartuSketsa(
                        p: tampil[i],
                        judul: 'Klien: ${tampil[i].userNama}',
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
