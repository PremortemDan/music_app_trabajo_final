import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/song_provider.dart';
import '../../providers/artist_provider.dart';
import 'register_creator_screen.dart';
import 'upload_song_screen.dart';

class CreatorScreen extends StatefulWidget {
  const CreatorScreen({super.key});

  @override
  State<CreatorScreen> createState() => _CreatorScreenState();
}

class _CreatorScreenState extends State<CreatorScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.isCreator) {
        context.read<ArtistProvider>().loadMyProfile();
        context.read<SongProvider>().loadMySongs();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final artistProvider = context.watch<ArtistProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Creador', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: !authProvider.isCreator || artistProvider.myProfile == null
          ? _buildNotCreatorView()
          : _buildCreatorView(),
    );
  }

  Widget _buildNotCreatorView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.mic,
              size: 80,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 24),
            const Text(
              '¿Eres un creador musical?',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            const Text(
              'Regístrate como creador para subir tus canciones y compartir tu música con el mundo.',
              style: TextStyle(color: Colors.grey, fontSize: 16),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const RegisterCreatorScreen(),
                    ),
                  );
                  if (result == true && mounted) {
                    await context.read<AuthProvider>().refreshUser();
                    await context.read<ArtistProvider>().loadMyProfile();
                  }
                },
                icon: const Icon(Icons.add_circle_outline),
                label: const Text(
                  'Registrarme como Creador',
                  style: TextStyle(fontSize: 16),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCreatorView() {
    final songProvider = context.watch<SongProvider>();
    final artistProvider = context.watch<ArtistProvider>();
    final profile = artistProvider.myProfile!;

    return RefreshIndicator(
      onRefresh: () => songProvider.loadMySongs(),
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Perfil del artista
          Card(
            color: Colors.white.withOpacity(0.05),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: Colors.grey[800],
                    backgroundImage: profile.image != null
                        ? NetworkImage('http://192.168.1.9:3000${profile.image}')
                        : null,
                    child: profile.image == null
                        ? Text(
                            profile.artistName[0].toUpperCase(),
                            style: const TextStyle(fontSize: 30, color: Colors.white),
                          )
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                profile.artistName,
                                style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            if (profile.verified)
                              const Icon(Icons.verified, color: Colors.blue, size: 20),
                          ],
                        ),
                        if (profile.genre != null)
                          Text(
                            profile.genre!,
                            style: TextStyle(color: Theme.of(context).colorScheme.primary),
                          ),
                        if (profile.bio != null)
                          Text(
                            profile.bio!,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Botón para subir canción
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const UploadSongScreen()),
                );
                if (result == true && mounted) {
                  await context.read<SongProvider>().loadMySongs();
                }
              },
              icon: const Icon(Icons.upload_file),
              label: const Text('Subir Canción', style: TextStyle(fontSize: 16)),
              style: ElevatedButton.styleFrom(
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Canciones subidas
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Mis Canciones',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              Text(
                '${songProvider.mySongs.length} canciones',
                style: const TextStyle(color: Colors.grey),
              ),
            ],
          ),

          const SizedBox(height: 12),

          if (songProvider.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (songProvider.mySongs.isEmpty)
            const Padding(
              padding: EdgeInsets.all(32),
              child: Text(
                'No has subido canciones aún\n¡Comparte tu música!',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey),
              ),
            )
          else
            ...songProvider.mySongs.map((song) => Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  color: Colors.white.withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListTile(
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        width: 50,
                        height: 50,
                        color: Colors.grey[800],
                        child: song.coverUrl != null
                            ? Image.network(song.coverUrl!, fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => const Icon(Icons.music_note))
                            : const Icon(Icons.music_note, color: Colors.white54),
                      ),
                    ),
                    title: Text(song.title, maxLines: 1, overflow: TextOverflow.ellipsis),
                    subtitle: Text(
                      '${song.formattedDuration} · ${song.formattedPlays} plays',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Eliminar canción'),
                            content: Text('¿Eliminar "${song.title}"?'),
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
                      },
                    ),
                  ),
                )),
        ],
      ),
    );
  }
}