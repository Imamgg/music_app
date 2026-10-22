import 'package:auno/core/localization/app_strings.dart';
import '../widgets/glass_surface.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../providers/audio_player_provider.dart';
import '../widgets/mini_player_widget.dart';
import 'home/home_screen.dart';
import 'library/library_screen.dart';
import 'search/search_screen.dart';

class MainShell extends ConsumerStatefulWidget {
  const MainShell({super.key});

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    SearchScreen(),
    LibraryScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    ref.listen(audioPlayerProvider.select((s) => s.errorMessage), (prev, next) {
      if (next != null && next.isNotEmpty && next != prev) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: AppText(next),
            backgroundColor: AppColors.error,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    });

    final playerState = ref.watch(audioPlayerProvider);
    final hasSong = playerState.hasCurrentSong;

    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: IndexedStack(index: _currentIndex, children: _screens),
          ),
          if (hasSong) const MiniPlayerWidget(),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: GlassSurface(
            radius: 24,
            child: BottomNavigationBar(
              elevation: 0,
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                });
              },
              backgroundColor: Colors.transparent,
              selectedItemColor: AppColors.textPrimary,
              unselectedItemColor: AppColors.textMuted,
              items: [
                BottomNavigationBarItem(
                  icon: Icon(Icons.home_filled),
                  activeIcon: Icon(
                    Icons.home_filled,
                    color: AppColors.textPrimary,
                  ),
                  label: context.tr('Beranda'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  activeIcon: Icon(Icons.search, color: AppColors.textPrimary),
                  label: context.tr('Cari'),
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.library_music_outlined),
                  activeIcon: Icon(
                    Icons.library_music,
                    color: AppColors.textPrimary,
                  ),
                  label: context.tr('Koleksi Kamu'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
