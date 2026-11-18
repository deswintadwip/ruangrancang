import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Foto rumah transparan yang membentang dari ujung kiri ke ujung kanan,
/// makin jelas ke kanan. Dipakai sebagai latar header semua halaman.
class HeaderFotoLatar extends StatelessWidget {
  final String foto;
  final double kekuatan; // 0..1, seberapa jelas fotonya
  final double radius;

  const HeaderFotoLatar({
    super.key,
    this.foto = 'lib/images/houselogin.jpg',
    this.kekuatan = 0.55,
    this.radius = 0,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Container(
        color: AppColors.background,
        width: double.infinity,
        height: double.infinity,
        child: Stack(fit: StackFit.expand, children: [
        ShaderMask(
          shaderCallback: (rect) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [Colors.black.withValues(alpha: 0.18), Colors.black],
          ).createShader(rect),
          blendMode: BlendMode.dstIn,
          child: Opacity(
            opacity: kekuatan,
            child: Image.asset(
              foto,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              alignment: Alignment.center,
              cacheWidth: 900,
            ),
          ),
        ),
        // Pudar ke bawah: foto menyatu dengan warna halaman (tanpa garis tepi)
        const IgnorePointer(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                stops: [0.0, 0.45, 1.0],
                colors: [
                  Color(0x00F4EFE6),
                  Color(0x00F4EFE6),
                  AppColors.background,
                ],
              ),
            ),
          ),
        ),
        ]),
      ),
    );
  }
}

/// Membungkus header (judul, ikon, dll.) dengan latar foto transparan.
/// [bulat] = true untuk header di dalam halaman yang punya padding samping.
class HeaderFoto extends StatelessWidget {
  final Widget child;
  final bool bulat;
  final String foto;

  const HeaderFoto({
    super.key,
    required this.child,
    this.bulat = false,
    this.foto = 'lib/images/houselogin.jpg',
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: HeaderFotoLatar(foto: foto, radius: bulat ? 18 : 0),
        ),
        bulat
            ? Padding(padding: const EdgeInsets.all(14), child: child)
            : child,
      ],
    );
  }
}

/// Logo RuangRancang (ikon rumah + nama) dengan ukuran yang bisa diatur.
class LogoRuangRancang extends StatelessWidget {
  final double ukuran; // tinggi ikon
  final Color? warna;

  const LogoRuangRancang({super.key, this.ukuran = 40, this.warna});

  @override
  Widget build(BuildContext context) {
    final c = warna ?? AppColors.primary;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(Icons.home_outlined, color: c, size: ukuran),
        const SizedBox(width: 8),
        Text('RuangRancang',
            style: AppTheme.heading(ukuran * 0.72).copyWith(color: c)),
      ],
    );
  }
}
