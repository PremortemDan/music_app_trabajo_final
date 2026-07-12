import { Router } from 'express';
import { streamSong } from '../controllers/stream.controller';

const router = Router();

router.get('/:songId', streamSong);

export { router as streamRoutes };