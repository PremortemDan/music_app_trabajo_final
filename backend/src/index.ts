import express from 'express';
import cors from 'cors';
import path from 'path';
import dotenv from 'dotenv';
import { authRoutes } from './routes/auth.routes';
import { userRoutes } from './routes/user.routes';
import { artistRoutes } from './routes/artist.routes';
import { songRoutes } from './routes/song.routes';
import { albumRoutes } from './routes/album.routes';
import { playlistRoutes } from './routes/playlist.routes';
import { streamRoutes } from './routes/stream.routes';
import { analyticsRoutes } from './routes/analytics.routes';
import { chatRoutes } from './routes/chat.routes';

dotenv.config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middlewares
app.use(cors({
  origin: '*',
  methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization', 'X-Requested-With', 'Accept', 'Origin'],
  credentials: true,
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Servir archivos estáticos (uploads)
app.use('/uploads', express.static(path.join(__dirname, '..', 'uploads')));

// Ruta base de la API
app.get('/api/', (_req, res) => {
  res.json({
    message: 'Music App API v1.0',
    endpoints: {
      auth: '/api/auth',
      users: '/api/users',
      artists: '/api/artists',
      songs: '/api/songs',
      albums: '/api/albums',
      playlists: '/api/playlists',
      stream: '/api/stream',
      analytics: '/api/analytics',
      chat: '/api/chat',
      health: '/api/health',
    },
  });
});

// Rutas
app.use('/api/auth', authRoutes);
app.use('/api/users', userRoutes);
app.use('/api/artists', artistRoutes);
app.use('/api/songs', songRoutes);
app.use('/api/albums', albumRoutes);
app.use('/api/playlists', playlistRoutes);
app.use('/api/stream', streamRoutes);
app.use('/api/analytics', analyticsRoutes);
app.use('/api/chat', chatRoutes);

// Ruta de health check
app.get('/api/health', (_req, res) => {
  res.json({ status: 'ok', timestamp: new Date().toISOString() });
});

// Manejo de errores global
app.use((err: any, _req: express.Request, res: express.Response, _next: express.NextFunction) => {
  console.error(err.stack);
  res.status(err.status || 500).json({
    error: err.message || 'Error interno del servidor',
  });
});

const HOST = process.env.HOST || '0.0.0.0';

app.listen(Number(PORT), HOST, () => {
  console.log(`🚀 Servidor corriendo en http://${HOST}:${PORT}`);
});

export default app;