import '../../widgets/header_foto.dart';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import '../../config/tarif_sketsa.dart';
import '../../data/arsitek_data.dart';
import '../../services/auth_service.dart';
import '../../services/pesanan_sketsa_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import 'sketsa_detail_screen.dart';

const _arah = ['Utara', 'Timur', 'Selatan', 'Barat', 'Timur Laut', 'Tenggara', 'Barat Daya', 'Barat Laut'];
const _kontur = ['Datar', 'Miring', 'Berbukit'];
const _kondisi = ['Lahan kosong', 'Ada bangunan lama'];
const _jenis = ['Rumah tinggal', 'Rumah + usaha', 'Ruko', 'Kos-kosan', 'Villa', 'Renovasi'];
const _ruang = [
  'Carport', 'Taman', 'Kolam renang', 'Ruang kerja', 'Ruang ibadah',
  'Dapur bersih', 'Laundry', 'Rooftop', 'Ruang usaha', 'Gudang',
];
const _material = ['Kayu', 'Batu alam', 'Beton ekspos', 'Kaca besar', 'Bata ekspos'];
const _palet = ['Netral', 'Hangat', 'Earth tone', 'Monokrom', 'Cerah'];
const _khusus = [
  'Ramah lansia', 'Ramah difabel', 'Ada anak kecil', 'Hewan peliharaan',
  'Rencana tambah lantai', 'Hemat energi',
];

/// Form "Pesan Sketsa Desain": banyak input, harga mengikuti luas lahan.
class SketsaFormScreen extends StatefulWidget {
  final Arsitek arsitek;
  const SketsaFormScreen({super.key, required this.arsitek});

  @override
  State<SketsaFormScreen> createState() => _SketsaFormScreenState();
}

class _SketsaFormScreenState extends State<SketsaFormScreen> {
  final _luas = TextEditingController();
  final _panjang = TextEditingController();
  final _lebar = TextEditingController();
  final _kota = TextEditingController();
  final _luasBangunan = TextEditingController();
  final _budget = TextEditingController();
  final _referensi = TextEditingController();
  final _catatan = TextEditingController();

  String? _arahHadap;
  String _konturPilih = _kontur.first;
  String _kondisiPilih = _kondisi.first;
  String _jenisPilih = _jenis.first;
  int _lantai = 1;
  int _kamarTidur = 2;
  int _kamarMandi = 1;
  int _penghuni = 4;
  final Set<String> _ruangPilih = {};
  final Set<String> _materialPilih = {};
  final Set<String> _khususPilih = {};
  late String _gaya;
  String _paletPilih = _palet.first;
  final List<Uint8List> _lampiran = [];
  String _nama = '';
  bool _mengirim = false;
  bool _setuju = false;

  @override
  void initState() {
    super.initState();
    _gaya = DataArsitek.daftarGaya.contains(widget.arsitek.spesialis)
        ? widget.arsitek.spesialis
        : DataArsitek.daftarGaya.first;
    _luas.addListener(() => setState(() {}));
    _muatNama();
  }

  Future<void> _muatNama() async {
    final p = await AuthService().getUserProfile();
    if (mounted) setState(() => _nama = (p?['nama'] as String?) ?? '');
  }

  @override
  void dispose() {
    for (final c in [_luas, _panjang, _lebar, _kota, _luasBangunan, _budget, _referensi, _catatan]) {
      c.dispose();
    }
    super.dispose();
  }

  int get _luasAngka => int.tryParse(_luas.text.trim()) ?? 0;
  int get _harga => TarifSketsa.hitung(_luasAngka);

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _tambahLampiran() async {
    if (_lampiran.length >= 3) return _pesan('Maksimal 3 gambar.');
    try {
      final x = await ImagePicker()
          .pickImage(source: ImageSource.gallery, maxWidth: 900, imageQuality: 55);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      final total = _lampiran.fold<int>(0, (s, b) => s + b.length) + bytes.length;
      if (total > 250 * 1024) {
        return _pesan('Total lampiran terlalu besar. Pilih gambar yang lebih kecil.');
      }
      if (mounted) setState(() => _lampiran.add(bytes));
    } catch (_) {
      _pesan('Tidak bisa membuka galeri.');
    }
  }

  Future<void> _kirim() async {
    if (_luasAngka <= 0) return _pesan('Isi luas lahan dulu (angka, dalam m²).');
    if (_kota.text.trim().isEmpty) return _pesan('Isi lokasi lahan (kota atau daerah).');
    if (!_setuju) return _pesan('Centang persetujuan ketentuan sketsa dulu.');
    setState(() => _mengirim = true);
    try {
      final id = await PesananSketsaService.buat(
        userNama: _nama.isEmpty ? 'Pengguna' : _nama,
        arsitekId: widget.arsitek.id,
        arsitekNama: widget.arsitek.nama,
        harga: _harga,
        isi: {
          'luasLahan': _luasAngka,
          'panjang': _panjang.text.trim(),
          'lebar': _lebar.text.trim(),
          'kota': _kota.text.trim(),
          'arahHadap': _arahHadap ?? '',
          'kontur': _konturPilih,
          'kondisiLahan': _kondisiPilih,
          'jenisBangunan': _jenisPilih,
          'jumlahLantai': _lantai,
          'luasBangunan': _luasBangunan.text.trim(),
          'kamarTidur': _kamarTidur,
          'kamarMandi': _kamarMandi,
          'penghuni': _penghuni,
          'ruangTambahan': _ruangPilih.toList(),
          'material': _materialPilih.toList(),
          'kebutuhanKhusus': _khususPilih.toList(),
          'gaya': _gaya,
          'palet': _paletPilih,
          'budget': _budget.text.trim(),
          'referensi': _referensi.text.trim(),
          'catatan': _catatan.text.trim(),
          'lampiran': _lampiran.map(base64Encode).toList(),
          'syaratDisetujui': true,
        },
      );
      if (!mounted) return;
      Navigator.pushReplacement(context,
          MaterialPageRoute(builder: (_) => SketsaDetailScreen(pesananId: id)));
    } catch (e) {
      debugPrint('SKETSA BUAT ERROR: $e');
      if (!mounted) return;
      setState(() => _mengirim = false);
      final teks = e.toString();
      _pesan(teks.startsWith('Exception: kamu') || teks.contains('masih punya pesanan')
          ? teks.replaceFirst('Exception: ', '')
          : 'Gagal membuat pesanan. Coba lagi.');
    }
  }

  // ───────────────────────── tampilan ─────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Text('Pesan Sketsa Desain', style: AppTheme.heading(20)),
      ),
      body: Column(children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
            children: [
              _kartuArsitek(),
              const SizedBox(height: 6),
              _info('Hasilnya berupa sketsa dalam file PDF yang dikirim ke aplikasi. '
                  'Tidak ada jadwal pertemuan. Harga mengikuti luas lahan.'),

              _judul('1. Data lahan'),
              _kotak([
                _teks(_luas, 'Luas lahan (m²) *', angka: true,
                    bantu: 'Menentukan harga sketsa'),
                Row(children: [
                  Expanded(child: _teks(_panjang, 'Panjang (m)', angka: true)),
                  const SizedBox(width: 10),
                  Expanded(child: _teks(_lebar, 'Lebar (m)', angka: true)),
                ]),
                _teks(_kota, 'Lokasi lahan (kota / daerah) *'),
                _label('Arah hadap lahan'),
                _pilihSatu(_arah, _arahHadap, (v) => setState(() => _arahHadap = v)),
                _label('Kontur tanah'),
                _pilihSatu(_kontur, _konturPilih, (v) => setState(() => _konturPilih = v!)),
                _label('Kondisi lahan'),
                _pilihSatu(_kondisi, _kondisiPilih, (v) => setState(() => _kondisiPilih = v!)),
              ]),

              _judul('2. Kebutuhan bangunan'),
              _kotak([
                _label('Jenis bangunan'),
                _pilihSatu(_jenis, _jenisPilih, (v) => setState(() => _jenisPilih = v!)),
                _stepper('Jumlah lantai', _lantai, 1, 4, (v) => setState(() => _lantai = v)),
                _teks(_luasBangunan, 'Target luas bangunan (m²), opsional', angka: true),
                _stepper('Kamar tidur', _kamarTidur, 0, 10, (v) => setState(() => _kamarTidur = v)),
                _stepper('Kamar mandi', _kamarMandi, 0, 10, (v) => setState(() => _kamarMandi = v)),
                _stepper('Jumlah penghuni', _penghuni, 1, 20, (v) => setState(() => _penghuni = v)),
              ]),

              _judul('3. Ruang tambahan'),
              _kotak([_pilihBanyak(_ruang, _ruangPilih)]),

              _judul('4. Gaya dan suasana'),
              _kotak([
                _label('Gaya desain'),
                _pilihSatu(DataArsitek.daftarGaya, _gaya, (v) => setState(() => _gaya = v!)),
                _label('Material favorit'),
                _pilihBanyak(_material, _materialPilih),
                _label('Palet warna'),
                _pilihSatu(_palet, _paletPilih, (v) => setState(() => _paletPilih = v!)),
              ]),

              _judul('5. Kebutuhan khusus'),
              _kotak([_pilihBanyak(_khusus, _khususPilih)]),

              _judul('6. Budget dan referensi'),
              _kotak([
                _teks(_budget, 'Estimasi budget pembangunan, contoh Rp300 juta'),
                _teks(_referensi, 'Link referensi desain (Pinterest, Drive, dll.)'),
                _teks(_catatan, 'Catatan tambahan untuk arsitek', baris: 4),
              ]),

              _judul('7. Lampiran (opsional)'),
              _kotak([_bagianLampiran()]),
            ],
          ),
        ),
        _barBawah(),
      ]),
    );
  }

  Widget _kartuArsitek() {
    final a = widget.arsitek;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(color: a.warna, borderRadius: BorderRadius.circular(12)),
          alignment: Alignment.center,
          child: Text(a.nama.isEmpty ? '?' : a.nama[0],
              style: AppTheme.heading(20).copyWith(color: Colors.white)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('${a.nama}, ${a.gelar}',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
            Text('Arsitek ${a.spesialis}',
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ]),
        ),
      ]),
    );
  }

  Widget _info(String teks) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
              color: const Color(0xFFE1EDFB), borderRadius: BorderRadius.circular(14)),
          child: Text(teks,
              style: const TextStyle(fontSize: 12, height: 1.5, color: Color(0xFF1D4E89))),
        ),
      );

  Widget _judul(String t) => Padding(
        padding: const EdgeInsets.fromLTRB(2, 22, 0, 8),
        child: Text(t, style: AppTheme.heading(18)),
      );

  Widget _kotak(List<Widget> anak) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < anak.length; i++) ...[
              if (i > 0) const SizedBox(height: 12),
              anak[i],
            ],
          ],
        ),
      );

  Widget _label(String t) => Text(t,
      style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600));

  Widget _teks(TextEditingController c, String hint,
      {bool angka = false, int baris = 1, String? bantu}) {
    return TextField(
      controller: c,
      keyboardType: angka ? TextInputType.number : TextInputType.text,
      inputFormatters: angka ? [FilteringTextInputFormatter.digitsOnly] : null,
      minLines: baris,
      maxLines: baris,
      maxLength: baris > 1 ? 400 : null,
      decoration: InputDecoration(
        labelText: hint,
        helperText: bantu,
        labelStyle: const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.background,
        counterText: '',
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _chip(String label, bool aktif, VoidCallback onTap) => GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
          decoration: BoxDecoration(
            color: aktif ? AppColors.primary : AppColors.background,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: aktif ? AppColors.primary : AppColors.border),
          ),
          child: Text(label,
              style: TextStyle(
                  fontSize: 12.5,
                  fontWeight: aktif ? FontWeight.w600 : FontWeight.w400,
                  color: aktif ? Colors.white : AppColors.textDark)),
        ),
      );

  Widget _pilihSatu(List<String> opsi, String? dipilih, ValueChanged<String?> onPilih) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in opsi) _chip(o, dipilih == o, () => onPilih(o)),
      ]);

  Widget _pilihBanyak(List<String> opsi, Set<String> dipilih) =>
      Wrap(spacing: 8, runSpacing: 8, children: [
        for (final o in opsi)
          _chip(o, dipilih.contains(o), () {
            setState(() => dipilih.contains(o) ? dipilih.remove(o) : dipilih.add(o));
          }),
      ]);

  Widget _stepper(String label, int nilai, int min, int max, ValueChanged<int> onUbah) {
    Widget tombol(IconData ic, bool aktif, VoidCallback onTap) => InkWell(
          onTap: aktif ? onTap : null,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: aktif ? AppColors.sageMuda : AppColors.background,
            ),
            child: Icon(ic, size: 18, color: aktif ? AppColors.primary : AppColors.border),
          ),
        );
    return Row(children: [
      Expanded(child: Text(label, style: const TextStyle(fontSize: 13.5))),
      tombol(Icons.remove, nilai > min, () => onUbah(nilai - 1)),
      SizedBox(
          width: 40,
          child: Text('$nilai',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700))),
      tombol(Icons.add, nilai < max, () => onUbah(nilai + 1)),
    ]);
  }

  Widget _bagianLampiran() {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      const Text('Foto lahan, denah lama, atau gambar referensi. Maksimal 3 gambar.',
          style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
      const SizedBox(height: 10),
      Wrap(spacing: 10, runSpacing: 10, children: [
        for (var i = 0; i < _lampiran.length; i++)
          Stack(children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(_lampiran[i], width: 84, height: 84, fit: BoxFit.cover),
            ),
            Positioned(
              right: 2,
              top: 2,
              child: GestureDetector(
                onTap: () => setState(() => _lampiran.removeAt(i)),
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                  child: const Icon(Icons.close, size: 14, color: Colors.white),
                ),
              ),
            ),
          ]),
        if (_lampiran.length < 3)
          InkWell(
            onTap: _tambahLampiran,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFC9BFAA), width: 1.5),
              ),
              child: const Icon(Icons.add_photo_alternate_outlined, color: AppColors.primary),
            ),
          ),
      ]),
    ]);
  }

  void _lihatKetentuan() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Ketentuan Sketsa Desain'),
        content: const SingleChildScrollView(
          child: Text(
              '1. Hasil berupa sketsa dalam file PDF, dikirim lewat aplikasi.\n\n'
              '2. Harga mengikuti luas lahan dan dibayar di muka.\n\n'
              '3. Pengerjaan dimulai setelah pembayaran diverifikasi admin. '
              'Target selesai 3 hari kerja, dengan batas toleransi sampai hari kerja ke-5.\n\n'
              '4. Tidak ada refund setelah pesanan dikerjakan.\n\n'
              '5. Kamu mendapat 1 kali revisi gratis, hanya untuk perubahan di dalam data yang sudah kamu isi. '
              'Permintaan baru di luar data awal dianggap pesanan baru.\n\n'
              '6. Jika data yang kamu isi tidak masuk akal atau kurang, arsitek dapat meminta data diperbaiki. '
              'Permintaan ini tidak memakai jatah revisi, dan pengerjaan dilanjutkan setelah datamu dilengkapi.\n\n'
              '7. Jika arsitek terlambat melewati batas, kamu mendapat voucher untuk pesanan berikutnya sebagai kompensasi.',
              style: TextStyle(fontSize: 13, height: 1.5)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Tutup')),
        ],
      ),
    );
  }

  Widget _barBawah() {
    final ada = _luasAngka > 0;
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          Expanded(
            child: Text(
                ada
                    ? 'Harga sketsa (lahan ${TarifSketsa.namaTingkat(_luasAngka)})'
                    : 'Harga sketsa mulai dari',
                style: const TextStyle(fontSize: 12.5, color: AppColors.textMuted)),
          ),
          Text(formatRupiah(ada ? _harga : TarifSketsa.hargaMulai),
              style: AppTheme.heading(19).copyWith(color: AppColors.primary)),
        ]),
        const SizedBox(height: 6),
        Row(children: [
          Checkbox(
            value: _setuju,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _setuju = v ?? false),
          ),
          Expanded(
            child: GestureDetector(
              onTap: _lihatKetentuan,
              child: const Text.rich(TextSpan(
                  style: TextStyle(fontSize: 12, color: AppColors.textDark),
                  children: [
                    TextSpan(text: 'Saya setuju dengan '),
                    TextSpan(
                        text: 'ketentuan sketsa',
                        style: TextStyle(
                            color: AppColors.primary,
                            decoration: TextDecoration.underline)),
                  ])),
            ),
          ),
        ]),
        FilledButton(
          onPressed: _mengirim ? null : _kirim,
          style: FilledButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
            backgroundColor: AppColors.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: _mengirim
              ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
              : const Text('Lanjut ke Pembayaran',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
        ),
      ]),
    );
  }
}
