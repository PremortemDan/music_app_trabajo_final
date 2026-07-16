import { Router } from 'express';
import { getCreatorMetrics } from '../controllers/analytics.controller';
import { authenticateToken, requireCreator } from '../middleware/auth.middleware';

const router = Router();

router.get('/creator', authenticateToken, requireCreator, getCreatorMetrics);

export { router as analyticsRoutes };