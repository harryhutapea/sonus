import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sonus/models/playlist.dart';
import 'package:sonus/models/song.dart';
import 'package:sonus/pages/playlist_detail_page.dart';
import 'package:sonus/services/database_service.dart';
import 'package:sonus/theme/app_colors.dart';
import 'package:sonus/utils/hive_boxes.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  // ── Song picker sheet ──────────────────────────────────────────────────────

  Future<List<Song>?> _pickSongsForPlaylist(
    BuildContext context, {
    required List<Song> currentSongs,
  }) async {
    final allSongs = DatabaseService().getAllSongs().cast<Song>().toList();
    final selectedPaths = currentSongs.map((s) => s.songPath).toSet();

    return showModalBottomSheet<List<Song>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setStateSheet) {
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
                              'Select songs',
                              style: TextStyle(
                                color: AppColors.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: () {
                              final chosen = allSongs
                                  .where((s) =>
                                      selectedPaths.contains(s.songPath))
                                  .toList();
                              Navigator.pop(sheetContext, chosen);
                            },
                            child: const Text('Done'),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: allSongs.isEmpty
                          ? Center(
                              child: Text(
                                'No songs found in your library.',
                                style:
                                    TextStyle(color: AppColors.onSurface),
                              ),
                            )
                          : ListView.builder(
                              itemCount: allSongs.length,
                              itemBuilder: (context, index) {
                                final song = allSongs[index];
                                final selected =
                                    selectedPaths.contains(song.songPath);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (value) {
                                    setStateSheet(() {
                                      if (value == true) {
                                        selectedPaths.add(song.songPath);
                                      } else {
                                        selectedPaths
                                            .remove(song.songPath);
                                      }
                                    });
                                  },
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

  // ── Create / edit dialog ───────────────────────────────────────────────────

  void _showCreateOrEditDialog(
    BuildContext context, {
    Playlist? playlist,
  }) {
    final Box<Playlist> box = Hive.box<Playlist>(HiveBoxes.playlist);
    final nameController = TextEditingController(
      text: playlist?.playlistName ?? '',
    );

    // Mutable state held in a ValueNotifier so StatefulBuilder can update it.
    // Using a simple wrapper class keeps the dialog clean.
    final List<Song> selectedSongs = playlist == null
        ? <Song>[]
        : (playlist.listOfSongs as List).cast<Song>().toList();

    // coverPath starts from the existing playlist value (or default asset).
    String coverPath = playlist?.coverImagePath ??
        'assets/images/default_song_cover.png';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (ctx, setStateDialog) {
            // ── Cover preview widget ─────────────────────────────────────
            final isAsset =
                coverPath.isEmpty || coverPath.startsWith('assets/');
            final coverFile = isAsset ? null : File(coverPath);
            final hasFileCover =
                coverFile != null && coverFile.existsSync();

            final coverWidget = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: hasFileCover
                  ? Image.file(
                      coverFile,
                      key: ValueKey(coverPath),
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    )
                  : Image.asset(
                      coverPath.isEmpty
                          ? 'assets/images/default_song_cover.png'
                          : coverPath,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
            );

            return AlertDialog(
              backgroundColor: AppColors.surface,
              title: Text(
                playlist == null ? 'Create Playlist' : 'Edit Playlist',
                style: TextStyle(color: AppColors.onSurface),
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Cover section ──────────────────────────────────
                    Center(child: coverWidget),
                    const SizedBox(height: 8),
                    Center(
                      child: TextButton.icon(
                        onPressed: () async {
                          final result =
                              await FilePicker.platform.pickFiles(
                            type: FileType.image,
                            allowMultiple: false,
                          );
                          final path = result?.files.single.path;
                          if (path != null) {
                            setStateDialog(() => coverPath = path);
                          }
                        },
                        icon: const Icon(Icons.image_outlined),
                        label: const Text('Change cover image'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Name field ─────────────────────────────────────
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Playlist name',
                        labelStyle:
                            TextStyle(color: AppColors.onSurface),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                              color: AppColors.onSurfaceVariant),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide:
                              BorderSide(color: AppColors.onSurface),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Song count / picker ────────────────────────────
                    Text(
                      '${selectedSongs.length} songs selected',
                      style: TextStyle(color: AppColors.onSurfaceVariant),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppColors.onSurface,
                        ),
                        onPressed: () async {
                          // Use dialogContext so the sheet sits on top of
                          // the dialog, not behind it.
                          final pickedSongs =
                              await _pickSongsForPlaylist(
                            dialogContext,
                            currentSongs: selectedSongs,
                          );
                          if (pickedSongs != null) {
                            setStateDialog(() {
                              selectedSongs
                                ..clear()
                                ..addAll(pickedSongs);
                            });
                          }
                        },
                        child: const Text('Choose songs'),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (selectedSongs.isNotEmpty)
                      ...selectedSongs.take(3).map(
                            (song) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Text(
                                '• ${song.songName}',
                                style: TextStyle(
                                    color: AppColors.onSurfaceVariant),
                              ),
                            ),
                          ),
                    if (selectedSongs.length > 3)
                      Text(
                        '…and ${selectedSongs.length - 3} more',
                        style: TextStyle(
                            color: AppColors.onSurfaceVariant),
                      ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  style: TextButton.styleFrom(
                    foregroundColor: AppColors.onSurface,
                  ),
                  onPressed: () => Navigator.pop(dialogContext),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.onSurface,
                    foregroundColor: AppColors.surfaceDim,
                  ),
                  onPressed: () async {
                    final name = nameController.text.trim();
                    if (name.isEmpty) return;

                    final resolvedCover = coverPath.isEmpty
                        ? 'assets/images/default_song_cover.png'
                        : coverPath;

                    if (playlist == null) {
                      await box.add(
                        Playlist(
                          playlistName: name,
                          listOfSongs: selectedSongs,
                          coverImagePath: resolvedCover,
                        ),
                      );
                    } else {
                      playlist.playlistName = name;
                      playlist.listOfSongs = selectedSongs;
                      playlist.coverImagePath = resolvedCover;
                      await playlist.save();
                    }

                    // ✅ Fixed: was using dialogContext which could be stale
                    //    after the song picker sheet was pushed on top.
                    if (dialogContext.mounted) {
                      Navigator.pop(dialogContext);
                    }
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    ).whenComplete(() {
      nameController.dispose();
    });
  }

  // ── Cover helper for list tiles ────────────────────────────────────────────

  Widget _buildPlaylistCover(Playlist playlist) {
    final path = playlist.coverImagePath;
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey(path),
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

  // ── Build ──────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final Box<Playlist> box = Hive.box<Playlist>(HiveBoxes.playlist);

    return Scaffold(
      appBar: AppBar(title: const Text('Playlists'), centerTitle: true),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text('No playlist yet.\nTap + to create.'),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final playlist = box.getAt(index) as Playlist?;
              if (playlist == null) return const SizedBox.shrink();

              return ListTile(
                // ✅ Fixed: was always Image.asset — now respects file paths.
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildPlaylistCover(playlist),
                ),
                title: Text(playlist.playlistName),
                subtitle: Text('${playlist.listOfSongs.length} songs'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) =>
                          PlaylistDetailPage(playlist: playlist),
                    ),
                  );
                },
                trailing: PopupMenuButton<String>(
                  onSelected: (value) async {
                    if (value == 'edit') {
                      _showCreateOrEditDialog(context, playlist: playlist);
                    } else if (value == 'delete') {
                      await playlist.delete();
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(value: 'edit', child: Text('Edit')),
                    PopupMenuItem(value: 'delete', child: Text('Delete')),
                  ],
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.onSurface,
        foregroundColor: AppColors.surfaceDim,
        onPressed: () => _showCreateOrEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }
}