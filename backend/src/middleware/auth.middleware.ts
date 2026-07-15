import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';
import prisma from '../lib/prisma';

export interface AuthRequest extends Request {
  userId?: string;
  userCreator?: boolean;
  file?: Express.Multer.File;
  files?: { [fieldname: string]: Express.Multer.File[] } | Express.Multer.File[];
}

interface JwtPayload {
  userId: string;
  creator: boolean;
}

export function authenticateToken(req: AuthRequest, res: Response, next: NextFunction): void {
  const authHeader = req.headers['authorization'];
  const token = authHeader && authHeader.split(' ')[1];

  if (!token) {
    res.status(401).json({ error: 'Token de acceso requerido' });
    return;
  }

  try {
    const decoded = jwt.verify(token, process.env.JWT_SECRET || 'secret') as JwtPayload;
    req.userId = decoded.userId;
    req.userCreator = decoded.creator;
    next();
  } catch (error) {
    res.status(403).json({ error: 'Token inválido o expirado' });
    return;
  }
}

export function requireCreator(req: AuthRequest, res: Response, next: NextFunction): void {
  // Si el JWT ya indica creator: true, permitir
  if (req.userCreator) {
    next();
    return;
  }

  // Fallback: verificar en la BD (el usuario pudo haberse registrado como creador después del login)
  prisma.user.findUnique({ where: { id: req.userId }, select: { creator: true } })
    .then(user => {
      if (user?.creator) {
        req.userCreator = true;
        next();
      } else {
        res.status(403).json({ error: 'Se requiere ser creador para realizar esta acción' });
      }
    })
    .catch(() => {
      res.status(500).json({ error: 'Error al verificar permisos' });
    });
}
