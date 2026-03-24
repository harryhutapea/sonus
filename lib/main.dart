import 'package:flutter/material.dart';

import 'package:hive_flutter/hive_flutter.dart';

import 'package:sonus/app.dart';

import 'package:sonus/models/playlist.dart';
import 'package:sonus/models/song.dart';

import 'package:sonus/utils/hive_boxes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Hive.initFlutter();

  Hive.registerAdapter(PlaylistAdapter());
  Hive.registerAdapter(SongAdapter());

  await Hive.openBox<Playlist>(HiveBoxes.playlist);
  await Hive.openBox<Song>(HiveBoxes.songs);
  await Hive.openBox(HiveBoxes.settings);

  runApp(const MyApp());
}