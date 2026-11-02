import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../models/ketersediaan.dart';
import '../models/pengaturan.dart';
import 'konsultasi_service.dart';

/// Ketersediaan arsitek, disimpan di dokumen `arsitek/{uid}`:
/// hariKerja (list int), slotJam (list string), cuti (list "yyyy-MM-dd").
class KetersediaanService {
  KetersediaanService._();

  static final _col = FirebaseFirestore.instance.collection(Koleksi.arsitek);

  /// Dipakai saat BOOKING (sisi user): cari dokumen arsitek dari ID yang
  /// dipakai di data contoh ("arsitek_01" = field `profilId`) atau UID.
  static Future<Ketersediaan> untuk(String idArsitek, Pengaturan p) async {
    try {
      final q =
      await _col.where('profilId', isEqualTo: idArsitek).limit(1).get();
      final data = q.docs.isNotEmpty
          ? q.docs.first.data()
          : (await _col.doc(idArsitek).get()).data();
      return Ketersediaan.dari(data, p);
    } catch (_) {
      return Ketersediaan.dari(null, p);
    }
  }

  static String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  /// Ketersediaan arsitek yang login (live).
  static Stream<Ketersediaan> saya(Pengaturan p) {
    final uid = _uid;
    if (uid == null) return Stream.value(Ketersediaan.dari(null, p));
    return _col.doc(uid).snapshots().map((d) => Ketersediaan.dari(d.data(), p));
  }

  static Future<void> simpanJadwal({
    required List<int> hariKerja,
    required List<String> slotJam,
  }) {
    return _col.doc(_uid).update({'hariKerja': hariKerja, 'slotJam': slotJam});
  }

  /// Tambah tanggal cuti. Ditolak (mengembalikan pesan) kalau di tanggal itu
  /// masih ada sesi yang sudah dikonfirmasi.
  static Future<String?> tambahCuti(DateTime tanggal) async {
    final kunci = Ketersediaan.kunci(tanggal);
    final semua = await KonsultasiService.milikArsitekSaya().first;
    final bentrok = semua.any(
            (k) => k.tanggal == kunci && k.status == StatusKonsultasi.dikonfirmasi);
    if (bentrok) {
      return 'Ada sesi terkonfirmasi di tanggal itu. Jadwal ulang atau '
          'batalkan sesinya dulu.';
    }
    await _col.doc(_uid).update({
      'cuti': FieldValue.arrayUnion([kunci])
    });
    return null;
  }

  static Future<void> hapusCuti(String kunci) {
    return _col.doc(_uid).update({
      'cuti': FieldValue.arrayRemove([kunci])
    });
  }
}