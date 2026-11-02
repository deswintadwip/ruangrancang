import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';
import '../config/tahap.dart';
import '../models/konsultasi.dart';
import '../models/update_progres.dart';
import 'notifikasi_service.dart';

/// Update progres kerja arsitek (subkoleksi `konsultasi/{id}/update`).
class UpdateService {
  UpdateService._();

  static CollectionReference<Map<String, dynamic>> _sub(String kid) =>
      FirebaseFirestore.instance
          .collection(Koleksi.konsultasi)
          .doc(kid)
          .collection('update');

  /// Semua update satu konsultasi (live), yang terbaru di atas.
  static Stream<List<UpdateProgres>> untuk(String kid) {
    return _sub(kid).snapshots().map((s) {
      final list = s.docs.map(UpdateProgres.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  /// Tambah update: catatan di subkoleksi + tahap/updatedAt di konsultasi
  /// (satu batch). Kalau [selesai], status jadi 'selesai' supaya klien
  /// bisa memberi ulasan. Klien diberi notifikasi.
  static Future<void> tambah(
      Konsultasi k, {
        required int tahap,
        required String catatan,
        bool selesai = false,
      }) async {
    final db = FirebaseFirestore.instance;
    final kRef = db.collection(Koleksi.konsultasi).doc(k.id);
    final batch = db.batch();
    batch.set(kRef.collection('update').doc(), {
      'tahap': tahap,
      'catatan': catatan,
      'arsitekId': k.arsitekId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    batch.update(kRef, {
      if (selesai) 'status': StatusKonsultasi.selesai,
      if (selesai) 'selesaiAt': FieldValue.serverTimestamp(),
      'tahap': tahap,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();

    if (selesai) {
      NotifikasiService.kirim(
        userId: k.userId,
        type: 'selesai',
        refId: k.id,
        judul: 'Konsultasi selesai',
        isi: 'Konsultasi dengan ${k.arsitekNama} sudah selesai. '
            'Yuk beri ulasan untuk membantu klien lain.',
      );
    } else {
      NotifikasiService.kirim(
        userId: k.userId,
        type: 'progres',
        refId: k.id,
        judul: 'Update: ${TahapKerja.namaTahap(tahap)}',
        isi: '${k.arsitekNama} memperbarui progres konsultasimu. $catatan',
      );
    }
  }

  /// Simpan link Google Meet untuk sesi online.
  static Future<void> simpanMeetLink(String kid, String link) {
    return FirebaseFirestore.instance
        .collection(Koleksi.konsultasi)
        .doc(kid)
        .update({
      'meetLink': link,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }
}