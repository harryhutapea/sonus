import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sonus/models/playlist.dart';
import 'package:sonus/models/song.dart';
import 'package:sonus/pages/main_page.dart';
import 'package:sonus/pages/playlist_detail_page.dart';
import 'package:sonus/services/database_service.dart';
import 'package:sonus/services/player_service.dart';
import 'package:sonus/theme/app_colors.dart';
import 'package:sonus/utils/hive_boxes.dart';

class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  Widget _buildPlaylistCover(Playlist playlist) {
    final path = playlist.coverImagePath;
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(file, key: ValueKey(path), width: 48, height: 48, fit: BoxFit.cover);
      }
    }

    return Image.asset(
      isAsset && path.isNotEmpty ? path : 'assets/images/default_song_cover.png',
      width: 48, height: 48, fit: BoxFit.cover,
    );
  }

  void _showCreateOrEditDialog(BuildContext context, {Playlist? playlist}) {
    showDialog<void>(
      context: context,
      builder: (_) => _PlaylistFormDialog(playlist: playlist),
    );
  }

  @override
  Widget build(BuildContext context) {
    final Box<Playlist> box = Hive.box<Playlist>(HiveBoxes.playlist);

    return Scaffold(
      appBar: AppBar(title: const Text('Playlists'), centerTitle: true),
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box box, _) {
          if (box.isEmpty) {
            return const Center(child: Text('No playlist yet.\nTap + to create.'));
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              final playlist = box.getAt(index) as Playlist?;
              if (playlist == null) return const SizedBox.shrink();

              return ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _buildPlaylistCover(playlist),
                ),
                title: Text(playlist.playlistName),
                subtitle: Text('${playlist.listOfSongs.length} songs'),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PlaylistDetailPage(playlist: playlist)),
                  );
                },
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Play button ─────────────────────────────────────────
                    IconButton(
                      icon: const Icon(Icons.play_circle_rounded),
                      iconSize: 28,
                      color: AppColors.onSurface,
                      tooltip: 'Play playlist',
                      onPressed: () {
                        final songs = (playlist.listOfSongs as List)
                            .cast<Song>()
                            .toList();
                        if (songs.isEmpty) return;
                        PlayerService().playQueue(
                          songs,
                          0,
                          playlist.playlistName,
                        );
                        MainPage.pageIndexNotifier.value = 1;
                      },
                    ),
                    // ── Three-dot menu ──────────────────────────────────────
                    PopupMenuButton<String>(
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

// ─────────────────────────────────────────────────────────────────────────────
// Proper StatefulWidget dialog — fixes _dependents.isEmpty assertion error
// and keyboard open/close slowness caused by StatefulBuilder + TextField combo.
// ─────────────────────────────────────────────────────────────────────────────

class _PlaylistFormDialog extends StatefulWidget {
  final Playlist? playlist;
  const _PlaylistFormDialog({this.playlist});

  @override
  State<_PlaylistFormDialog> createState() => _PlaylistFormDialogState();
}

class _PlaylistFormDialogState extends State<_PlaylistFormDialog> {
  late final TextEditingController _nameController;
  late List<Song> _selectedSongs;
  late String _coverPath;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.playlist?.playlistName ?? '');
    _selectedSongs = widget.playlist == null
        ? <Song>[]
        : (widget.playlist!.listOfSongs as List).cast<Song>().toList();
    _coverPath = widget.playlist?.coverImagePath ?? 'assets/images/default_playlist_cover.png';
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickSongs() async {
    final allSongs = DatabaseService().getAllSongs().cast<Song>().toList();
    final selectedPaths = _selectedSongs.map((s) => s.songPath).toSet();

    final picked = await showModalBottomSheet<List<Song>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: StatefulBuilder(
            builder: (ctx, setSheetState) {
              return SizedBox(
                height: MediaQuery.of(sheetContext).size.height * 0.75,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Text('Select songs',
                              style: TextStyle(color: AppColors.onSurface, fontSize: 18, fontWeight: FontWeight.w700)),
                          ),
                          TextButton(
                            onPressed: () {
                              final chosen = allSongs.where((s) => selectedPaths.contains(s.songPath)).toList();
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
                          ? Center(child: Text('No songs found.', style: TextStyle(color: AppColors.onSurface)))
                          : ListView.builder(
                              itemCount: allSongs.length,
                              itemBuilder: (context, index) {
                                final song = allSongs[index];
                                final selected = selectedPaths.contains(song.songPath);
                                return CheckboxListTile(
                                  value: selected,
                                  onChanged: (value) {
                                    setSheetState(() {
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

    if (!mounted) return;
    if (picked != null) {
      setState(() {
        _selectedSongs..clear()..addAll(picked);
      });
    }
  }

  Future<void> _pickCoverImage() async {
    final result = await FilePicker.platform.pickFiles(type: FileType.image, allowMultiple: false);
    final path = result?.files.single.path;
    if (path != null && mounted) setState(() => _coverPath = path);
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) return;

    final resolvedCover = _coverPath.isEmpty ? 'assets/images/default_playlist_cover.png' : _coverPath;
    final box = Hive.box<Playlist>(HiveBoxes.playlist);

    if (widget.playlist == null) {
      await box.add(Playlist(playlistName: name, listOfSongs: _selectedSongs, coverImagePath: resolvedCover));
    } else {
      widget.playlist!
        ..playlistName = name
        ..listOfSongs = _selectedSongs
        ..coverImagePath = resolvedCover;
      await widget.playlist!.save();
    }

    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final isAsset = _coverPath.isEmpty || _coverPath.startsWith('assets/');
    final coverFile = isAsset ? null : File(_coverPath);
    final hasFileCover = coverFile != null && coverFile.existsSync();

    final coverWidget = ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: hasFileCover
          ? Image.file(coverFile, key: ValueKey(_coverPath), width: 80, height: 80, fit: BoxFit.cover)
          : Image.asset(
              _coverPath.isEmpty ? 'assets/images/default_playlist_cover.png' : _coverPath,
              width: 80, height: 80, fit: BoxFit.cover),
    );

    return AlertDialog(
      backgroundColor: AppColors.surface,
      title: Text(
        widget.playlist == null ? 'Create Playlist' : 'Edit Playlist',
        style: TextStyle(color: AppColors.onSurface),
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(child: coverWidget),
            const SizedBox(height: 8),
            Center(
              child: TextButton.icon(
                onPressed: _pickCoverImage,
                icon: const Icon(Icons.image_outlined),
                label: const Text('Change cover image'),
                style: TextButton.styleFrom(foregroundColor: AppColors.onSurface),
              ),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: 'Playlist name',
                labelStyle: TextStyle(color: AppColors.onSurface),
                enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.onSurfaceVariant)),
                focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: AppColors.onSurface)),
              ),
            ),
            const SizedBox(height: 14),
            Text('${_selectedSongs.length} songs selected', style: TextStyle(color: AppColors.onSurfaceVariant)),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.onSurface),
                onPressed: _pickSongs,
                child: const Text('Choose songs'),
              ),
            ),
            const SizedBox(height: 12),
            if (_selectedSongs.isNotEmpty)
              ..._selectedSongs.take(3).map(
                    (song) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Text('• ${song.songName}', style: TextStyle(color: AppColors.onSurfaceVariant)),
                    ),
                  ),
            if (_selectedSongs.length > 3)
              Text('…and ${_selectedSongs.length - 3} more', style: TextStyle(color: AppColors.onSurfaceVariant)),
          ],
        ),
      ),
      actions: [
        TextButton(
          style: TextButton.styleFrom(foregroundColor: AppColors.onSurface),
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.onSurface, foregroundColor: AppColors.surfaceDim),
          onPressed: _save,
          child: const Text('Save'),
        ),
      ],
    );
  }
}