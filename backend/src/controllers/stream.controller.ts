import { Response } from 'express';
import fs from 'fs';
import path from 'path';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

export async function streamSong(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { songId } = req.params;

    const song = await prisma.song.findUnique({
      where: { id: songId },
    });

    if (!song) {
      res.status(404).json({ error: 'Canción no encontrada' });
      return;
    }

    // Eliminar slash inicial si existe para que path.join funcione correctamente
    const relativePath = song.filePath.startsWith('/') ? song.filePath.slice(1) : song.filePath;
    const filePath = path.join(__dirname, '..', '..', relativePath);

    // Verificar que el archivo existe
    if (!fs.existsSync(filePath)) {
      res.status(404).json({ error: 'Archivo de audio no encontrado' });
      return;
    }

    const stat = fs.statSync(filePath);
    const fileSize = stat.size;
    const range = req.headers.range;

    if (range) {
      const parts = range.replace(/bytes=/, '').split('-');
      const start = parseInt(parts[0], 10);
      const end = parts[1] ? parseInt(parts[1], 10) : fileSize - 1;
      const chunksize = end - start + 1;

      const file = fs.createReadStream(filePath, { start, end });
      const head = {
        'Content-Range': `bytes ${start}-${end}/${fileSize}`,
        'Accept-Ranges': 'bytes',
        'Content-Length': chunksize,
        'Content-Type': 'audio/mpeg',
      };

      res.writeHead(206, head);
      file.pipe(res);
    } else {
      const head = {
        'Content-Length': fileSize,
        'Content-Type': 'audio/mpeg',
      };

      res.writeHead(200, head);
      fs.createReadStream(filePath).pipe(res);
    }

    // Incrementar plays
    await prisma.song.update({
      where: { id: songId },
      data: { plays: { increment: 1 } },
    });
  } catch (error) {
    console.error('Error en streamSong:', error);
    res.status(500).json({ error: 'Error al transmitir canción' });
  }
}