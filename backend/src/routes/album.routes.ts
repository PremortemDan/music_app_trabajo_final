import { Router } from 'express';
import {
  getAlbums,
  getAlbumById,
  createAlbum,
  updateAlbum,
  deleteAlbum,
} from '../controllers/album.controller';
import { authenticateToken, requireCreator } from '../middleware/auth.middleware';
import { uploadImage } from '../middleware/upload.middleware';

const router = Router();

router.get('/', getAlbums);
router.get('/:id', getAlbumById);
router.post('/', authenticateToken, requireCreator, uploadImage.single('cover'), createAlbum);
router.put('/:id', authenticateToken, requireCreator, uploadImage.single('cover'), updateAlbum);
router.delete('/:id', authenticateToken, requireCreator, deleteAlbum);

export { router as albumRoutes };