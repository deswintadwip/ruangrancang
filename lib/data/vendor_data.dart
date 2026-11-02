import 'package:flutter/material.dart';

/// Satu vendor konstruksi. Data sementara (statis) seperti DataArsitek;
/// nanti dipindah ke Firestore lewat layar "Kelola Vendor" admin.
/// Semua nama & angka di bawah adalah CONTOH FIKTIF.
class Vendor {
  final String id;
  final String nama;
  final String jenis; // salah satu DataVendor.kategori
  final String jenisLengkap;
  final String kota;
  final String area;
  final double rating;
  final int proyek;
  final String harga;
  final String tentang;
  final List<String> layanan;
  final String jamKerja;
  final String respon;
  final Color warna;
  final List<String> portofolio; // path aset

  const Vendor({
    required this.id,
    required this.nama,
    required this.jenis,
    required this.jenisLengkap,
    required this.kota,
    required this.area,
    required this.rating,
    required this.proyek,
    required this.harga,
    required this.tentang,
    required this.layanan,
    required this.jamKerja,
    required this.respon,
    required this.warna,
    required this.portofolio,
  });

  String get inisial => nama.isEmpty ? '?' : nama[0].toUpperCase();
}

class DataVendor {
  DataVendor._();

  static const kategori = ['Kontraktor', 'Interior', 'Atap', 'Listrik', 'Plumbing'];

  static const jenisPekerjaan = [
    'Bangun rumah baru',
    'Renovasi total',
    'Tambah lantai',
    'Interior & furnitur',
    'Atap & waterproofing',
    'Instalasi listrik',
    'Plumbing & sanitasi',
    'Lainnya',
  ];

  static const anggaran = [
    '< Rp 100 jt',
    'Rp 100–300 jt',
    'Rp 300–700 jt',
    '> Rp 700 jt',
  ];

  static const semua = <Vendor>[
    Vendor(
      id: 'vendor_01',
      nama: 'CV Karya Bangun Mandiri',
      jenis: 'Kontraktor',
      jenisLengkap: 'Kontraktor Bangunan',
      kota: 'Depok',
      area: 'Jabodetabek',
      rating: 4.9,
      proyek: 42,
      harga: 'Mulai Rp 3,2 jt / m²',
      tentang:
          'Kontraktor rumah tinggal dengan pengalaman 12 tahun. Menangani bangun baru, renovasi total, dan perluasan lantai dua, lengkap dengan RAB tertulis dan jadwal kerja mingguan.',
      layanan: ['Bangun rumah baru', 'Renovasi total', 'Tambah lantai', 'Pagar & carport'],
      jamKerja: 'Sen–Sab, 08.00–17.00',
      respon: '< 1 hari',
      warna: Color(0xFF2F4A3F),
      portofolio: [
        'lib/images/rumahdashboard1.jpg',
        'lib/images/rumahdashboard2.jpg',
        'lib/images/rumahdashboard3.jpg',
      ],
    ),
    Vendor(
      id: 'vendor_02',
      nama: 'Sentra Interior Jaya',
      jenis: 'Interior',
      jenisLengkap: 'Interior & Furnitur',
      kota: 'Jakarta Selatan',
      area: 'Jabodetabek',
      rating: 4.8,
      proyek: 57,
      harga: 'Mulai Rp 1,5 jt / m²',
      tentang:
          'Studio interior dan produksi furnitur custom: kitchen set, lemari tanam, dan panel dinding. Gambar kerja dan render 3D diberikan sebelum produksi.',
      layanan: ['Kitchen set', 'Lemari tanam', 'Panel dinding', 'Furnitur custom'],
      jamKerja: 'Sen–Jum, 09.00–17.00',
      respon: '< 1 hari',
      warna: Color(0xFF8A5A3C),
      portofolio: [
        'lib/images/rumahdashboard4.jpg',
        'lib/images/rumahdashboard2.jpg',
        'lib/images/rumahdashboard1.jpg',
      ],
    ),
    Vendor(
      id: 'vendor_03',
      nama: 'Atap Nusantara',
      jenis: 'Atap',
      jenisLengkap: 'Atap & Waterproofing',
      kota: 'Bogor',
      area: 'Bogor, Depok, Jakarta',
      rating: 4.7,
      proyek: 31,
      harga: 'Mulai Rp 185 rb / m²',
      tentang:
          'Spesialis rangka atap baja ringan, penutup atap, dan pelapisan anti bocor untuk rumah tinggal.',
      layanan: ['Baja ringan', 'Genteng metal', 'Waterproofing', 'Perbaikan bocor'],
      jamKerja: 'Sen–Sab, 08.00–16.00',
      respon: '1–2 hari',
      warna: Color(0xFF4F6B7A),
      portofolio: [
        'lib/images/rumahdashboard3.jpg',
        'lib/images/rumahdashboard1.jpg',
        'lib/images/rumahdashboard4.jpg',
      ],
    ),
    Vendor(
      id: 'vendor_04',
      nama: 'Voltra Elektrikal',
      jenis: 'Listrik',
      jenisLengkap: 'Listrik & Instalasi',
      kota: 'Depok',
      area: 'Depok, Jakarta, Bekasi',
      rating: 4.7,
      proyek: 64,
      harga: 'Survei gratis',
      tentang:
          'Instalasi listrik rumah tinggal, penambahan daya, dan pemasangan panel sesuai standar keselamatan.',
      layanan: ['Instalasi baru', 'Tambah titik', 'Panel listrik', 'Penerangan taman'],
      jamKerja: 'Sen–Sab, 08.00–17.00',
      respon: '< 1 hari',
      warna: Color(0xFF7A6A2E),
      portofolio: [
        'lib/images/rumahdashboard2.jpg',
        'lib/images/rumahdashboard3.jpg',
        'lib/images/rumahdashboard4.jpg',
      ],
    ),
    Vendor(
      id: 'vendor_05',
      nama: 'Tirta Plumbing & Sanitasi',
      jenis: 'Plumbing',
      jenisLengkap: 'Plumbing & Sanitasi',
      kota: 'Tangerang Selatan',
      area: 'Tangerang, Jakarta',
      rating: 4.6,
      proyek: 28,
      harga: 'Mulai Rp 450 rb / titik',
      tentang:
          'Pemasangan pipa air bersih dan kotor, kamar mandi, dan sistem pembuangan untuk rumah tinggal.',
      layanan: ['Pipa air bersih', 'Kamar mandi', 'Septic tank', 'Pompa air'],
      jamKerja: 'Sen–Sab, 08.00–16.00',
      respon: '1–2 hari',
      warna: Color(0xFF3F5F5A),
      portofolio: [
        'lib/images/rumahdashboard4.jpg',
        'lib/images/rumahdashboard3.jpg',
        'lib/images/rumahdashboard2.jpg',
      ],
    ),
  ];

  static Vendor? byId(String? id) {
    for (final v in semua) {
      if (v.id == id) return v;
    }
    return null;
  }
}
