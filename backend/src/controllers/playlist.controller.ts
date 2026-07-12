import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export async function getPlaylists(req: AuthRequest, res: Response): Promise<void> {
  try {
    const playlists = await prisma.playlist.findMany({
      where: { userId: req.userId },
      include: {
        _count: {
          select: { songs: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(playlists);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener playlists' });
  }
}

export async function getPlaylistById(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const playlist = await prisma.playlist.findUnique({
      where: { id },
      include: {
        songs: {
          orderBy: { position: 'asc' },
          include: {
            song: {
              include: {
                owner: {
                  select: { id: true, username: true, avatar: true },
                },
                artist: {
                  select: { id: true, artistName: true, image: true },
                },
                album: {
                  select: { id: true, title: true, cover: true },
                },
              },
            },
          },
        },
      },
    });

    if (!playlist) {
      res.status(404).json({ error: 'Playlist no encontrada' });
      return;
    }

    res.json(playlist);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener playlist' });
  }
}

export async function createPlaylist(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { name, cover, isPublic } = req.body;

    if (!name) {
      res.status(400).json({ error: 'El nombre de la playlist es requerido' });
      return;
    }

    const playlist = await prisma.playlist.create({
      data: {
        userId: req.userId!,
        name,
        cover: cover || null,
        isPublic: isPublic !== undefined ? isPublic : true,
      },
    });

    res.status(201).json(playlist);
  } catch (error) {
    res.status(500).json({ error: 'Error al crear playlist' });
  }
}

export async function updatePlaylist(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { name, cover, isPublic } = req.body;

    const existingPlaylist = await prisma.playlist.findUnique({
      where: { id },
    });

    if (!existingPlaylist) {
      res.status(404).json({ error: 'Playlist no encontrada' });
      return;
    }

    if (existingPlaylist.userId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para editar esta playlist' });
      return;
    }

    const playlist = await prisma.playlist.update({
      where: { id },
      data: {
        ...(name && { name }),
        ...(cover !== undefined && { cover }),
        ...(isPublic !== undefined && { isPublic }),
      },
    });

    res.json(playlist);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar playlist' });
  }
}

export async function deletePlaylist(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const existingPlaylist = await prisma.playlist.findUnique({
      where: { id },
    });

    if (!existingPlaylist) {
      res.status(404).json({ error: 'Playlist no encontrada' });
      return;
    }

    if (existingPlaylist.userId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para eliminar esta playlist' });
      return;
    }

    await prisma.playlist.delete({
      where: { id },
    });

    res.json({ message: 'Playlist eliminada exitosamente' });
  } catch (error) {
    res.status(500).json({ error: 'Error al eliminar playlist' });
  }
}

export async function addSongToPlaylist(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id, songId } = req.params;

    const playlist = await prisma.playlist.findUnique({
      where: { id },
    });

    if (!playlist) {
      res.status(404).json({ error: 'Playlist no encontrada' });
      return;
    }

    if (playlist.userId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para modificar esta playlist' });
      return;
    }

    // Obtener la última posición
    const lastSong = await prisma.playlistSong.findFirst({
      where: { playlistId: id },
      orderBy: { position: 'desc' },
    });

    const position = lastSong ? lastSong.position + 1 : 0;

    await prisma.playlistSong.create({
      data: {
        playlistId: id,
        songId,
        position,
      },
    });

    res.json({ message: 'Canción añadida a la playlist' });
  } catch (error) {
    res.status(500).json({ error: 'Error al añadir canción a playlist' });
  }
}

export async function removeSongFromPlaylist(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id, songId } = req.params;

    const playlist = await prisma.playlist.findUnique({
      where: { id },
    });

    if (!playlist) {
      res.status(404).json({ error: 'Playlist no encontrada' });
      return;
    }

    if (playlist.userId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para modificar esta playlist' });
      return;
    }

    await prisma.playlistSong.deleteMany({
      where: {
        playlistId: id,
        songId,
      },
    });

    res.json({ message: 'Canción eliminada de la playlist' });
  } catch (error) {
    res.status(500).json({ error: 'Error al eliminar canción de playlist' });
  }
}