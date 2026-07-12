import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/song_provider.dart';
import '../../models/song_model.dart';

class FullPlayerScreen extends StatelessWidget {
  const FullPlayerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();
    final song = songProvider.currentSong;

    if (song == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('No hay canción seleccionada')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(song.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(),

            // Cover Art
            Container(
              width: MediaQuery.of(context).size.width * 0.7,
              height: MediaQuery.of(context).size.width * 0.7,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.5),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: song.coverUrl != null
                    ? Image.network(
                        song.coverUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.grey[900],
                          child: Icon(Icons.music_note, size: 80, color: Colors.grey[700]),
                        ),
                      )
                    : Container(
                        color: Colors.grey[900],
                        child: Icon(Icons.music_note, size: 80, color: Colors.grey[700]),
                      ),
              ),
            ),

            const Spacer(),

            // Song Info
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          song.title,
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          song.artist?.artistName ?? song.owner?.username ?? 'Artista desconocido',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.primary,
                            fontSize: 18,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Consumer<SongProvider>(
                    builder: (context, songProvider, _) {
                      final isLiked = songProvider.isSongLiked(song.id);
                      return IconButton(
                        iconSize: 32,
                        icon: Icon(
                          isLiked ? Icons.favorite : Icons.favorite_border,
                          color: isLiked ? Colors.red : Colors.white70,
                        ),
                        onPressed: () => songProvider.toggleLike(song.id),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Genre & Stats
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Row(
                children: [
                  if (song.genre != null) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        song.genre!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.primary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  Icon(Icons.play_arrow, size: 16, color: Colors.grey[600]),
                  Text(
                    ' ${song.formattedPlays} reproducciones',
                    style: TextStyle(color: Colors.grey[600], fontSize: 13),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // Progress bar (simulado)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: 0.3,
                  minHeight: 4,
                  backgroundColor: Colors.grey[800],
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),

            // Tiempos
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('1:23', style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                  Text(song.formattedDuration, style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Controles principales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Previous
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: Colors.white70,
                  onPressed: () {
                    _changeSong(context, -1);
                  },
                ),

                const SizedBox(width: 24),

                // Play/Pause
                Consumer<SongProvider>(
                  builder: (context, songProvider, _) {
                    return Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      child: IconButton(
                        iconSize: 48,
                        icon: Icon(
                          songProvider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                        ),
                        color: Colors.white,
                        onPressed: () {
                          songProvider.setPlaying(!songProvider.isPlaying);
                        },
                      ),
                    );
                  },
                ),

                const SizedBox(width: 24),

                // Next
                IconButton(
                  iconSize: 36,
                  icon: const Icon(Icons.skip_next_rounded),
                  color: Colors.white70,
                  onPressed: () {
                    _changeSong(context, 1);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Controles adicionales
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.shuffle_rounded),
                  color: Colors.grey[500],
                  onPressed: () {},
                ),
                const SizedBox(width: 32),
                IconButton(
                  icon: const Icon(Icons.repeat_rounded),
                  color: Colors.grey[500],
                  onPressed: () {},
                ),
              ],
            ),

            const Spacer(),
          ],
        ),
      ),
    );
  }

  void _changeSong(BuildContext context, int direction) {
    final songProvider = context.read<SongProvider>();
    final songs = songProvider.songs;
    if (songs.isEmpty) return;

    final currentIndex = songs.indexWhere((s) => s.id == songProvider.currentSong?.id);
    int newIndex = currentIndex + direction;

    if (newIndex < 0) newIndex = songs.length - 1;
    if (newIndex >= songs.length) newIndex = 0;

    songProvider.setCurrentSong(songs[newIndex]);
    songProvider.setPlaying(true);
  }
}