import 'package:hive/hive.dart';

part 'song.g.dart';

@HiveType(typeId: 0)
class Song extends HiveObject{
  @HiveField(0)
  String songName;
  @HiveField(1)
  final String songPath;
  @HiveField(3)
  String artistName;
  @HiveField(4)
  String coverPath;

  Song({
    required this.songName,
    required this.songPath,
    this.artistName = "Unknown Artist",
    this.coverPath = "assets/images/default_song_cover.png",
  });
}
