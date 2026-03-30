import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'package:sonus/models/playlist.dart';
import 'package:sonus/models/song.dart';
import 'package:sonus/theme/app_colors.dart';
import 'package:sonus/utils/hive_boxes.dart';

class AddToPlaylistPage extends StatefulWidget {
  final Song song;

  const AddToPlaylistPage({super.key, required this.song});

  @override
  State<AddToPlaylistPage> createState() => _AddToPlaylistPageState();
}

class _AddToPlaylistPageState extends State<AddToPlaylistPage> {
  // ─── Cover helpers ────────────────────────────────────────────────────────

  Widget _buildSongCover(double size) {
    final path = widget.song.coverPath;
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.asset(
      (isAsset && path.isNotEmpty)
          ? path
          : 'assets/images/default_song_cover.png',
      key: ValueKey(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  Widget _buildPlaylistCover(Playlist playlist) {
    final path = playlist.coverImagePath;
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey(path),
          width: 52,
          height: 52,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.asset(
      isAsset && path.isNotEmpty
          ? path
          : 'assets/images/default_playlist_cover.png',
      width: 52,
      height: 52,
      fit: BoxFit.cover,
    );
  }

  // ─── Check / toggle song in playlist ─────────────────────────────────────

  bool _isSongInPlaylist(Playlist playlist) {
    return playlist.listOfSongs
        .any((s) => s.songPath == widget.song.songPath);
  }

  Future<void> _toggleSongInPlaylist(Playlist playlist) async {
    final alreadyAdded = _isSongInPlaylist(playlist);

    if (alreadyAdded) {
      playlist.listOfSongs
          .removeWhere((s) => s.songPath == widget.song.songPath);
    } else {
      playlist.listOfSongs.add(widget.song);
    }

    await playlist.save();

    if (mounted) {
      ScaffoldMessenger.of(context)
        ..clearSnackBars()
        ..showSnackBar(
          SnackBar(
            content: Text(
              alreadyAdded
                  ? 'Removed from "${playlist.playlistName}"'
                  : 'Added to "${playlist.playlistName}"',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 2),
          ),
        );
    }
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final coverSize = screenWidth * 0.80;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.song.songName,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        centerTitle: true,
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 16),

          // ── Song cover ──────────────────────────────────────────────────
          Center(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.50),
                    blurRadius: 36,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _buildSongCover(coverSize),
              ),
            ),
          ),

          const SizedBox(height: 20),

          // ── Playlist list ───────────────────────────────────────────────
          Expanded(
            child: ValueListenableBuilder(
              valueListenable:
                  Hive.box<Playlist>(HiveBoxes.playlist).listenable(),
              builder: (context, Box box, _) {
                if (box.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Text(
                        'No playlists yet.\nCreate one in the Playlists tab.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          color: AppColors.onSurfaceVariant,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return Container(
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceContainer,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    itemCount: box.length,
                    separatorBuilder: (_, _) => Divider(
                      color: AppColors.onSurfaceVariant.withValues(alpha: 0.15),
                      height: 1,
                      indent: 76,
                      endIndent: 16,
                    ),
                    itemBuilder: (context, index) {
                      final playlist = box.getAt(index) as Playlist?;
                      if (playlist == null) return const SizedBox.shrink();

                      final inPlaylist = _isSongInPlaylist(playlist);

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        leading: ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _buildPlaylistCover(playlist),
                        ),
                        title: Text(
                          playlist.playlistName,
                          style: TextStyle(
                            color: AppColors.onSurface,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          '${playlist.listOfSongs.length} songs',
                          style: TextStyle(
                            color: AppColors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                        trailing: Icon(
                          inPlaylist
                              ? Icons.bookmark_rounded
                              : Icons.bookmark_border_rounded,
                          color: inPlaylist
                              ? Colors.white
                              : AppColors.onSurfaceVariant,
                          size: 24,
                        ),
                        onTap: () => _toggleSongInPlaylist(playlist),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}