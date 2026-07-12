import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../models/song_model.dart';
import '../player/full_player_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SongProvider>().loadSongs();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final songProvider = context.watch<SongProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Inicio',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (authProvider.user != null)
            PopupMenuButton<String>(
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: ListTile(
                    leading: CircleAvatar(
                      child: Text(authProvider.user!.username[0].toUpperCase()),
                    ),
                    title: Text(authProvider.user!.username),
                    subtitle: Text(authProvider.user!.email),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout),
                    title: Text('Cerrar Sesión'),
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'logout') {
                  authProvider.logout();
                  Navigator.pushReplacementNamed(context, '/login');
                }
              },
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => songProvider.loadSongs(),
        child: songProvider.isLoading && songProvider.songs.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : songProvider.songs.isEmpty
                ? const Center(
                    child: Text(
                      'No hay canciones disponibles',
                      style: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: songProvider.songs.length,
                    itemBuilder: (context, index) {
                      final song = songProvider.songs[index];
                      return _SongListItem(
                        song: song,
                        onTap: () {
                          songProvider.setCurrentSong(song);
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const FullPlayerScreen(),
                            ),
                          );
                        },
                      );
                    },
                  ),
      ),
    );
  }
}

class _SongListItem extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;

  const _SongListItem({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: onTap,
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 56,
            height: 56,
            color: Colors.grey[800],
            child: song.coverUrl != null
                ? Image.network(song.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note, size: 30))
                : const Icon(Icons.music_note, size: 30, color: Colors.white54),
          ),
        ),
        title: Text(
          song.title,
          style: const TextStyle(fontWeight: FontWeight.w600),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Row(
          children: [
            if (song.artist != null)
              Text(
                song.artist!.artistName,
                style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
              ),
            const SizedBox(width: 8),
            Text(
              '${song.formattedDuration} · ${song.formattedPlays} reproducciones',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ],
        ),
        trailing: Consumer<SongProvider>(
          builder: (context, songProvider, _) {
            final isLiked = songProvider.isSongLiked(song.id);
            return IconButton(
              icon: Icon(
                isLiked ? Icons.favorite : Icons.favorite_border,
                color: isLiked ? Colors.red : Colors.grey,
              ),
              onPressed: () => songProvider.toggleLike(song.id),
            );
          },
        ),
      ),
    );
  }
}