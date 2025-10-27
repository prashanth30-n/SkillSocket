import 'package:flutter/material.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:barter_system/services/chat_service.dart';
import 'package:barter_system/services/user_service.dart';
import 'package:barter_system/profilepage.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class Chat extends StatefulWidget {
  final String chatId;
  final String recipientId;
  final String name;

  const Chat(
      {super.key,
      required this.chatId,
      required this.recipientId,
      required this.name});

  @override
  State<Chat> createState() => _ChatState();
}

class _ChatState extends State<Chat> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  final ScrollController _scrollController = ScrollController();
  late IO.Socket socket;
  String? currentUserId;
  Map<String, dynamic>? currentUserProfile;
  bool _isLoading = false;
  bool _isTyping = false;
  Timer? _typingTimer;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    setState(() {
      _isLoading = true;
    });

    // Get current user ID
    currentUserId = await ChatService.getCurrentUserId();

    if (currentUserId != null) {
      currentUserProfile = await UserService.getUserProfileById(currentUserId!);
      await _loadChatHistory();
      _connectToServer();
    } else {
      print('Error: No user ID found');
    }

    setState(() {
      _isLoading = false;
    });
  }

  Future<void> _loadChatHistory() async {
    try {
      final messages = await ChatService.getChatMessages(widget.recipientId);
      if (messages != null) {
        setState(() {
          _messages.clear();
          for (var message in messages) {
            _messages.add({
              'text': message['content'],
              'isMe': message['from']['_id'] == currentUserId,
              'time': _formatTime(message['createdAt']),
              'senderId': message['from']['_id'],
              'senderName': message['from']['name'],
              'senderProfile': message['from']['profileImage'], // new line
              'status': 'sent',
            });
          }
        });
        _scrollToBottom(); // Scroll to bottom after loading messages
      }
    } catch (e) {
      print('Error loading chat history: $e');
    }
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      return DateFormat('HH:mm').format(dateTime);
    } catch (e) {
      return TimeOfDay.now().format(context);
    }
  }

  void _connectToServer() {
    socket = IO.io(
  "https://skillsocket-backend.onrender.com/",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      print("Connected to socket server");
      if (currentUserId != null) {
        socket.emit("joinRoom", currentUserId);
      }
    });

    // Only add messages from other users to prevent duplicates
    socket.on("receiveMessage", (data) {
      if (mounted && data['from']['_id'] != currentUserId) {
        setState(() {
          _messages.add({
            'text': data['content'],
            'isMe': false,
            'time': _formatTime(data['createdAt']),
            'senderId': data['from']['_id'],
            'senderName': data['from']['name'],
          });
        });
        _scrollToBottom();

        // Mark message as read when received
        ChatService.markMessagesAsRead(widget.recipientId);
      }
    });

    // Handle message status updates
    socket.on("messageDelivered", (data) {
      if (mounted) {
        setState(() {
          // Update message status to delivered
          for (var i = _messages.length - 1; i >= 0; i--) {
            if (_messages[i]['isMe'] && _messages[i]['status'] == 'sent') {
              _messages[i]['status'] = 'delivered';
              break;
            }
          }
        });
      }
    });

    socket.on("messageRead", (data) {
      if (mounted) {
        setState(() {
          // Update all delivered messages to read
          for (var i = 0; i < _messages.length; i++) {
            if (_messages[i]['isMe'] &&
                (_messages[i]['status'] == 'delivered' ||
                    _messages[i]['status'] == 'sent')) {
              _messages[i]['status'] = 'read';
            }
          }
        });
      }
    });

    // Handle typing indicators
    socket.on("typing", (data) {
      if (mounted && data['from'] != currentUserId) {
        setState(() {
          _isTyping = true;
        });
      }
    });

    socket.on("stopTyping", (data) {
      if (mounted && data['from'] != currentUserId) {
        setState(() {
          _isTyping = false;
        });
      }
    });

    socket.onError((error) {
      print("Socket error: $error");
    });

    socket.onDisconnect((_) {
      print("Disconnected from socket server");
    });
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping() {
    socket.emit("typing", {
      'from': currentUserId,
      'to': widget.recipientId,
    });
  }

  void _onStopTyping() {
    socket.emit("stopTyping", {
      'from': currentUserId,
      'to': widget.recipientId,
    });
  }

  Widget _buildMessageStatusIcon(String status) {
    switch (status) {
      case 'sending':
        return const SizedBox(
          width: 12,
          height: 12,
          child: CircularProgressIndicator(
            strokeWidth: 1.5,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white70),
          ),
        );
      case 'sent':
        return const Icon(
          Icons.check,
          size: 12,
          color: Colors.white70,
        );
      case 'delivered':
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.white70,
        );
      case 'read':
        return const Icon(
          Icons.done_all,
          size: 12,
          color: Colors.blue,
        );
      default:
        return const Icon(
          Icons.check,
          size: 12,
          color: Colors.white70,
        );
    }
  }

  void _sendMessage() {
    if (_controller.text.trim().isEmpty || currentUserId == null) return;

    String message = _controller.text.trim();
    final now = DateTime.now();
    final timeString = DateFormat('HH:mm').format(now);

    // Add message to UI immediately for sender
    setState(() {
      _messages.add({
        'text': message,
        'isMe': true,
        'time': timeString,
        'senderId': currentUserId,
        'senderName': 'You',
        'senderProfile': currentUserProfile?['profileImage'],
        'status': 'sending', // sending, sent, delivered, read
      });
    });

    // Send message via socket
    socket.emit("sendMessage", {
      'from': currentUserId,
      'to': widget.recipientId,
      'content': message,
    });

    // Update message status to sent after a short delay
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted) {
        setState(() {
          if (_messages.isNotEmpty && _messages.last['status'] == 'sending') {
            _messages.last['status'] = 'sent';
          }
        });
      }
    });

    _controller.clear();
    _onStopTyping(); // Stop typing when message is sent
    _scrollToBottom();
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _scrollController.dispose();
    socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF123b53),
        title: Row(
          children: [
            FutureBuilder<Map<String, dynamic>?>(
              future: UserService.getUserProfileById(widget.recipientId),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const CircleAvatar(
                    backgroundColor: Color(0xFFB6E1F0),
                    child: Icon(Icons.person, color: Colors.white),
                  );
                } else if (snapshot.hasData &&
                    snapshot.data != null &&
                    snapshot.data!['profileImage'] != null) {
                  return CircleAvatar(
                    backgroundImage:
                        NetworkImage(snapshot.data!['profileImage']),
                  );
                } else {
                  return const CircleAvatar(
                    backgroundColor: Color(0xFFB6E1F0),
                    child: Icon(Icons.person, color: Colors.white),
                  );
                }
              },
            ),
            const SizedBox(width: 8),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => UserProfilePage(
                        userId: widget.recipientId,
                        name: widget.name,
                      ),
                    ),
                  );
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.name,
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        //decoration: TextDecoration.underline,
                      ),
                    ),
                    if (_isTyping)
                      const Text("typing...",
                          style: TextStyle(fontSize: 12, color: Colors.white70))
                    else
                      const Text("online",
                          style:
                              TextStyle(fontSize: 12, color: Colors.white70)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF123b53),
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      Expanded(
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.all(12),
                          itemCount: _messages.length,
                          itemBuilder: (context, index) {
                            final msg = _messages[index];
                            return Align(
                              alignment: msg['isMe']
                                  ? Alignment.centerRight
                                  : Alignment.centerLeft,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  // Left side (receiver avatar)
                                  if (!msg['isMe']) ...[
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.grey.shade300,
                                      backgroundImage: msg['senderProfile'] !=
                                              null
                                          ? NetworkImage(msg['senderProfile'])
                                          : null,
                                      child: msg['senderProfile'] == null
                                          ? Text(
                                              msg['senderName'][0]
                                                  .toUpperCase(),
                                              style: const TextStyle(
                                                  color: Color(0xFF123b53),
                                                  fontWeight: FontWeight.bold),
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 6),
                                  ],

                                  // Message bubble
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 10),
                                    margin:
                                        const EdgeInsets.symmetric(vertical: 4),
                                    decoration: BoxDecoration(
                                      color: msg['isMe']
                                          ? const Color.fromARGB(
                                              255, 58, 137, 164)
                                          : const Color(0xFFB6E1F0),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: [
                                        Text(
                                          msg['text'],
                                          style: TextStyle(
                                              color: msg['isMe']
                                                  ? Colors.white
                                                  : Colors.black87),
                                        ),
                                        const SizedBox(height: 4),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            Text(
                                              msg['time'],
                                              style: TextStyle(
                                                  color: msg['isMe']
                                                      ? Colors.white70
                                                      : Colors.black54,
                                                  fontSize: 10),
                                            ),
                                            if (msg['isMe']) ...[
                                              const SizedBox(width: 4),
                                              _buildMessageStatusIcon(
                                                  msg['status'] ?? 'sent'),
                                            ],
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),

                                  // Right side (sender avatar)
                                  if (msg['isMe']) ...[
                                    const SizedBox(width: 6),
                                    CircleAvatar(
                                      radius: 12,
                                      backgroundColor: Colors.grey.shade300,
                                      backgroundImage: msg['senderProfile'] !=
                                              null
                                          ? NetworkImage(msg['senderProfile'])
                                          : null,
                                      child: msg['senderProfile'] == null
                                          ? const Icon(Icons.person,
                                              size: 14,
                                              color: Color(0xFF123b53))
                                          : null,
                                    ),
                                  ],
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                      // Typing indicator
                      if (_isTyping)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          child: Row(
                            children: [
                              const SizedBox(width: 8),
                              Text(
                                '${widget.name} is typing...',
                                style: const TextStyle(
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                    Colors.grey.shade400,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: Color(0xFF123b53),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _controller,
                          style: const TextStyle(color: Colors.white),
                          decoration: InputDecoration(
                            hintText: "Type a message...",
                            hintStyle:
                                TextStyle(color: Colors.white.withOpacity(0.7)),
                            border: InputBorder.none,
                          ),
                          onChanged: (text) {
                            if (text.isNotEmpty) {
                              _onTyping();
                              // Cancel previous timer
                              _typingTimer?.cancel();
                              // Set new timer to stop typing after 2 seconds
                              _typingTimer =
                                  Timer(const Duration(seconds: 2), () {
                                _onStopTyping();
                              });
                            } else {
                              _onStopTyping();
                            }
                          },
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      IconButton(
                          icon: const Icon(Icons.send, color: Colors.white),
                          onPressed: _sendMessage),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}
