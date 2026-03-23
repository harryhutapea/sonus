import 'package:flutter/material.dart';

import 'package:sonus/pages/home_page.dart';
import 'package:sonus/pages/playlist_page.dart';
import 'package:sonus/pages/song_page.dart';

import 'package:sonus/widgets/app_icon.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 1;

  final List<Widget> _pages = const [SongPage(), HomePage(), PlaylistPage()];

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          BottomNavigationBarItem(
            icon: AppIcon("song_icon_outline", color: Colors.white, size: 36),
            activeIcon: AppIcon("song_icon_fill", color: Colors.white, size: 36),
            label: 'Song',
          ),
          BottomNavigationBarItem(
            icon: AppIcon("home_icon_outline", color: Colors.white, size: 36),
            activeIcon: AppIcon("home_icon_fill", color: Colors.white, size: 36),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: AppIcon("playlist_icon_outline", color: Colors.white, size: 36),
            activeIcon: AppIcon("playlist_icon_fill", color: Colors.white, size: 36),
            label: 'Playlist',
          ),
        ],
      ),
    );
  }
}
