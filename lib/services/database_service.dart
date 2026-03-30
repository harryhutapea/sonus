import 'dart:io';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';

import 'package:sonus/models/song.dart';
import 'package:sonus/models/playlist.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  static const String _songBoxName = 'songs_box';
  static const String _settingsBoxName = 'settings_box';
  static const String _pathKey = 'music_folder_path';

  static const String _firstRunKey = 'is_first_run';

  // Initialize Hive and Open Boxes
  Future<void> init() async {
    await Hive.initFlutter();

    if (!Hive.isAdapterRegistered(0)) Hive.registerAdapter(SongAdapter());
    if (!Hive.isAdapterRegistered(1)) Hive.registerAdapter(PlaylistAdapter());

    await Hive.openBox<Song>(_songBoxName);
    await Hive.openBox(_settingsBoxName);
  }

  // --- FOLDER PATH LOGIC ---

  Future<void> setMusicFolder(String path) async {
    final box = Hive.box(_settingsBoxName);
    await box.put(_pathKey, path);
  }

  Future<String> getMusicFolder() async {
    final box = Hive.box(_settingsBoxName);
    String? savedPath = box.get(_pathKey);

    if (savedPath != null && Directory(savedPath).existsSync()) {
      return savedPath;
    }

    Directory? defaultDir;
    if (Platform.isAndroid) {
      defaultDir = await getExternalStorageDirectory();
    } else {
      defaultDir = await getApplicationDocumentsDirectory();
    }

    return defaultDir?.path ?? "";
  }

  // --- SONG OPERATIONS ---

  Future<void> saveSongs(List<Song> songs) async {
    final box = Hive.box<Song>(_songBoxName);

    for (var song in songs) {
      // Logic: Only add if it doesn't exist, to preserve user edits (like custom names)
      if (!box.containsKey(song.songPath)) {
        await box.put(song.songPath, song);
      }
    }
  }

  List<Song> getAllSongs() {
    return Hive.box<Song>(_songBoxName).values.toList();
  }

  Future<void> updateSong(Song song) async {
    await song.save();
  }

  int get totalSongCount {
    return Hive.box<Song>('songs_box').length;
  }

  List<Song> getSongsSortedByName() {
    final songs = Hive.box<Song>('songs_box').values.toList();

    songs.sort(
      (a, b) => a.songName.toLowerCase().compareTo(b.songName.toLowerCase()),
    );

    return songs;
  }

  List<Playlist> getPlaylistsSorted() {
    final playlists = Hive.box<Playlist>('playlists_box').values.toList();
    playlists.sort(
      (a, b) =>
          a.playlistName.toLowerCase().compareTo(b.playlistName.toLowerCase()),
    );
    return playlists;
  }

  bool isFirstRun() {
    final box = Hive.box('settings_box');
    return box.get(_firstRunKey, defaultValue: true);
  }

  Future<void> markFirstRunCompleted() async {
    final box = Hive.box('settings_box');
    await box.put(_firstRunKey, false);
  }

  // lib/services/database_service.dart

  Future<void> deleteSong(Song song) async {
    final box = Hive.box<Song>('songs_box');

    try {
      final file = File(song.songPath);

      if (await file.exists()) {
        await file.delete();
        // print("✅ File deleted from disk");
      } else {
        // print("⚠️ File not found, skipping disk delete");
      }
    } catch (e) {
      // print("❌ File delete error: $e");
    }

    // ✅ ALWAYS delete from Hive (even if file fails)
    await box.delete(song.songPath);
    // print("🗑️ Song removed from database");
    // print("Deleting: ${song.songPath}");
  }

  String? getSavedFolderPath() {
    final box = Hive.box('settings_box');

    // This looks for the value we saved earlier.
    // If it's not there, it returns null.
    return box.get('music_folder_path');
  }
}
