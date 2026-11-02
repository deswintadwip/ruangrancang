import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import '../config/status.dart';

/// Satu akun arsitek (dokumen `arsitek/{uid}`).
class AkunArsitek {
  final String uid;
  final String nama;
  final String profilId;
  final String spesialisasi;
  final bool aktif;

  const AkunArsitek({
    required this.uid,
    required this.nama,
    required this.profilId,
    required this.spesialisasi,
    required this.aktif,
  });

  factory AkunArsitek.fromDoc(DocumentSnapshot<Map<String, dynamic>> d) {
    final m = d.data() ?? {};
    return AkunArsitek(
      uid: d.id,
      nama: m['nama'] as String? ?? '-',
      profilId: m['profilId'] as String? ?? '',
      spesialisasi: m['spesialisasi'] as String? ?? '',
      aktif: m['isActive'] as bool? ?? true,
    );
  }
}

/// Admin membuat akun arsitek langsung dari aplikasi (tanpa Console).
class AdminArsitekService {
  AdminArsitekService._();

  static final _db = FirebaseFirestore.instance;

  static Stream<List<AkunArsitek>> semua() =>
      _db.collection(Koleksi.arsitek).snapshots().map((s) {
        final list = s.docs.map(AkunArsitek.fromDoc).toList();
        list.sort((a, b) => a.profilId.compareTo(b.profilId));
        return list;
      });

  /// Membuat akun Authentication + dokumen `users` + dokumen `arsitek`.
  /// Akun dibuat lewat "aplikasi kedua" supaya admin tidak ikut logout.
  /// Arsitek langsung bisa masuk tanpa verifikasi email.
  static Future<void> buat({
    required String nama,
    required String email,
    required String password,
    required String noHp,
    required String profilId,
    required String spesialisasi,
  }) async {
    final dipakai = await _db
        .collection(Koleksi.arsitek)
        .where('profilId', isEqualTo: profilId)
        .limit(1)
        .get();
    if (dipakai.docs.isNotEmpty) {
      throw Exception('Profil $profilId sudah punya akun arsitek.');
    }

    FirebaseApp app;
    try {
      app = await Firebase.initializeApp(
          name: 'buatAkunArsitek', options: Firebase.app().options);
    } catch (_) {
      app = Firebase.app('buatAkunArsitek');
    }
    final auth = FirebaseAuth.instanceFor(app: app);

    final cred = await auth.createUserWithEmailAndPassword(
        email: email, password: password);
    final user = cred.user!;
    try {
      var hp = noHp.replaceAll(RegExp(r'\D'), '');
      if (hp.startsWith('0')) hp = hp.substring(1);
      final batch = _db.batch();
      batch.set(_db.collection(Koleksi.users).doc(user.uid), {
        'nama': nama,
        'email': email,
        'noHp': hp,
        'role': Role.arsitek,
        'isActive': true,
        'emailVerified': false,
        'phoneVerified': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      batch.set(_db.collection(Koleksi.arsitek).doc(user.uid), {
        'nama': nama,
        'profilId': profilId,
        'spesialisasi': spesialisasi,
        'pengalaman': 0,
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
      });
      await batch.commit();
      await user.updateDisplayName(nama);
    } catch (e) {
      // Gagal menyimpan data: hapus akun Auth supaya tidak menggantung.
      try {
        await user.delete();
      } catch (_) {}
      rethrow;
    } finally {
      await auth.signOut();
    }
  }
}
