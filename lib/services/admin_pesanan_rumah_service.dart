import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';
import '../models/pesanan_rumah.dart';
import 'notifikasi_service.dart';

/// Aksi admin untuk pesanan rumah (verifikasi booking fee).
class AdminPesananRumahService {
  AdminPesananRumahService._();

  static final _col = FirebaseFirestore.instance.collection(Koleksi.pesananRumah);

  static Stream<List<PesananRumah>> semua() => _col.snapshots().map((s) {
        final list = s.docs.map(PesananRumah.fromDoc).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  static Stream<DocumentSnapshot<Map<String, dynamic>>> mentah(String id) =>
      _col.doc(id).snapshots();

  static Future<void> setujui(PesananRumah p) async {
    await _col.doc(p.id).update({
      'status': StatusPesananRumah.disetujui,
      'alasanTolak': FieldValue.delete(),
      'diverifikasiAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'rumah',
      refId: p.id,
      judul: 'Booking fee terverifikasi',
      isi: 'Unit ${p.tipe} di ${p.perumahanNama} sudah tertahan untukmu. '
          'Tim kami akan menghubungimu.',
    );
  }

  static Future<void> tolak(PesananRumah p, String alasan) async {
    await _col.doc(p.id).update({
      'status': StatusPesananRumah.ditolak,
      'alasanTolak': alasan,
      'diverifikasiAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'rumah',
      refId: p.id,
      judul: 'Pembayaran booking ditolak',
      isi: alasan,
    );
  }
}
