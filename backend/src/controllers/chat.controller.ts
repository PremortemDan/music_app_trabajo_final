import { Response } from 'express';
import prisma from '../lib/prisma';
import { AuthRequest } from '../middleware/auth.middleware';

// Obtener todas las conversaciones del usuario
export async function getConversations(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.userId!;

    const conversations = await prisma.conversation.findMany({
      where: {
        OR: [
          { user1Id: userId },
          { user2Id: userId },
        ],
      },
      include: {
        user1: {
          select: { id: true, username: true, avatar: true },
        },
        user2: {
          select: { id: true, username: true, avatar: true },
        },
        messages: {
          orderBy: { createdAt: 'desc' },
          take: 1,
          select: {
            id: true,
            content: true,
            senderId: true,
            read: true,
            createdAt: true,
          },
        },
        _count: {
          select: {
            messages: {
              where: {
                senderId: { not: userId },
                read: false,
              },
            },
          },
        },
      },
      orderBy: { updatedAt: 'desc' },
    });

    const result = conversations.map((c) => {
      const other = c.user1Id === userId ? c.user2 : c.user1;
      const lastMessage = c.messages[0] || null;
      return {
        id: c.id,
        otherUser: other,
        lastMessage,
        unreadCount: c._count.messages,
        updatedAt: c.updatedAt,
      };
    });

    res.json(result);
  } catch (error) {
    console.error('Error getConversations:', error);
    res.status(500).json({ error: 'Error al obtener conversaciones' });
  }
}

// Obtener mensajes de una conversación
export async function getMessages(req: AuthRequest, res: Response): Promise<void> {
  try {
    const userId = req.userId!;
    const { conversationId } = req.params;
    const { limit = 50, before } = req.query;

    // Verificar que el usuario pertenece a la conversación
    const conversation = await prisma.conversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation || (conversation.user1Id !== userId && conversation.user2Id !== userId)) {
      res.status(403).json({ error: 'No tienes acceso a esta conversación' });
      return;
    }

    const where: any = { conversationId };
    if (before) {
      where.createdAt = { lt: new Date(before as string) };
    }

    const messages = await prisma.message.findMany({
      where,
      include: {
        sender: {
          select: { id: true, username: true, avatar: true },
        },
      },
      orderBy: { createdAt: 'desc' },
      take: Number(limit),
    });

    // Marcar como leídos los mensajes del otro usuario
    await prisma.message.updateMany({
      where: {
        conversationId,
        senderId: { not: userId },
        read: false,
      },
      data: { read: true },
    });

    res.json(messages.reverse());
  } catch (error) {
    console.error('Error getMessages:', error);
    res.status(500).json({ error: 'Error al obtener mensajes' });
  }
}

// Enviar un mensaje
export async function sendMessage(req: AuthRequest, res: Response): Promise<void> {
  try {
    const senderId = req.userId!;
    const { conversationId, content, receiverUsername } = req.body;

    if (!content || content.trim().length === 0) {
      res.status(400).json({ error: 'El mensaje no puede estar vacío' });
      return;
    }

    let convId = conversationId;

    // Si no hay conversationId, buscar o crear conversación por username
    if (!convId) {
      if (!receiverUsername) {
        res.status(400).json({ error: 'Se requiere receiverUsername o conversationId' });
        return;
      }

      const receiver = await prisma.user.findUnique({
        where: { username: receiverUsername },
      });

      if (!receiver) {
        res.status(404).json({ error: 'Usuario no encontrado' });
        return;
      }

      if (receiver.id === senderId) {
        res.status(400).json({ error: 'No puedes chatear contigo mismo' });
        return;
      }

      // Buscar o crear conversación (ordenar IDs para garantizar unicidad)
      const user1Id = senderId < receiver.id ? senderId : receiver.id;
      const user2Id = senderId < receiver.id ? receiver.id : senderId;

      let conversation = await prisma.conversation.findUnique({
        where: { user1Id_user2Id: { user1Id, user2Id } },
      });

      if (!conversation) {
        conversation = await prisma.conversation.create({
          data: { user1Id, user2Id },
        });
      }

      convId = conversation.id;
    }

    // Crear el mensaje
    const message = await prisma.message.create({
      data: {
        conversationId: convId,
        senderId,
        content: content.trim(),
      },
      include: {
        sender: {
          select: { id: true, username: true, avatar: true },
        },
      },
    });

    // Actualizar el updatedAt de la conversación
    await prisma.conversation.update({
      where: { id: convId },
      data: { updatedAt: new Date() },
    });

    res.status(201).json(message);
  } catch (error) {
    console.error('Error sendMessage:', error);
    res.status(500).json({ error: 'Error al enviar mensaje' });
  }
}

// Buscar usuarios para iniciar chat
export async function searchUsers(req: AuthRequest, res: Response): Promise<void> {
  try {
    const { q } = req.query;
    const userId = req.userId!;

    if (!q || (q as string).trim().length < 2) {
      res.json([]);
      return;
    }

    const users = await prisma.user.findMany({
      where: {
        username: { contains: q as string, mode: 'insensitive' },
        id: { not: userId },
      },
      select: {
        id: true,
        username: true,
        avatar: true,
      },
      take: 20,
    });

    res.json(users);
  } catch (error) {
    console.error('Error searchUsers:', error);
    res.status(500).json({ error: 'Error al buscar usuarios' });
  }
}