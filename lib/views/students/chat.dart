import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:project_management/services/ai_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class chatscreen extends StatefulWidget {
  const chatscreen({Key? key}) : super(key: key);

  @override
  State<chatscreen> createState() => _chatscreenState();
}

class ChatSession {
  final String id;
  final String title;
  final DateTime createdAt;
  final List<ChatMessage> messages;

  ChatSession({
    required this.id,
    required this.title,
    required this.createdAt,
    required this.messages,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'createdAt': createdAt.toIso8601String(),
      'messages': messages.map((msg) => msg.toJson()).toList(),
    };
  }

  factory ChatSession.fromJson(Map<String, dynamic> json) {
    return ChatSession(
      id: json['id'] as String,
      title: json['title'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      messages:
          (json['messages'] as List)
              .map((msg) => ChatMessage.fromJson(msg as Map<String, dynamic>))
              .toList(),
    );
  }
}

class _chatscreenState extends State<chatscreen> {
  final TextEditingController _messageController = TextEditingController();
  final AiService _aiService = AiService();

  List<ChatSession> _allChats = [];
  late ChatSession _currentChat;
  bool _isLoading = false;
  String _studentName = '';

  @override
  void initState() {
    super.initState();
    _currentChat = ChatSession(
      id: 'temp',
      title: 'New Chat',
      createdAt: DateTime.now(),
      messages: [],
    );
    _loadStudentName();
    _loadAllChats().then((_) {
      if (mounted) {
        _startNewChat();
      }
    });
  }

  Future<void> _loadStudentName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _studentName = prefs.getString('studentName') ?? 'there';
    });
  }

  Future<void> _loadAllChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = prefs.getString('all_chats');
      if (chatsJson != null) {
        final List<dynamic> decodedChats = jsonDecode(chatsJson);
        setState(() {
          _allChats =
              decodedChats
                  .map(
                    (chat) =>
                        ChatSession.fromJson(chat as Map<String, dynamic>),
                  )
                  .toList();
          _allChats.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        });
      }
    } catch (e) {
      print('Error loading chats: $e');
    }
  }

  void _startNewChat() {
    setState(() {
      _currentChat = ChatSession(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: 'New Chat',
        createdAt: DateTime.now(),
        messages: [],
      );
    });
  }

  Future<void> _saveAllChats() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final chatsJson = jsonEncode(
        _allChats.map((chat) => chat.toJson()).toList(),
      );
      await prefs.setString('all_chats', chatsJson);
    } catch (e) {
      print('Error saving chats: $e');
    }
  }

  void _loadChat(ChatSession chat) {
    setState(() {
      _currentChat = chat;
    });
    Navigator.pop(context);
  }

  void _deleteChat(String chatId) {
    setState(() {
      _allChats.removeWhere((chat) => chat.id == chatId);
    });
    _saveAllChats();
    if (_currentChat.id == chatId) {
      _startNewChat();
    }
  }

  void _sendMessage() async {
    if (_messageController.text.trim().isEmpty) return;

    final userMessage = _messageController.text.trim();
    _messageController.clear();

    setState(() {
      _currentChat.messages.add(
        ChatMessage(text: userMessage, isUser: true, timestamp: DateTime.now()),
      );
      _isLoading = true;

      // Update title if it's still "New Chat"
      if (_currentChat.title == 'New Chat' &&
          _currentChat.messages.length == 1) {
        _currentChat = ChatSession(
          id: _currentChat.id,
          title:
              userMessage.length > 30
                  ? '${userMessage.substring(0, 30)}...'
                  : userMessage,
          createdAt: _currentChat.createdAt,
          messages: _currentChat.messages,
        );
      }
    });

    try {
      final aiResponse = await _aiService.sendChatMessage(userMessage);

      if (aiResponse != null && mounted) {
        setState(() {
          _currentChat.messages.add(
            ChatMessage(
              text: aiResponse,
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      } else if (mounted) {
        setState(() {
          _currentChat.messages.add(
            ChatMessage(
              text: "Sorry, I couldn't get a response. Please try again.",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _currentChat.messages.add(
            ChatMessage(
              text: "Error: ${e.toString()}",
              isUser: false,
              timestamp: DateTime.now(),
            ),
          );
          _isLoading = false;
        });
      }
    }

    // Save to history
    if (_currentChat.messages.isNotEmpty) {
      final existingIndex = _allChats.indexWhere(
        (chat) => chat.id == _currentChat.id,
      );
      if (existingIndex >= 0) {
        _allChats[existingIndex] = _currentChat;
      } else {
        _allChats.insert(0, _currentChat);
      }
      _saveAllChats();
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: const Color(0xFFE5A72E),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Chat with AI',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.history, color: Colors.black),
            onPressed: _showChatHistory,
          ),
        ],
      ),
      body: Column(
        children: [
          // Messages area
          Expanded(
            child:
                _currentChat.messages.isEmpty
                    ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Opacity(
                            opacity: 0.5,
                            child: SvgPicture.asset(
                              'assets/icons/chat.svg',
                              width: 70,
                              height: 70,
                              colorFilter: const ColorFilter.mode(
                                Color(0xFFE5A72E),
                                BlendMode.srcIn,
                              ),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            'Hey, $_studentName!',
                            style: const TextStyle(
                              color: Color.fromARGB(221, 133, 130, 130),
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            "What's the plan?",
                            style: TextStyle(
                              color: Color(0xFFE5A72E),
                              fontSize: 16,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    )
                    : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _currentChat.messages.length,
                      itemBuilder: (context, index) {
                        return ChatBubble(
                          message: _currentChat.messages[index],
                        );
                      },
                    ),
          ),
          if (_isLoading)
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.grey[400]!,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Input area
          Container(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(
                      hintText: 'Type your message...',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: const Color(0xFFE5A72E),
                  child: IconButton(
                    icon: const Icon(Icons.send, color: Colors.white),
                    onPressed: _sendMessage,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showChatHistory() {
    showModalBottomSheet(
      context: context,
      builder:
          (context) => Container(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Chat History',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child:
                      _allChats.isEmpty
                          ? const Center(child: Text('No chat history yet'))
                          : ListView.builder(
                            itemCount: _allChats.length,
                            itemBuilder: (context, index) {
                              final chat = _allChats[index];
                              final isCurrentChat = chat.id == _currentChat.id;
                              return Container(
                                color: isCurrentChat ? Colors.grey[100] : null,
                                child: ListTile(
                                  title: Text(
                                    chat.title,
                                    style: TextStyle(
                                      fontWeight:
                                          isCurrentChat
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                    ),
                                  ),
                                  subtitle: Text(
                                    'Created: ${_formatDate(chat.createdAt)}',
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                  onTap: () => _loadChat(chat),
                                  trailing: IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _deleteChat(chat.id),
                                  ),
                                ),
                              );
                            },
                          ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE5A72E),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      onPressed: () {
                        _startNewChat();
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'New Chat',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final dateOnly = DateTime(date.year, date.month, date.day);

    if (dateOnly == today) {
      return 'Today ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
    } else if (dateOnly == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }
}

class ChatLoadingIndicator extends StatefulWidget {
  @override
  State<ChatLoadingIndicator> createState() => _ChatLoadingIndicatorState();
}

class _ChatLoadingIndicatorState extends State<ChatLoadingIndicator>
    with TickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AnimatedDot(
            animation: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.0, 0.4),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedDot(
            animation: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.2, 0.6),
              ),
            ),
          ),
          const SizedBox(width: 4),
          AnimatedDot(
            animation: Tween(begin: 0.0, end: 1.0).animate(
              CurvedAnimation(
                parent: _controller,
                curve: const Interval(0.4, 0.8),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class AnimatedDot extends StatelessWidget {
  final Animation<double> animation;

  const AnimatedDot({required this.animation});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, -animation.value * 4),
          child: Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: Colors.grey.shade600,
              shape: BoxShape.circle,
            ),
          ),
        );
      },
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final DateTime timestamp;

  ChatMessage({
    required this.text,
    required this.isUser,
    required this.timestamp,
  });

  // Convert to JSON for saving
  Map<String, dynamic> toJson() {
    return {
      'text': text,
      'isUser': isUser,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  // Create from JSON for loading
  factory ChatMessage.fromJson(Map<String, dynamic> json) {
    return ChatMessage(
      text: json['text'] as String,
      isUser: json['isUser'] as bool,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }
}

class ChatBubble extends StatelessWidget {
  final ChatMessage message;

  const ChatBubble({Key? key, required this.message}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Align(
        alignment:
            message.isUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color:
                message.isUser ? const Color(0xFFE5A72E) : Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          child: Text(
            message.text,
            style: TextStyle(
              color: message.isUser ? Colors.white : Colors.black87,
              fontSize: 15,
            ),
          ),
        ),
      ),
    );
  }
}
