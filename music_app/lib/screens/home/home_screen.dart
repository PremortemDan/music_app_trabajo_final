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
      context.read<SongProvider>().loadHomeSections();
    });
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final songProvider = context.watch<SongProvider>();
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Icon(Icons.music_note_rounded,
                color: theme.colorScheme.primary, size: 28),
            const SizedBox(width: 10),
            const Text(
              'Melodia',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 22,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          if (authProvider.user != null)
            PopupMenuButton<String>(
              offset: const Offset(0, 48),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              itemBuilder: (context) => [
                PopupMenuItem<String>(
                  enabled: false,
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: theme.colorScheme.primary,
                      child: Text(
                        authProvider.user!.username[0].toUpperCase(),
                        style: const TextStyle(
                            color: Colors.black, fontWeight: FontWeight.bold),
                      ),
                    ),
                    title: Text(
                      authProvider.user!.username,
                    ),
                    subtitle: Text(
                      authProvider.user!.email,
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                  ),
                ),
                const PopupMenuDivider(),
                const PopupMenuItem<String>(
                  value: 'logout',
                  child: ListTile(
                    leading: Icon(Icons.logout, color: Colors.grey),
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
              child: Padding(
                padding: const EdgeInsets.only(right: 8.0),
                child: CircleAvatar(
                  radius: 16,
                  backgroundColor: Colors.grey[800],
                  child: Text(
                    authProvider.user?.username[0].toUpperCase() ?? '?',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        color: theme.colorScheme.primary,
        onRefresh: () async {
          songProvider.resetSections();
          await songProvider.loadHomeSections();
        },
        child: songProvider.isLoading && !songProvider.sectionsLoaded
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(),
                    SizedBox(height: 16),
                    Text('Cargando tu música...',
                        style: TextStyle(color: Colors.grey)),
                  ],
                ),
              )
            : CustomScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                slivers: [
                  SliverToBoxAdapter(
                    child: _buildGreeting(authProvider),
                  ),
                  if (songProvider.mostPlayed.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHeroSection(
                        context,
                        'Lo más escuchado',
                        'Las canciones que todos están reproduciendo',
                        songProvider.mostPlayed,
                      ),
                    ),
                  if (songProvider.monthlyTop.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                        context,
                        'Lo mejor de este mes',
                        songProvider.monthlyTop,
                      ),
                    ),
                  if (songProvider.recentSongs.isNotEmpty)
                    SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                        context,
                        'Novedades recientes',
                        songProvider.recentSongs,
                      ),
                    ),
                  ...songProvider.genreSections.entries.map((entry) {
                    final icon = _genreIcon(entry.key);
                    return SliverToBoxAdapter(
                      child: _buildHorizontalSection(
                        context,
                        '$icon Lo más popular en ${entry.key}',
                        entry.value,
                      ),
                    );
                  }),
                  const SliverToBoxAdapter(
                    child: SizedBox(height: 120),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildGreeting(AuthProvider authProvider) {
    final hour = DateTime.now().hour;
    String greeting;
    if (hour < 12) {
      greeting = 'Buenos días';
    } else if (hour < 18) {
      greeting = 'Buenas tardes';
    } else {
      greeting = 'Buenas noches';
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            greeting,
            style: const TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '¿Qué quieres escuchar hoy?',
            style: TextStyle(
              color: Colors.grey[400],
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroSection(BuildContext context, String title,
      String subtitle, List<SongModel> songs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(color: Colors.grey[500], fontSize: 13),
              ),
            ],
          ),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return _HeroCard(
                song: song,
                rank: index + 1,
                onTap: () => _playSong(context, song),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildHorizontalSection(
      BuildContext context, String title, List<SongModel> songs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.3,
                ),
              ),
              if (songs.length > 6)
                Text(
                  'Mostrar todo',
                  style: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
            ],
          ),
        ),
        SizedBox(
          height: 180,
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            scrollDirection: Axis.horizontal,
            itemCount: songs.length,
            itemBuilder: (context, index) {
              final song = songs[index];
              return _HorizontalSongCard(
                song: song,
                onTap: () => _playSong(context, song),
              );
            },
          ),
        ),
        const SizedBox(height: 8),
      ],
    );
  }

  void _playSong(BuildContext context, SongModel song) {
    final songProvider = context.read<SongProvider>();
    songProvider.setCurrentSong(song);
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
    );
  }

  String _genreIcon(String genre) {
    switch (genre.toLowerCase()) {
      case 'rock':
        return 'Rock';
      case 'pop':
        return 'Pop';
      case 'electrónica':
      case 'electronica':
        return 'Electrónica';
      case 'hip hop':
      case 'hip-hop':
        return 'Hip Hop';
      case 'reggaeton':
      case 'reguetón':
        return 'Reggaetón';
      case 'jazz':
        return 'Jazz';
      case 'clásica':
      case 'clasica':
        return 'Clásica';
      case 'salsa':
        return 'Salsa';
      case 'metal':
        return 'Metal';
      default:
        return genre;
    }
  }
}

// ─── Tarjeta Hero (Lo más escuchado) ───
class _HeroCard extends StatelessWidget {
  final SongModel song;
  final int rank;
  final VoidCallback onTap;

  const _HeroCard(
      {required this.song, required this.rank, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 180,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.surface,
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withOpacity(0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -20,
              top: -20,
              child: Opacity(
                opacity: 0.1,
                child: Icon(
                  Icons.music_note_rounded,
                  size: 150,
                  color: Colors.white,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'TOP $rank',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.black26,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: song.coverUrl != null
                          ? Image.network(song.coverUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => const Icon(
                                  Icons.music_note,
                                  color: Colors.white54,
                                  size: 28))
                          : const Icon(Icons.music_note,
                              color: Colors.white54, size: 28),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    song.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    song.artist?.artistName ?? 'Artista desconocido',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.play_circle_fill,
                          color: Colors.white70, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        song.formattedPlays,
                        style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11,
                            fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta horizontal por sección ───
class _HorizontalSongCard extends StatelessWidget {
  final SongModel song;
  final VoidCallback onTap;

  const _HorizontalSongCard({required this.song, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        margin: const EdgeInsets.only(right: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.grey[850],
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: song.coverUrl != null
                        ? Image.network(song.coverUrl!,
                            fit: BoxFit.cover,
                            width: 140,
                            height: 140,
                            errorBuilder: (_, __, ___) => _defaultCover())
                        : _defaultCover(),
                  ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 8,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.play_arrow_rounded,
                          color: Colors.black, size: 24),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              song.title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              song.artist?.artistName ?? 'Desconocido',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _defaultCover() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey[800]!,
            Colors.grey[900]!,
          ],
        ),
      ),
      child: const Icon(Icons.music_note_rounded,
          color: Colors.white24, size: 48),
    );
  }
}