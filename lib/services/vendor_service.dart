import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../models/permintaan_vendor.dart';
import 'notifikasi_service.dart';

/// Permintaan vendor milik user. Daftar vendor sendiri masih statis
/// (lihat data/vendor_data.dart).
class VendorService {
  VendorService._();

  static final _col =
      FirebaseFirestore.instance.collection(Koleksi.permintaanVendor);

  /// Permintaan milik user yang login, terbaru di atas.
  static Stream<List<PermintaanVendor>> milikSaya() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _col.where('userId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(PermintaanVendor.fromDoc).toList();
      list.sort((a, b) => (b.createdAt ?? DateTime.now())
          .compareTo(a.createdAt ?? DateTime.now()));
      return list;
    });
  }

  static Stream<PermintaanVendor?> satu(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? PermintaanVendor.fromDoc(d) : null);

  /// Kirim permintaan baru. Mengembalikan id dokumen.
  static Future<String> kirim({
    required String userNama,
    required String userWa,
    required String jenisPekerjaan,
    required String kota,
    required String anggaran,
    required String rencanaMulai,
    required String deskripsi,
    String linkDesain = '',
    String vendorDipilih = '',
    String vendorNamaDipilih = '',
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final ref = await _col.add({
      'userId': uid,
      'userNama': userNama,
      'userWa': userWa,
      'jenisPekerjaan': jenisPekerjaan,
      'kota': kota,
      'anggaran': anggaran,
      'rencanaMulai': rencanaMulai,
      'deskripsi': deskripsi,
      'linkDesain': linkDesain,
      'vendorDipilih': vendorDipilih,
      'vendorNamaDipilih': vendorNamaDipilih,
      'status': StatusPermintaanVendor.baru,
      'catatanAdmin': '',
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: uid,
      type: 'vendor',
      refId: ref.id,
      judul: 'Permintaan vendor terkirim',
      isi: 'Permintaan "$jenisPekerjaan" sedang ditinjau admin.',
    );
    return ref.id;
  }

  /// User menutup permintaan setelah vendor menghubungi (dihubungi -> selesai).
  static Future<void> tandaiSelesai(PermintaanVendor p) {
    return _col.doc(p.id).update({
      'status': StatusPermintaanVendor.selesai,
      'selesaiAt': FieldValue.serverTimestamp(),
    });
  }
}
