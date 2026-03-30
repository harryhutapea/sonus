import 'package:flutter/foundation.dart';
import 'package:just_audio/just_audio.dart';

import 'package:sonus/models/song.dart';

enum RepeatMode { off, all, one }

class PlayerService extends ChangeNotifier {
  // ─── Singleton ───────────────────────────────────────────────────────────────
  static final PlayerService _instance = PlayerService._internal();
  factory PlayerService() => _instance;

  PlayerService._internal() {
    _player.playerStateStream.listen((state) {
      if (state.processingState == ProcessingState.completed) {
        _onSongCompleted();
      }
    });
  }

  // ─── Internal state ──────────────────────────────────────────────────────────
  final AudioPlayer _player = AudioPlayer();

  List<Song> _queue = [];
  List<Song> _shuffledQueue = [];
  int _currentIndex = 0;
  String _sourceName = '';
  bool _isShuffle = false;
  RepeatMode _repeatMode = RepeatMode.off;

  // ─── Public read-only ────────────────────────────────────────────────────────
  AudioPlayer get player => _player;
  String get sourceName => _sourceName;
  bool get isShuffle => _isShuffle;
  RepeatMode get repeatMode => _repeatMode;

  List<Song> get activeQueue => _isShuffle ? _shuffledQueue : _queue;

  Song? get currentSong {
    final q = activeQueue;
    if (q.isEmpty || _currentIndex < 0 || _currentIndex >= q.length) return null;
    return q[_currentIndex];
  }

  bool get hasPrevious => _currentIndex > 0;
  bool get hasNext => _currentIndex < activeQueue.length - 1;

  Stream<PlayerState> get playerStateStream => _player.playerStateStream;
  Stream<Duration> get positionStream => _player.positionStream;
  Stream<Duration?> get durationStream => _player.durationStream;

  // ─── Public commands ─────────────────────────────────────────────────────────

  /// Start playing [songs] from [startIndex], labelled with [sourceName].
  /// notifyListeners() is called IMMEDIATELY after setting queue state so the
  /// UI (HomePage) updates right away — before the async audio load completes.
  Future<void> playQueue(
    List<Song> songs,
    int startIndex,
    String sourceName,
  ) async {
    _queue = List.from(songs);
    _sourceName = sourceName;

    if (_isShuffle) {
      _buildShuffledQueue(startIndex);
    } else {
      _currentIndex = startIndex.clamp(0, songs.length - 1);
    }

    // ✅ Notify immediately so HomePage shows the song before audio loads
    notifyListeners();

    await _loadCurrent();
  }

  Future<void> togglePlayPause() async {
    if (_player.playing) {
      await _player.pause();
    } else {
      if (_player.processingState == ProcessingState.completed) {
        await _player.seek(Duration.zero);
      }
      await _player.play();
    }
    notifyListeners();
  }

  Future<void> skipNext() async {
    if (hasNext) {
      _currentIndex++;
      await _loadCurrent();
      notifyListeners();
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
      await _loadCurrent();
      notifyListeners();
    }
  }

  Future<void> skipPrevious() async {
    if (_player.position.inSeconds > 3) {
      await _player.seek(Duration.zero);
      return;
    }
    if (hasPrevious) {
      _currentIndex--;
      await _loadCurrent();
      notifyListeners();
    }
  }

  void toggleShuffle() {
    if (_isShuffle) {
      final current = currentSong;
      _isShuffle = false;
      if (current != null) {
        final idx = _queue.indexOf(current);
        _currentIndex = idx >= 0 ? idx : 0;
      }
    } else {
      final current = currentSong;
      _isShuffle = true;
      final originalIndex =
          current != null ? _queue.indexOf(current) : _currentIndex;
      _buildShuffledQueue(originalIndex >= 0 ? originalIndex : 0);
    }
    notifyListeners();
  }

  void cycleRepeatMode() {
    switch (_repeatMode) {
      case RepeatMode.off:
        _repeatMode = RepeatMode.all;
        break;
      case RepeatMode.all:
        _repeatMode = RepeatMode.one;
        break;
      case RepeatMode.one:
        _repeatMode = RepeatMode.off;
        break;
    }
    notifyListeners();
  }

  Future<void> seek(Duration position) => _player.seek(position);

  // ─── Internal helpers ────────────────────────────────────────────────────────

  Future<void> _loadCurrent() async {
    final song = currentSong;
    if (song == null) return;
    try {
      await _player.setAudioSource(AudioSource.uri(Uri.file(song.songPath)));
      await _player.play();
    } catch (e) {
      debugPrint('PlayerService._loadCurrent error: $e');
    }
  }

  void _buildShuffledQueue(int originalStartIndex) {
    final startSong = _queue[originalStartIndex];
    final others = List<Song>.from(_queue)..remove(startSong);
    others.shuffle();
    _shuffledQueue = [startSong, ...others];
    _currentIndex = 0;
  }

  void _onSongCompleted() {
    if (_repeatMode == RepeatMode.one) {
      _player.seek(Duration.zero).then((_) => _player.play());
    } else if (hasNext) {
      _currentIndex++;
      _loadCurrent();
      notifyListeners();
    } else if (_repeatMode == RepeatMode.all) {
      _currentIndex = 0;
      _loadCurrent();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }
}