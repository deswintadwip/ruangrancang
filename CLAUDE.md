# RuangRancang — catatan proyek untuk Claude

> Baca file ini dulu sebelum mengerjakan apa pun. Isinya konteks lengkap proyek,
> aturan bisnis, keputusan yang sudah diambil, dan cara kerja dengan pemilik proyek.
> Terakhir diperbarui: 3 Nov 2026.

## 1. Siapa dan apa

- **Pemilik/pengguna Claude:** **Deswinta Dwi Putri** (GitHub `deswintadwip`, deswintadwip@gmail.com), **bukan programmer** berpengalaman. Jangan menulis nama atau kampus lain di dokumen/laporan.
- **Proyek:** tugas kelompok (kuliah) membuat aplikasi **RuangRancang**: platform konsultasi arsitek, pesan sketsa desain, booking rumah (perumahan), dan permintaan vendor konstruksi.
- **Stack:** Flutter (Dart 3) + Firebase (Auth, Firestore). **Tanpa Cloud Functions / Storage / paket Blaze** (gratis saja).
- **Lokasi kode:** `C:\Users\wita\StudioProjects\arsitek` (folder `lib/`). Dijalankan dengan `flutter run -d chrome --web-port 5000` (utama di web/Chrome).
- **GitHub:** https://github.com/deswintadwip/ruangrancang.git (public; kolaborasi dengan teman satu kelompok).
- **Dosen/review:** ada butir review dosen yang belum selesai: (1) VA/QRIS, (6) invoice admin. Laporan Word perlu diperbarui untuk fitur sketsa.

## 1b. Konsep proyek

RuangRancang adalah **satu aplikasi untuk seluruh perjalanan membangun rumah**, dari mencari ide sampai mendapat rumah/pekerjaan terlaksana. Ada tiga pihak:

- **User (klien):** orang yang ingin merancang atau membeli rumah.
- **Arsitek:** profesional yang memberi konsultasi dan membuat sketsa desain.
- **Admin:** pengelola platform; memverifikasi pembayaran, meneruskan permintaan, mengatur harga dan aturan.

Empat layanan utama:

1. **Konsultasi desain:** sesi bertemu arsitek (online via Google Meet atau datang ke studio), dibayar di muka, dengan pelacakan progres kerja 5 tahap.
2. **Sketsa desain:** user mengisi data lahan dan kebutuhan, membayar, lalu arsitek mengirim hasil berupa PDF lewat aplikasi (tanpa pertemuan). Ada 1 revisi gratis.
3. **Perumahan:** user memilih perumahan dan tipe, membayar **booking fee** untuk menahan unit.
4. **Vendor konstruksi:** user mengirim permintaan pekerjaan; admin meneruskan ke vendor yang cocok; vendor menghubungi user.

Pembayaran selalu **transfer manual + unggah bukti + verifikasi admin** (belum ada payment gateway sungguhan; rencananya VA/QRIS tiruan + invoice).

## 1c. Alur utama

**Alur umum pembayaran (konsultasi, sketsa, booking rumah):**
1. User membuat pesanan → status `menunggu_pembayaran`, hitung mundur batas bayar (default 24 jam).
2. User transfer lalu mengunggah bukti → `menunggu_verifikasi` (admin dapat notifikasi di lonceng/Perlu tindakan).
3. Admin memeriksa bukti: **setujui** (lanjut), **minta unggah ulang** (kembali ke langkah 1 dengan batas baru), atau **tolak**.
4. Bila lewat batas bayar tanpa bukti → dibatalkan otomatis (dijalankan aplikasi saat dibuka, slot jadwal dilepas).
5. Semua perubahan status dicek lewat transaksi, sehingga dua pihak tidak bisa menimpa satu sama lain (mis. admin menyetujui pesanan yang baru dibatalkan user).

**Alur konsultasi:**
1. User membuka tab Konsultasi atau mencari di Beranda → memilih arsitek → Booking Konsultasi (pilih tanggal/jam, metode, isi detail proyek, setuju syarat).
2. Konsultasi pertama pengguna baru **GRATIS** (langsung `dikonfirmasi`, tanpa bayar); selebihnya mengikuti alur pembayaran di atas (harga dari Pengaturan admin, default Rp200.000, durasi 2 jam).
3. Setelah `dikonfirmasi`, jadwal terkunci (koleksi `jadwal`). Arsitek mengisi link Meet dan memperbarui **tahap kerja** (1–5); user memantau di bar hijau Beranda dan halaman Lacak. Jadwal ulang boleh 1 kali, minimal 6 jam sebelum sesi.
4. Arsitek menandai selesai → user dapat memberi **ulasan** → muncul di Riwayat.
5. **Pembatalan & refund:** persen refund bergantung waktu (lihat bagian 6). User mengisi rekening refund, admin transfer lalu menandai refund selesai.

**Alur sketsa:**
1. User memilih arsitek → Pesan Sketsa Desain → mengisi data lahan (luas menentukan harga), kebutuhan bangunan, gaya, referensi, lampiran → centang ketentuan sketsa → bayar.
2. Admin verifikasi → `dikerjakan`; arsitek dapat notifikasi pesanan baru.
3. Arsitek menyiapkan PDF dan mengirim → `selesai`; user mengunduh PDF (web). Bila data user tidak masuk akal, arsitek memakai "Minta data diperbaiki" (user membalas, pengerjaan lanjut).
4. User boleh 1x "Ajukan revisi" → kembali `dikerjakan` → arsitek mengirim PDF baru. Setelah itu tidak ada revisi/refund lagi.
5. (Rencana) tenggat 3 hari kerja, perpanjangan sampai hari ke-5, status Terlambat, kompensasi voucher.

**Alur perumahan:** user melihat daftar/detail perumahan → pilih tipe → pesan → bayar booking fee (default Rp10.000.000) → admin verifikasi → `disetujui` (unit tertahan, tim menghubungi user).

**Alur vendor:** user mengisi form permintaan (jenis pekerjaan, kota, anggaran, rencana mulai, deskripsi) → admin `baru` → **teruskan** ke vendor → vendor menghubungi (`dihubungi`) → ditutup `selesai` oleh admin/user.

**Alur akun:** daftar (email + verifikasi, nomor telepon/OTP) → login → `after_login` memuat data arsitek dari Firestore → diarahkan ke Beranda sesuai role (user/arsitek/admin). Akun arsitek dibuat manual di Firebase Console lalu dihubungkan lewat `profilId`.

**Notifikasi:** hampir setiap perubahan status mengirim notifikasi ke pihak yang terkait (user, arsitek, atau admin lewat daftar "Perlu tindakan").

## 2. Cara bekerja dengan Deswinta (PENTING)

- Bahasa: **Indonesia santai**. Dia gampang kewalahan → langkah **bernomor, sederhana**.
- Data (mis. daftar field, akun) diberikan sebagai **teks**, bukan file/spreadsheet.
- **Firestore Rules selalu ditempel inline dan LENGKAP** (bukan potongan), lalu "Publish".
- File kode: berikan **file utuh** dengan path persis, atau edit langsung lewat jembatan device (`mcp__remote-devices__device_bash`; skrip patch Python dijalankan dengan `python3 -I`, cek keseimbangan kurung setelahnya). VM Claude tidak punya Flutter, jadi kode **belum pernah dikompilasi oleh Claude**: selalu minta dia menjalankan `flutter run` dan kirim error merah.
- Jangan menjelaskan hal teknis panjang; hasil dulu, ringkas, lalu cara mencoba.
- Palet warna: background `F4EFE6`, surface `FBF8F2`, primary `2F4A3F`, textDark `2B2A27`, border `E3DCCF`. Font: Playfair Display (judul), Poppins (isi). Aksen emas `D9A441`.

## 3. Keputusan produk yang SUDAH final

- **Tidak ada fitur WhatsApp** di mana pun, kecuali WA CS: Profil "Hubungi CS", vendor "Chat Admin", kontak di Beranda.
- **Harga tidak ditampilkan di profil arsitek.** Harga hanya muncul di halaman pembayaran (form sketsa tetap punya bar harga live).
- **Admin TIDAK membuat akun arsitek.** Akun arsitek dibuat manual di Firebase Console, dihubungkan lewat `profilId`. Profil arsitek (nama, foto, dll.) tetap di kode `data/arsitek_data.dart`; daftar akun arsitek di admin hidup dari Firestore.
- **Pembayaran** manual: transfer + unggah bukti (base64 di Firestore) + verifikasi admin. Batas bayar default 24 jam (diatur admin).
- **Sketsa:** tanpa refund setelah dikerjakan; **1 kali revisi gratis** (hanya perubahan dalam data awal); arsitek bisa "Minta data diperbaiki" (tidak memakai jatah revisi). Kompensasi keterlambatan = **voucher**, bukan refund.
- **Tenggat sketsa (BELUM dikodekan):** target **3 hari kerja** sejak pembayaran terverifikasi; kalau di hari ke-3 belum ada proses, tenggat diperpanjang sampai **hari kerja ke-5** (sketsa harus sudah ada). Lewat itu → status "Terlambat", admin dapat peringatan, admin bisa "tambah waktu 3 hari" atau "alihkan ke arsitek lain", user dapat voucher. Karena tanpa Cloud Functions, status terlambat dihitung di aplikasi saat dibuka.
- **Promo:** konsultasi pertama GRATIS untuk pengguna baru; berhak bila riwayat konsultasi kosong (sketsa/rumah/vendor tidak dihitung) dan `users/{uid}.promoKonsultasiTerpakai` belum true.
- Pelacak hijau (tracking bar) di Beranda hilang otomatis saat selesai.
- Header: foto rumah transparan melebar ujung ke ujung, memudar ke bawah; logo RuangRancang dibuat besar.

## 4. Peran pengguna

- `users/{uid}.role`: `user` | `arsitek` | `admin`. Registrasi selalu `user`; admin/arsitek diangkat manual di Firebase. Arsitek melewati verifikasi email.
- **User:** Beranda (hero + cari + promo, arsitek, perumahan, proyek), Konsultasi, Vendor, Perumahan, Profil; Riwayat; Pesanan Sketsa; Notifikasi.
- **Arsitek:** Beranda, Konsultasi, Sketsa, Jadwal (ketersediaan/cuti), Profil.
- **Admin:** Dashboard (ringkasan + "Perlu tindakan" + lonceng), Konsultasi, Kelola (sketsa, perumahan, vendor, pengguna, proyek, arsitek), Atur (pengaturan).

## 5. Struktur kode (`lib/`)

- `config/`: `status.dart` (nama koleksi `Koleksi.*` dan konstanta status `StatusKonsultasi/StatusSketsa/StatusPesananRumah/StatusPermintaanVendor`), `tahap.dart` (5 tahap kerja), `tarif_sketsa.dart`.
- `models/`: konsultasi, pesanan_sketsa, pesanan_rumah, permintaan_vendor, pengaturan, notifikasi, pengguna, proyek, ketersediaan, dll.
- `services/`: logika Firestore per fitur. **Semua perubahan status memakai `ubahBilaStatus()` (`status_berubah.dart`)**: transaksi yang membaca status terbaru dulu; bila status sudah berubah → `StatusBerubah` ("Pesanan sudah berubah…"). Pakai ini untuk aksi baru.
- `screens/`: `admin/`, `arsitek/`, `auth/`, `home/`, `konsultasi/`, `perumahan/`, `vendor/`, `sketsa/`, `notifikasi/`, `info/`.
- `widgets/`: `header_foto.dart` (HeaderFotoLatar, HeaderFoto, LogoRuangRancang), `tracking_bar.dart`, `arsitek_foto.dart`, dll. `screens/admin/admin_util.dart` (BuktiTransfer, tanyaAlasan, KartuAdmin, barisInfo), `admin_widgets.dart` (AdminPageHeader, AdminSection).
- `data/`: data statis arsitek (10 orang, `DataArsitek.semua` + loader Firestore live), perumahan, vendor.
- Notifikasi: `NotifikasiService.kirim(userId,type,refId,judul,isi)` menulis dokumen di `notifikasi` (field: userId,type,refId,judul,isi,isRead,createdAt).

## 6. Model data Firestore (koleksi)

`users`, `arsitek` (id = UID, field `profilId` mis. "arsitek_01" menghubungkan ke data statis), `konsultasi` (+sub `update`, `revisi`), `jadwal` (kunci slot `{arsitekId}_{tanggal}_{jam}`), `ulasan`, `pengaturan/aplikasi`, `portofolio`, `pesanan_sketsa` (+sub `hasil` berisi potongan PDF base64 600.000 karakter, maks 3 MB), `pesanan_rumah`, `permintaan_vendor`, `notifikasi`. Koleksi lain DITOLAK Rules.

- `konsultasi.arsitekId` bisa UID atau profilId; Rules `ketugaskan(id)` menjembatani. Query arsitek dibuat **satu query per ID** lalu digabung (agar Rules bisa membuktikan akses).
- Status konsultasi: menunggu_pembayaran → menunggu_verifikasi → dikonfirmasi → selesai | dibatalkan | ditolak. Refund konsultasi: >24 jam sebelum sesi 100%, 6–24 jam 50%, <6 jam 0%, belum bayar 0%, dibatalkan arsitek/admin 100%. User mengisi **rekening refund** (Riwayat → Dibatalkan); admin hanya bisa "Tandai refund selesai" bila rekening terisi.
- Status sketsa: menunggu_pembayaran → menunggu_verifikasi → dikerjakan → selesai | ditolak | dibatalkan. Flag di dokumen: `butuhData`, `revisiDipakai` (0/1).
- Tarif sketsa: ≤50 m² Rp300.000; ≤100 Rp450.000; ≤200 Rp650.000; ≤500 Rp850.000; ≤1000 Rp1.500.000; >1000 Rp2.500.000 (ada di `tarif_sketsa.dart` DAN di fungsi `hargaSketsa` pada Rules — ubah keduanya).
- Pengaturan bawaan: hargaKonsultasi 200.000, batasBayarJam 24, bookingFeeRumah 10.000.000.

## 7. Firestore Rules (ringkas; versi lengkap ada di `firestore.rules` di root proyek)

Helper: `isSignedIn, isOwner, hasRole, isAdmin, isArsitek, ketugaskan, changedFields, konsultasiDoc, peng, batasWajar, batalSistemSah, hargaSketsa`. Prinsip: harga divalidasi terhadap `pengaturan`; batas bayar dicek jam server (toleransi 1 jam); bukti hanya dari status menunggu_pembayaran sebelum batas; pembatalan otomatis ("sistem") hanya sah setelah batas lewat; arsitek hanya `dikerjakan→selesai`; `users` hanya dibaca pemilik/admin; notifikasi dibuat untuk diri sendiri atau oleh admin/arsitek; promo gratis via `getAfter` pada flag user. **Setiap kali Rules berubah, kirim ulang versi LENGKAP.**

## 8. Yang SUDAH selesai (ringkas)

Konsultasi end-to-end (booking, bayar, verifikasi, tahap kerja, jadwal ulang, batal+refund+rekening, ulasan, lacak); Sketsa end-to-end (form lengkap, bayar, admin verifikasi, arsitek kirim PDF, unduh PDF di web, revisi 1x, minta data diperbaiki, ketentuan sketsa, anti pesanan dobel, validasi PDF); perumahan & vendor ke Firestore + admin; notifikasi; lonceng admin; dashboard admin (Perlu tindakan); pencarian Beranda (arsitek/perumahan/vendor); promo konsultasi gratis; header foto gradasi + logo besar; transaksi status; Rules diperketat (8 poin audit "Penting").

## 9. Daftar kerja berikutnya (urutan disepakati)

1. **Tenggat sketsa** 3 hari kerja → perpanjangan sampai hari ke-5, status Terlambat, tombol admin (tambah waktu / alihkan), notifikasi pengingat.
2. **Voucher** (koleksi `voucher`: kode, nominal, pemilik, terpakai) + pemakaian di pemesanan + Rules.
3. **Invoice + payment gateway tiruan** (halaman invoice, nomor VA/QRIS contoh, konfirmasi manual) → memenuhi review dosen butir 1 dan 6.
4. **Foto berbeda tiap arsitek:** Deswinta akan memberi 10 gambar (mis. `arsitek_01.jpg`…`arsitek_10.jpg` di `lib/images/arsitek/`); foto dipakai lewat `widgets/arsitek_foto.dart`.
5. Pelacak (tracking bar) untuk arsitek/admin lebih lengkap; riwayat gabungan (sketsa/rumah/vendor).
6. Perbarui FAQ & Syarat Ketentuan, laporan Word (sketsa), admin jadwal/pindah jadwal/batalkan sesi.
7. Audit sisa: #9 slot terkunci bila user tidak kembali (admin "Lepas slot"), #10 cuti arsitek hanya dicek di aplikasi, #18 base64 di Firestore (idealnya Storage), #21 daftar admin tanpa halaman. Tampilkan sebagai batasan di laporan bila tidak dikerjakan.
8. Masalah terbuka: **Jadwal arsitek "permission-denied"** (cek Rules sudah Publish, dokumen `arsitek/{uid}` ada untuk akun itu, restart); harga 175.000 lama pada booking lama (harga tersimpan di pesanan); admin vendor/perumahan "tidak masuk" belum bisa direproduksi.

## 10. Batasan yang diketahui (jujur untuk laporan)

- Tanpa Cloud Functions: pembatalan otomatis & status terlambat dijalankan di aplikasi saat dibuka.
- Persen refund konsultasi hanya dicek kewajarannya di Rules (0/50/100, nominal ≤ harga×persen), bukan dicocokkan dengan sisa waktu.
- Promo gratis: akun lama dengan riwayat konsultasi secara teknis bisa mengklaim sekali bila memakai trik di luar aplikasi.
- Tarif sketsa terduplikasi di kode dan Rules.
- Jam HP melenceng >1 jam bisa membuat booking ditolak.
- Unduh PDF hanya di web.

## 11. Tips teknis yang pernah menjebak

- Setelah ubah Rules: Publish, lalu restart app (`R`).
- Package tambahan: `flutter pub add <nama>` (jangan ada titik di akhir).
- Zip lama yang menimpa file bisa menghapus perubahan; lebih aman edit langsung.
- Skrip patch: tulis ke file lalu jalankan `python3 -I`; verifikasi kurung seimbang.
- Dart records/switch expression dipakai (Dart 3).
