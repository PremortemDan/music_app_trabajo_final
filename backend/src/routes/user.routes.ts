import { Router } from 'express';
import { getProfile, updateProfile, getLikedSongs, toggleLikeSong } from '../controllers/user.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.get('/profile', authenticateToken, getProfile);
router.put('/profile', authenticateToken, updateProfile);
router.get('/liked-songs', authenticateToken, getLikedSongs);
router.post('/like/:songId', authenticateToken, toggleLikeSong);

export { router as userRoutes };