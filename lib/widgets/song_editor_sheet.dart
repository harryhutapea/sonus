import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:sonus/models/song.dart';
import 'package:sonus/theme/app_colors.dart';

Future<void> showSongEditorSheet(
  BuildContext context,
  Song song,
) async {
  final songNameController = TextEditingController(text: song.songName);
  final artistNameController = TextEditingController(
    text: song.artistName == 'Unknown Artist' ? '' : song.artistName,
  );

  String coverPath = song.coverPath;

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: EdgeInsets.only(
            left: 16,
            right: 16,
            top: 16,
            bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
          ),
          child: StatefulBuilder(
            builder: (context, setState) {
              final file = File(coverPath);
              final hasFileCover =
                  coverPath.isNotEmpty && !coverPath.startsWith('assets/') && file.existsSync();

              final coverPreview = ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: hasFileCover
                    ? Image.file(
                        file,
                        width: 170,
                        height: 170,
                        fit: BoxFit.cover,
                      )
                    : Image.asset(
                        coverPath.isEmpty
                            ? 'assets/images/default_song_cover.png'
                            : coverPath,
                        width: 170,
                        height: 170,
                        fit: BoxFit.cover,
                      ),
              );

              return SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    coverPreview,
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );
                        final path = result?.files.single.path;
                        if (path != null) {
                          setState(() => coverPath = path);
                        }
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Change cover image'),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'song name',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: songNameController,
                      decoration: const InputDecoration(
                        hintText: 'Current song name',
                      ),
                    ),
                    const SizedBox(height: 12),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'artist name',
                        style: TextStyle(
                          color: AppColors.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    TextField(
                      controller: artistNameController,
                      decoration: const InputDecoration(
                        hintText: 'Current artist name',
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton(
                            onPressed: () => Navigator.pop(sheetContext),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.onSurface,
                              foregroundColor: AppColors.surfaceDim,
                            ),
                            onPressed: () async {
                              final newSongName = songNameController.text.trim();
                              final newArtistName = artistNameController.text.trim();

                              if (newSongName.isEmpty) return;

                              song.songName = newSongName;
                              song.artistName = newArtistName.isEmpty
                                  ? 'Unknown Artist'
                                  : newArtistName;
                              song.coverPath = coverPath.isEmpty
                                  ? 'assets/images/default_song_cover.png'
                                  : coverPath;

                              await song.save();

                              if (sheetContext.mounted) {
                                Navigator.pop(sheetContext);
                              }
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      );
    },
  );

  songNameController.dispose();
  artistNameController.dispose();
}