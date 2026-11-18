import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

/// Membungkus widget yang isinya scroll HORIZONTAL (PageView / ListView samping)
/// supaya putaran roda mouse arah VERTIKAL tetap menggulung halaman di
/// belakangnya, bukan "nyangkut" di carousel.
///
/// Khusus berguna di web/desktop (mouse/trackpad). Di HP (sentuhan) tidak ada
/// pointer-signal, jadi perilakunya tidak berubah sama sekali.
class ForwardWheel extends StatelessWidget {
  /// Controller milik scroll halaman (ListView vertikal di belakang).
  final ScrollController parent;
  final Widget child;

  const ForwardWheel({super.key, required this.parent, required this.child});

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerSignal: (event) {
        if (event is! PointerScrollEvent) return;
        if (!parent.hasClients) return;

        final dy = event.scrollDelta.dy;
        // Hanya teruskan kalau gerakannya memang dominan vertikal, biar geser
        // samping (horizontal) carousel tetap normal.
        if (dy.abs() <= event.scrollDelta.dx.abs()) return;

        final pos = parent.position;
        final target =
        (parent.offset + dy).clamp(pos.minScrollExtent, pos.maxScrollExtent);
        parent.jumpTo(target);
      },
      child: child,
    );
  }
}