import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:sonus/models/playlist.dart';

import 'package:sonus/utils/hive_boxes.dart';


class PlaylistPage extends StatelessWidget {
  const PlaylistPage({super.key});

  @override
  Widget build(BuildContext context) {
    final box = Hive.box<Playlist>(HiveBoxes.playlist);

    return Scaffold(
      appBar: AppBar(title: const Text("Playlists"), centerTitle: true),

      // 🔥 Reactive UI (auto update when Hive changes)
      body: ValueListenableBuilder(
        valueListenable: box.listenable(),
        builder: (context, Box<Playlist> box, _) {
          if (box.isEmpty) {
            return const Center(
              child: Text("No playlist yet. Tap + to create."),
            );
          }

          return ListView.builder(
            itemCount: box.length,
            itemBuilder: (context, index) {
              
              final playlist = box.getAt(index)!;
              return ListTile(
                leading: Image.asset(playlist.coverImagePath),
                title: Text(playlist.playlistName),
                subtitle: Text("${playlist.listOfSongs.length} songs"),

                onTap: () {
                  // TODO: open playlist detail
                },

                trailing: PopupMenuButton<String>(
                  onSelected: (value) {
                    if (value == "edit") {
                      _showCreateOrEditDialog(context, playlist: playlist);
                    } else if (value == "delete") {
                      playlist.delete();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(value: "edit", child: Text("Edit")),
                    const PopupMenuItem(value: "delete", child: Text("Delete")),
                  ],
                ),
              );
            },
          );
        },
      ),

      // ➕ Create playlist button
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showCreateOrEditDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  // 🔥 Create / Edit Dialog (REUSABLE)
  void _showCreateOrEditDialog(BuildContext context, {Playlist? playlist}) {
    final controller = TextEditingController(
      text: playlist?.playlistName ?? "",
    );

    final box = Hive.box<Playlist>(HiveBoxes.playlist);

    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(playlist == null ? "Create Playlist" : "Edit Playlist"),

          content: TextField(
            controller: controller,
            decoration: const InputDecoration(hintText: "Playlist name"),
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final navigator = Navigator.of(context);

                final name = controller.text.trim();
                if (name.isEmpty) return;

                if (playlist == null) {
                  final newPlaylist = Playlist(
                    playlistName: name,
                    listOfSongs: [],
                  );
                  await box.add(newPlaylist);
                } else {
                  playlist.playlistName = name;
                  await playlist.save();
                }

                navigator.pop(); // ✅ safe
              },
              child: const Text("Save"),
            ),
          ],
        );
      },
    );
  }
}
