import 'dart:io';
import 'dart:isolate';

import 'package:file_picker/file_picker.dart';
import 'package:hive/hive.dart';
import 'package:on_audio_query/on_audio_query.dart';

import 'package:sonus/models/song.dart';
import 'package:sonus/services/database_service.dart';

class MusicScannerService {
  final _db = DatabaseService();

  String _getFileName(String path) {
    return path.split('/').last.replaceAll(RegExp(r'\.\w+$'), '');
  }

  Future<String?> pickAndSaveNewFolder() async {
    try {
      // 1. Open the folder picker
      String? selectedDirectory = await FilePicker.platform.getDirectoryPath();

      if (selectedDirectory != null) {
        // 2. Save the path to Hive using our DatabaseService
        final box = Hive.box('settings_box');
        await box.put('music_folder_path', selectedDirectory);

        print("📁 Folder selected and saved: $selectedDirectory");
        return selectedDirectory;
      }

      return null; // User canceled the picker
    } catch (e) {
      print("Error picking folder: $e");
      return null;
    }
  }

  Future<void> syncLibrary() async {
    final box = Hive.box<Song>('songs_box');

    // STEP 1: CLEANUP (same as before)
    final currentHiveSongs = box.values.toList();
    for (var song in currentHiveSongs) {
      final file = File(song.songPath);
      if (!file.existsSync()) {
        await box.delete(song.songPath);
      }
    }

    // STEP 2: GET PATH
    String? folderPath = _db.getSavedFolderPath();
    if (folderPath == null || folderPath.isEmpty) return;

    // STEP 3: SCAN FILE PATHS (Isolate)
    List<String> paths = await Isolate.run(() => _scanDirectory(folderPath));

    // STEP 4: EXTRACT METADATA (Main Thread)
    final OnAudioQuery audioQuery = OnAudioQuery();

    // 🔑 Get ALL device songs ONCE
    final List<SongModel> deviceSongs = await audioQuery.querySongs(
      uriType: UriType.EXTERNAL,
      ignoreCase: true,
    );

    // Convert to map for fast lookup
    final Map<String, SongModel> songMap = {
      for (var s in deviceSongs) s.data: s,
    };

    for (String path in paths) {
      if (box.containsKey(path)) continue;

      try {
        final metadata = songMap[path];

        final song = Song(
          songName: metadata?.title ?? _getFileName(path),
          songPath: path,
          artistName: metadata?.artist ?? "Unknown Artist",
          coverPath: "assets/images/default_song_cover.png",
        );

        await box.put(path, song);
      } catch (e) {
        final song = Song(
          songName: _getFileName(path),
          songPath: path,
          artistName: "Unknown Artist",
        );

        await box.put(path, song);
      }
    }

    print("✅ Sync Complete. Total songs: ${box.length}");
  }

  // This function runs in the background (Isolate)
  static List<String> _scanDirectory(String rootPath) {
    final dir = Directory(rootPath);
    List<String> results = [];

    if (!dir.existsSync()) return [];

    try {
      final entities = dir.listSync(recursive: true);

      for (var entity in entities) {
        if (entity is File && _isAudioFile(entity.path)) {
          results.add(entity.path); // ✅ only path
        }
      }
    } catch (e) {
      print("Scan Error: $e");
    }

    return results;
  }

  static bool _isAudioFile(String path) {
    final p = path.toLowerCase();
    return p.endsWith('.mp3') ||
        p.endsWith('.wav') ||
        p.endsWith('.flac') ||
        p.endsWith('.m4a');
  }
}
