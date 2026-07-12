import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/song_provider.dart';
import '../../models/song_model.dart';
import '../player/full_player_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _search(String query) {
    context.read<SongProvider>().loadSongs(search: query.isNotEmpty ? query : null);
  }

  @override
  Widget build(BuildContext context) {
    final songProvider = context.watch<SongProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Buscar', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              onChanged: _search,
              decoration: InputDecoration(
                hintText: '¿Qué quieres escuchar?',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _search('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.1),
              ),
            ),
          ),
          Expanded(
            child: songProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : songProvider.songs.isEmpty
                    ? const Center(
                        child: Text('Busca canciones', style: TextStyle(color: Colors.grey)),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: songProvider.songs.length,
                        itemBuilder: (context, index) {
                          final song = songProvider.songs[index];
                          return ListTile(
                            onTap: () {
                              songProvider.setCurrentSong(song);
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
                              song.artist?.artistName ?? song.owner?.username ?? 'Desconocido',
                              style: TextStyle(color: Theme.of(context).colorScheme.primary, fontSize: 13),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }
}