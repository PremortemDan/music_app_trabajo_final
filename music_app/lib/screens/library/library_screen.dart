import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/song_provider.dart';
import '../../models/song_model.dart';
import '../player/full_player_screen.dart';

class LibraryScreen extends StatefulWidget {
  const LibraryScreen({super.key});

  @override
  State<LibraryScreen> createState() => _LibraryScreenState();
}

class _LibraryScreenState extends State<LibraryScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SongProvider>().loadLikedSongs();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tu Biblioteca', style: TextStyle(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.primary,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: 'Favoritos'),
            Tab(text: 'Mis Canciones'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Favoritos
          songProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : songProvider.likedSongs.isEmpty
                  ? const Center(
                      child: Text('No tienes canciones favoritas', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: songProvider.likedSongs.length,
                      itemBuilder: (context, index) {
                        final song = songProvider.likedSongs[index];
                        return _SongTile(song: song);
                      },
                    ),
          // Mis canciones
          songProvider.isLoading
              ? const Center(child: CircularProgressIndicator())
              : songProvider.mySongs.isEmpty
                  ? const Center(
                      child: Text('No has subido canciones aún', style: TextStyle(color: Colors.grey)),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: songProvider.mySongs.length,
                      itemBuilder: (context, index) {
                        final song = songProvider.mySongs[index];
                        return _SongTile(
                          song: song,
                          showDelete: true,
                          onDelete: () => _deleteSong(song),
                        );
                      },
                    ),
        ],
      ),
    );
  }

  void _deleteSong(SongModel song) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Eliminar canción'),
        content: Text('¿Estás seguro de eliminar "${song.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () {
              context.read<SongProvider>().deleteSong(song.id);
              Navigator.pop(ctx);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class _SongTile extends StatelessWidget {
  final SongModel song;
  final bool showDelete;
  final VoidCallback? onDelete;

  const _SongTile({required this.song, this.showDelete = false, this.onDelete});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      color: Colors.white.withOpacity(0.05),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        onTap: () {
          context.read<SongProvider>().setCurrentSong(song);
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
          );
        },
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Container(
            width: 50,
            height: 50,
            color: Colors.grey[800],
            child: song.coverUrl != null
                ? Image.network(song.coverUrl!, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const Icon(Icons.music_note))
                : const Icon(Icons.music_note, color: Colors.white54),
          ),
        ),
        title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Text(
          '${song.formattedDuration} · ${song.formattedPlays} reproducciones',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
        trailing: showDelete
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: onDelete,
              )
            : Consumer<SongProvider>(
                builder: (context, songProvider, _) {
                  return IconButton(
                    icon: Icon(
                      songProvider.isSongLiked(song.id) ? Icons.favorite : Icons.favorite_border,
                      color: songProvider.isSongLiked(song.id) ? Colors.red : Colors.grey,
                    ),
                    onPressed: () => songProvider.toggleLike(song.id),
                  );
                },
              ),
      ),
    );
  }
}