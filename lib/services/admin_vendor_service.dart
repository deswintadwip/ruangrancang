import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';
import '../data/vendor_data.dart';
import '../models/permintaan_vendor.dart';
import 'notifikasi_service.dart';
import 'status_berubah.dart';

/// Aksi admin untuk permintaan vendor.
class AdminVendorService {
  AdminVendorService._();

  static final _col =
      FirebaseFirestore.instance.collection(Koleksi.permintaanVendor);

  static Stream<List<PermintaanVendor>> semua() => _col.snapshots().map((s) {
        final list = s.docs.map(PermintaanVendor.fromDoc).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  static Stream<PermintaanVendor?> satu(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? PermintaanVendor.fromDoc(d) : null);

  static Future<void> _notif(PermintaanVendor p, String judul, String isi) =>
      NotifikasiService.kirim(
          userId: p.userId, type: 'vendor', refId: p.id, judul: judul, isi: isi);

  static Future<void> teruskan(
      PermintaanVendor p, Vendor vendor, String catatan) async {
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusPermintaanVendor.baru, StatusPermintaanVendor.diteruskan],
      ubah: (_) => {
        'status': StatusPermintaanVendor.diteruskan,
        'vendorId': vendor.id,
        'vendorNama': vendor.nama,
        'catatanAdmin': catatan,
        'diteruskanAt': FieldValue.serverTimestamp(),
      },
    );
    await _notif(p, 'Permintaan diteruskan ke vendor',
        '"${p.jenisPekerjaan}" diteruskan ke ${vendor.nama}. Vendor akan menghubungimu lewat WhatsApp.');
  }

  static Future<void> tandaiDihubungi(PermintaanVendor p) async {
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusPermintaanVendor.diteruskan],
      ubah: (_) => {
        'status': StatusPermintaanVendor.dihubungi,
        'dihubungiAt': FieldValue.serverTimestamp(),
      },
    );
    await _notif(p, 'Vendor sudah menghubungimu',
        '${p.vendorNama} sudah menghubungimu. Cek WhatsApp-mu.');
  }

  static Future<void> tandaiSelesai(PermintaanVendor p) async {
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusPermintaanVendor.diteruskan, StatusPermintaanVendor.dihubungi],
      ubah: (_) => {
        'status': StatusPermintaanVendor.selesai,
        'selesaiAt': FieldValue.serverTimestamp(),
      },
    );
    await _notif(p, 'Permintaan vendor selesai',
        'Permintaan "${p.jenisPekerjaan}" sudah ditutup.');
  }
}
