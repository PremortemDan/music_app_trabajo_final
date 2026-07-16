import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ChatUser {
  final String id;
  final String username;
  final String? avatar;

  ChatUser({required this.id, required this.username, this.avatar});

  factory ChatUser.fromJson(Map<String, dynamic> json) {
    return ChatUser(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      avatar: json['avatar'],
    );
  }
}

class ChatMessage {
  final String id;
  final String conversationId;
  final String senderId;
  final String? senderUsername;
  final String? senderAvatar;
  final String content;
  final bool read;
  final DateTime createdAt;

  ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    this.senderUsername,
    this.senderAvatar,
    required this.content,
    required this.read,
    required this.createdAt,
  });

  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      id: json['id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      senderId: json['senderId'] ?? (json['sender']?['id'] ?? ''),
      senderUsername: json['sender']?['username'],
      senderAvatar: json['sender']?['avatar'],
      content: json['content'] ?? '',
      read: json['read'] ?? false,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
    );
  }
}

class Conversation {
  final String id;
  final ChatUser otherUser;
  final ChatMessage? lastMessage;
  final int unreadCount;
  final DateTime updatedAt;

  Conversation({
    required this.id,
    required this.otherUser,
    this.lastMessage,
    required this.unreadCount,
    required this.updatedAt,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['id'] ?? '',
      otherUser: ChatUser.fromJson(json['otherUser'] ?? {}),
      lastMessage: json['lastMessage'] != null
          ? ChatMessage.fromJson(json['lastMessage'])
          : null,
      unreadCount: json['unreadCount'] ?? 0,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : DateTime.now(),
    );
  }
}

class ChatProvider extends ChangeNotifier {
  List<Conversation> _conversations = [];
  List<ChatMessage> _messages = [];
  List<ChatUser> _searchResults = [];
  bool _isLoadingConversations = false;
  bool _isLoadingMessages = false;
  bool _isSearching = false;
  String? _currentConversationId;

  List<Conversation> get conversations => _conversations;
  List<ChatMessage> get messages => _messages;
  List<ChatUser> get searchResults => _searchResults;
  bool get isLoadingConversations => _isLoadingConversations;
  bool get isLoadingMessages => _isLoadingMessages;
  bool get isSearching => _isSearching;
  String? get currentConversationId => _currentConversationId;

  int get totalUnread {
    return _conversations.fold(0, (sum, c) => sum + c.unreadCount);
  }

  Future<void> loadConversations() async {
    _isLoadingConversations = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/chat/conversations');
      _conversations = (data as List)
          .map((e) => Conversation.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _conversations = [];
    }

    _isLoadingConversations = false;
    notifyListeners();
  }

  Future<void> loadMessages(String conversationId) async {
    _isLoadingMessages = true;
    _currentConversationId = conversationId;
    notifyListeners();

    try {
      final data = await ApiService.get(
        '/chat/conversations/$conversationId/messages',
      );
      _messages = (data as List)
          .map((e) => ChatMessage.fromJson(e as Map<String, dynamic>))
          .toList();
      // Marcar no leídos como 0 en la conversación local
      final idx = _conversations.indexWhere((c) => c.id == conversationId);
      if (idx >= 0) {
        _conversations[idx] = Conversation(
          id: _conversations[idx].id,
          otherUser: _conversations[idx].otherUser,
          lastMessage: _conversations[idx].lastMessage,
          unreadCount: 0,
          updatedAt: _conversations[idx].updatedAt,
        );
      }
    } catch (e) {
      _messages = [];
    }

    _isLoadingMessages = false;
    notifyListeners();
  }

  Future<ChatMessage?> sendMessage(String conversationId, String content) async {
    try {
      final data = await ApiService.post(
        '/chat/messages',
        body: {
          'conversationId': conversationId,
          'content': content,
        },
      );
      final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
      _messages.add(msg);
      notifyListeners();
      return msg;
    } catch (e) {
      return null;
    }
  }

  Future<ChatMessage?> sendMessageToUser(String username, String content) async {
    try {
      final data = await ApiService.post(
        '/chat/messages',
        body: {
          'receiverUsername': username,
          'content': content,
        },
      );
      final msg = ChatMessage.fromJson(data as Map<String, dynamic>);
      _messages.add(msg);
      notifyListeners();
      return msg;
    } catch (e) {
      return null;
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().length < 2) {
      _searchResults = [];
      _isSearching = false;
      notifyListeners();
      return;
    }

    _isSearching = true;
    notifyListeners();

    try {
      final data = await ApiService.get('/chat/search?q=$query');
      _searchResults = (data as List)
          .map((e) => ChatUser.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      _searchResults = [];
    }

    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    _isSearching = false;
  }

  void clearMessages() {
    _messages = [];
    _currentConversationId = null;
  }
}