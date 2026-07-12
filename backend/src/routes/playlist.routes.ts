import { Router } from 'express';
import {
  getPlaylists,
  getPlaylistById,
  createPlaylist,
  updatePlaylist,
  deletePlaylist,
  addSongToPlaylist,
  removeSongFromPlaylist,
} from '../controllers/playlist.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.get('/', authenticateToken, getPlaylists);
router.get('/:id', authenticateToken, getPlaylistById);
router.post('/', authenticateToken, createPlaylist);
router.put('/:id', authenticateToken, updatePlaylist);
router.delete('/:id', authenticateToken, deletePlaylist);
router.post('/:id/songs/:songId', authenticateToken, addSongToPlaylist);
router.delete('/:id/songs/:songId', authenticateToken, removeSongFromPlaylist);

export { router as playlistRoutes };