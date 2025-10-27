import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class ChatbotScreen extends StatefulWidget {
  @override
  State<ChatbotScreen> createState() => _ChatbotScreenState();
}

class _ChatbotScreenState extends State<ChatbotScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, dynamic>> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    // Add initial bot welcome message
    _messages.add({
      'text':
          'Hello! I\'m your AI study assistant. How can I help you today?\n\n• Ask me about study topics\n• Get help with homework\n• Learn about new skills\n• Find study strategies',
      'isBot': true,
      'timestamp': DateTime.now(),
    });
  }

  // Fallback responses for when backend is not available
  String _getFallbackResponse(String message) {
    final lowerMessage = message.toLowerCase();

    if (lowerMessage.contains('hello') ||
        lowerMessage.contains('hi') ||
        lowerMessage.contains('hey')) {
      return 'Hello! I\'m here to help you with your studies. What would you like to learn about today?';
    } else if (lowerMessage.contains('help') ||
        lowerMessage.contains('assistance')) {
      return 'I can help you with:\n• Study strategies and techniques\n• Subject-specific questions\n• Skill development advice\n• Learning resources\n\nWhat specific area would you like help with?';
    } else if (lowerMessage.contains('study') ||
        lowerMessage.contains('learn')) {
      return 'Great! Learning is a wonderful journey. Here are some effective study tips:\n\n• Use active recall techniques\n• Practice spaced repetition\n• Take regular breaks (Pomodoro technique)\n• Create mind maps for complex topics\n\nWhat subject are you studying?';
    } else if (lowerMessage.contains('programming') ||
        lowerMessage.contains('coding') ||
        lowerMessage.contains('flutter') ||
        lowerMessage.contains('dart')) {
      return 'Programming is an excellent skill! For Flutter and Dart:\n\n• Start with basic Dart syntax\n• Practice building simple widgets\n• Learn state management\n• Build projects to solidify concepts\n\nWould you like resources for any specific programming topic?';
    } else if (lowerMessage.contains('math') ||
        lowerMessage.contains('mathematics')) {
      return 'Mathematics builds logical thinking! Some effective strategies:\n\n• Practice problems daily\n• Understand concepts before memorizing formulas\n• Use visual aids and diagrams\n• Work through examples step by step\n\nWhat math topic are you working on?';
    } else if (lowerMessage.contains('time') ||
        lowerMessage.contains('schedule') ||
        lowerMessage.contains('manage')) {
      return 'Time management is crucial for effective learning:\n\n• Create a study schedule\n• Prioritize important topics\n• Use time-blocking techniques\n• Set realistic daily goals\n• Take regular breaks\n\nWould you like help creating a study plan?';
    } else {
      return 'That\'s an interesting question! While I\'d love to provide a detailed response, I recommend:\n\n• Breaking down complex topics into smaller parts\n• Using multiple learning resources\n• Practicing regularly\n• Seeking help from teachers or peers when needed\n\nCould you be more specific about what you\'d like to learn?';
    }
  }

  Future<void> _sendMessageToBot(String message) async {
    setState(() {
      _isLoading = true;
    });

    try {
      // First try the deployed MCP Gateway
      print('Sending message to MCP Gateway: $message');
      try {
        final mcpResponse = await http
            .post(
              Uri.parse('https://skill-socket-agents.onrender.com/mcp/invoke'),
              headers: {
                'Content-Type': 'application/json',
              },
              body: jsonEncode({
                'query': message,
              }),
            )
            .timeout(Duration(seconds: 10));

        print('MCP Gateway response status code: ${mcpResponse.statusCode}');
        print('MCP Gateway response body: ${mcpResponse.body}');

        if (mcpResponse.statusCode == 200) {
          final responseData = jsonDecode(mcpResponse.body);
          print('Parsed MCP Gateway response data: $responseData');

          String botReply;

          // Handle different response formats from MCP Gateway
          if (responseData['response'] != null) {
            // Direct response format
            botReply = responseData['response'];
          } else if (responseData['result'] != null) {
            // Agent-based response format
            final result = responseData['result'];

            if (result is Map) {
              // Check for different agent response formats
              if (result['roadmap'] != null) {
                // Roadmap agent response
                botReply = result['roadmap'];
              } else if (result['answer'] != null) {
                // Perplexity agent response
                botReply = result['answer'];

                // Add sources if available
                if (result['sources'] != null && result['sources'] is List) {
                  final sources = result['sources'] as List;
                  if (sources.isNotEmpty) {
                    botReply += '\n\n📚 **Sources:**\n';
                    for (int i = 0; i < sources.length && i < 3; i++) {
                      final source = sources[i];
                      if (source['title'] != null) {
                        botReply += '• ${source['title']}\n';
                      }
                    }
                  }
                }
              } else if (result['response'] != null) {
                // SkillMatch agent response - use the formatted response
                botReply = result['response'];

                // Add additional match details if available
                if (result['matches'] != null && result['matches'] is List) {
                  final matches = result['matches'] as List;
                  if (matches.isNotEmpty) {
                    botReply += '\n\n🎯 **Match Details:**\n';
                    for (var match in matches) {
                      if (match is Map) {
                        botReply +=
                            '• **${match['name'] ?? match['email'] ?? 'User'}**\n';
                        if (match['skillsOffered'] != null &&
                            match['skillsOffered'] is List) {
                          botReply +=
                              '  💡 Offers: ${(match['skillsOffered'] as List).join(', ')}\n';
                        }
                        if (match['skillsRequired'] != null &&
                            match['skillsRequired'] is List) {
                          botReply +=
                              '  🎯 Needs: ${(match['skillsRequired'] as List).join(', ')}\n';
                        }
                        botReply += '\n';
                      }
                    }
                  }
                }
              } else if (result['matches'] != null) {
                // Handle SkillMatch agent response with matches only
                final matches = result['matches'];
                if (matches is List && matches.isNotEmpty) {
                  botReply =
                      '🎯 **Skill Match Results:**\n\nI found ${matches.length} user(s) with complementary skills:\n\n';
                  for (var match in matches) {
                    if (match is Map) {
                      botReply +=
                          '� **${match['name'] ?? match['email'] ?? 'User'}**\n';
                      if (match['skillsOffered'] != null &&
                          match['skillsOffered'] is List) {
                        botReply +=
                            '💡 Offers: ${(match['skillsOffered'] as List).join(', ')}\n';
                      }
                      if (match['skillsRequired'] != null &&
                          match['skillsRequired'] is List) {
                        botReply +=
                            '🎯 Needs: ${(match['skillsRequired'] as List).join(', ')}\n';
                      }
                      botReply += '\n';
                    }
                  }
                } else {
                  botReply =
                      '🔍 No users found with complementary skills at the moment. Try expanding your skill requirements or check back later!';
                }
              } else if (result['error'] != null) {
                // Handle error responses from agents
                botReply =
                    '❌ ${result['error']}\n\nPlease try rephrasing your request or contact support if the issue persists.';
              } else {
                // Generic result object - convert to string
                botReply = result.toString();
              }
            } else {
              // Result is a simple value
              botReply = result.toString();
            }
          } else {
            // Fallback for unexpected format
            botReply = responseData.toString();
          }

          if (botReply.isNotEmpty) {
            setState(() {
              _messages.add({
                'text': botReply,
                'isBot': true,
                'timestamp': DateTime.now(),
              });
              _isLoading = false;
            });
            return; // Successfully got response from MCP Gateway
          }
        }
        // If we reach here, MCP Gateway didn't return a valid response
        throw Exception('MCP Gateway response not valid');
      } catch (mcpError) {
        // MCP Gateway failed, fall back to the original Gemini endpoint
        print('MCP Gateway error, falling back to Gemini: $mcpError');

        final response = await http.post(
          Uri.parse('https://skillsocket-backend.onrender.com/api/chat'),
          headers: {
            'Content-Type': 'application/json',
          },
          body: jsonEncode({
            'message': message,
          }),
        );

        print('Fallback response status code: ${response.statusCode}');
        print('Fallback response body: ${response.body}');

        if (response.statusCode == 200) {
          final responseData = jsonDecode(response.body);
          print('Parsed fallback response data: $responseData');

          String botReply;
          if (responseData['success'] == true &&
              responseData['reply'] != null) {
            botReply = responseData['reply'];
          } else if (responseData['reply'] != null) {
            botReply = responseData['reply'];
          } else {
            botReply = 'Sorry, I received an empty response. Please try again.';
          }

          setState(() {
            _messages.add({
              'text': botReply,
              'isBot': true,
              'timestamp': DateTime.now(),
            });
            _isLoading = false;
          });
        } else {
          final errorData = jsonDecode(response.body);
          print('Error response: $errorData');
          setState(() {
            _messages.add({
              'text': 'Sorry, I encountered an error. Please try again later.',
              'isBot': true,
              'timestamp': DateTime.now(),
            });
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error sending message: $e');
      setState(() {
        _messages.add({
          'text': 'Sorry, I encountered an error. Please try again.',
          'isBot': true,
          'timestamp': DateTime.now(),
        });
        _isLoading = false;
      });
    }
  }

  void handleSend() {
    final text = _controller.text.trim();
    if (text.isNotEmpty) {
      setState(() {
        _messages.add({
          'text': text,
          'isBot': false,
          'timestamp': DateTime.now(),
        });
      });
      _controller.clear();

      // Send message to backend AI
      _sendMessageToBot(text);
    }
  }

  void _sendPredefinedMessage(String message) {
    setState(() {
      _messages.add({
        'text': message,
        'isBot': false,
        'timestamp': DateTime.now(),
      });
    });
    _sendMessageToBot(message);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Color(0xFF123b53),
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
          const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              AssetImage('assets/new-chatbot-skyblue.png'),
                        ),
            SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Study Assistant',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Online',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Chat Area
          Expanded(
            child: ListView.builder(
              reverse: true,
              padding: EdgeInsets.all(16),
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                // Show loading indicator at the top (first item when reversed)
                if (_isLoading && index == 0) {
                  return Container(
                    margin: EdgeInsets.symmetric(vertical: 8),
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(0xFF56195B).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFF123b53),
                            ),
                          ),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'AI is thinking...',
                          style: TextStyle(
                            color: Color(0xFF123b53),
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Adjust index for actual messages
                final messageIndex = _isLoading ? index - 1 : index;
                final reversedIndex = _messages.length - 1 - messageIndex;
                final message = _messages[reversedIndex];

                return Container(
                  margin: EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: message['isBot']
                        ? MainAxisAlignment.start
                        : MainAxisAlignment.end,
                    children: [
                      if (message['isBot']) ...[
                        const CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.transparent,
                          backgroundImage:
                              AssetImage('assets/new-chatbot-skyblue.png'),
                        ),
                        SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: MediaQuery.of(context).size.width * 0.75,
                          ),
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: message['isBot']
                                ? Color.fromARGB(255, 141, 204, 226)
                                    .withOpacity(0.1)
                                : Color.fromARGB(255, 141, 204, 226),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            message['text'],
                            style: TextStyle(
                              color: message['isBot']
                                  ? Colors.black87
                                  : const Color.fromARGB(255, 57, 51, 51),
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ),
                      if (!message['isBot']) ...[
                        SizedBox(width: 8),
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: Color(0xFF123b53),
                          child:
                              Icon(Icons.person, color: Colors.white, size: 16),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ),

          // Quick action buttons
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              children: [
                _buildOptionButton(
                  label: "What are trending skills in tech?",
                  onTap: () {
                    _sendPredefinedMessage(
                        "What are the trending skills in technology?");
                  },
                ),
                SizedBox(height: 8),
                _buildOptionButton(
                  label: "Suggest me a skill to learn",
                  onTap: () {
                    _sendPredefinedMessage(
                        "Can you suggest a skill I should learn based on current market trends?");
                  },
                ),
              ],
            ),
          ),

          // Input Area
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey[300]!),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: TextField(
                      controller: _controller,
                      decoration: InputDecoration(
                        hintText:
                            "Type: 'I offer Flutter, need Java' or ask anything...",
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onSubmitted: (_) => handleSend(),
                    ),
                  ),
                ),
                SizedBox(width: 8),
                GestureDetector(
                  onTap: _isLoading ? null : handleSend,
                  child: Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _isLoading ? Colors.grey[400] : Color(0xFF123b53),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.send,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionButton({
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: Color(0xFF123b53).withOpacity(0.1),
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: Color(0xFF56195B).withOpacity(0.3)),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF56195B),
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
