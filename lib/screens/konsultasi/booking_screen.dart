import '../../services/promo_service.dart';
import '../../widgets/header_foto.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../config/status.dart';
import '../../data/arsitek_data.dart';
import '../../models/konsultasi.dart';
import '../../models/pengaturan.dart';
import '../../services/auth_service.dart';
import '../../services/konsultasi_service.dart';
import '../../models/ketersediaan.dart';
import '../../services/ketersediaan_service.dart';
import '../../services/pengaturan_service.dart';
import '../../theme/app_theme.dart';
import '../../utils/format.dart';
import '../../widgets/arsitek_foto.dart';
import 'riwayat_screen.dart';

const _hariPendek = ['Sen', 'Sel', 'Rab', 'Kam', 'Jum', 'Sab', 'Min'];
const _hariPanjang = [
  'Senin', 'Selasa', 'Rabu', 'Kamis', 'Jumat', 'Sabtu', 'Minggu'
];
const _bulanPendek = [
  'Jan', 'Feb', 'Mar', 'Apr', 'Mei', 'Jun',
  'Jul', 'Agu', 'Sep', 'Okt', 'Nov', 'Des'
];
const _bulanPanjang = [
  'Januari', 'Februari', 'Maret', 'April', 'Mei', 'Juni',
  'Juli', 'Agustus', 'September', 'Oktober', 'November', 'Desember'
];

const _gayaProyek = [
  'Minimalis Modern', 'Klasik', 'Skandinavia', 'Industrial', 'Tropis', 'Japandi'
];

String _kunciTanggal(DateTime d) =>
    '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

/// Booking konsultasi 3 langkah: Jadwal -> Proyek -> Review.
class BookingScreen extends StatefulWidget {
  final Arsitek arsitek;
  const BookingScreen({super.key, required this.arsitek});

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  int _langkah = 0; // 0 Jadwal, 1 Proyek, 2 Review

  // Langkah 1
  String _metode = 'online';
  late final List<DateTime> _hari;
  DateTime? _tanggal;
  String? _slot; // contoh "09:00-11:00"

  // Langkah 2
  final _luas = TextEditingController();
  final _budget = TextEditingController();
  final _catatan = TextEditingController();
  late String _gaya;

  // Langkah 3
  bool _setuju = false;
  bool _mengirim = false;

  Pengaturan _p = Pengaturan.bawaan;
  bool _gratis = false; // promo konsultasi pertama gratis
  Ketersediaan? _kt; // jadwal yang diatur arsitek
  String _namaUser = '';

  @override
  void initState() {
    super.initState();
    final mulai = DateTime.now().add(const Duration(days: 1)); // minimal H-1
    _hari = List.generate(
        14, (i) => DateTime(mulai.year, mulai.month, mulai.day + i));
    _gaya = _gayaProyek.contains(widget.arsitek.spesialis)
        ? widget.arsitek.spesialis
        : _gayaProyek.first;
    _muatData();
  }

  Future<void> _muatData() async {
    final p = await PengaturanService.ambil();
    final kt = await KetersediaanService.untuk(widget.arsitek.id, p);
    final profil = await AuthService().getUserProfile();
    final gratis = await PromoService.berhakKonsultasiGratis().first;
    if (!mounted) return;
    setState(() {
      _gratis = gratis;
      _p = p;
      _kt = kt;
      _namaUser = (profil?['nama'] as String?) ?? '';
      // pilih otomatis hari operasional pertama
      _tanggal ??= _hari.firstWhere(_hariBuka, orElse: () => _hari.first);
    });
  }

  @override
  void dispose() {
    _luas.dispose();
    _budget.dispose();
    _catatan.dispose();
    super.dispose();
  }

  bool _hariBuka(DateTime d) => _kt != null
      ? _kt!.hariBuka(d)
      : _p.hariOperasional.contains(d.weekday);

  String get _jamMulai => _slot!.split('-').first.trim();
  String get _jamSelesai => _slot!.split('-').last.trim();
  String get _slotTampil => '$_jamMulai – $_jamSelesai';

  void _pesan(String teks) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(teks)));
  }

  void _lanjut() {
    if (_langkah == 0) {
      if (_tanggal == null || _slot == null) {
        _pesan('Pilih tanggal dan jam dulu.');
        return;
      }
    } else if (_langkah == 1) {
      if (double.tryParse(_luas.text.replaceAll(',', '.').trim()) == null) {
        _pesan('Isi luas dengan angka, contoh 90.');
        return;
      }
      if (_budget.text.trim().isEmpty) {
        _pesan('Isi estimasi budget pembangunan.');
        return;
      }
    }
    FocusScope.of(context).unfocus();
    setState(() => _langkah++);
  }

  void _kembali() {
    if (_langkah == 0) {
      Navigator.pop(context);
    } else {
      setState(() => _langkah--);
    }
  }

  Future<void> _bayar() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _pesan('Sesi login habis. Masuk lagi dulu.');
      return;
    }
    setState(() => _mengirim = true);
    final a = widget.arsitek;
    final k = Konsultasi(
      id: '',
      userId: user.uid,
      userNama: _namaUser,
      arsitekId: a.id,
      arsitekNama: a.namaLengkap,
      spesialis: a.spesialis,
      tanggal: _kunciTanggal(_tanggal!),
      jam: _jamMulai,
      jamSelesai: _jamSelesai,
      metode: _metode,
      harga: _gratis ? 0 : _p.hargaKonsultasi,
      status: _gratis
          ? StatusKonsultasi.dikonfirmasi
          : StatusKonsultasi.menungguPembayaran,
      luas: _luas.text.trim(),
      budget: _budget.text.trim(),
      gaya: _gaya,
      catatan: _catatan.text.trim(),
      batasBayar:
          _gratis ? null : DateTime.now().add(Duration(hours: _p.batasBayarJam)),
    );
    try {
      await KonsultasiService.buatBooking(k);
      if (!mounted) return;
      final nav = Navigator.of(context);
      final messenger = ScaffoldMessenger.of(context);
      nav.popUntil((r) => r.isFirst);
      nav.push(MaterialPageRoute(builder: (_) => const RiwayatScreen()));
      messenger.showSnackBar(SnackBar(
        content: Text(_gratis
            ? 'Booking dikonfirmasi! Konsultasi pertamamu gratis.'
            : 'Booking dibuat. Selesaikan pembayaran dalam ${_p.batasBayarJam} jam.'),
      ));
    } on JadwalTerisi {
      if (!mounted) return;
      setState(() {
        _mengirim = false;
        _slot = null;
        _langkah = 0;
      });
      _pesan('Maaf, jam itu baru saja dipesan orang lain. Pilih jam lain.');
    } catch (e) {
      if (!mounted) return;
      setState(() => _mengirim = false);
      _pesan('Gagal membuat booking. Periksa koneksi dan coba lagi.');
    }
  }

  @override
  Widget build(BuildContext context) {
    const judul = ['Pilih Jadwal', 'Detail Proyek', 'Review Booking'];
    return PopScope(
      canPop: _langkah == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _kembali();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
        flexibleSpace: const HeaderFotoLatar(),
          backgroundColor: AppColors.background,
          elevation: 0,
          scrolledUnderElevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: AppColors.textDark),
            onPressed: _kembali,
          ),
          title: Text(judul[_langkah], style: AppTheme.heading(19)),
        ),
        body: Column(
          children: [
            _indikator(),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                children: [
                  _kartuArsitek(),
                  if (_langkah == 0) ..._langkahJadwal(),
                  if (_langkah == 1) ..._langkahProyek(),
                  if (_langkah == 2) ..._langkahReview(),
                ],
              ),
            ),
            _tombolBawah(),
          ],
        ),
      ),
    );
  }

  // ───────────────────────── umum ─────────────────────────

  Widget _indikator() {
    const nama = ['Jadwal', 'Proyek', 'Review'];
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Row(
        children: [
          for (int i = 0; i < 3; i++) ...[
            if (i > 0) const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 5,
                    decoration: BoxDecoration(
                      color: i <= _langkah
                          ? AppColors.primary
                          : AppColors.border,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    nama[i],
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight:
                      i == _langkah ? FontWeight.w700 : FontWeight.w500,
                      color: i <= _langkah
                          ? AppColors.primary
                          : AppColors.textMuted,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _kartuArsitek() {
    final a = widget.arsitek;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(children: [
        ArsitekFoto(
          arsitek: a,
          width: 54,
          height: 54,
          borderRadius: BorderRadius.circular(14),
          fontSize: 20,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(a.namaLengkap,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700)),
              const SizedBox(height: 2),
              Text('Arsitek ${a.spesialis}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textMuted)),
            ],
          ),
        ),
        const Icon(Icons.star_rounded, size: 16, color: Color(0xFFF5B301)),
        const SizedBox(width: 3),
        Text(a.rating.toStringAsFixed(1),
            style:
            const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
      ]),
    );
  }

  Widget _subjudul(String teks, {double atas = 24}) => Padding(
    padding: EdgeInsets.only(top: atas),
    child: Text(teks, style: AppTheme.heading(17)),
  );

  Widget _tombolBawah() {
    final terakhir = _langkah == 2;
    final aktif = !_mengirim && (!terakhir || _setuju);
    final label = terakhir
        ? (_gratis
            ? 'Konfirmasi Booking · GRATIS'
            : 'Bayar Sekarang · ${formatRupiah(_p.hargaKonsultasi)}')
        : (_langkah == 0 ? 'Lanjut ke Detail Proyek' : 'Lanjut ke Review');
    return Container(
      padding: EdgeInsets.fromLTRB(
          20, 12, 20, 12 + MediaQuery.of(context).padding.bottom * 0.5),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: FilledButton(
        onPressed: aktif ? (terakhir ? _bayar : _lanjut) : null,
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(52),
          backgroundColor: AppColors.primary,
          disabledBackgroundColor: AppColors.border,
          shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _mengirim
            ? const SizedBox(
          width: 22,
          height: 22,
          child: CircularProgressIndicator(
              strokeWidth: 2.5, color: Colors.white),
        )
            : Text(label,
            style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w600)),
      ),
    );
  }

  // ───────────────────── langkah 1: jadwal ─────────────────────

  List<Widget> _langkahJadwal() {
    final bulanTerpilih = _tanggal ?? _hari.first;
    return [
      _subjudul('Metode Konsultasi', atas: 22),
      const SizedBox(height: 12),
      _kartuMetode(
        'online',
        Icons.videocam_outlined,
        'Konsultasi Online',
        'Via Google Meet. Link aktif 15 menit sebelum sesi.',
      ),
      const SizedBox(height: 10),
      _kartuMetode(
        'studio',
        Icons.apartment,
        'Datang ke Studio',
        'RuangRancang Studio, Jakarta Selatan',
      ),
      Padding(
        padding: const EdgeInsets.only(top: 26),
        child: Row(children: [
          Expanded(child: Text('Pilih Tanggal', style: AppTheme.heading(17))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
                '${_bulanPanjang[bulanTerpilih.month - 1]} ${bulanTerpilih.year}',
                style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary)),
          ),
        ]),
      ),
      const SizedBox(height: 12),
      SizedBox(
        height: 106,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _hari.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (_, i) => _gelembungTanggal(_hari[i]),
        ),
      ),
      const SizedBox(height: 4),
      const Text('Pemesanan minimal H-1. Tanggal pudar = hari libur.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
      _subjudul('Pilih Jam'),
      const SizedBox(height: 12),
      if (_tanggal != null)
        StreamBuilder<Set<String>>(
          stream: KonsultasiService.jamTerisi(
              widget.arsitek.id, _kunciTanggal(_tanggal!)),
          builder: (context, snap) {
            final terisi = snap.data ?? <String>{};
            return Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                for (final s in (_kt?.slotJam ?? _p.slotJam))
                  _chipJam(s, terisi.contains(s.split('-').first.trim())),
              ],
            );
          },
        ),
      const SizedBox(height: 10),
      const Text('Jam yang dicoret sudah dipesan.',
          style: TextStyle(fontSize: 11.5, color: AppColors.textMuted)),
    ];
  }

  Widget _kartuMetode(
      String nilai, IconData ikon, String judul, String keterangan) {
    final dipilih = _metode == nilai;
    return GestureDetector(
      onTap: () => setState(() => _metode = nilai),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: dipilih
              ? AppColors.primary.withValues(alpha: 0.08)
              : AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
              color: dipilih ? AppColors.primary : AppColors.border,
              width: dipilih ? 1.5 : 1),
        ),
        child: Row(children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: dipilih ? AppColors.primary : AppColors.background,
              shape: BoxShape.circle,
            ),
            child: Icon(ikon,
                size: 22, color: dipilih ? Colors.white : AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(judul,
                    style: const TextStyle(
                        fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(keterangan,
                    style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textMuted)),
              ],
            ),
          ),
          Icon(dipilih ? Icons.radio_button_checked : Icons.radio_button_off,
              color: dipilih ? AppColors.primary : AppColors.border),
        ]),
      ),
    );
  }

  Widget _gelembungTanggal(DateTime d) {
    final buka = _hariBuka(d);
    final dipilih = _tanggal != null && _kunciTanggal(_tanggal!) == _kunciTanggal(d);
    return Opacity(
      opacity: buka ? 1 : 0.45,
      child: GestureDetector(
        onTap: buka
            ? () => setState(() {
          _tanggal = d;
          _slot = null; // jam harus dipilih ulang
        })
            : null,
        child: Container(
          width: 62,
          decoration: BoxDecoration(
            color: dipilih ? AppColors.primary : AppColors.surface,
            borderRadius: BorderRadius.circular(34),
            border: Border.all(
                color: dipilih ? AppColors.primary : AppColors.border),
            boxShadow: dipilih
                ? [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 6))
            ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(_hariPendek[d.weekday - 1],
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: dipilih ? Colors.white70 : AppColors.textMuted)),
              Container(
                width: 38,
                height: 38,
                margin: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: dipilih ? Colors.white : AppColors.background,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('${d.day}',
                    style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: dipilih ? AppColors.primary : AppColors.textDark)),
              ),
              Text(buka ? _bulanPendek[d.month - 1] : 'Libur',
                  style: TextStyle(
                      fontSize: 10.5,
                      color: dipilih ? Colors.white70 : AppColors.textMuted)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chipJam(String slot, bool terisi) {
    final dipilih = _slot == slot;
    final tampil = slot.split('-').map((e) => e.trim()).join(' – ');
    return GestureDetector(
      onTap: terisi ? null : () => setState(() => _slot = slot),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: dipilih
              ? AppColors.primary
              : (terisi
              ? AppColors.border.withValues(alpha: 0.5)
              : AppColors.surface),
          borderRadius: BorderRadius.circular(26),
          border: Border.all(
              color: dipilih ? AppColors.primary : AppColors.border),
        ),
        child: Text(
          tampil,
          style: TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: dipilih
                ? Colors.white
                : (terisi ? AppColors.textMuted : AppColors.textDark),
            decoration: terisi ? TextDecoration.lineThrough : null,
          ),
        ),
      ),
    );
  }

  // ───────────────────── langkah 2: proyek ─────────────────────

  List<Widget> _langkahProyek() {
    return [
      _subjudul('Ceritakan Proyekmu', atas: 22),
      const SizedBox(height: 12),
      _kolom(_luas, 'Luas lahan / bangunan (m²)',
          tipe: const TextInputType.numberWithOptions(decimal: true)),
      const SizedBox(height: 14),
      _kolom(_budget, 'Estimasi budget pembangunan, contoh Rp300 juta'),
      const Padding(
        padding: EdgeInsets.only(top: 22),
        child: Text('Gaya desain impian',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
      ),
      const SizedBox(height: 10),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final g in _gayaProyek)
            GestureDetector(
              onTap: () => setState(() => _gaya = g),
              child: Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: _gaya == g ? AppColors.primary : AppColors.surface,
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(
                      color:
                      _gaya == g ? AppColors.primary : AppColors.border),
                ),
                child: Text(g,
                    style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: _gaya == g ? Colors.white : AppColors.textDark)),
              ),
            ),
        ],
      ),
      const SizedBox(height: 22),
      _kolom(_catatan, 'Catatan tambahan (opsional)', baris: 4),
    ];
  }

  Widget _kolom(TextEditingController c, String label,
      {TextInputType? tipe, int baris = 1}) {
    return TextField(
      controller: c,
      keyboardType: tipe,
      minLines: baris,
      maxLines: baris == 1 ? 1 : baris + 2,
      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      decoration: InputDecoration(
        labelText: label,
        labelStyle:
        const TextStyle(fontSize: 13, color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.surface,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      ),
    );
  }

  // ───────────────────── langkah 3: review ─────────────────────

  List<Widget> _langkahReview() {
    final t = _tanggal!;
    final harga = _gratis ? 'GRATIS' : formatRupiah(_p.hargaKonsultasi);
    return [
      const SizedBox(height: 20),
      _kotakRingkas([
        ('Tanggal',
        '${_hariPanjang[t.weekday - 1]}, ${t.day} ${_bulanPanjang[t.month - 1]} ${t.year}'),
        ('Jam', '$_slotTampil WIB'),
        ('Metode',
        _metode == 'online' ? 'Online (Google Meet)' : 'Datang ke Studio'),
        ('Durasi', _p.durasiKonsultasi),
      ]),
      const SizedBox(height: 14),
      _kotakRingkas([
        ('Luas', '${_luas.text.trim()} m²'),
        ('Budget', _budget.text.trim()),
        ('Gaya', _gaya),
        if (_catatan.text.trim().isNotEmpty) ('Catatan', _catatan.text.trim()),
      ]),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.primary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(children: [
          Row(children: [
            const Expanded(
                child: Text('Biaya konsultasi',
                    style: TextStyle(fontSize: 13, color: Colors.white70))),
            Text(harga,
                style: const TextStyle(fontSize: 13, color: Colors.white)),
          ]),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1, color: Colors.white24),
          ),
          Row(children: [
            const Expanded(
                child: Text('Total bayar',
                    style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white))),
            Text(harga,
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
          ]),
        ]),
      ),
      const SizedBox(height: 14),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: const Color(0xFFFFF7ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Transfer dan unggah bukti dalam ${_p.batasBayarJam} jam. '
              'Kalau lewat, pesanan dibatalkan dan jadwal dibuka kembali.',
          style: const TextStyle(
              fontSize: 12.5, height: 1.5, color: Color(0xFF8A3F0B)),
        ),
      ),
      const SizedBox(height: 12),
      Container(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Expanded(
                  child: Text('Syarat refund & jadwal ulang',
                      style: TextStyle(
                          fontSize: 12.5, fontWeight: FontWeight.w700))),
              GestureDetector(
                onTap: _bacaSyarat,
                child: const Text('Baca lengkap',
                    style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary)),
              ),
            ]),
            const SizedBox(height: 4),
            const Text(
              'Batal lebih dari 24 jam: refund 100%. 6 sampai 24 jam: 50%. '
                  'Kurang dari 6 jam: tidak ada refund.',
              style: TextStyle(
                  fontSize: 11.5, height: 1.5, color: AppColors.textMuted),
            ),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: () => setState(() => _setuju = !_setuju),
              behavior: HitTestBehavior.opaque,
              child: Row(children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _setuju ? AppColors.primary : Colors.white,
                    borderRadius: BorderRadius.circular(7),
                    border: Border.all(
                        color: _setuju ? AppColors.primary : AppColors.border,
                        width: 2),
                  ),
                  child: _setuju
                      ? const Icon(Icons.check, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text('Saya sudah membaca dan menyetujui syarat ini',
                      style: TextStyle(fontSize: 12.5)),
                ),
              ]),
            ),
          ],
        ),
      ),
    ];
  }

  Widget _kotakRingkas(List<(String, String)> baris) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          for (int i = 0; i < baris.length; i++)
            Padding(
              padding: EdgeInsets.only(top: i == 0 ? 0 : 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 80,
                    child: Text(baris[i].$1,
                        style: const TextStyle(
                            fontSize: 13, color: AppColors.textMuted)),
                  ),
                  Expanded(
                    child: Text(baris[i].$2,
                        textAlign: TextAlign.right,
                        style: const TextStyle(
                            fontSize: 13.5, fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _bacaSyarat() {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        builder: (context, scroll) => ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          children: [
            Text('Syarat Refund & Jadwal Ulang', style: AppTheme.heading(20)),
            const SizedBox(height: 14),
            _barisSyarat('Batal lebih dari 24 jam sebelum sesi',
                'Refund 100%. Jadwal ulang gratis, 1 kali.'),
            _barisSyarat('Batal 6 sampai 24 jam sebelum sesi',
                'Refund 50%. Jadwal ulang 1 kali.'),
            _barisSyarat('Batal kurang dari 6 jam, atau tidak hadir',
                'Tidak ada refund dan tidak bisa jadwal ulang.'),
            _barisSyarat('Arsitek membatalkan atau tidak hadir',
                'Refund 100%, atau kamu boleh memilih arsitek lain.'),
            const SizedBox(height: 8),
            Text('Revisi hasil', style: AppTheme.heading(16)),
            const SizedBox(height: 8),
            const Text(
              'Satu putaran revisi sudah termasuk dalam biaya konsultasi dan '
                  'dapat diminta dalam 7 hari setelah hasil dikirim. Revisi '
                  'berikutnya dihitung sebagai konsultasi baru.',
              style: TextStyle(
                  fontSize: 13, height: 1.55, color: AppColors.textMuted),
            ),
            const SizedBox(height: 16),
            const Text(
              'Refund diproses admin dalam 1 sampai 3 hari kerja ke rekening '
                  'asal pembayaran.',
              style: TextStyle(
                  fontSize: 13, height: 1.55, color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _barisSyarat(String kondisi, String aturan) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(kondisi,
              style: const TextStyle(
                  fontSize: 13.5, fontWeight: FontWeight.w700)),
          const SizedBox(height: 4),
          Text(aturan,
              style: const TextStyle(
                  fontSize: 13, color: AppColors.textMuted)),
        ],
      ),
    ),
  );
}