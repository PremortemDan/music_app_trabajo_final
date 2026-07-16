import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export async function getSongs(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { genre, search, artistId, albumId, limit, offset, orderBy, order, since } = req.query;

    const where: any = { isPublic: true };

    if (genre) where.genre = genre as string;
    if (artistId) where.artistId = artistId as string;
    if (albumId) where.albumId = albumId as string;
    if (search) {
      where.OR = [
        { title: { contains: search as string, mode: 'insensitive' } },
      ];
    }
    if (since) {
      where.createdAt = { gte: new Date(since as string) };
    }

    // Determinar ordenamiento
    let orderByClause: any = { createdAt: 'desc' };
    if (orderBy === 'plays') {
      orderByClause = { plays: order === 'asc' ? 'asc' : 'desc' };
    } else if (orderBy === 'createdAt') {
      orderByClause = { createdAt: order === 'asc' ? 'asc' : 'desc' };
    }

    const songs = await prisma.song.findMany({
      where,
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
      orderBy: orderByClause,
      take: limit ? parseInt(limit as string) : 50,
      skip: offset ? parseInt(offset as string) : 0,
    });

    const total = await prisma.song.count({ where });

    res.json({ songs, total });
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener canciones' });
  }
}

export async function getSongById(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const song = await prisma.song.findUnique({
      where: { id },
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
    });

    if (!song) {
      res.status(404).json({ error: 'Canción no encontrada' });
      return;
    }

    res.json(song);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener canción' });
  }
}

export async function getMySongs(req: AuthRequest, res: Response): Promise<void> {
  try {
    const songs = await prisma.song.findMany({
      where: { ownerId: req.userId },
      include: {
        artist: {
          select: { id: true, artistName: true, image: true },
        },
        album: {
          select: { id: true, title: true, cover: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(songs);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener mis canciones' });
  }
}

export async function uploadSongController(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.userId!;
    const { title, genre, albumId, isPublic } = req.body;

    if (!title) {
      res.status(400).json({ error: 'El título de la canción es requerido' });
      return;
    }

    const files = req.files as { [fieldname: string]: Express.Multer.File[] };
    const songFile = files?.['song']?.[0];
    const coverFile = files?.['cover']?.[0];

    if (!songFile) {
      res.status(400).json({ error: 'El archivo de audio es requerido' });
      return;
    }

    // Obtener el artist profile del usuario
    const artistProfile = await prisma.artistProfile.findUnique({
      where: { userId },
    });

    const song = await prisma.song.create({
      data: {
        ownerId: userId,
        artistId: artistProfile?.id || null,
        albumId: albumId || null,
        title,
        genre: genre || null,
        filePath: `/uploads/${songFile.filename}`,
        coverImage: coverFile ? `/uploads/${coverFile.filename}` : null,
        isPublic: isPublic === 'false' ? false : true,
        duration: 0, // Se podría calcular con una librería de audio
      },
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
    });

    res.status(201).json(song);
  } catch (error) {
    console.error('Error en uploadSong:', error);
    res.status(500).json({ error: 'Error al subir canción' });
  }
}

export async function updateSong(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { title, genre, albumId, isPublic } = req.body;

    // Verificar que la canción pertenece al usuario
    const existingSong = await prisma.song.findUnique({
      where: { id },
    });

    if (!existingSong) {
      res.status(404).json({ error: 'Canción no encontrada' });
      return;
    }

    if (existingSong.ownerId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para editar esta canción' });
      return;
    }

    const files = req.files as { [fieldname: string]: Express.Multer.File[] };
    const coverFile = files?.['cover']?.[0];

    const updatedSong = await prisma.song.update({
      where: { id },
      data: {
        ...(title && { title }),
        ...(genre !== undefined && { genre }),
        ...(albumId !== undefined && { albumId: albumId || null }),
        ...(isPublic !== undefined && { isPublic: isPublic === 'false' ? false : true }),
        ...(coverFile && { coverImage: `/uploads/${coverFile.filename}` }),
      },
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
    });

    res.json(updatedSong);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar canción' });
  }
}

export async function deleteSong(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const existingSong = await prisma.song.findUnique({
      where: { id },
    });

    if (!existingSong) {
      res.status(404).json({ error: 'Canción no encontrada' });
      return;
    }

    if (existingSong.ownerId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para eliminar esta canción' });
      return;
    }

    await prisma.song.delete({
      where: { id },
    });

    res.json({ message: 'Canción eliminada exitosamente' });
  } catch (error) {
    res.status(500).json({ error: 'Error al eliminar canción' });
  }
}

export async function incrementPlays(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const song = await prisma.song.findUnique({
      where: { id },
      select: { id: true, ownerId: true },
    });

    if (!song) {
      res.status(404).json({ error: 'Canción no encontrada' });
      return;
    }

    // Obtener IP y User-Agent
    const ip = (req.headers['x-forwarded-for'] as string)?.split(',')[0]?.trim() || req.socket.remoteAddress || null;
    const userAgent = (req.headers['user-agent'] as string) || null;

    // Usar el country del usuario autenticado si existe
    const userCountry = req.userId
      ? (await prisma.user.findUnique({ where: { id: req.userId }, select: { country: true } }))?.country
      : null;

    // Registrar el stream
    await prisma.$transaction([
      prisma.song.update({
        where: { id },
        data: { plays: { increment: 1 } },
      }),
      prisma.streamRecord.create({
        data: {
          songId: id,
          ownerId: song.ownerId,
          userId: req.userId || null,
          ip,
          userAgent,
          country: userCountry || null,
        },
      }),
    ]);

    const updatedSong = await prisma.song.findUnique({ where: { id }, select: { plays: true } });
    res.json({ plays: updatedSong?.plays || 0 });
  } catch (error) {
    console.error('Error en incrementPlays:', error);
    res.status(500).json({ error: 'Error al registrar reproducción' });
  }
}
