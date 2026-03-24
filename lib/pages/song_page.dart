import 'package:flutter/material.dart';

import 'package:sonus/services/database_service.dart';
import 'package:sonus/services/music_scanner_service.dart';

import 'package:sonus/theme/app_colors.dart';

import 'package:sonus/widgets/hover_marquee_text.dart';

import 'package:permission_handler/permission_handler.dart';

class SongPage extends StatefulWidget {
  const SongPage({super.key});

  @override
  State<SongPage> createState() => _SongPageState();
}

class _SongPageState extends State<SongPage> {
  bool _isScanning = false;
  final _db = DatabaseService();
  final _scanner = MusicScannerService();

  Future<void> _handleRescan() async {
    setState(() => _isScanning = true);

    try {
      // This checks both the old storage permission AND the new audio permission
      Map<Permission, PermissionStatus> statuses = await [
        Permission.storage,
        Permission.audio,
      ].request();

      // If either is granted (depending on Android version), proceed
      if (statuses[Permission.audio]!.isGranted ||
          statuses[Permission.storage]!.isGranted) {
        await _scanner.syncLibrary();

        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text("Library updated!")));
        }
      } else {
        // If denied, show a message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Permission required to see songs.")),
          );
        }
      }
    } catch (e) {
      print("Error: $e");
    } finally {
      if (mounted) setState(() => _isScanning = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final songs = _db.getAllSongs();

    return Scaffold(
      appBar: AppBar(title: const Text("Your Library"), centerTitle: true),

      // Use a Stack so we can show a loading spinner over the list
      body: Stack(
        children: [
          // 1. The Song List
          songs.isEmpty
              ? const Center(child: Text("No songs found. Click '+' to scan."))
              : ListView.builder(
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
                          leading: Image.asset("assets/images/default_song_cover.png"),
                          title: HoverMarqueeText(song.songName),
                          subtitle: Text(song.artistName),
                          trailing: PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert),
                            onSelected: (String result) async {
                            },
                            itemBuilder: (BuildContext context) => [
                              const PopupMenuItem(
                                value: 'Edit',
                                child: Text('Edit'),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),

          // 2. The Loading Overlay (only shows when _isScanning is true)
          if (_isScanning)
            Container(
              color: Colors.black.withValues(alpha: 0.5),
              child: const Center(child: CircularProgressIndicator()),
            ),
        ],
      ),

      // 3. The Floating Action Button
      floatingActionButton: FloatingActionButton(
        onPressed: _isScanning
            ? null
            : _handleRescan, // Disable button while scanning
        child: const Icon(Icons.sync),
      ),
    );
  }
}
