import 'dart:io';
import 'dart:math' as math;

import 'package:audio_video_progress_bar/audio_video_progress_bar.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';

import 'package:sonus/models/song.dart';
import 'package:sonus/pages/add_to_playlist_page.dart';
import 'package:sonus/services/database_service.dart';
import 'package:sonus/services/music_scanner_service.dart';
import 'package:sonus/services/player_service.dart';
import 'package:sonus/theme/app_colors.dart';
import 'package:sonus/widgets/song_editor_sheet.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _playerService = PlayerService();

  @override
  void initState() {
    super.initState();
    _playerService.addListener(_onPlayerChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkFirstRun());
  }

  @override
  void dispose() {
    _playerService.removeListener(_onPlayerChanged);
    super.dispose();
  }

  void _onPlayerChanged() {
    if (mounted) setState(() {});
  }

  // ─── First-run flow ──────────────────────────────────────────────────────────

  Future<void> _checkFirstRun() async {
    final db = DatabaseService();
    final scanner = MusicScannerService();

    if (db.isFirstRun()) {
      final proceed = await _showWelcomeDialog();
      if (proceed == true) {
        final path = await scanner.pickAndSaveNewFolder();
        if (path != null) {
          await scanner.syncLibrary();
          await db.markFirstRunCompleted();
        }
      }
    }
  }

  Future<bool?> _showWelcomeDialog() {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: const Text('Welcome to Sonus!'),
        content: const Text(
          'To get started, please select the folder where you keep your music. '
          'We will scan it to build your library.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('SELECT FOLDER'),
          ),
        ],
      ),
    );
  }

  // ─── Cover image helper ──────────────────────────────────────────────────────

  Widget _buildCoverImage(Song song, double size) {
    final path = song.coverPath;
    final isAsset = path.isEmpty || path.startsWith('assets/');

    if (!isAsset) {
      final file = File(path);
      if (file.existsSync()) {
        return Image.file(
          file,
          key: ValueKey(path),
          width: size,
          height: size,
          fit: BoxFit.cover,
        );
      }
    }

    return Image.asset(
      (isAsset && path.isNotEmpty)
          ? path
          : 'assets/images/default_song_cover.png',
      key: ValueKey(path),
      width: size,
      height: size,
      fit: BoxFit.cover,
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final song = _playerService.currentSong;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          song != null ? _playerService.sourceName : 'Sonus',
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: song == null ? _buildEmptyState() : _buildPlayerUI(song),
    );
  }

  // ─── Empty state ─────────────────────────────────────────────────────────────

  Widget _buildEmptyState() {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.music_note_rounded, size: 80, color: AppColors.onSurfaceVariant),
          SizedBox(height: 16),
          Text(
            'No song playing',
            style: TextStyle(
              color: AppColors.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Tap a song in Songs or Playlists to start',
            style: TextStyle(color: AppColors.onSurfaceVariant, fontSize: 14),
          ),
        ],
      ),
    );
  }

  // ─── Full player UI ───────────────────────────────────────────────────────────

  Widget _buildPlayerUI(Song song) {
    final screenSize = MediaQuery.of(context).size;
    // Cover: square, max 88% of width but never taller than ~44% of screen
    final coverSize = math.min(screenSize.width * 0.88, screenSize.height * 0.44);

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Column(
        children: [
          const SizedBox(height: 20),

          // ── Album Art ────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.55),
                    blurRadius: 40,
                    offset: const Offset(0, 14),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(18),
                child: _buildCoverImage(song, coverSize),
              ),
            ),
          ),

          const SizedBox(height: 28),

          // ── Song info row ─────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        song.songName,
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: -0.3,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        song.artistName,
                        style: const TextStyle(
                          fontSize: 14,
                          color: AppColors.onSurface,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                _iconBtn(
                  icon: Icons.playlist_add_rounded,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AddToPlaylistPage(song: song),
                      ),
                    );
                  },
                ),
                const SizedBox(width: 6),
                _iconBtn(
                  icon: Icons.edit_outlined,
                  onTap: () => showSongEditorSheet(context, song),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // ── Progress bar ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: StreamBuilder<Duration>(
              stream: _playerService.positionStream,
              builder: (context, posSnap) {
                final position = posSnap.data ?? Duration.zero;
                return StreamBuilder<Duration?>(
                  stream: _playerService.durationStream,
                  builder: (context, durSnap) {
                    final duration = durSnap.data ?? Duration.zero;
                    final safePosition =
                        position > duration ? duration : position;
                    return ProgressBar(
                      progress: safePosition,
                      total: duration,
                      onSeek: _playerService.seek,
                      baseBarColor:
                          AppColors.onSurfaceVariant.withValues(alpha: 0.35),
                      progressBarColor: Colors.white,
                      bufferedBarColor: Colors.white.withValues(alpha: 0.15),
                      thumbColor: Colors.white,
                      thumbRadius: 7,
                      barHeight: 4,
                      timeLabelTextStyle: const TextStyle(
                        color: AppColors.onSurface,
                        fontSize: 12,
                      ),
                    );
                  },
                );
              },
            ),
          ),

          const SizedBox(height: 6),

          // ── Controls ──────────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: _buildControls(),
          ),

          const SizedBox(height: 16),
        ],
      ),
    );
  }

  // ─── Controls row ─────────────────────────────────────────────────────────────

  Widget _buildControls() {
    final p = _playerService;
    final repeatMode = p.repeatMode;
    final nextEnabled = p.hasNext || repeatMode == RepeatMode.all;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Shuffle
        _sideButton(
          icon: Icons.shuffle_rounded,
          active: p.isShuffle,
          onTap: p.toggleShuffle,
        ),

        // Previous (grayed-out when first song)
        _squareButton(
          icon: Icons.skip_previous_rounded,
          enabled: p.hasPrevious,
          onTap: p.hasPrevious ? p.skipPrevious : null,
        ),

        // Play / Pause
        _playPauseButton(),

        // Next
        _squareButton(
          icon: Icons.skip_next_rounded,
          enabled: nextEnabled,
          onTap: nextEnabled ? p.skipNext : null,
        ),

        // Repeat
        _repeatButton(repeatMode),
      ],
    );
  }

  Widget _playPauseButton() {
    return StreamBuilder<PlayerState>(
      stream: _playerService.playerStateStream,
      builder: (context, snap) {
        final state = snap.data;
        final isPlaying = state?.playing ?? false;
        final isLoading =
            state?.processingState == ProcessingState.loading ||
            state?.processingState == ProcessingState.buffering;

        return GestureDetector(
          onTap: _playerService.togglePlayPause,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppColors.brand,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.brand.withValues(alpha: 0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: isLoading
                ? const Center(
                    child: SizedBox(
                      width: 26,
                      height: 26,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.5,
                      ),
                    ),
                  )
                : Icon(
                    isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 46,
                  ),
          ),
        );
      },
    );
  }

  Widget _squareButton({
    required IconData icon,
    required bool enabled,
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 56,
        height: 56,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: enabled ? Colors.white : AppColors.onSurfaceVariant,
          size: 32,
        ),
      ),
    );
  }

  Widget _sideButton({
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          icon,
          color: active ? Colors.white : AppColors.onSurfaceVariant,
          size: 26,
        ),
      ),
    );
  }

  Widget _repeatButton(RepeatMode mode) {
    return GestureDetector(
      onTap: _playerService.cycleRepeatMode,
      child: SizedBox(
        width: 40,
        height: 40,
        child: Icon(
          mode == RepeatMode.one
              ? Icons.repeat_one_rounded
              : Icons.repeat_rounded,
          color:
              mode != RepeatMode.off ? Colors.white : AppColors.onSurfaceVariant,
          size: 26,
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.surfaceContainer,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.onSurface, size: 20),
      ),
    );
  }
}