import { Router } from 'express';
import {
  getArtists,
  getArtistById,
  registerAsCreator,
  getMyArtistProfile,
  updateArtistProfile,
} from '../controllers/artist.controller';
import { authenticateToken } from '../middleware/auth.middleware';
import { uploadImage } from '../middleware/upload.middleware';

const router = Router();

router.get('/', getArtists);
router.get('/:id', getArtistById);
router.post('/register', authenticateToken, uploadImage.single('image'), registerAsCreator);
router.get('/profile/me', authenticateToken, getMyArtistProfile);
router.put('/profile/me', authenticateToken, uploadImage.single('image'), updateArtistProfile);

export { router as artistRoutes };