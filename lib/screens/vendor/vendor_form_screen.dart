import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../data/vendor_data.dart';
import '../../services/auth_service.dart';
import '../../services/vendor_service.dart';
import '../../theme/app_theme.dart';
import 'vendor_terkirim_screen.dart';

const _bulan = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];

/// Form "Hubungi Vendor". Admin yang meneruskan ke vendor.
class VendorFormScreen extends StatefulWidget {
  final Vendor? vendor;
  const VendorFormScreen({super.key, this.vendor});

  @override
  State<VendorFormScreen> createState() => _VendorFormScreenState();
}

class _VendorFormScreenState extends State<VendorFormScreen> {
  final _kota = TextEditingController();
  final _deskripsi = TextEditingController();
  final _link = TextEditingController();
  final _wa = TextEditingController();
  String _nama = '';
  late String _jenis;
  String _anggaran = DataVendor.anggaran[1];
  DateTime? _mulai;
  bool _setuju = true;
  bool _mengirim = false;

  @override
  void initState() {
    super.initState();
    _jenis = _jenisAwal(widget.vendor?.jenis);
    _isiProfil();
  }

  static String _jenisAwal(String? kategori) {
    switch (kategori) {
      case 'Interior':
        return 'Interior & furnitur';
      case 'Atap':
        return 'Atap & waterproofing';
      case 'Listrik':
        return 'Instalasi listrik';
      case 'Plumbing':
        return 'Plumbing & sanitasi';
      default:
        return 'Bangun rumah baru';
    }
  }

  Future<void> _isiProfil() async {
    final p = await AuthService().getUserProfile();
    if (!mounted || p == null) return;
    setState(() {
      _nama = p['nama'] as String? ?? '';
      _wa.text = (p['noHp'] as String? ?? '').replaceFirst(RegExp(r'^0+'), '');
    });
  }

  @override
  void dispose() {
    _kota.dispose();
    _deskripsi.dispose();
    _link.dispose();
    _wa.dispose();
    super.dispose();
  }

  void _pesan(String t) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(t)));

  Future<void> _pilihBulan() async {
    final sekarang = DateTime.now();
    final d = await showDatePicker(
      context: context,
      initialDate: _mulai ?? sekarang.add(const Duration(days: 30)),
      firstDate: sekarang,
      lastDate: DateTime(sekarang.year + 3),
      helpText: 'Rencana mulai pengerjaan',
    );
    if (d != null) setState(() => _mulai = d);
  }

  Future<void> _kirim() async {
    final kota = _kota.text.trim();
    final isi = _deskripsi.text.trim();
    final link = _link.text.trim();
    final wa = _wa.text.replaceAll(RegExp(r'\D'), '').replaceFirst(RegExp(r'^0+'), '');
    if (kota.isEmpty) return _pesan('Isi lokasi proyek dulu.');
    if (_mulai == null) return _pesan('Pilih rencana mulai pengerjaan.');
    if (isi.length < 15) return _pesan('Ceritakan kebutuhanmu minimal 15 karakter.');
    if (link.isNotEmpty && !(link.startsWith('http://') || link.startsWith('https://'))) {
      return _pesan('Link harus diawali https://');
    }
    if (wa.length < 9) return _pesan('Nomor WhatsApp belum benar.');
    if (!_setuju) return _pesan('Centang persetujuan berbagi kontak dulu.');

    setState(() => _mengirim = true);
    try {
      final id = await VendorService.kirim(
        userNama: _nama,
        userWa: '62$wa',
        jenisPekerjaan: _jenis,
        kota: kota,
        anggaran: _anggaran,
        rencanaMulai: '${_bulan[_mulai!.month - 1]} ${_mulai!.year}',
        deskripsi: isi,
        linkDesain: link,
        vendorDipilih: widget.vendor?.id ?? '',
        vendorNamaDipilih: widget.vendor?.nama ?? '',
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => VendorTerkirimScreen(permintaanId: id)),
      );
    } catch (e) {
      debugPrint('KIRIM PERMINTAAN VENDOR ERROR: $e');
      if (!mounted) return;
      setState(() => _mengirim = false);
      _pesan('Gagal mengirim permintaan. Coba lagi.');
    }
  }

  Widget _label(String t, {String? tambahan}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text.rich(TextSpan(
          text: t,
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          children: [
            if (tambahan != null)
              TextSpan(
                  text: ' $tambahan',
                  style: const TextStyle(
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted)),
          ],
        )),
      );

  Widget _pilihanChip(List<String> opsi, String aktif, ValueChanged<String> pilih) {
    return Wrap(spacing: 8, runSpacing: 8, children: [
      for (final o in opsi)
        ChoiceChip(
          label: Text(o),
          selected: aktif == o,
          onSelected: (_) => pilih(o),
          showCheckmark: false,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          side: BorderSide(
              color: aktif == o ? AppColors.primary : AppColors.border),
          labelStyle: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w500,
              color: aktif == o ? Colors.white : AppColors.textDark),
        ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final v = widget.vendor;
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Text('Hubungi Vendor', style: AppTheme.heading(21)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
              children: [
                if (v != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: AppColors.sageMuda,
                        borderRadius: BorderRadius.circular(16)),
                    child: Row(children: [
                      Container(
                        width: 44,
                        height: 44,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                            color: v.warna,
                            borderRadius: BorderRadius.circular(12)),
                        child: Text(v.inisial,
                            style: AppTheme.heading(20)
                                .copyWith(color: AppColors.surface)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(v.nama,
                                style: const TextStyle(
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w600)),
                            Text('${v.jenisLengkap} · ${v.kota}',
                                style: const TextStyle(
                                    fontSize: 11.5, color: AppColors.primary)),
                          ],
                        ),
                      ),
                    ]),
                  ),
                const SizedBox(height: 18),
                _label('Jenis pekerjaan'),
                _pilihanChip(DataVendor.jenisPekerjaan, _jenis,
                    (o) => setState(() => _jenis = o)),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Lokasi proyek'),
                          TextField(
                              controller: _kota,
                              textCapitalization: TextCapitalization.words,
                              decoration:
                                  const InputDecoration(hintText: 'Depok')),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Rencana mulai'),
                          InkWell(
                            onTap: _pilihBulan,
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              height: 52,
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 16),
                              alignment: Alignment.centerLeft,
                              decoration: BoxDecoration(
                                color: AppColors.surface,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: AppColors.border),
                              ),
                              child: Text(
                                _mulai == null
                                    ? 'Pilih bulan'
                                    : '${_bulan[_mulai!.month - 1]} ${_mulai!.year}',
                                style: TextStyle(
                                    fontSize: 14,
                                    color: _mulai == null
                                        ? AppColors.textMuted
                                        : AppColors.textDark),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),
                _label('Perkiraan anggaran'),
                _pilihanChip(DataVendor.anggaran, _anggaran,
                    (o) => setState(() => _anggaran = o)),
                const SizedBox(height: 18),
                _label('Ceritakan kebutuhanmu'),
                TextField(
                  controller: _deskripsi,
                  minLines: 4,
                  maxLines: 7,
                  maxLength: 500,
                  decoration: const InputDecoration(
                      hintText:
                          'Contoh: rumah 2 lantai di lahan 90 m², butuh RAB dan jadwal pengerjaan.'),
                ),
                const SizedBox(height: 10),
                _label('Link denah atau desain', tambahan: '(opsional)'),
                TextField(
                  controller: _link,
                  keyboardType: TextInputType.url,
                  decoration: const InputDecoration(
                      hintText: 'https://drive.google.com/...'),
                ),
                const SizedBox(height: 18),
                _label('Nomor WhatsApp'),
                TextField(
                  controller: _wa,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(
                      prefixText: '+62 ', hintText: '81234567890'),
                ),
                const SizedBox(height: 14),
                InkWell(
                  onTap: () => setState(() => _setuju = !_setuju),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _setuju,
                        activeColor: AppColors.primary,
                        onChanged: (v) => setState(() => _setuju = v ?? false),
                      ),
                      const Expanded(
                        child: Padding(
                          padding: EdgeInsets.only(top: 12),
                          child: Text(
                              'Saya setuju nama dan nomor WhatsApp saya dibagikan kepada vendor yang dipilih admin.',
                              style: TextStyle(fontSize: 12, height: 1.55)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.fromLTRB(
                20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.border)),
            ),
            child: ElevatedButton(
              onPressed: _mengirim ? null : _kirim,
              child: _mengirim
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: Colors.white))
                  : const Text('Kirim Permintaan'),
            ),
          ),
        ],
      ),
    );
  }
}
