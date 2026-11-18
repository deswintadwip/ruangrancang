import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../config/status.dart';
import '../models/konsultasi.dart';
import 'arsitek_service.dart';
import 'notifikasi_service.dart';
import 'status_berubah.dart';

class KonsultasiService {
  KonsultasiService._();

  static final _col =
  FirebaseFirestore.instance.collection(Koleksi.konsultasi);

  /// Semua konsultasi milik user yang sedang login (live).
  /// Diurutkan di sisi aplikasi supaya tidak butuh index Firestore.
  static Stream<List<Konsultasi>> milikSaya() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return Stream.value(const []);
    return _col.where('userId', isEqualTo: uid).snapshots().map((snap) {
      final list = snap.docs.map(Konsultasi.fromDoc).toList();
      _batalkanYangKedaluwarsa(list);
      list.sort((a, b) {
        final x = a.mulai, y = b.mulai;
        if (x == null || y == null) return 0;
        return x.compareTo(y);
      });
      return list;
    });
  }

  /// Konsultasi yang ditugaskan ke arsitek yang sedang login (live).
  static Stream<List<Konsultasi>> milikArsitekSaya() async* {
    final ids = await ArsitekService.idSaya();
    yield* _untukArsitek(ids);
  }

  // Satu query per ID (UID dan profilId), hasilnya digabung. Query terpisah
  // dipilih supaya Firestore rules gampang membuktikan akses tiap query.
  static Stream<List<Konsultasi>> _untukArsitek(List<String> ids) {
    final controller = StreamController<List<Konsultasi>>();
    final hasil = <String, List<Konsultasi>>{};
    final langganan = <StreamSubscription<QuerySnapshot<Map<String, dynamic>>>>[];

    void kirim() {
      final semua = hasil.values.expand((e) => e).toList();
      semua.sort((a, b) {
        final x = a.mulai, y = b.mulai;
        if (x == null || y == null) return 0;
        return x.compareTo(y);
      });
      if (!controller.isClosed) controller.add(semua);
    }

    if (ids.isEmpty) {
      controller.add(const []);
    }
    for (final id in ids) {
      langganan.add(
        _col.where('arsitekId', isEqualTo: id).snapshots().listen(
              (snap) {
            hasil[id] = snap.docs.map(Konsultasi.fromDoc).toList();
            kirim();
          },
          onError: (_) {
            hasil[id] = const [];
            kirim();
          },
        ),
      );
    }
    controller.onCancel = () {
      for (final l in langganan) {
        l.cancel();
      }
    };
    return controller.stream;
  }

  /// Satu konsultasi (live), untuk layar pembayaran.
  static Stream<Konsultasi?> satu(String id) => _col
      .doc(id)
      .snapshots()
      .map((d) => d.exists ? Konsultasi.fromDoc(d) : null);

  /// Kirim bukti transfer (gambar base64 yang sudah dikecilkan).
  /// Status berubah jadi menunggu_verifikasi, admin yang mengecek.
  static Future<void> kirimBukti(String id, String base64Gambar) async {
    await ubahBilaStatus(
      _col.doc(id),
      dari: [StatusKonsultasi.menungguPembayaran],
      ubah: (_) => {
        'status': StatusKonsultasi.menungguVerifikasi,
        'buktiBayar': base64Gambar,
        'buktiBayarAt': FieldValue.serverTimestamp(),
      },
    );
    NotifikasiService.kirimKeSaya(
      type: 'pembayaran',
      refId: id,
      judul: 'Bukti pembayaran terkirim',
      isi: 'Admin akan memverifikasi, biasanya dalam 1 x 24 jam.',
    );
  }

  /// Persen refund menurut sisa waktu sebelum sesi (usulan, perlu disepakati):
  /// > 24 jam = 100, 6 sampai 24 jam = 50, < 6 jam = 0.
  /// Belum dibayar -> 0 (tidak ada uang yang perlu dikembalikan).
  static int hitungRefundPersen(Konsultasi k, {bool olehArsitek = false}) {
    if (k.status == StatusKonsultasi.menungguPembayaran) return 0;
    if (olehArsitek) return 100;
    final mulai = k.mulai;
    if (mulai == null) return 0;
    final jam = mulai.difference(DateTime.now()).inMinutes / 60;
    if (jam > 24) return 100;
    if (jam >= 6) return 50;
    return 0;
  }

  /// Batalkan konsultasi + lepas slot jadwalnya (satu batch).
  /// oleh: 'user' | 'arsitek' | 'sistem'
  static Future<void> batalkan(
      Konsultasi k, {
        String oleh = 'user',
        String alasan = '',
      }) async {
    var persen = 0;
    var nominal = 0;
    final db = FirebaseFirestore.instance;
    // Status dibaca ulang di dalam transaksi: kalau sudah berubah
    // (misalnya admin sudah menyetujui/membatalkan), tidak ada yang ditulis.
    await ubahBilaStatus(
      _col.doc(k.id),
      dari: oleh == 'sistem'
          ? [StatusKonsultasi.menungguPembayaran]
          : [
              StatusKonsultasi.menungguPembayaran,
              StatusKonsultasi.menungguVerifikasi,
              StatusKonsultasi.dikonfirmasi,
            ],
      ubah: (d) {
        final f = Konsultasi.fromDoc(d);
        persen = hitungRefundPersen(f, olehArsitek: oleh == 'arsitek');
        nominal = f.harga * persen ~/ 100;
        return {
          'status': StatusKonsultasi.dibatalkan,
          'dibatalkanOleh': oleh,
          'dibatalkanAt': FieldValue.serverTimestamp(),
          'alasanBatal': alasan,
          'refundPersen': persen,
          'refundNominal': nominal,
          'refundStatus': nominal > 0 ? 'diproses' : 'tidak_ada',
        };
      },
      hapus: (d) {
        final f = Konsultasi.fromDoc(d);
        return [
          db
              .collection(Koleksi.jadwal)
              .doc('${f.arsitekId}_${f.tanggal}_${f.jam}')
        ];
      },
    );
    if (nominal > 0) {
      NotifikasiService.kirim(
        userId: k.userId,
        type: 'refund',
        refId: k.id,
        judul: 'Refund diproses',
        isi: 'Refund $persen% sedang diproses admin. Isi rekening tujuan di '
            'Riwayat > Dibatalkan agar dana bisa dikirim.',
      );
    } else if (oleh == 'sistem') {
      NotifikasiService.kirim(
        userId: k.userId,
        type: 'batal',
        refId: k.id,
        judul: 'Pesanan dibatalkan',
        isi: 'Pembayaran tidak diterima sebelum batas waktu, jadwal dibuka '
            'kembali.',
      );
    }
  }

  /// User mengisi rekening tujuan refund (hanya saat refund 'diproses').
  static Future<void> simpanRekeningRefund(
      Konsultasi k, String bank, String rekening, String atasNama) {
    return ubahBilaStatus(
      _col.doc(k.id),
      dari: [StatusKonsultasi.dibatalkan],
      ubah: (d) {
        if ((d.data() ?? {})['refundStatus'] != 'diproses') {
          throw Exception('Refund ini sudah tidak bisa diubah.');
        }
        return {
          'refundBank': bank,
          'refundRekening': rekening,
          'refundAtasNama': atasNama,
          'refundDiisiAt': FieldValue.serverTimestamp(),
        };
      },
    );
  }

  /// Sisa jam sebelum sesi mulai (negatif kalau sudah lewat).
  static double sisaJam(Konsultasi k) {
    final mulai = k.mulai;
    if (mulai == null) return 0;
    return mulai.difference(DateTime.now()).inMinutes / 60;
  }

  /// Alasan jadwal ulang ditolak, atau null kalau boleh.
  static String? alasanTidakBisaJadwalUlang(Konsultasi k) {
    if (k.status != StatusKonsultasi.dikonfirmasi) {
      return 'Hanya sesi yang sudah dikonfirmasi yang bisa dijadwal ulang.';
    }
    if (k.jadwalUlang >= 1) {
      return 'Jadwal ulang hanya boleh 1 kali untuk tiap konsultasi.';
    }
    if (sisaJam(k) < 6) {
      return 'Kurang dari 6 jam sebelum sesi, jadwal tidak bisa diubah.';
    }
    return null;
  }

  /// Pindahkan sesi ke tanggal/jam baru: lepas slot lama, kunci slot baru,
  /// dan ubah dokumen konsultasi, semuanya dalam satu transaksi.
  static Future<void> jadwalUlang(
      Konsultasi k, {
        required String tanggalBaru,
        required String jamBaru,
        required String jamSelesaiBaru,
      }) async {
    final db = FirebaseFirestore.instance;
    final kRef = _col.doc(k.id);
    final jLama = db
        .collection(Koleksi.jadwal)
        .doc('${k.arsitekId}_${k.tanggal}_${k.jam}');
    final jBaru = db
        .collection(Koleksi.jadwal)
        .doc('${k.arsitekId}_${tanggalBaru}_$jamBaru');
    await db.runTransaction((tx) async {
      final baru = await tx.get(jBaru);
      final sekarang = await tx.get(kRef);
      final dataSekarang = sekarang.data() ?? {};
      if ((dataSekarang['jadwalUlang'] as num? ?? 0) >= 1) {
        throw StateError('Jadwal ulang hanya boleh 1 kali.');
      }
      if (baru.exists) throw JadwalTerisi();
      tx.delete(jLama);
      tx.set(jBaru, {
        'arsitekId': k.arsitekId,
        'tanggal': tanggalBaru,
        'jam': jamBaru,
        'konsultasiId': k.id,
        'userId': k.userId,
      });
      tx.update(kRef, {
        'tanggal': tanggalBaru,
        'jam': jamBaru,
        'jamSelesai': jamSelesaiBaru,
        'jadwalUlang': 1,
      });
    });
  }

  /// Pembatalan otomatis pesanan yang lewat batas bayar.
  /// Ini penutup sementara; versi benarnya Cloud Function terjadwal.
  static void _batalkanYangKedaluwarsa(List<Konsultasi> list) {
    final sekarang = DateTime.now();
    for (final k in list) {
      final b = k.batasBayar;
      if (k.status == StatusKonsultasi.menungguPembayaran &&
          b != null &&
          b.isBefore(sekarang)) {
        batalkan(k,
            oleh: 'sistem',
            alasan: 'Melewati batas waktu pembayaran')
            .catchError((_) {});
      }
    }
  }

  /// Jam yang sudah terisi untuk satu arsitek di satu tanggal (live).
  /// Hasil: kumpulan jam mulai, contoh {"09:00", "13:00"}.
  static Stream<Set<String>> jamTerisi(String arsitekId, String tanggal) {
    return FirebaseFirestore.instance
        .collection(Koleksi.jadwal)
        .where('arsitekId', isEqualTo: arsitekId)
        .where('tanggal', isEqualTo: tanggal)
        .snapshots()
        .map((s) => s.docs.map((d) => d.data()['jam'] as String? ?? '').toSet());
  }

  /// Buat booking: mengunci slot di `jadwal` DAN membuat dokumen `konsultasi`
  /// dalam satu transaksi. Kalau slot keburu diambil orang lain -> JadwalTerisi.
  static Future<String> buatBooking(Konsultasi k) async {
    final db = FirebaseFirestore.instance;
    final kRef = db.collection(Koleksi.konsultasi).doc();
    final jRef = db
        .collection(Koleksi.jadwal)
        .doc('${k.arsitekId}_${k.tanggal}_${k.jam}');
    await db.runTransaction((tx) async {
      final j = await tx.get(jRef);
      if (j.exists) throw JadwalTerisi();
      tx.set(jRef, {
        'arsitekId': k.arsitekId,
        'tanggal': k.tanggal,
        'jam': k.jam,
        'konsultasiId': kRef.id,
        'userId': k.userId,
      });
      tx.set(kRef, k.toMap());
      if (k.harga == 0) {
        // Promo konsultasi gratis: tandai sudah terpakai (sekali per akun).
        tx.update(db.collection(Koleksi.users).doc(k.userId),
            {'promoKonsultasiTerpakai': true});
      }
    });
    NotifikasiService.kirim(
      userId: k.userId,
      type: 'booking',
      refId: kRef.id,
      judul: k.harga == 0 ? 'Konsultasi gratis dikonfirmasi' : 'Booking dibuat',
      isi: k.harga == 0
          ? 'Promo pengguna baru terpakai. Konsultasi dengan ${k.arsitekNama} '
              '(${k.tanggal}, ${k.jam}) sudah dikonfirmasi.'
          : 'Konsultasi dengan ${k.arsitekNama} (${k.tanggal}, ${k.jam}). '
              'Selesaikan pembayaran agar jadwalmu terkunci.',
    );
    return kRef.id;
  }
}

class JadwalTerisi implements Exception {
  @override
  String toString() => 'Jam ini baru saja dipesan orang lain.';
}