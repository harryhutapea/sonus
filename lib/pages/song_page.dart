import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:permission_handler/permission_handler.dart';

import 'package:sonus/models/song.dart';

// import 'package:sonus/services/database_service.dart';
import 'package:sonus/services/music_scanner_service.dart';

import 'package:sonus/theme/app_colors.dart';

import 'package:sonus/utils/hive_boxes.dart';

import 'package:sonus/widgets/hover_marquee_text.dart';
import 'package:sonus/widgets/song_editor_sheet.dart';

class SongPage extends StatefulWidget {
  const SongPage({super.key});

  @override
  State createState() => _SongPageState();
}

class _SongPageState extends State {
  bool _isScanning = false;
  // final _db = DatabaseService();
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
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Library updated!')));
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Permission required to see songs.')),
          );
        }
      }
    } catch (e) {
      print('Error: $e');
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
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
                    leading: Image.asset(
                      'assets/images/default_song_cover.png',
                    ),
                    title: HoverMarqueeText(song.songName),
                    subtitle: Text(song.artistName),
                    trailing: PopupMenuButton(
                      icon: const Icon(Icons.more_vert),
                      onSelected: (String result) {
                        if (result == 'Edit') {
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
