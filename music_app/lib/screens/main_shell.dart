import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/song_provider.dart';
import '../providers/artist_provider.dart';
import 'home/home_screen.dart';
import 'search/search_screen.dart';
import 'library/library_screen.dart';
import 'creator/creator_screen.dart';
import 'player/mini_player.dart';
import 'player/full_player_screen.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  Future<void> _loadInitialData() async {
    final songProvider = context.read<SongProvider>();
    final artistProvider = context.read<ArtistProvider>();

    await Future.wait([
      songProvider.loadSongs(),
      songProvider.loadLikedSongs(),
      artistProvider.loadArtists(),
    ]);

    final authProvider = context.read<AuthProvider>();
    if (authProvider.isCreator) {
      await artistProvider.loadMyProfile();
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final songProvider = context.watch<SongProvider>();

    // Para el menú inferior, mostramos 3 o 4 opciones según si es creator
    final screens = <Widget>[
      const HomeScreen(),
      const SearchScreen(),
      const LibraryScreen(),
      const CreatorScreen(),
    ];

    return Scaffold(
      body: Stack(
        children: [
          screens[_currentIndex],
          // Mini player (si hay canción actual)
          if (songProvider.currentSong != null)
            Positioned(
              bottom: 60,
              left: 0,
              right: 0,
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const FullPlayerScreen()),
                  );
                },
                child: const MiniPlayer(),
              ),
            ),
        ],
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          border: Border(
            top: BorderSide(
              color: Colors.grey.withOpacity(0.2),
              width: 0.5,
            ),
          ),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          items: [
            const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Inicio',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.search),
              activeIcon: Icon(Icons.search),
              label: 'Buscar',
            ),
            const BottomNavigationBarItem(
              icon: Icon(Icons.library_music_outlined),
              activeIcon: Icon(Icons.library_music),
              label: 'Biblioteca',
            ),
            BottomNavigationBarItem(
              icon: const Icon(Icons.mic_outlined),
              activeIcon: const Icon(Icons.mic),
              label: authProvider.isCreator ? 'Creador' : 'Creador',
            ),
          ],
        ),
      ),
    );
  }
}