import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../models/song.dart';
import '../theme/app_colors.dart';

Future<void> showSongEditorSheet(BuildContext context, Song song) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    // ✅ useSafeArea + Flutter's own resize handles keyboard inset correctly
    useSafeArea: true,
    backgroundColor: AppColors.surface,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _SongEditorSheet(song: song),
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
  bool _coverIsFile = false;

  @override
  void initState() {
    super.initState();
    _songNameController = TextEditingController(text: widget.song.songName);
    _artistNameController = TextEditingController(
      text: widget.song.artistName == 'Unknown Artist' ? '' : widget.song.artistName,
    );

    _coverPath = widget.song.coverPath;
    _coverIsFile =
        _coverPath.isNotEmpty &&
        !_coverPath.startsWith('assets/') &&
        File(_coverPath).existsSync();
  }

  @override
  void dispose() {
    _songNameController.dispose();
    _artistNameController.dispose();
    super.dispose();
  }

  Widget _buildCoverPreview() {
    if (_coverIsFile) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: Image.file(
          File(_coverPath),
          key: ValueKey(_coverPath),
          width: 170,
          height: 170,
          fit: BoxFit.cover,
          filterQuality: FilterQuality.low,
          cacheWidth: 340,
          cacheHeight: 340,
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: Image.asset(
        'assets/images/default_song_cover.png',
        width: 170,
        height: 170,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.low,
        cacheWidth: 340,
        cacheHeight: 340,
      ),
    );
  }

  Future<void> _pickCover() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );

    final path = result?.files.single.path;
    if (path == null || !mounted) return;

    setState(() {
      _coverPath = path;
      _coverIsFile = true;
    });
  }

  Future<void> _save() async {
    FocusManager.instance.primaryFocus?.unfocus();

    final newSongName = _songNameController.text.trim();
    final newArtistName = _artistNameController.text.trim();

    if (newSongName.isEmpty) return;

    final resolvedArtist = newArtistName.isEmpty ? 'Unknown Artist' : newArtistName;
    final resolvedCover = _coverPath.isEmpty
        ? 'assets/images/default_song_cover.png'
        : _coverPath;

    var changed = false;

    if (widget.song.songName != newSongName) {
      widget.song.songName = newSongName;
      changed = true;
    }
    if (widget.song.artistName != resolvedArtist) {
      widget.song.artistName = resolvedArtist;
      changed = true;
    }
    if (widget.song.coverPath != resolvedCover) {
      widget.song.coverPath = resolvedCover;
      changed = true;
    }

    if (changed) await widget.song.save();

    if (!mounted) return;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    // ✅ FIX: Ganti AnimatedPadding (penyebab keyboard lambat) dengan Padding biasa.
    // MediaQuery.viewInsetsOf hanya subscribe ke viewInsets, bukan seluruh MediaQuery.
    // Ini jauh lebih efisien dan tidak menyebabkan rebuild setiap frame keyboard.

    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildCoverPreview(),
            const SizedBox(height: 12),
            TextButton.icon(
              onPressed: _pickCover,
              icon: const Icon(Icons.image_outlined),
              label: const Text('Change cover image'),
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('song name', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _songNameController,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('artist name', style: TextStyle(fontWeight: FontWeight.w600)),
            ),
            const SizedBox(height: 6),
            TextField(
              controller: _artistNameController,
              textInputAction: TextInputAction.done,
            ),
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
                    onPressed: _save,
                    child: const Text('Save'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}