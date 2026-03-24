// lib/widgets/song_editor_sheet.dart
import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
// import 'package:hive_flutter/hive_flutter.dart';
import '../models/song.dart';           // adjust path if needed
import '../theme/app_colors.dart';     // adjust path if needed

void showSongEditorSheet(BuildContext context, Song song) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (sheetContext) => _SongEditorSheet(song: song),
  );
}

class _SongEditorSheet extends StatefulWidget {
  final Song song;
  const _SongEditorSheet({required this.song});

  @override
  State<_SongEditorSheet> createState() => _SongEditorSheetState();
}

class _SongEditorSheetState extends State<_SongEditorSheet> {
  late final TextEditingController _songNameController;
  late final TextEditingController _artistNameController;
  String _coverPath = '';

  @override
  void initState() {
    super.initState();
    _songNameController = TextEditingController(text: widget.song.songName);
    _artistNameController = TextEditingController(
      text: widget.song.artistName == 'Unknown Artist' ? '' : widget.song.artistName,
    );
    _coverPath = widget.song.coverPath;
  }

  @override
  void dispose() {
    _songNameController.dispose();
    _artistNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final hasFileCover = _coverPath.isNotEmpty &&
        !_coverPath.startsWith('assets/') &&
        File(_coverPath).existsSync();

    final coverPreview = ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: hasFileCover
          ? Image.file(
              File(_coverPath),
              key: ValueKey(_coverPath),
              width: 170,
              height: 170,
              fit: BoxFit.cover,
            )
          : Image.asset(
              _coverPath.isEmpty
                  ? 'assets/images/default_song_cover.png'
                  : _coverPath,
              width: 170,
              height: 170,
              fit: BoxFit.cover,
            ),
    );

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 16,
          right: 16,
          top: 16,
          bottom: 16 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
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
                    setState(() => _coverPath = path);
                  }
                },
                icon: const Icon(Icons.image_outlined),
                label: const Text('Change cover image'),
              ),
              const SizedBox(height: 12),

              // Song name
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('song name', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              TextField(controller: _songNameController),

              const SizedBox(height: 12),

              // Artist name
              const Align(
                alignment: Alignment.centerLeft,
                child: Text('artist name', style: TextStyle(fontWeight: FontWeight.w600)),
              ),
              const SizedBox(height: 6),
              TextField(controller: _artistNameController),

              const SizedBox(height: 18),

              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
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

                        final newSongName = _songNameController.text.trim();
                        final newArtistName = _artistNameController.text.trim();

                        if (newSongName.isEmpty) return;

                        bool changed = false;

                        if (widget.song.songName != newSongName) {
                          widget.song.songName = newSongName;
                          changed = true;
                        }

                        final resolvedArtist = newArtistName.isEmpty ? 'Unknown Artist' : newArtistName;
                        if (widget.song.artistName != resolvedArtist) {
                          widget.song.artistName = resolvedArtist;
                          changed = true;
                        }

                        final resolvedCover = _coverPath.isEmpty
                            ? 'assets/images/default_song_cover.png'
                            : _coverPath;
                        if (widget.song.coverPath != resolvedCover) {
                          widget.song.coverPath = resolvedCover;
                          changed = true;
                        }

                        if (changed) await widget.song.save();

                        if (mounted) Navigator.pop(context);   // simple & safe
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
  }
}