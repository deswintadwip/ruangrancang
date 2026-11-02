import 'dart:convert';
import 'dart:math';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../models/pesanan_sketsa.dart';
import 'arsitek_service.dart';
import 'notifikasi_service.dart';
import 'pengaturan_service.dart';

/// Semua aksi pesanan sketsa: user (pesan & bayar), arsitek (kirim hasil
/// PDF), dan admin (verifikasi pembayaran).
class PesananSketsaService {
  PesananSketsaService._();

  static final _col =
      FirebaseFirestore.instance.collection(Koleksi.pesananSketsa);

  /// Ukuran maksimal file hasil (PDF).
  static const batasUkuranHasil = 3 * 1024 * 1024;
  static const _panjangBagian = 600000; // karakter base64 per dokumen

  static int _urut(PesananSketsa a, PesananSketsa b) =>
      (b.createdAt ?? DateTime.now()).compareTo(a.createdAt ?? DateTime.now());

  // ───────────────────────── USER ─────────────────────────

  static Stream<List<PesananSketsa>> milikSaya() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _col.where('userId', isEqualTo: uid).snapshots().map((s) {
      final list = s.docs.map(PesananSketsa.fromDoc).toList()..sort(_urut);
      _batalkanYangKedaluwarsa(list);
      return list;
    });
  }

  static Stream<PesananSketsa?> satu(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? PesananSketsa.fromDoc(d) : null);

  /// Buat pesanan baru. Mengembalikan id pesanan.
  static Future<String> buat({
    required String userNama,
    required String arsitekId,
    required String arsitekNama,
    required int harga,
    required Map<String, dynamic> isi,
  }) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;
    final p = await PengaturanService.ambil();
    final batas = DateTime.now().add(Duration(hours: p.batasBayarJam));
    final ref = await _col.add({
      ...isi,
      'userId': uid,
      'userNama': userNama,
      'arsitekId': arsitekId,
      'arsitekNama': arsitekNama,
      'harga': harga,
      'status': StatusSketsa.menungguPembayaran,
      'batasBayar': Timestamp.fromDate(batas),
      'createdAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: uid,
      type: 'sketsa',
      refId: ref.id,
      judul: 'Pesanan sketsa dibuat',
      isi: 'Sketsa desain oleh $arsitekNama. Bayar dalam '
          '${p.batasBayarJam} jam agar pesananmu diproses.',
    );
    return ref.id;
  }

  static Future<void> kirimBukti(PesananSketsa p, String base64Gambar) async {
    await _col.doc(p.id).update({
      'status': StatusSketsa.menungguVerifikasi,
      'buktiBayar': base64Gambar,
      'buktiBayarAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Bukti pembayaran terkirim',
      isi: 'Admin akan memverifikasi pembayaran sketsamu, biasanya dalam '
          '1 x 24 jam.',
    );
  }

  static Future<void> batalkan(PesananSketsa p,
      {String oleh = 'user', String alasan = 'Dibatalkan sebelum pembayaran'}) {
    return _col.doc(p.id).update({
      'status': StatusSketsa.dibatalkan,
      'dibatalkanOleh': oleh,
      'alasanBatal': alasan,
      'dibatalkanAt': FieldValue.serverTimestamp(),
    });
  }

  static void _batalkanYangKedaluwarsa(List<PesananSketsa> list) {
    final sekarang = DateTime.now();
    for (final p in list) {
      final b = p.batasBayar;
      if (p.status == StatusSketsa.menungguPembayaran &&
          b != null &&
          b.isBefore(sekarang)) {
        batalkan(p, oleh: 'sistem', alasan: 'Melewati batas waktu pembayaran')
            .catchError((_) {});
      }
    }
  }

  // ───────────────────────── ARSITEK ─────────────────────────

  /// Pesanan sketsa yang ditugaskan ke arsitek yang sedang login
  /// (hanya yang sudah dibayar: dikerjakan / selesai).
  static Stream<List<PesananSketsa>> untukSaya() async* {
    final ids = await ArsitekService.idSaya();
    if (ids.isEmpty) {
      yield const [];
      return;
    }
    yield* _col.where('arsitekId', whereIn: ids).snapshots().map((s) {
      final list = s.docs
          .map(PesananSketsa.fromDoc)
          .where((p) =>
              p.status == StatusSketsa.dikerjakan ||
              p.status == StatusSketsa.selesai)
          .toList()
        ..sort(_urut);
      return list;
    });
  }

  /// Kirim hasil sketsa (PDF). Dipecah supaya muat di batas dokumen Firestore.
  static Future<void> kirimHasil(
      PesananSketsa p, Uint8List bytes, String nama) async {
    if (bytes.length > batasUkuranHasil) {
      throw Exception('Ukuran file maksimal 3 MB.');
    }
    final b64 = base64Encode(bytes);
    final bagian = <String>[];
    for (var i = 0; i < b64.length; i += _panjangBagian) {
      bagian.add(b64.substring(i, min(i + _panjangBagian, b64.length)));
    }
    final sub = _col.doc(p.id).collection('hasil');
    final batch = FirebaseFirestore.instance.batch();
    for (var i = 0; i < bagian.length; i++) {
      batch.set(sub.doc(i.toString().padLeft(3, '0')),
          {'urutan': i, 'data': bagian[i]});
    }
    batch.update(_col.doc(p.id), {
      'status': StatusSketsa.selesai,
      'hasilNama': nama,
      'hasilUkuran': bytes.length,
      'hasilBagian': bagian.length,
      'hasilAt': FieldValue.serverTimestamp(),
    });
    await batch.commit();
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Sketsamu sudah jadi',
      isi: '${p.arsitekNama} sudah mengirim hasil sketsa. '
          'Ketuk untuk melihat dan mengunduh PDF-nya.',
    );
  }

  /// Ambil isi file hasil (PDF).
  static Future<Uint8List> ambilHasil(PesananSketsa p) async {
    final s = await _col.doc(p.id).collection('hasil').orderBy('urutan').get();
    final sb = StringBuffer();
    for (final d in s.docs.take(p.hasilBagian)) {
      sb.write(d.data()['data'] as String? ?? '');
    }
    return base64Decode(sb.toString());
  }

  // ───────────────────────── ADMIN ─────────────────────────

  static Stream<List<PesananSketsa>> semua() => _col.snapshots().map((s) {
        return s.docs.map(PesananSketsa.fromDoc).toList()..sort(_urut);
      });

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

  static Future<void> setujui(PesananSketsa p) async {
    await _col.doc(p.id).update({
      'status': StatusSketsa.dikerjakan,
      'alasanTolak': FieldValue.delete(),
      'diverifikasiAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Pembayaran sketsa terverifikasi',
      isi: '${p.arsitekNama} mulai mengerjakan sketsamu. '
          'Hasilnya akan muncul di sini dalam bentuk PDF.',
    );
    final uid = await _uidArsitek(p.arsitekId);
    if (uid != null) {
      NotifikasiService.kirim(
        userId: uid,
        type: 'sketsa',
        refId: p.id,
        judul: 'Pesanan sketsa baru',
        isi: '${p.userNama} memesan sketsa untuk lahan ${p.luasLahan} m². '
            'Ketuk untuk melihat detail dan mengirim hasil.',
      );
    }
  }

  static Future<void> mintaUnggahUlang(PesananSketsa p, String alasan) async {
    final pg = await PengaturanService.ambil();
    await _col.doc(p.id).update({
      'status': StatusSketsa.menungguPembayaran,
      'alasanTolak': alasan,
      'buktiBayar': FieldValue.delete(),
      'batasBayar':
          Timestamp.fromDate(DateTime.now().add(Duration(hours: pg.batasBayarJam))),
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Bukti pembayaran perlu diunggah ulang',
      isi: alasan,
    );
  }

  static Future<void> tolak(PesananSketsa p, String alasan) async {
    await _col.doc(p.id).update({
      'status': StatusSketsa.ditolak,
      'alasanTolak': alasan,
      'diverifikasiAt': FieldValue.serverTimestamp(),
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Pembayaran sketsa ditolak',
      isi: alasan,
    );
  }
}
