import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export async function getAlbums(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { artistId } = req.query;

    const where: any = {};
    if (artistId) where.artistId = artistId as string;

    const albums = await prisma.album.findMany({
      where,
      include: {
        artist: {
          select: { id: true, artistName: true, image: true },
        },
        _count: {
          select: { songs: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(albums);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener álbumes' });
  }
}

export async function getAlbumById(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const album = await prisma.album.findUnique({
      where: { id },
      include: {
        artist: {
          select: { id: true, artistName: true, image: true },
        },
        songs: {
          orderBy: { createdAt: 'desc' },
          include: {
            owner: {
              select: { id: true, username: true },
            },
          },
        },
        _count: {
          select: { songs: true },
        },
      },
    });

    if (!album) {
      res.status(404).json({ error: 'Álbum no encontrado' });
      return;
    }

    res.json(album);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener álbum' });
  }
}

export async function createAlbum(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { title, genre, releaseDate } = req.body;

    if (!title) {
      res.status(400).json({ error: 'El título del álbum es requerido' });
      return;
    }

    // Obtener el artist profile del usuario
    const artistProfile = await prisma.artistProfile.findUnique({
      where: { userId: req.userId },
    });

    if (!artistProfile) {
      res.status(400).json({ error: 'Necesitas un perfil de creador para crear álbumes' });
      return;
    }

    const cover = req.file ? `/uploads/${req.file.filename}` : null;

    const album = await prisma.album.create({
      data: {
        artistId: artistProfile.id,
        title,
        genre: genre || null,
        releaseDate: releaseDate ? new Date(releaseDate) : null,
        cover,
      },
      include: {
        artist: {
          select: { id: true, artistName: true, image: true },
        },
      },
    });

    res.status(201).json(album);
  } catch (error) {
    res.status(500).json({ error: 'Error al crear álbum' });
  }
}

export async function updateAlbum(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;
    const { title, genre, releaseDate } = req.body;

    const existingAlbum = await prisma.album.findUnique({
      where: { id },
      include: { artist: true },
    });

    if (!existingAlbum) {
      res.status(404).json({ error: 'Álbum no encontrado' });
      return;
    }

    if (existingAlbum.artist.userId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para editar este álbum' });
      return;
    }

    const cover = req.file ? `/uploads/${req.file.filename}` : undefined;

    const album = await prisma.album.update({
      where: { id },
      data: {
        ...(title && { title }),
        ...(genre !== undefined && { genre }),
        ...(releaseDate !== undefined && { releaseDate: releaseDate ? new Date(releaseDate) : null }),
        ...(cover && { cover }),
      },
      include: {
        artist: {
          select: { id: true, artistName: true, image: true },
        },
      },
    });

    res.json(album);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar álbum' });
  }
}

export async function deleteAlbum(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const existingAlbum = await prisma.album.findUnique({
      where: { id },
      include: { artist: true },
    });

    if (!existingAlbum) {
      res.status(404).json({ error: 'Álbum no encontrado' });
      return;
    }

    if (existingAlbum.artist.userId !== req.userId) {
      res.status(403).json({ error: 'No tienes permiso para eliminar este álbum' });
      return;
    }

    await prisma.album.delete({
      where: { id },
    });

    res.json({ message: 'Álbum eliminado exitosamente' });
  } catch (error) {
    res.status(500).json({ error: 'Error al eliminar álbum' });
  }
}