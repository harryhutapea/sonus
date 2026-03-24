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

  Future<List<Song>?> _pickSongsForPlaylist(
    BuildContext context, {
    required List<Song> currentSongs,
  }) async {
    final allSongs = DatabaseService().getAllSongs().cast<Song>().toList();
    final selectedPaths = currentSongs.map((song) => song.songPath).toSet();

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
                              final chosenSongs = allSongs
                                  .where(
                                    (song) =>
                                        selectedPaths.contains(song.songPath),
                                  )
                                  .toList();
                              Navigator.pop(sheetContext, chosenSongs);
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
                                style: TextStyle(color: AppColors.onSurface),
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
                                        selectedPaths.remove(song.songPath);
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

  void _showCreateOrEditDialog(
    BuildContext context, {
    Playlist? playlist,
  }) {
    final Box<Playlist> box = Hive.box<Playlist>(HiveBoxes.playlist);
    final nameController = TextEditingController(
      text: playlist?.playlistName ?? '',
    );

    final List<Song> selectedSongs = playlist == null
        ? <Song>[]
        : (playlist.listOfSongs as List).cast<Song>().toList();

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
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
                    TextField(
                      controller: nameController,
                      decoration: InputDecoration(
                        labelText: 'Playlist name',
                        labelStyle: TextStyle(color: AppColors.onSurface),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.onSurfaceVariant,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
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
                          final pickedSongs = await _pickSongsForPlaylist(
                            context,
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
                                  color: AppColors.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ),
                    if (selectedSongs.length > 3)
                      Text(
                        '…and ${selectedSongs.length - 3} more',
                        style: TextStyle(color: AppColors.onSurfaceVariant),
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

                    if (playlist == null) {
                      await box.add(
                        Playlist(
                          playlistName: name,
                          listOfSongs: selectedSongs,
                        ),
                      );
                    } else {
                      playlist.playlistName = name;
                      playlist.listOfSongs = selectedSongs;
                      await playlist.save();
                    }

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
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<Playlist> box = Hive.box<Playlist>(HiveBoxes.playlist);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Playlists'),
        centerTitle: true,
      ),
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
                leading: Image.asset(playlist.coverImagePath),
                title: Text(playlist.playlistName),
                subtitle: Text('${playlist.listOfSongs.length} songs'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => PlaylistDetailPage(playlist: playlist),
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