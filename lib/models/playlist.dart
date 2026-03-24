import 'package:hive/hive.dart';

import 'package:sonus/models/song.dart';

part 'playlist.g.dart';

@HiveType(typeId: 1)
class Playlist extends HiveObject {
  @HiveField(0)
  List<Song> listOfSongs;

  @HiveField(1)
  String playlistName;

  @HiveField(2)
  String coverImagePath;

  Playlist({
    required this.listOfSongs,
    required this.playlistName,
    this.coverImagePath = "assets/images/default_playlist_cover.png",
  });
}