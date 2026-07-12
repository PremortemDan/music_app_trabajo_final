import multer, { FileFilterCallback } from 'multer';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { Request } from 'express';

// Configuración de almacenamiento
const storage = multer.diskStorage({
  destination: (_req: Request, _file: Express.Multer.File, cb: (error: Error | null, destination: string) => void) => {
    cb(null, path.join(__dirname, '..', '..', 'uploads'));
  },
  filename: (_req: Request, file: Express.Multer.File, cb: (error: Error | null, filename: string) => void) => {
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;
    cb(null, filename);
  },
});

// Extensiones y MIME types permitidos
const allowedAudioExtensions = ['.mp3', '.wav', '.flac', '.aac', '.ogg', '.m4a', '.wma', '.opus'];
const allowedImageExtensions = ['.jpg', '.jpeg', '.png', '.webp', '.gif', '.bmp'];
const allowedAudioMimes = [
  'audio/mpeg', 'audio/mp3', 'audio/wav', 'audio/x-wav', 'audio/wave',
  'audio/flac', 'audio/aac', 'audio/ogg', 'audio/x-m4a', 'audio/mp4',
  'audio/opus', 'application/octet-stream', 'audio/x-ms-wma',
];
const allowedImageMimes = [
  'image/jpeg', 'image/png', 'image/jpg', 'image/webp',
  'image/gif', 'image/bmp', 'application/octet-stream',
];

// Filtro combinado (MIME type O extensión)
const fileFilter = (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
  const ext = path.extname(file.originalname).toLowerCase();

  const isAllowedMime = [...allowedAudioMimes, ...allowedImageMimes].includes(file.mimetype);
  const isAllowedExt = [...allowedAudioExtensions, ...allowedImageExtensions].includes(ext);

  if (isAllowedMime || isAllowedExt) {
    cb(null, true);
  } else {
    console.error(`Archivo rechazado - MIME: ${file.mimetype}, Ext: ${ext}, Nombre: ${file.originalname}`);
    cb(new Error(`Tipo de archivo no permitido (MIME: ${file.mimetype}, Ext: ${ext})`));
  }
};

// Upload para canciones
export const uploadSong = multer({
  storage,
  fileFilter,
  limits: { fileSize: 50 * 1024 * 1024 }, // 50MB
});

// Upload para imágenes
export const uploadImage = multer({
  storage,
  fileFilter: (_req: Request, file: Express.Multer.File, cb: FileFilterCallback) => {
    const ext = path.extname(file.originalname).toLowerCase();
    const isAllowedMime = allowedImageMimes.includes(file.mimetype);
    const isAllowedExt = allowedImageExtensions.includes(ext);

    if (isAllowedMime || isAllowedExt) {
      cb(null, true);
    } else {
      console.error(`Imagen rechazada - MIME: ${file.mimetype}, Ext: ${ext}`);
      cb(new Error(`Solo se permiten imágenes (JPEG, PNG, WebP). Recibido: MIME=${file.mimetype}, Ext=${ext}`));
    }
  },
  limits: { fileSize: 5 * 1024 * 1024 }, // 5MB
});
