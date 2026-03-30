import 'dart:io';

import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:sonus/models/song.dart';
import 'package:sonus/pages/main_page.dart';
import 'package:sonus/services/music_scanner_service.dart';
import 'package:sonus/services/player_service.dart';
import 'package:sonus/theme/app_colors.dart';
import 'package:sonus/utils/hive_boxes.dart';
import 'package:sonus/widgets/hover_marquee_text.dart';
import 'package:sonus/widgets/song_editor_sheet.dart';

class SongPage extends StatefulWidget {
  const SongPage({super.key});

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  bool _isScanning = false;
  final _scanner = MusicScannerService();

  Future<void> _handleRescan() async {
    setState(() => _isScanning = true);
    try {
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio,
      ].request();

      if (statuses[Permission.audio]!.isGranted ||
          statuses[Permission.storage]!.isGranted) {
        await _scanner.syncLibrary();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Library updated!')),
          );
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('Permission required to see songs.')),
          );
        }
      }
    } catch (e) {
      debugPrint('Error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  /// Builds the cover widget for a song — respects file paths set by the
  /// editor as well as the default asset fallback.
  Widget _buildCover(Song song) {
    final path = song.coverPath;
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey(path), // ensures image cache is busted on path change
          width: 48,
          height: 48,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.asset(
      isAsset && path.isNotEmpty
          ? path
          : 'assets/images/default_song_cover.png',
      width: 48,
      height: 48,
      fit: BoxFit.cover,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Your Library'), centerTitle: true),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Song>(HiveBoxes.songs).listenable(),
        builder: (context, box, _) {
          final songs = box.values.toList();

          if (songs.isEmpty) {
            return const Center(
              child: Text('No songs found.\nClick \'+\' to scan.'),
            );
          }

          return ListView.builder(
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];

              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                child: Material(
                  color: AppColors.surfaceContainer,
                  borderRadius: BorderRadius.circular(10),
                  elevation: 2,
                  child: ListTile(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    onTap: () {
                      // Play the tapped song from the full "All Songs" queue
                      PlayerService().playQueue(songs, index, 'All Songs');
                      // Switch to the Home (player) tab
                      MainPage.pageIndexNotifier.value = 1;
                    },
                    // ✅ Fixed: was always showing the default asset.
                    //    Now reads song.coverPath and handles file paths too.
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: _buildCover(song),
                    ),
                    title: HoverMarqueeText(song.songName),
                    subtitle: Text(song.artistName),
                    trailing: PopupMenuButton<String>(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String result) {
                        if (result == 'Edit') {
                          // microtask keeps us off the build frame so no
                          // setState-during-build issues.
                          Future.microtask(() {
                            if (!context.mounted) return;
                            showSongEditorSheet(context, song);
                          });
                        }
                      },
                      itemBuilder: (BuildContext context) => const [
                        PopupMenuItem(value: 'Edit', child: Text('Edit')),
                      ],
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning ? null : _handleRescan,
        child: const Icon(Icons.sync),
      ),
    );
  }
}