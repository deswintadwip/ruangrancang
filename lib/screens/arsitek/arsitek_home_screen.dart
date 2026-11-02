import 'package:flutter/material.dart';
import '../../theme/app_theme.dart';
import '../home/profil_tab.dart';
import 'arsitek_beranda_tab.dart';
import 'arsitek_jadwal_tab.dart';
import 'arsitek_konsultasi_tab.dart';
import 'arsitek_sketsa_tab.dart';
import '../../widgets/tracking_bar.dart';

/// Cangkang Beranda Arsitek: bar bawah 4 tab (Beranda, Konsultasi,
/// Jadwal, Profil) dengan gaya yang sama seperti sisi user.
class ArsitekHomeScreen extends StatefulWidget {
  const ArsitekHomeScreen({super.key});

  @override
  State<ArsitekHomeScreen> createState() => _ArsitekHomeScreenState();
}

class _ArsitekHomeScreenState extends State<ArsitekHomeScreen> {
  int _index = 0;

  void _buka(int i) => setState(() => _index = i);

  @override
  Widget build(BuildContext context) {
    final pages = [
      ArsitekBerandaTab(onOpenTab: _buka),
      const ArsitekKonsultasiTab(),
      const ArsitekSketsaTab(),
      const ArsitekJadwalTab(),
      const ProfilTab(modeArsitek: true),
    ];

    return Scaffold(
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const TrackingBarArsitek(),
          NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _buka,
            backgroundColor: AppColors.surface,
            indicatorColor: AppColors.primary.withValues(alpha: 0.12),
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home, color: AppColors.primary),
                label: 'Beranda',
              ),
              NavigationDestination(
                icon: Icon(Icons.format_list_bulleted),
                selectedIcon:
                Icon(Icons.format_list_bulleted, color: AppColors.primary),
                label: 'Konsultasi',
              ),
              NavigationDestination(
                icon: Icon(Icons.draw_outlined),
                selectedIcon: Icon(Icons.draw, color: AppColors.primary),
                label: 'Sketsa',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month, color: AppColors.primary),
                label: 'Jadwal',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person, color: AppColors.primary),
                label: 'Profil',
              ),
            ],
          ),
        ],
      ),
    );
  }
}