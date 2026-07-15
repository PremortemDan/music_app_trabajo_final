import { Response } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export async function getArtists(_req: AuthRequest, res: Response): Promise<void> {
  try {
    const artists = await prisma.artistProfile.findMany({
      include: {
        user: {
          select: { id: true, username: true, avatar: true },
        },
        _count: {
          select: { songs: true, albums: true },
        },
      },
      orderBy: { createdAt: 'desc' },
    });

    res.json(artists);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener artistas' });
  }
}

export async function getArtistById(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { id } = req.params;

    const artist = await prisma.artistProfile.findUnique({
      where: { id },
      include: {
        user: {
          select: { id: true, username: true, avatar: true },
        },
        songs: {
          orderBy: { createdAt: 'desc' },
        },
        albums: {
          orderBy: { createdAt: 'desc' },
        },
        _count: {
          select: { songs: true, albums: true },
        },
      },
    });

    if (!artist) {
      res.status(404).json({ error: 'Artista no encontrado' });
      return;
    }

    res.json(artist);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener artista' });
  }
}

export async function registerAsCreator(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.userId!;
    const { artistName, bio, genre, website, instagram } = req.body;

    if (!artistName) {
      res.status(400).json({ error: 'El nombre de artista es requerido' });
      return;
    }

    // Verificar que no tenga ya artist profile
    const existingProfile = await prisma.artistProfile.findUnique({
      where: { userId },
    });

    if (existingProfile) {
      res.status(400).json({ error: 'Ya tienes un perfil de creador' });
      return;
    }

    const image = req.file ? `/uploads/${req.file.filename}` : null;

    const artistProfile = await prisma.artistProfile.create({
      data: {
        userId,
        artistName,
        bio: bio || null,
        genre: genre || null,
        website: website || null,
        instagram: instagram || null,
        image,
      },
      include: {
        user: {
          select: { id: true, username: true, email: true, avatar: true },
        },
      },
    });

    // Actualizar creator flag en el usuario
    const updatedUser = await prisma.user.update({
      where: { id: userId },
      data: { creator: true },
      select: { id: true, email: true, username: true, avatar: true, creator: true },
    });

    // Generar nuevo token JWT con creator: true
    const token = jwt.sign(
      { userId: updatedUser.id, creator: updatedUser.creator },
      process.env.JWT_SECRET || 'secret',
      { expiresIn: '7d' }
    );

    res.status(201).json({
      message: 'Perfil de creador registrado exitosamente',
      artistProfile,
      token,
      user: updatedUser,
    });
  } catch (error) {
    console.error('Error en registerAsCreator:', error);
    res.status(500).json({ error: 'Error al registrar como creador' });
  }
}

export async function getMyArtistProfile(req: AuthRequest, res: Response): Promise<void> {
  try {
    const artistProfile = await prisma.artistProfile.findUnique({
      where: { userId: req.userId },
      include: {
        user: {
          select: { id: true, username: true, email: true, avatar: true },
        },
        songs: {
          orderBy: { createdAt: 'desc' },
        },
        albums: {
          orderBy: { createdAt: 'desc' },
        },
        _count: {
          select: { songs: true, albums: true },
        },
      },
    });

    if (!artistProfile) {
      res.status(404).json({ error: 'No tienes un perfil de creador. Regístrate primero.' });
      return;
    }

    res.json(artistProfile);
  } catch (error) {
    res.status(500).json({ error: 'Error al obtener perfil de creador' });
  }
}

export async function updateArtistProfile(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { artistName, bio, genre, website, instagram } = req.body;
    const image = req.file ? `/uploads/${req.file.filename}` : undefined;

    const artistProfile = await prisma.artistProfile.update({
      where: { userId: req.userId },
      data: {
        ...(artistName && { artistName }),
        ...(bio !== undefined && { bio }),
        ...(genre !== undefined && { genre }),
        ...(website !== undefined && { website }),
        ...(instagram !== undefined && { instagram }),
        ...(image && { image }),
      },
      include: {
        user: {
          select: { id: true, username: true, email: true, avatar: true },
        },
      },
    });

    res.json(artistProfile);
  } catch (error) {
    res.status(500).json({ error: 'Error al actualizar perfil de creador' });
  }
}