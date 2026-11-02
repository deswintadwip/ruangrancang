import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../data/perumahan_data.dart';
import '../models/pesanan_rumah.dart';
import 'notifikasi_service.dart';
import 'pengaturan_service.dart';

/// Pesanan (booking fee) rumah milik user.
class PesananRumahService {
  PesananRumahService._();

  static final _col = FirebaseFirestore.instance.collection(Koleksi.pesananRumah);

  static Stream<List<PesananRumah>> milikSaya() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _col.where('userId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(PesananRumah.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      _batalkanYangKedaluwarsa(list);
      return list;
    });
  }

  static Stream<PesananRumah?> satu(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? PesananRumah.fromDoc(d) : null);

  /// Buat pesanan baru. Nilai booking fee & batas bayar diambil dari
  /// Pengaturan admin. Mengembalikan id pesanan.
  static Future<String> buat({
    required String userNama,
    required Perumahan perumahan,
    required TipeRumah tipe,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final p = await PengaturanService.ambil();
    final batas = DateTime.now().add(Duration(hours: p.batasBayarJam));
    final ref = await _col.add({
      'userId': uid,
      'userNama': userNama,
      'perumahanId': perumahan.id,
      'perumahanNama': perumahan.nama,
      'kota': perumahan.kota,
      'tipe': tipe.nama,
      'hargaUnit': tipe.harga,
      'bookingFee': p.bookingFeeRumah,
      'status': StatusPesananRumah.menungguPembayaran,
      'batasBayar': Timestamp.fromDate(batas),
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: uid,
      type: 'rumah',
      refId: ref.id,
      judul: 'Pesanan rumah dibuat',
      isi: '${perumahan.nama} · ${tipe.nama}. Bayar booking fee dalam '
          '${p.batasBayarJam} jam agar unitmu tertahan.',
    );
    return ref.id;
  }

  /// Unggah bukti transfer (base64) -> menunggu verifikasi admin.
  static Future<void> kirimBukti(PesananRumah p, String base64Gambar) async {
    await _col.doc(p.id).update({
      'status': StatusPesananRumah.menungguVerifikasi,
      'buktiBayar': base64Gambar,
      'buktiBayarAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'rumah',
      refId: p.id,
      judul: 'Bukti pembayaran terkirim',
      isi: 'Admin akan memverifikasi booking fee ${p.perumahanNama}, '
          'biasanya dalam 1 x 24 jam.',
    );
  }

  /// Batalkan pesanan yang belum dibayar.
  static Future<void> batalkan(PesananRumah p,
      {String oleh = 'user', String alasan = 'Dibatalkan sebelum pembayaran'}) {
    return _col.doc(p.id).update({
      'status': StatusPesananRumah.dibatalkan,
      'dibatalkanOleh': oleh,
      'alasanBatal': alasan,
      'dibatalkanAt': FieldValue.serverTimestamp(),
    });
  }

  /// Pesanan yang lewat batas bayar dibatalkan otomatis (tanpa Cloud
  /// Functions; terjadi saat user membuka daftar pesanannya).
  static void _batalkanYangKedaluwarsa(List<PesananRumah> list) {
    final sekarang = DateTime.now();
    for (final p in list) {
      final b = p.batasBayar;
      if (p.status == StatusPesananRumah.menungguPembayaran &&
          b != null &&
          b.isBefore(sekarang)) {
        batalkan(p, oleh: 'sistem', alasan: 'Melewati batas waktu pembayaran')
            .catchError((_) {});
      }
    }
  }
}
