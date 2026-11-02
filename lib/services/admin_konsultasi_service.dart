import 'package:cloud_firestore/cloud_firestore.dart';
import '../config/status.dart';
import '../models/konsultasi.dart';
import 'notifikasi_service.dart';
import 'pengaturan_service.dart';

/// Aksi admin untuk konsultasi: verifikasi pembayaran, tolak, batalkan, refund.
/// Dijaga oleh Rules (admin boleh mengubah semua field konsultasi).
class AdminKonsultasiService {
  AdminKonsultasiService._();

  static final _db = FirebaseFirestore.instance;
  static final _col = _db.collection(Koleksi.konsultasi);

  /// Semua konsultasi, terbaru di atas (diurutkan di aplikasi).
  static Stream<List<Konsultasi>> semua() => _col.snapshots().map((s) {
        final list = s.docs.map(Konsultasi.fromDoc).toList();
        list.sort((a, b) => (b.createdAt ?? DateTime.now())
            .compareTo(a.createdAt ?? DateTime.now()));
        return list;
      });

  /// Dokumen mentah (untuk field yang tidak ada di model, misalnya buktiBayar).
  static Stream<DocumentSnapshot<Map<String, dynamic>>> mentah(String id) =>
      _col.doc(id).snapshots();

  static DocumentReference<Map<String, dynamic>> _slot(Konsultasi k) =>
      _db.collection(Koleksi.jadwal).doc('${k.arsitekId}_${k.tanggal}_${k.jam}');

  /// arsitekId bisa berupa UID atau id contoh ("arsitek_01") yang disimpan
  /// di field profilId pada dokumen arsitek/{uid}.
  static Future<String?> _uidArsitek(String arsitekId) async {
    try {
      final col = FirebaseFirestore.instance.collection(Koleksi.arsitek);
      final d = await col.doc(arsitekId).get();
      if (d.exists) return d.id;
      final q = await col.where('profilId', isEqualTo: arsitekId).limit(1).get();
      return q.docs.isEmpty ? null : q.docs.first.id;
    } catch (_) {
      return null;
    }
  }

  static Future<void> _notifArsitek(Konsultasi k,
      {required String type, required String judul, required String isi}) async {
    final uid = await _uidArsitek(k.arsitekId);
    if (uid == null) return;
    NotifikasiService.kirim(
        userId: uid, type: type, refId: k.id, judul: judul, isi: isi);
  }

  /// Bukti valid -> dikonfirmasi. User dan arsitek diberi tahu.
  static Future<void> setujui(Konsultasi k) async {
    await _col.doc(k.id).update({
      'status': StatusKonsultasi.dikonfirmasi,
      'alasanTolak': FieldValue.delete(),
      'diverifikasiAt': FieldValue.serverTimestamp(),
      'tahap': 1,
      'updatedAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: k.userId,
      type: 'pembayaran',
      refId: k.id,
      judul: 'Pembayaran terverifikasi',
      isi: 'Jadwal konsultasi dengan ${k.arsitekNama} (${k.tanggal}, ${k.jam}) '
          'sudah dikonfirmasi.',
    );
    await _notifArsitek(k,
        type: 'booking',
        judul: 'Konsultasi baru dikonfirmasi',
        isi: '${k.userNama} · ${k.tanggal}, ${k.jam}.');
  }

  /// Bukti kurang jelas / salah: user diminta mengunggah ulang.
  /// Status kembali ke menunggu_pembayaran dengan batas bayar baru.
  static Future<void> mintaUnggahUlang(Konsultasi k, String alasan) async {
    final p = await PengaturanService.ambil();
    final batas = DateTime.now().add(Duration(hours: p.batasBayarJam));
    await _col.doc(k.id).update({
      'status': StatusKonsultasi.menungguPembayaran,
      'alasanTolak': alasan,
      'buktiBayar': FieldValue.delete(),
      'batasBayar': Timestamp.fromDate(batas),
    });
    NotifikasiService.kirim(
      userId: k.userId,
      type: 'pembayaran',
      refId: k.id,
      judul: 'Bukti pembayaran perlu diunggah ulang',
      isi: alasan,
    );
  }

  /// Tolak permanen: status ditolak dan slot jadwal dilepas.
  static Future<void> tolakPermanen(Konsultasi k, String alasan) async {
    final batch = _db.batch();
    batch.update(_col.doc(k.id), {
      'status': StatusKonsultasi.ditolak,
      'alasanTolak': alasan,
      'diverifikasiAt': FieldValue.serverTimestamp(),
    });
    batch.delete(_slot(k));
    await batch.commit();
    NotifikasiService.kirim(
      userId: k.userId,
      type: 'batal',
      refId: k.id,
      judul: 'Pembayaran ditolak',
      isi: alasan,
    );
  }

  /// Persen refund kalau admin yang membatalkan: 100% bila sudah ada
  /// pembayaran yang masuk, 0% bila belum membayar.
  static int persenRefundAdmin(Konsultasi k) =>
      k.status == StatusKonsultasi.menungguPembayaran ? 0 : 100;

  /// Admin membatalkan konsultasi aktif. Slot dilepas, refund dicatat.
  static Future<void> batalkan(Konsultasi k, String alasan) async {
    final persen = persenRefundAdmin(k);
    final nominal = k.harga * persen ~/ 100;
    final batch = _db.batch();
    batch.update(_col.doc(k.id), {
      'status': StatusKonsultasi.dibatalkan,
      'dibatalkanOleh': 'admin',
      'dibatalkanAt': FieldValue.serverTimestamp(),
      'alasanBatal': alasan,
      'refundPersen': persen,
      'refundNominal': nominal,
      'refundStatus': nominal > 0 ? 'diproses' : 'tidak_ada',
    });
    batch.delete(_slot(k));
    await batch.commit();
    NotifikasiService.kirim(
      userId: k.userId,
      type: nominal > 0 ? 'refund' : 'batal',
      refId: k.id,
      judul: 'Konsultasi dibatalkan admin',
      isi: nominal > 0
          ? '$alasan. Refund $persen% sedang diproses, estimasi 1 sampai 3 hari kerja.'
          : alasan,
    );
    await _notifArsitek(k,
        type: 'batal',
        judul: 'Konsultasi dibatalkan admin',
        isi: '${k.userNama} · ${k.tanggal}, ${k.jam}. $alasan');
  }

  /// Dana sudah dikembalikan ke user.
  static Future<void> tandaiRefundSelesai(Konsultasi k, String catatan) async {
    await _col.doc(k.id).update({
      'refundStatus': 'selesai',
      'refundSelesaiAt': FieldValue.serverTimestamp(),
      'catatanRefund': catatan,
    });
    NotifikasiService.kirim(
      userId: k.userId,
      type: 'refund',
      refId: k.id,
      judul: 'Refund selesai',
      isi: 'Dana refund sudah dikirim. ${catatan.isEmpty ? '' : catatan}',
    );
  }
}
