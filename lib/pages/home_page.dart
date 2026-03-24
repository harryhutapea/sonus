import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:sonus/models/song.dart';

import 'package:sonus/services/database_service.dart';
import 'package:sonus/services/music_scanner_service.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    // We use a small delay to ensure the UI is rendered before showing the folder picker
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
    });
  }

  Future<void> _checkFirstRun() async {
    final db = DatabaseService();
    final scanner = MusicScannerService();

    if (db.isFirstRun()) {
      // 1. Show a friendly dialog explaining why we need a folder
      bool? proceed = await _showWelcomeDialog();

      if (proceed == true) {
        // 2. Let them pick the folder
        String? path = await scanner.pickAndSaveNewFolder();

        if (path != null) {
          // 3. Run the scan
          await scanner.syncLibrary();
          // 4. Never show this again
          await db.markFirstRunCompleted();

          // setState(() {}); // Refresh UI to show the new songs
        }
      }
    }
  }

  Future<bool?> _showWelcomeDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false, // Force them to choose
      builder: (context) => AlertDialog(
        title: const Text("Welcome to Sonus!"),
        content: const Text(
          "To get started, please select the folder where you keep your music. We will scan it to build your library.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("SELECT FOLDER"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {

    return ValueListenableBuilder(
      
      valueListenable: Hive.box<Song>('songs_box').listenable(),
      builder: (context, Box<Song> box, _) {
        final songs = DatabaseService().getAllSongs();
        return Scaffold(
          
          appBar: AppBar(title: Text("Playing Songs"), centerTitle: true),
          body: Center(
            child: Column(
              children: [
                if (songs.isEmpty)
                  const Expanded(
                    child: Center(
                      child: Text("No songs found in your folder."),
                    ),
                  )
                else
                  SizedBox(
                    width: 340,
                    height: 340,
                    child: Image.asset(
                      "assets/images/default_song_cover.png",
                      fit: BoxFit.cover,
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}
