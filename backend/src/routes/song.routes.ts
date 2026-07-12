import { Router } from 'express';
import {
  getSongs,
  getSongById,
  uploadSongController,
  updateSong,
  deleteSong,
  getMySongs,
  incrementPlays,
} from '../controllers/song.controller';
import { authenticateToken, requireCreator } from '../middleware/auth.middleware';
import { uploadSong } from '../middleware/upload.middleware';

const router = Router();

router.get('/', getSongs);
router.get('/my-songs', authenticateToken, getMySongs);
router.get('/:id', getSongById);
router.post('/upload', authenticateToken, requireCreator, uploadSong.fields([
  { name: 'song', maxCount: 1 },
  { name: 'cover', maxCount: 1 },
]), uploadSongController);
router.put('/:id', authenticateToken, requireCreator, uploadSong.fields([
  { name: 'song', maxCount: 1 },
  { name: 'cover', maxCount: 1 },
]), updateSong);
router.delete('/:id', authenticateToken, requireCreator, deleteSong);
router.post('/:id/play', incrementPlays);

export { router as songRoutes };