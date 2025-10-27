import 'package:flutter/material.dart';
import 'package:barter_system/notification.dart';
import 'package:barter_system/profile.dart';
import 'package:barter_system/reviews.dart';
import 'package:barter_system/history.dart';
import 'package:barter_system/login.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:barter_system/services/user_service.dart'; // ✅ Added for fetching user data

class StudyRoom extends StatefulWidget {
  @override
  _StudyRoomState createState() => _StudyRoomState();
}

class _StudyRoomState extends State<StudyRoom> {
  List<String> roomNames = ["Python", "Flutter", "English"];
  String searchQuery = "";
  String? _profileImageUrl; // ✅ added for profile image

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
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

  Future<void> _launchExternal(Uri uri) async {
    final bool launched = await launchUrl(
      uri,
      mode: LaunchMode.externalApplication,
      webOnlyWindowName: '_blank',
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Google Meet.')),
      );
    }
  }

  Future<void> _startNewMeet() async {
    await _launchExternal(Uri.parse('https://meet.google.com/new'));
  }

  @override
  Widget build(BuildContext context) {
    List<String> filteredRooms = roomNames
        .where((room) => room.toLowerCase().contains(searchQuery.toLowerCase()))
        .toList();

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF123b53),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              child: Row(
                children: [
                  Expanded(
                    child: Align(
                      alignment: Alignment.center,
                      child: Text(
                        'SkillSocket',
                        style: TextStyle(
                            color: Colors.white,
                            fontSize: 39,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: Icon(Icons.history, color: Colors.white),
              title: Text('History', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => History()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
              leading: Icon(Icons.reviews, color: Colors.white),
              title: Text('Reviews', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Reviews()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
              leading: Icon(Icons.logout, color: Colors.white),
              title: Text('Sign Out', style: TextStyle(color: Colors.white)),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => LoginScreen()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
          ],
        ),
      ),
      backgroundColor: Colors.white,
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'SkillSocket',
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.w500),
        ),
        backgroundColor: const Color(0xFF123b53),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Notifications()));
            },
            icon: const Icon(Icons.notifications),
          ),
          IconButton(
            onPressed: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => Profile()));
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
      body: Column(
        children: [
          // Search bar
          Container(
            padding: const EdgeInsets.all(16),
            child: TextField(
              onChanged: (value) {
                setState(() {
                  searchQuery = value;
                });
              },
              decoration: InputDecoration(
                hintText: "Join a room",
                filled: true,
                fillColor: const Color(0xFF66B7D2),
                prefixIcon: const Icon(Icons.search, color: Colors.white),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20),
                hintStyle: const TextStyle(color: Colors.white),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
              ),
              style: const TextStyle(color: Colors.white),
            ),
          ),
          // Room list
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 6)],
                    ),
                    child: const ListTile(
                      leading: Icon(Icons.headphones,
                          size: 40, color: Color(0xFF123b53)),
                      title: Text("StudyBuddy",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text("Make friends to study with"),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: filteredRooms.length,
                      itemBuilder: (context, index) {
                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFB6E1F0),
                            borderRadius: BorderRadius.circular(15),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.grey.shade400,
                                blurRadius: 4,
                                offset: const Offset(2, 2),
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(filteredRooms[index],
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black)),
                              ElevatedButton(
                                onPressed: () async {
                                  await _startNewMeet();
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF123b53),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(20)),
                                ),
                                child: const Text("Join",
                                    style: TextStyle(color: Colors.white)),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          _showCreateRoomDialog();
        },
        label: const Text("Create", style: TextStyle(color: Colors.white)),
        icon: const Icon(Icons.add, color: Colors.white),
        backgroundColor: const Color(0xFF123b53),
      ),
    );
  }

  void _showCreateRoomDialog() {
    TextEditingController _controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text("Create Room"),
          content: TextField(
            controller: _controller,
            decoration: const InputDecoration(hintText: "Enter room name"),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                if (_controller.text.trim().isNotEmpty) {
                  setState(() {
                    roomNames.add(_controller.text.trim());
                  });
                  Navigator.pop(context);
                  await _startNewMeet();
                }
              },
              child: const Text("Create"),
            ),
          ],
        );
      },
    );
  }
}
