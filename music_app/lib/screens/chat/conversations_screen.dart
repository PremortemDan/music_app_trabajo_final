import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:timeago/timeago.dart' as timeago;
import '../../providers/chat_provider.dart';
import 'chat_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  final _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadConversations();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ChatProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Chats', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: Column(
        children: [
          // Barra de búsqueda de usuarios
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar usuario por nombre...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          provider.clearSearch();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
              ),
              onChanged: (value) {
                setState(() {});
                provider.searchUsers(value);
              },
            ),
          ),

          // Resultados de búsqueda
          if (provider.isSearching)
            const Padding(
              padding: EdgeInsets.all(16),
              child: CircularProgressIndicator(),
            )
          else if (provider.searchResults.isNotEmpty)
            Expanded(
              child: ListView.builder(
                itemCount: provider.searchResults.length,
                itemBuilder: (context, index) {
                  final user = provider.searchResults[index];
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: Colors.grey[800],
                      child: Text(
                        user.username[0].toUpperCase(),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                    title: Text(user.username),
                    trailing: const Icon(Icons.send_outlined, color: Color(0xff9bd49f)),
                    onTap: () async {
                      _searchController.clear();
                      provider.clearSearch();
                      setState(() {});
                      
                      // Abrir chat con este usuario
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => ChatScreen(
                            username: user.username,
                            otherUserId: user.id,
                          ),
                        ),
                      );
                      
                      if (mounted) {
                        provider.loadConversations();
                      }
                    },
                  );
                },
              ),
            )
          else if (provider.searchResults.isEmpty && _searchController.text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'No se encontraron usuarios',
                style: TextStyle(color: Colors.grey[400]),
              ),
            )
          else
            // Lista de conversaciones
            Expanded(
              child: provider.isLoadingConversations
                  ? const Center(child: CircularProgressIndicator())
                  : provider.conversations.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.chat_bubble_outline, size: 60,
                                  color: Colors.grey[600]),
                              const SizedBox(height: 16),
                              Text('No tienes conversaciones',
                                  style: TextStyle(color: Colors.grey[400], fontSize: 16)),
                              const SizedBox(height: 8),
                              Text('Busca un usuario arriba para iniciar un chat',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 13)),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: () => provider.loadConversations(),
                          child: ListView.builder(
                            itemCount: provider.conversations.length,
                            itemBuilder: (context, index) {
                              final conv = provider.conversations[index];
                              final hasUnread = conv.unreadCount > 0;

                              return ListTile(
                                leading: Stack(
                                  children: [
                                    CircleAvatar(
                                      backgroundColor: Colors.grey[800],
                                      child: Text(
                                        conv.otherUser.username[0].toUpperCase(),
                                        style: const TextStyle(color: Colors.white),
                                      ),
                                    ),
                                    if (hasUnread)
                                      Positioned(
                                        right: 0,
                                        bottom: 0,
                                        child: Container(
                                          width: 14,
                                          height: 14,
                                          decoration: const BoxDecoration(
                                            color: Color(0xff9bd49f),
                                            shape: BoxShape.circle,
                                          ),
                                          child: Center(
                                            child: Text(
                                              '${conv.unreadCount}',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 9,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                title: Text(
                                  conv.otherUser.username,
                                  style: TextStyle(
                                    fontWeight:
                                        hasUnread ? FontWeight.bold : FontWeight.normal,
                                  ),
                                ),
                                subtitle: Text(
                                  conv.lastMessage != null
                                      ? conv.lastMessage!.content
                                      : 'Inicia una conversación',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: hasUnread ? Colors.white : Colors.grey[500],
                                    fontWeight:
                                        hasUnread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                ),
                                trailing: Text(
                                  timeago.format(conv.updatedAt, locale: 'es'),
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                  ),
                                ),
                                onTap: () async {
                                  await Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => ChatScreen(
                                        conversationId: conv.id,
                                        otherUserId: conv.otherUser.id,
                                        username: conv.otherUser.username,
                                      ),
                                    ),
                                  );
                                  if (mounted) {
                                    provider.loadConversations();
                                  }
                                },
                              );
                            },
                          ),
                        ),
            ),
        ],
      ),
    );
  }
}