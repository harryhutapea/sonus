import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import 'package:sonus/models/song.dart';
import 'package:sonus/theme/app_colors.dart';

Future<void> showSongEditorSheet(BuildContext context, Song song) async {
  // Controllers must be created before the sheet opens and disposed only
  // after it fully closes — using whenComplete avoids the _dependents.isEmpty
  // crash that happened when they were disposed right after await returned.
  final songNameController = TextEditingController(text: song.songName);
  final artistNameController = TextEditingController(
    text: song.artistName == 'Unknown Artist' ? '' : song.artistName,
  );

  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) {
      // coverPath lives inside StatefulBuilder so setState() can rebuild only
      // the sheet, not the whole page — this also fixes keyboard jank because
      // MediaQuery.of(sheetContext).viewInsets is read inside the builder now.
      String coverPath = song.coverPath;

      return StatefulBuilder(
        builder: (context, setSheetState) {
          final file = File(coverPath);
          final hasFileCover =
              coverPath.isNotEmpty &&
              !coverPath.startsWith('assets/') &&
              file.existsSync();

          final coverPreview = ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: hasFileCover
                ? Image.file(
                    file,
                    key: ValueKey(coverPath), // bust Flutter image cache
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

          return SafeArea(
            child: Padding(
              // viewInsets read here (inside builder) so keyboard resize only
              // rebuilds the sheet widget tree, not the parent page.
              padding: EdgeInsets.only(
                left: 16,
                right: 16,
                top: 16,
                bottom: 16 + MediaQuery.of(sheetContext).viewInsets.bottom,
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // ── Cover preview ──────────────────────────────────────
                    coverPreview,
                    const SizedBox(height: 12),

                    // ── Change cover button ────────────────────────────────
                    TextButton.icon(
                      onPressed: () async {
                        final result = await FilePicker.platform.pickFiles(
                          type: FileType.image,
                          allowMultiple: false,
                        );
                        final path = result?.files.single.path;
                        if (path != null) {
                          setSheetState(() => coverPath = path);
                        }
                      },
                      icon: const Icon(Icons.image_outlined),
                      label: const Text('Change cover image'),
                    ),
                    const SizedBox(height: 12),

                    // ── Song name ──────────────────────────────────────────
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

                    // ── Artist name ────────────────────────────────────────
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

                    // ── Action buttons ─────────────────────────────────────
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
                              FocusScope.of(context).unfocus();
                              final newSongName = songNameController.text
                                  .trim();
                              final newArtistName = artistNameController.text
                                  .trim();

                              if (newSongName.isEmpty) return;

                              // Only write fields that actually changed so
                              // Hive doesn't emit a spurious change event.
                              bool changed = false;

                              if (song.songName != newSongName) {
                                song.songName = newSongName;
                                changed = true;
                              }

                              final resolvedArtist = newArtistName.isEmpty
                                  ? 'Unknown Artist'
                                  : newArtistName;
                              if (song.artistName != resolvedArtist) {
                                song.artistName = resolvedArtist;
                                changed = true;
                              }

                              final resolvedCover = coverPath.isEmpty
                                  ? 'assets/images/default_song_cover.png'
                                  : coverPath;
                              if (song.coverPath != resolvedCover) {
                                song.coverPath = resolvedCover;
                                changed = true;
                              }

                              if (changed) await song.save();

                              // if (sheetContext.mounted) {
                              //   // Navigator.pop(sheetContext);
                              //   Navigator.of(context).pop();
                              // }
                              WidgetsBinding.instance.addPostFrameCallback((_) {
                                if (sheetContext.mounted) {
                                  Navigator.of(context).pop();
                                }
                              });
                            },
                            child: const Text('Save'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  ).whenComplete(() {
    // Dispose controllers only AFTER the sheet is fully gone — this is what
    // prevents the _dependents.isEmpty assertion error.
    songNameController.dispose();
    artistNameController.dispose();
  });
}
