import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

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
  if (!req.userCreator) {
    res.status(403).json({ error: 'Se requiere ser creador para realizar esta acción' });
    return;
  }
  next();
}