import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'firebase_options.dart';
import 'screens/splash_screen.dart';
import 'theme/app_theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Mode debug: OTP memakai NOMOR UJI dari console Firebase (tanpa SMS asli)
  if (kDebugMode) {
    await FirebaseAuth.instance.setSettings(
      appVerificationDisabledForTesting: true,
    );
  }

  runApp(const RuangRancangApp());
}

/// Setelan scroll global: izinkan menggulung dengan mouse & trackpad
/// (bukan cuma roda mouse / scrollbar). Tanpa ini, di web halaman TIDAK bisa
/// di-scroll dengan cara klik-tahan-geser pakai mouse.
class _AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.trackpad,
    PointerDeviceKind.stylus,
  };
}

class RuangRancangApp extends StatelessWidget {
  const RuangRancangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RuangRancang',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      scrollBehavior: _AppScrollBehavior(),
      home: const SplashScreen(),
    );
  }
}