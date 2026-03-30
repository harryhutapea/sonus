import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sonus/models/playlist.dart';
import 'package:sonus/models/song.dart';
import 'package:sonus/pages/main_page.dart';
import 'package:sonus/services/player_service.dart';
import 'package:sonus/theme/app_colors.dart';
import 'package:sonus/utils/hive_boxes.dart';
import 'package:sonus/widgets/hover_marquee_text.dart';
import 'package:sonus/widgets/song_editor_sheet.dart';

class PlaylistDetailPage extends StatelessWidget {
  final Playlist playlist;

  const PlaylistDetailPage({super.key, required this.playlist});

  // ─── Cover helpers ─────────────────────────────────────────────────────────

  /// Safely builds a cover image that works for both asset paths and file paths.
  /// ✅ FIX: previously used Image.asset() for all paths, which crashes when
  /// coverPath is a local file path (e.g. /storage/emulated/0/...).
  Widget _buildCover(String path, {double size = 52, double radius = 8}) {
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Image.file(
            file,
            key: ValueKey(path),
            width: size,
            height: size,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: Image.asset(
        (isAsset && path.isNotEmpty)
            ? path
            : 'assets/images/default_song_cover.png',
        width: size,
        height: size,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildPlaylistCover(String path) {
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Image.file(
            file,
            key: ValueKey(path),
            height: 220,
            width: double.infinity,
            fit: BoxFit.cover,
          ),
        );
      }
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: Image.asset(
        (isAsset && path.isNotEmpty)
            ? path
            : 'assets/images/default_playlist_cover.png',
        height: 220,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  // ─── Add songs sheet ────────────────────────────────────────────────────────

  Future<void> _showAddSongsSheet(BuildContext context) async {
    final songBox = Hive.box<Song>(HiveBoxes.songs);
    final allSongs = songBox.values.toList();
    final existingPaths = (playlist.listOfSongs as List)
        .cast<Song>()
        .map((s) => s.songPath)
        .toSet();

    final availableSongs = allSongs
        .where((song) => !existingPaths.contains(song.songPath))
        .toList();
    final selectedPaths = <String>{};

    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (context, setStateSheet) {
              return SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.75,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text(
                              'Add songs',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () async {
                              playlist.listOfSongs.addAll(
                                availableSongs.where(
                                  (song) => selectedPaths.contains(song.songPath),
                                ),
                              );
                              await playlist.save();
                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: availableSongs.isEmpty
                          ? Center(
                              child: Text(
                                'No more songs available to add.',
                                style: TextStyle(color: AppColors.onSurface),
                              ),
                            )
                          : ListView.builder(
                              itemCount: availableSongs.length,
                              itemBuilder: (context, index) {
                                final song = availableSongs[index];
                                final selected =
                                    selectedPaths.contains(song.songPath);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (value) {
                                    setStateSheet(() {
                                      if (value == true) {
                                        selectedPaths.add(song.songPath);
                                      } else {
                                        selectedPaths.remove(song.songPath);
                                      }
                                    });
                                  },
                                  // ✅ FIX: was Image.asset(song.coverPath) — crashes on file paths
                                  secondary: _buildCover(song.coverPath),
                                  title: Text(song.songName),
                                  subtitle: Text(song.artistName),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  // ─── Song tile ──────────────────────────────────────────────────────────────

  Widget _buildSongTile(
    BuildContext context,
    Song song,
    int index,
    List<Song> allSongs,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(10),
        elevation: 2,
        child: ListTile(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          // ✅ FIX: was Image.asset(song.coverPath) — crashes on file paths
          leading: _buildCover(song.coverPath),
          title: HoverMarqueeText(song.songName),
          subtitle: Text(song.artistName),
          onTap: () {
            PlayerService().playQueue(allSongs, index, playlist.playlistName);
            Navigator.of(context).popUntil((route) => route.isFirst);
            MainPage.pageIndexNotifier.value = 1;
          },
          trailing: PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (value) async {
              if (value == 'edit') {
                await showSongEditorSheet(context, song);
              } else if (value == 'remove') {
                playlist.listOfSongs
                    .removeWhere((s) => s.songPath == song.songPath);
                await playlist.save();
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'remove',
                child: Text('Remove from playlist'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final coverPath = playlist.coverImagePath.isEmpty
        ? 'assets/images/default_playlist_cover.png'
        : playlist.coverImagePath;

    return Scaffold(
      appBar: AppBar(title: Text(playlist.playlistName), centerTitle: true),
      body: ValueListenableBuilder(
        valueListenable: Hive.box<Playlist>(HiveBoxes.playlist).listenable(),
        builder: (context, box, _) {
          final updatedPlaylist = box.get(playlist.key);
          final updatedSongs =
              (updatedPlaylist?.listOfSongs ?? playlist.listOfSongs)
                  .cast<Song>();

          return Column(
            children: [
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                // ✅ FIX: was Image.asset(coverPath) — crashes on file paths
                child: _buildPlaylistCover(coverPath),
              ),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.onSurface,
                      foregroundColor: AppColors.surfaceDim,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    onPressed: () => _showAddSongsSheet(context),
                    icon: const Icon(Icons.add),
                    label: const Text('Add songs'),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Expanded(
                child: updatedSongs.isEmpty
                    ? Center(
                        child: Text(
                          'No songs in this playlist yet.',
                          style: TextStyle(color: AppColors.onSurface),
                        ),
                      )
                    : ListView.builder(
                        itemCount: updatedSongs.length,
                        itemBuilder: (context, index) {
                          return _buildSongTile(
                            context,
                            updatedSongs[index],
                            index,
                            updatedSongs,
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}