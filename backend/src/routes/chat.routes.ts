import { Router } from 'express';
import {
  getConversations,
  getMessages,
  sendMessage,
  searchUsers,
} from '../controllers/chat.controller';
import { authenticateToken } from '../middleware/auth.middleware';

const router = Router();

router.get('/conversations', authenticateToken, getConversations);
router.get('/conversations/:conversationId/messages', authenticateToken, getMessages);
router.post('/messages', authenticateToken, sendMessage);
router.get('/search', authenticateToken, searchUsers);

export { router as chatRoutes };