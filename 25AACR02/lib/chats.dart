import 'package:flutter/material.dart';
import 'chat.dart';
import 'new_chat_screen.dart';
import 'package:barter_system/profile.dart';
import 'package:barter_system/reviews.dart';
import 'package:barter_system/notification.dart';
import 'package:barter_system/history.dart';
import 'package:barter_system/login.dart';
import 'package:barter_system/services/chat_service.dart';
import 'package:barter_system/services/user_service.dart'; // ✅ Added
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'notification_helper.dart';

class Chats extends StatefulWidget {
  const Chats({super.key});

  @override
  State<Chats> createState() => _ChatsState();
}

class _ChatsState extends State<Chats> with SingleTickerProviderStateMixin {
  List<Map<String, dynamic>> chats = [];
  bool _isLoading = true;
  String? currentUserId;
  late IO.Socket socket;

  // ✅ Added for profile image
  String? _profileImageUrl;

  // Animation for unread badge pulse
  late AnimationController _badgeController;
  late Animation<double> _badgeScale;
  late Animation<double> _badgeGlow;

  Map<String, int> _unreadCounts = {};
  String searchQuery = "";

  @override
  void initState() {
    super.initState();
    NotificationHelper.initialize();

    _badgeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);

    _badgeScale = Tween<double>(begin: 0.85, end: 1.2).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
    );
    _badgeGlow = Tween<double>(begin: 0.0, end: 12.0).animate(
      CurvedAnimation(parent: _badgeController, curve: Curves.easeInOut),
    );

    _initializeChats();
    _fetchProfileImage(); // ✅ same as MyHomePage
  }

  Future<void> _fetchProfileImage() async {
    try {
      final userData = await UserService.getUserProfile(); // ✅ Adjust if needed
      if (userData != null &&
          userData['profileImage'] != null &&
          userData['profileImage'].toString().isNotEmpty) {
        setState(() {
          _profileImageUrl = userData['profileImage'];
        });
      }
    } catch (e) {
      print('Error fetching profile image: $e');
    }
  }

  Future<void> _initializeChats() async {
    currentUserId = await ChatService.getCurrentUserId();
    await _loadChats();

    if (currentUserId != null) {
      _connectToSocket();
    }
  }

  void _connectToSocket() {
    socket = IO.io(
      "https://skillsocket-backend.onrender.com/",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .build(),
    );

    socket.connect();

    socket.onConnect((_) {
      if (currentUserId != null) socket.emit("joinRoom", currentUserId);
    });

    socket.on("receiveMessage", (data) {
      if (mounted) {
        _updateChatWithNewMessage(data);
        if (data['from'] != null && data['from']['_id'] != currentUserId) {
          NotificationHelper.showNotification(
            'New Message from ${data['from']['name'] ?? 'Someone'}',
            data['content'] ?? '',
          );
        }
      }
    });

    socket.onError((error) => print("Socket error: $error"));
    socket.onDisconnect((_) => print("Disconnected from socket server"));
  }

  void _updateChatWithNewMessage(dynamic messageData) {
    setState(() {
      String partnerId;
      final isFromMe = messageData['from']['_id'] == currentUserId;
      if (isFromMe) {
        partnerId = messageData['to']['_id'];
      } else {
        partnerId = messageData['from']['_id'];
      }

      int chatIndex =
          chats.indexWhere((chat) => chat['participant']['_id'] == partnerId);

      if (chatIndex != -1) {
        chats[chatIndex]['lastMessage'] = {
          'content': messageData['content'],
          'createdAt': messageData['createdAt'],
          'from': messageData['from']['_id'],
          'seen': isFromMe ? true : (messageData['seen'] ?? false)
        };
        if (!isFromMe) {
          final current = _unreadCounts[partnerId] ?? 0;
          _unreadCounts[partnerId] = current + 1;
        }
        var updatedChat = chats.removeAt(chatIndex);
        chats.insert(0, updatedChat);
      } else {
        final partner = isFromMe ? messageData['to'] : messageData['from'];
        chats.insert(0, {
          '_id': '${currentUserId}_$partnerId',
          'participant': partner,
          'lastMessage': {
            'content': messageData['content'],
            'createdAt': messageData['createdAt'],
            'from': messageData['from']['_id'],
            'seen': isFromMe ? true : (messageData['seen'] ?? false)
          }
        });
        if (!isFromMe) {
          final current = _unreadCounts[partnerId] ?? 0;
          _unreadCounts[partnerId] = current + 1;
        }
      }
    });
  }

  Future<void> _loadChats() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        ChatService.getUserChats(),
        ChatService.getUnreadCounts(),
      ]);
      final chatData = results[0] as List<Map<String, dynamic>>?;
      final unread = results[1] as Map<String, int>;
      if (chatData != null) {
        setState(() {
          chats = chatData;
          _unreadCounts = unread;
        });
      }
    } catch (e) {
      print('Error loading chats: $e');
    }
    setState(() => _isLoading = false);
  }

  String _formatLastMessageTime(String timestamp) {
    try {
      final messageTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(messageTime);

      if (difference.inDays > 0) {
        return '${difference.inDays}d ago';
      } else if (difference.inHours > 0) {
        return '${difference.inHours}h ago';
      } else if (difference.inMinutes > 0) {
        return '${difference.inMinutes}m ago';
      } else {
        return 'Now';
      }
    } catch (_) {
      return 'Recently';
    }
  }

  @override
  void dispose() {
    _badgeController.dispose();
    if (currentUserId != null) socket.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final filteredChats = chats.where((chat) {
      final participant = chat['participant'];
      final name = participant['name']?.toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase());
    }).toList();

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF123b53),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Center(
                child: Text(
                  'SkillSocket',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold),
                ),
              ),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.white),
              title: Text('History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const History()));
              },
            ),
            Divider(color: Colors.white),
            ListTile(
              leading: Icon(Icons.reviews, color: Colors.white),
              title: Text('Reviews', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (_) => const Reviews()));
              },
            ),
            Divider(color: Colors.white),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('Sign Out', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (_) => const LoginScreen()));
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'SkillSocket',
          style: TextStyle(fontSize: 20, color: Colors.white),
        ),
        backgroundColor: const Color(0xFF123b53),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Notifications()));
              },
              icon: const Icon(Icons.notifications)),
          IconButton(
            onPressed: () {
              Navigator.push(
                  context, MaterialPageRoute(builder: (context) => Profile()));
            },
            icon: _profileImageUrl != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(_profileImageUrl!),
                    radius: 14,
                  )
                : const Icon(Icons.person_rounded),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF123b53)),
            )
          : filteredChats.isEmpty
              ? const Center(
                  child: Text('No chats found', style: TextStyle(fontSize: 16)))
              : RefreshIndicator(
                  onRefresh: _loadChats,
                  child: ListView.separated(
                    itemCount: filteredChats.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final chat = filteredChats[index];
                      final participant = chat['participant'];
                      final lastMessage = chat['lastMessage'];
                      final unread = _unreadCounts[participant['_id']] ?? 0;
                      final isUnseen = unread > 0;

                      return ListTile(
                        leading: Stack(
                          children: [
                            CircleAvatar(
                              backgroundColor: const Color(0xFFB6E1F0),
                              backgroundImage: participant['profileImage'] !=
                                          null &&
                                      participant['profileImage'].isNotEmpty
                                  ? NetworkImage(participant['profileImage'])
                                  : null,
                              child: participant['profileImage'] == null ||
                                      participant['profileImage'].isEmpty
                                  ? Text(
                                      participant['name'][0].toUpperCase(),
                                      style: const TextStyle(
                                          color: Color(0xFF123b53),
                                          fontWeight: FontWeight.bold),
                                    )
                                  : null,
                            ),
                            if (isUnseen)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: ScaleTransition(
                                  scale: _badgeScale,
                                  child: AnimatedBuilder(
                                    animation: _badgeController,
                                    builder: (context, _) {
                                      final glow = _badgeGlow.value;
                                      return Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.green,
                                          shape: BoxShape.circle,
                                          boxShadow: [
                                            BoxShadow(
                                              color:
                                                  Colors.green.withOpacity(0.6),
                                              blurRadius: glow,
                                              spreadRadius: glow / 4,
                                            ),
                                          ],
                                        ),
                                        constraints: const BoxConstraints(
                                            minWidth: 18, minHeight: 18),
                                        child: Center(
                                          child: Text(
                                            unread > 99
                                                ? '99+'
                                                : unread.toString(),
                                            style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 10,
                                                fontWeight: FontWeight.bold),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                          ],
                        ),
                        title: Text(participant['name'],
                            style:
                                const TextStyle(fontWeight: FontWeight.w500)),
                        subtitle: Text(
                          lastMessage['content'],
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isUnseen ? Colors.green : Colors.black,
                            fontWeight:
                                isUnseen ? FontWeight.bold : FontWeight.normal,
                          ),
                        ),
                        trailing: Text(
                          _formatLastMessageTime(lastMessage['createdAt']),
                          style:
                              const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                        onTap: () async {
                          final partnerId = participant['_id'];
                          setState(() {
                            _unreadCounts[partnerId] = 0;
                          });
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => Chat(
                                chatId: chat['_id'],
                                recipientId: participant['_id'],
                                name: participant['name'],
                              ),
                            ),
                          );
                          await ChatService.markMessagesAsRead(partnerId);
                          await _loadChats();
                        },
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => const NewChatScreen()));
        },
        backgroundColor: const Color(0xFF123b53),
        child: const Icon(Icons.add, color: Colors.white),
      ),
    );
  }
}
