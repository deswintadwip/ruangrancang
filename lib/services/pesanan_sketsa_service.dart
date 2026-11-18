import 'dart:async';
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
import 'status_berubah.dart';

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
    // Cegah pesanan dobel: masih ada pesanan ke arsitek yang sama yang
    // belum dibayar / sedang diverifikasi.
    final lama = await _col.where('userId', isEqualTo: uid).get();
    final dobel = lama.docs.any((d) {
      final m = d.data();
      return m['arsitekId'] == arsitekId &&
          (m['status'] == StatusSketsa.menungguPembayaran ||
              m['status'] == StatusSketsa.menungguVerifikasi);
    });
    if (dobel) {
      throw Exception('Kamu masih punya pesanan sketsa ke arsitek ini yang '
          'belum selesai dibayar. Selesaikan atau batalkan dulu di '
          '"Pesanan Sketsa".');
    }
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
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusSketsa.menungguPembayaran],
      ubah: (_) => {
        'status': StatusSketsa.menungguVerifikasi,
        'buktiBayar': base64Gambar,
        'buktiBayarAt': FieldValue.serverTimestamp(),
      },
    );
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
    return ubahBilaStatus(
      _col.doc(p.id),
      dari: oleh == 'sistem'
          ? [StatusSketsa.menungguPembayaran]
          : [StatusSketsa.menungguPembayaran, StatusSketsa.menungguVerifikasi],
      ubah: (_) => {
        'status': StatusSketsa.dibatalkan,
        'dibatalkanOleh': oleh,
        'alasanBatal': alasan,
        'dibatalkanAt': FieldValue.serverTimestamp(),
      },
    );
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
    yield* _untukArsitek(ids);
  }

  // Satu query per ID (UID dan profilId), digabung. Query terpisah dipilih
  // supaya Firestore Rules gampang membuktikan akses tiap query.
  static Stream<List<PesananSketsa>> _untukArsitek(List<String> ids) {
    final controller = StreamController<List<PesananSketsa>>();
    final hasil = <String, List<PesananSketsa>>{};
    final langganan =
        <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void kirim() {
      final semua = hasil.values
          .expand((e) => e)
          .where((p) =>
              p.status == StatusSketsa.dikerjakan ||
              p.status == StatusSketsa.selesai)
          .toList()
        ..sort(_urut);
      if (!controller.isClosed) controller.add(semua);
    }

    if (ids.isEmpty) controller.add(const []);
    for (final id in ids) {
      langganan.add(_col.where('arsitekId', isEqualTo: id).snapshots().listen(
        (snap) {
          hasil[id] = snap.docs.map(PesananSketsa.fromDoc).toList();
          kirim();
        },
        onError: (_) {
          hasil[id] = const [];
          kirim();
        },
      ));
    }
    controller.onCancel = () {
      for (final l in langganan) {
        l.cancel();
      }
    };
    return controller.stream;
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
    await FirebaseFirestore.instance.runTransaction((tx) async {
      final snap = await tx.get(_col.doc(p.id));
      final status = (snap.data() ?? {})['status'] as String? ?? '';
      if (status != StatusSketsa.dikerjakan) throw StatusBerubah(status);
      for (var i = 0; i < bagian.length; i++) {
        tx.set(sub.doc(i.toString().padLeft(3, '0')),
            {'urutan': i, 'data': bagian[i]});
      }
      tx.update(_col.doc(p.id), {
        'status': StatusSketsa.selesai,
        'hasilNama': nama,
        'hasilUkuran': bytes.length,
        'hasilBagian': bagian.length,
        'hasilAt': FieldValue.serverTimestamp(),
      });
    });
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Sketsamu sudah jadi',
      isi: '${p.arsitekNama} sudah mengirim hasil sketsa. '
          'Ketuk untuk melihat dan mengunduh PDF-nya.',
    );
  }

  /// Arsitek: minta klien melengkapi / memperbaiki data (mis. luas lahan
  /// tidak masuk akal). Pesanan tetap 'dikerjakan'; tidak memakai jatah revisi.
  static Future<void> mintaDataDiperbaiki(PesananSketsa p, String alasan) async {
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusSketsa.dikerjakan],
      ubah: (d) {
        if ((d.data() ?? {})['butuhData'] == true) {
          throw Exception('Permintaan data sudah dikirim, tunggu klien.');
        }
        return {
          'butuhData': true,
          'alasanMinta': alasan,
          'mintaDataAt': FieldValue.serverTimestamp(),
        };
      },
    );
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Arsitek butuh data tambahan',
      isi: '${p.arsitekNama} meminta datamu dilengkapi: $alasan',
    );
  }

  /// User: kirim data perbaikan sebagai jawaban atas permintaan arsitek.
  static Future<void> kirimPerbaikanData(PesananSketsa p, String teks) async {
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusSketsa.dikerjakan],
      ubah: (d) {
        if ((d.data() ?? {})['butuhData'] != true) {
          throw Exception('Tidak ada permintaan data dari arsitek.');
        }
        return {
          'butuhData': false,
          'dataPerbaikan': teks,
          'perbaikanAt': FieldValue.serverTimestamp(),
        };
      },
    );
    final uid = await _uidArsitek(p.arsitekId);
    if (uid != null) {
      NotifikasiService.kirim(
        userId: uid,
        type: 'sketsa',
        refId: p.id,
        judul: 'Klien sudah melengkapi data',
        isi: '${p.userNama} mengirim data perbaikan. Lanjutkan pengerjaan sketsa.',
      );
    }
  }

  /// User: ajukan revisi (jatah 1 kali, gratis). Hanya setelah hasil dikirim.
  static Future<void> mintaRevisi(PesananSketsa p, String alasan) async {
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusSketsa.selesai],
      ubah: (d) {
        if (((d.data() ?? {})['revisiDipakai'] as num? ?? 0) >= 1) {
          throw Exception('Jatah revisi sudah terpakai.');
        }
        return {
          'status': StatusSketsa.dikerjakan,
          'revisiDipakai': 1,
          'alasanRevisi': alasan,
          'revisiAt': FieldValue.serverTimestamp(),
        };
      },
    );
    final uid = await _uidArsitek(p.arsitekId);
    if (uid != null) {
      NotifikasiService.kirim(
        userId: uid,
        type: 'sketsa',
        refId: p.id,
        judul: 'Permintaan revisi sketsa',
        isi: '${p.userNama} meminta revisi: $alasan',
      );
    }
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
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusSketsa.menungguVerifikasi],
      ubah: (_) => {
        'status': StatusSketsa.dikerjakan,
        'alasanTolak': FieldValue.delete(),
        'diverifikasiAt': FieldValue.serverTimestamp(),
      },
    );
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
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusSketsa.menungguVerifikasi],
      ubah: (_) => {
        'status': StatusSketsa.menungguPembayaran,
        'alasanTolak': alasan,
        'buktiBayar': FieldValue.delete(),
        'batasBayar': Timestamp.fromDate(
            DateTime.now().add(Duration(hours: pg.batasBayarJam))),
      },
    );
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Bukti pembayaran perlu diunggah ulang',
      isi: alasan,
    );
  }

  static Future<void> tolak(PesananSketsa p, String alasan) async {
    await ubahBilaStatus(
      _col.doc(p.id),
      dari: [StatusSketsa.menungguVerifikasi],
      ubah: (_) => {
        'status': StatusSketsa.ditolak,
        'alasanTolak': alasan,
        'diverifikasiAt': FieldValue.serverTimestamp(),
      },
    );
    NotifikasiService.kirim(
      userId: p.userId,
      type: 'sketsa',
      refId: p.id,
      judul: 'Pembayaran sketsa ditolak',
      isi: alasan,
    );
  }
}
