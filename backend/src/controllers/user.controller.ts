import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export async function getProfile(req: AuthRequest, res: Response): Promise<void> {
  try {
    const user = await prisma.user.findUnique({
      where: { id: req.userId },
      include: {
        artistProfile: true,
        _count: {
          select: {
            likedSongs: true,
            playlists: true,
          },
        },
      },
    });

    if (!user) {
      res.status(404).json({ error: 'Usuario no encontrado' });
      return;
    }

    const { password: _, ...userWithoutPassword } = user;
    res.json(userWithoutPassword);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener perfil' });
  }
}

export async function updateProfile(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { username, avatar } = req.body;

    const updatedUser = await prisma.user.update({
      where: { id: req.userId },
      data: {
        ...(username && { username }),
        ...(avatar && { avatar }),
      },
      select: {
        id: true,
        email: true,
        username: true,
        avatar: true,
        creator: true,
        createdAt: true,
        updatedAt: true,
      },
    });

    res.json(updatedUser);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar perfil' });
  }
}

export async function getLikedSongs(req: AuthRequest, res: Response): Promise<void> {
  try {
    const likedSongs = await prisma.likedSong.findMany({
      where: { userId: req.userId },
      include: {
        song: {
          include: {
            owner: {
              select: { id: true, username: true, avatar: true },
            },
            artist: {
              select: { id: true, artistName: true },
            },
            album: {
              select: { id: true, title: true, cover: true },
            },
          },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(likedSongs.map(ls => ls.song));
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener canciones favoritas' });
  }
}

export async function toggleLikeSong(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { songId } = req.params;
    const userId = req.userId!;

    const existing = await prisma.likedSong.findUnique({
      where: {
        userId_songId: { userId, songId },
      },
    });

    if (existing) {
      await prisma.likedSong.delete({
        where: { id: existing.id },
      });
      res.json({ liked: false });
    } else {
      await prisma.likedSong.create({
        data: { userId, songId },
      });
      res.json({ liked: true });
    }
  } catch (error) {
    res.status(500).json({ error: 'Error al alternar me gusta' });
  }
}