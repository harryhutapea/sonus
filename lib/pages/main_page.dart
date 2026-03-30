import 'package:flutter/material.dart';

import 'package:sonus/pages/home_page.dart';
import 'package:sonus/pages/playlist_page.dart';
import 'package:sonus/pages/song_page.dart';
import 'package:sonus/widgets/app_icon.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  /// Static notifier so any page can switch tabs without needing a BuildContext
  /// that reaches up to MainPage.  Value: 0 = Songs, 1 = Home, 2 = Playlists.
  static final pageIndexNotifier = ValueNotifier<int>(1);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  static const List<Widget> _pages = [SongPage(), HomePage(), PlaylistPage()];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: MainPage.pageIndexNotifier,
      builder: (context, selectedIndex, _) {
        return Scaffold(
          body: IndexedStack(
            index: selectedIndex,
            children: _pages,
          ),
          bottomNavigationBar: BottomNavigationBar(
            currentIndex: selectedIndex,
            onTap: (index) => MainPage.pageIndexNotifier.value = index,
            items: const [
              BottomNavigationBarItem(
                icon: AppIcon('song_icon_outline', color: Colors.white, size: 36),
                activeIcon: AppIcon('song_icon_fill', color: Colors.white, size: 36),
                label: 'Song',
              ),
              BottomNavigationBarItem(
                icon: AppIcon('home_icon_outline', color: Colors.white, size: 36),
                activeIcon: AppIcon('home_icon_fill', color: Colors.white, size: 36),
                label: 'Home',
              ),
              BottomNavigationBarItem(
                icon: AppIcon('playlist_icon_outline', color: Colors.white, size: 36),
                activeIcon: AppIcon('playlist_icon_fill', color: Colors.white, size: 36),
                label: 'Playlist',
              ),
            ],
          ),
        );
      },
    );
  }
}