import 'package:flutter/material.dart';
import '../data/arsitek_data.dart';

/// Foto arsitek. Kalau file fotonya belum ada, otomatis tampil
/// placeholder berwarna dengan inisial nama (mis. "AW").
class ArsitekFoto extends StatelessWidget {
  final Arsitek arsitek;
  final double? width;
  final double? height;
  final BorderRadius borderRadius;
  final double fontSize;

  const ArsitekFoto({
    super.key,
    required this.arsitek,
    this.width,
    this.height,
    this.borderRadius = BorderRadius.zero,
    this.fontSize = 32,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: borderRadius,
      child: SizedBox(
        width: width,
        height: height,
        child: Image.asset(
          arsitek.foto,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
          errorBuilder: (context, error, stack) => _placeholder(),
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            arsitek.warna,
            Color.lerp(arsitek.warna, Colors.black, 0.35)!,
          ],
        ),
      ),
      alignment: Alignment.center,
      child: Text(
        arsitek.inisial,
        style: TextStyle(
          color: Colors.white.withValues(alpha: 0.92),
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          letterSpacing: 1,
        ),
      ),
    );
  }
}