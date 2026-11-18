import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../data/arsitek_data.dart';
import '../../services/admin_arsitek_service.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import 'admin_arsitek_detail_page.dart';
import 'admin_ringkasan.dart';
import 'admin_util.dart';
import 'admin_widgets.dart';

/// Admin: daftar akun arsitek + tombol membuat akun baru.
class AdminArsitekPage extends StatefulWidget {
  const AdminArsitekPage({super.key});

  @override
  State<AdminArsitekPage> createState() => _AdminArsitekPageState();
}

class _AdminArsitekPageState extends State<AdminArsitekPage> {
  late final Stream<List<AkunArsitek>> _stream = AdminArsitekService.semua();

  Future<void> _tambah(List<AkunArsitek> ada) async {
    final dipakai = ada.map((e) => e.profilId).toSet();
    final sisa = DataArsitek.semuaProfil.where((a) => !dipakai.contains(a.id)).toList();
    if (sisa.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Semua profil arsitek sudah punya akun.')));
      return;
    }
    final nama = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => _FormArsitek(pilihan: sisa),
    );
    if (nama != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Akun $nama dibuat. Bisa langsung login.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<AkunArsitek>>(
      stream: _stream,
      builder: (context, snap) {
        final list = snap.data ?? const <AkunArsitek>[];
        return Scaffold(
          backgroundColor: AppColors.background,
          body: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminPageHeader(
                icon: Icons.architecture_outlined,
                judul: 'Arsitek',
                subjudul: 'Daftar akun arsitek',
              ),
              Expanded(
                child: snap.hasError
                    ? const Center(child: Text('Gagal memuat daftar arsitek.'))
                    : !snap.hasData
                    ? const Center(child: CircularProgressIndicator())
                    : list.isEmpty
                    ? const Center(
                    child: Text('Belum ada akun arsitek.',
                        style: TextStyle(color: AppColors.textMuted)))
                    : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _Baris(a: list[i]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _Baris extends StatelessWidget {
  final AkunArsitek a;
  const _Baris({required this.a});

  @override
  Widget build(BuildContext context) {
    return Material(
      type: MaterialType.transparency,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => AdminArsitekDetailPage(a: a)),
        ),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.line.withValues(alpha: 0.7)),
          ),
          child: Row(children: [
            Container(
              width: 42,
              height: 42,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                  color: AppColors.primary, borderRadius: BorderRadius.circular(12)),
              child: Text(a.nama.isEmpty ? '?' : a.nama[0].toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(a.nama,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(
                    '${a.profilId.isEmpty ? 'belum terhubung' : a.profilId}'
                        '${a.spesialisasi.isEmpty ? '' : ' · ${a.spesialisasi}'}',
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
              ]),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: a.aktif ? AppColors.sageMuda : const Color(0xFFF7E3DD),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(a.aktif ? 'Aktif' : 'Nonaktif',
                  style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w600,
                      color: a.aktif ? AppColors.primary : const Color(0xFF7A3F32))),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 20),
          ]),
        ),
      ),
    );
  }
}

/// Lembar isian akun baru. Mengembalikan nama (String) kalau berhasil.
class _FormArsitek extends StatefulWidget {
  final List<Arsitek> pilihan;
  const _FormArsitek({required this.pilihan});

  @override
  State<_FormArsitek> createState() => _FormArsitekState();
}

class _FormArsitekState extends State<_FormArsitek> {
  late Arsitek _profil = widget.pilihan.first;
  final _nama = TextEditingController();
  final _email = TextEditingController();
  final _sandi = TextEditingController(text: 'Demo12345');
  final _hp = TextEditingController();
  final _spes = TextEditingController();
  bool _sibuk = false;
  String? _galat;

  @override
  void initState() {
    super.initState();
    _isiDari(_profil);
  }

  /// Isi awal dari data profil; semuanya boleh diubah.
  void _isiDari(Arsitek a) {
    _nama.text = a.nama;
    _spes.text = a.spesialis;
    final depan = a.nama
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z ]'), '')
        .split(' ')
        .firstWhere((e) => e.isNotEmpty, orElse: () => 'arsitek');
    _email.text = '$depan@ruangrancang.com';
    final no = int.tryParse(a.id.replaceAll(RegExp(r'\D'), '')) ?? 0;
    _hp.text = '8120000${no.toString().padLeft(4, '0')}';
  }

  @override
  void dispose() {
    for (final c in [_nama, _email, _sandi, _hp, _spes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _simpan() async {
    final nama = _nama.text.trim();
    final email = _email.text.trim();
    if (nama.isEmpty || !email.contains('@')) {
      return setState(() => _galat = 'Nama dan email wajib diisi dengan benar.');
    }
    if (_sandi.text.length < 6) {
      return setState(() => _galat = 'Password minimal 6 karakter.');
    }
    if (_hp.text.trim().isEmpty) {
      return setState(() => _galat = 'Nomor HP wajib diisi.');
    }
    setState(() {
      _sibuk = true;
      _galat = null;
    });
    try {
      await AdminArsitekService.buat(
        nama: nama,
        email: email,
        password: _sandi.text,
        noHp: _hp.text.trim(),
        profilId: _profil.id,
        spesialisasi: _spes.text.trim(),
      );
      if (mounted) Navigator.pop(context, nama);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _sibuk = false;
        _galat = e is FirebaseAuthException
            ? AuthService.errorMessage(e)
            : e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _kolom(TextEditingController c, String label,
      {bool angka = false, bool rahasia = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: c,
        obscureText: rahasia,
        keyboardType: angka ? TextInputType.phone : TextInputType.text,
        decoration: InputDecoration(
          labelText: label,
          filled: true,
          fillColor: AppColors.background,
          border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
          20, 20, 20, 20 + MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Tambah Arsitek', style: AppTheme.heading(20)),
            const SizedBox(height: 4),
            const Text(
                'Akun langsung aktif dan bisa login tanpa verifikasi email.',
                style: TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
            const SizedBox(height: 16),
            DropdownButtonFormField<Arsitek>(
              initialValue: _profil,
              decoration: InputDecoration(
                labelText: 'Profil arsitek di aplikasi',
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none),
              ),
              items: [
                for (final a in widget.pilihan)
                  DropdownMenuItem(value: a, child: Text('${a.id} · ${a.nama}')),
              ],
              onChanged: _sibuk
                  ? null
                  : (a) {
                if (a == null) return;
                setState(() {
                  _profil = a;
                  _isiDari(a);
                });
              },
            ),
            const SizedBox(height: 12),
            _kolom(_nama, 'Nama'),
            _kolom(_email, 'Email login'),
            _kolom(_sandi, 'Password'),
            _kolom(_hp, 'No. HP (tanpa 0 di depan)', angka: true),
            _kolom(_spes, 'Spesialisasi'),
            if (_galat != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: Text(_galat!,
                    style: const TextStyle(fontSize: 12.5, color: Color(0xFFB3392F))),
              ),
            FilledButton(
              onPressed: _sibuk ? null : _simpan,
              style: FilledButton.styleFrom(
                minimumSize: const Size.fromHeight(50),
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: _sibuk
                  ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                  : const Text('Buat Akun',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}