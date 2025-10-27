import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:swipable_stack/swipable_stack.dart';
import 'package:barter_system/services/connection_service.dart';
import 'package:barter_system/services/user_service.dart';
// import 'package:shared_preferences/shared_preferences.dart'; // For future local storage

class ProfileEditScreen extends StatefulWidget {
  final String requiredSkill;
  final String offeredSkill;

  const ProfileEditScreen({
    super.key,
    required this.requiredSkill,
    required this.offeredSkill,
  });

  @override
  State<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends State<ProfileEditScreen> {
  final SwipableStackController _controller = SwipableStackController();
  bool isExpanded = true;
  Map<int, bool> expandedProfiles = {};
  List<Map<String, dynamic>> profiles = [];
  bool isLoading = true;
  bool _isSending = false; // debounce flag to prevent multiple sends
  final Set<String> _sentRequests =
      {}; // track already requested userIds in this session
  String? _currentUserId; // store current user's ID to prevent self-requests

  @override
  void initState() {
    super.initState();
    _loadCurrentUser(); // load current user ID first
    fetchMatchingProfiles();
    _loadAlreadySentRequests(); // preload sent requests to prevent duplicates across sessions
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh sent requests when returning to this screen
    // This allows sending new requests after rejections
    _loadAlreadySentRequests();
  }

  // Load current user ID to prevent self-requests and self-profile display
  Future<void> _loadCurrentUser() async {
    try {
      final userProfile = await UserService.getUserProfile();
      if (userProfile != null) {
        setState(() {
          _currentUserId = userProfile['_id'] ?? userProfile['id'];
        });
        print('Current user ID loaded: $_currentUserId');
      }
    } catch (e) {
      print('Error loading current user: $e');
    }
  }

  Future<void> fetchMatchingProfiles() async {
    setState(() => isLoading = true);
  final url = Uri.parse(
  'https://skillsocket-backend.onrender.com/api/users/match?required=${widget.requiredSkill}&offered=${widget.offeredSkill}');

    try {
      final response = await http.get(url);
      print(
          '🔍 API Response: Status=${response.statusCode}, Body=${response.body}');

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        print('📊 Found ${data.length} matching users from backend');

        if (data.isNotEmpty) {
          print('✅ Showing real matching users');
          setState(() {
            profiles = data
                .where((u) {
                  final userId = u["_id"] ?? u["id"] ?? "";
                  // Filter out current user's profile
                  return _currentUserId == null ||
                      userId.toString() != _currentUserId;
                })
                .map((u) => {
                      "id": u["_id"] ?? "", // Add user ID
                      "name": u["name"] ?? "",
                      "profileImage": u["profileImage"],
                      "skillsOffered":
                          (u["skillsOffered"] as List?)?.join(', ') ?? "",
                      "skillsRequired":
                          (u["skillsRequired"] as List?)?.join(', ') ?? "",
                      "education": u["education"] ?? "",
                      "location": u["location"] ?? "",
                      "profession": u["profession"] ?? "",
                      "ratingsValue": u["ratingsValue"] ?? 4.5,
                      "reviews": u["reviews"] ??
                          _staticReviews(), // Use real reviews from backend
                    })
                .toList();
            isLoading = false;
          });
        } else {
          // Show random static profiles if no match found
          print('❌ No matches found - showing random static profiles');
          setState(() {
            profiles = _randomStaticProfiles();
            isLoading = false;
          });

          // Show message about no real matches found
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "No real users found with ${widget.requiredSkill} ↔ ${widget.offeredSkill}. Showing sample profiles - try different skills!"),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 4),
                action: SnackBarAction(
                  label: 'Change Skills',
                  textColor: Colors.white,
                  onPressed: () => Navigator.pop(context),
                ),
              ),
            );
          });
        }
      } else {
        print('⚠️ API error - showing random static profiles');
        setState(() {
          profiles = _randomStaticProfiles();
          isLoading = false;
        });

        // Show message about API error
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Could not connect to find real matches. Showing sample profiles for ${widget.requiredSkill} ↔ ${widget.offeredSkill}."),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
              action: SnackBarAction(
                label: 'Retry',
                textColor: Colors.white,
                onPressed: () => fetchMatchingProfiles(),
              ),
            ),
          );
        });
      }
    } catch (e) {
      print('❗ Exception in fetchMatchingProfiles: $e');
      setState(() {
        profiles = _randomStaticProfiles();
        isLoading = false;
      });

      // Show message about connection error
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                "Connection error. Showing sample profiles for ${widget.requiredSkill} ↔ ${widget.offeredSkill}."),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'Retry',
              textColor: Colors.white,
              onPressed: () => fetchMatchingProfiles(),
            ),
          ),
        );
      });
    }
  }

  List<Map<String, dynamic>> _staticReviews() {
    return [
      {
        "reviewer": "Demo Reviewer",
        "rating": 5.0,
        "title": "Great collaborator",
        "date": "21 Sep 2025",
        "comment": "Very helpful and skilled."
      }
    ];
  }

  List<String> _getSkillsList(dynamic skills) {
    if (skills == null) return [];
    if (skills is List) {
      return skills.map((e) => e.toString()).toList();
    }
    if (skills is String) {
      return skills
          .split(',')
          .map((e) => e.trim())
          .where((e) => e.isNotEmpty)
          .toList();
    }
    return [];
  }

  List<Map<String, dynamic>> _randomStaticProfiles() {
    // Generate completely random demo profiles - NOT from database
    // These are synthetic users to show when no real matches exist
    final demoNames = [
      "Alex Chen",
      "Maya Patel",
      "Jordan Lee",
      "Priya Singh",
      "Lucas Brown",
      "Aria Sharma",
      "Dev Kumar",
      "Sofia Rodriguez",
      "Ryan O'Connor",
      "Zara Ahmed",
      "Kai Nakamura",
      "Elena Petrov",
      "Marcus Johnson",
      "Ava Thompson",
      "Leo Zhang",
      "Ananya Gupta",
      "Ethan Taylor",
      "Ravi Mehta",
      "Isabella Garcia",
      "Arjun Patel",
      "Chloe Wilson",
      "Rohan Sharma",
      "Emma Davis",
      "Vikram Singh",
      "Olivia Brown",
      "Karan Verma",
      "Sophia Martinez",
      "Aditya Kumar",
      "Grace Lee",
      "Nikhil Jain"
    ];

    final demoLocations = [
      "Mumbai, India",
      "New York, USA",
      "London, UK",
      "Toronto, Canada",
      "Sydney, Australia",
      "Berlin, Germany",
      "Tokyo, Japan",
      "Paris, France",
      "Singapore",
      "Dubai, UAE",
      "São Paulo, Brazil",
      "Stockholm, Sweden",
      "Amsterdam, Netherlands",
      "Barcelona, Spain",
      "Melbourne, Australia",
      "Vancouver, Canada",
      "Seoul, South Korea",
      "Tel Aviv, Israel",
      "Zurich, Switzerland",
      "Dublin, Ireland",
      "Vienna, Austria",
      "Copenhagen, Denmark",
      "Helsinki, Finland",
      "Oslo, Norway",
      "Prague, Czech Republic",
      "Warsaw, Poland",
      "Budapest, Hungary",
      "Lisbon, Portugal",
      "Athens, Greece",
      "Istanbul, Turkey"
    ];

    final demoEducations = [
      "B.Tech Computer Science",
      "M.Sc Data Science",
      "B.E Software Engineering",
      "MBA Technology",
      "B.Sc Information Systems",
      "M.Tech AI/ML",
      "B.Des UI/UX",
      "M.Sc Cybersecurity",
      "B.Com + Digital Marketing",
      "Ph.D Computer Science",
      "B.Sc Mathematics",
      "M.A Psychology",
      "B.Tech Information Technology",
      "M.S Computer Science",
      "B.Sc Software Engineering",
      "M.Tech Data Science",
      "B.Des Product Design",
      "M.Sc Artificial Intelligence",
      "B.E Electronics & Communication",
      "MBA Business Analytics",
      "B.Sc Applied Mathematics",
      "M.A Digital Media",
      "B.Tech Mechanical Engineering",
      "M.Sc Machine Learning",
      "B.Sc Statistics",
      "M.Tech Software Engineering",
      "B.A Computer Applications",
      "M.Sc Information Technology",
      "B.Tech Civil Engineering",
      "MBA Marketing"
    ];

    final demoProfessions = [
      "Software Developer",
      "Data Analyst",
      "ML Engineer",
      "Product Manager",
      "Full Stack Developer",
      "UI/UX Designer",
      "DevOps Engineer",
      "Cybersecurity Analyst",
      "Digital Marketing Specialist",
      "Research Scientist",
      "Technical Writer",
      "Business Analyst",
      "Game Developer",
      "Mobile App Developer",
      "Frontend Developer",
      "Backend Developer",
      "Data Scientist",
      "Cloud Architect",
      "AI Research Engineer",
      "Quality Assurance Engineer",
      "System Administrator",
      "Database Administrator",
      "Network Engineer",
      "Blockchain Developer",
      "IoT Developer",
      "AR/VR Developer",
      "Site Reliability Engineer",
      "Solutions Architect",
      "Engineering Manager",
      "Scrum Master",
      "Product Owner",
      "Growth Hacker",
      "Content Strategist",
      "SEO Specialist",
      "Social Media Manager",
      "Brand Manager"
    ];

    final demoComments = [
      "Great collaboration skills and very patient teacher!",
      "Helped me understand complex concepts with ease.",
      "Professional approach and excellent communication.",
      "Would love to work together on future projects.",
      "Knowledgeable and always willing to share expertise.",
      "Perfect match for skill exchange, highly recommended!",
      "Clear explanations and supportive learning environment.",
      "Inspiring mentor with practical industry experience.",
      "Amazing problem-solving skills and creative thinking.",
      "Very responsive and delivers quality work on time.",
      "Excellent technical knowledge and leadership qualities.",
      "Great at breaking down complex topics into simple steps.",
      "Fantastic team player with strong analytical skills.",
      "Outstanding communication and project management abilities.",
      "Innovative approach to challenges and solutions.",
      "Highly skilled professional with deep industry insights.",
      "Exceptional mentor who guides with patience and expertise.",
      "Reliable collaborator with impressive technical depth."
    ];

    List<Map<String, dynamic>> randomProfiles = [];

    // Shuffle lists to get truly random combinations
    demoNames.shuffle();
    demoLocations.shuffle();
    demoEducations.shuffle();
    demoProfessions.shuffle();
    demoComments.shuffle();

    // Generate 8-12 random profiles with complementary skills for more variety
    final numProfiles = 8 + (DateTime.now().millisecond % 5); // 8-12 profiles

    for (int i = 0; i < numProfiles; i++) {
      // More randomized selection from larger pools
      final nameIndex =
          (DateTime.now().millisecondsSinceEpoch + i) % demoNames.length;
      final locationIndex =
          (DateTime.now().microsecond + i * 7) % demoLocations.length;
      final educationIndex =
          (DateTime.now().millisecond + i * 13) % demoEducations.length;
      final professionIndex =
          (DateTime.now().microsecond + i * 11) % demoProfessions.length;

      randomProfiles.add({
        "id":
            "random_demo_${DateTime.now().millisecondsSinceEpoch}_${i}_${(demoNames[nameIndex].hashCode + i).abs()}",
        "name": demoNames[nameIndex],
        "profileImage": null,
        "skillsOffered": widget.requiredSkill, // Exactly what user needs
        "skillsRequired": widget.offeredSkill, // Exactly what user offers
        "education": demoEducations[educationIndex],
        "location": demoLocations[locationIndex],
        "profession": demoProfessions[professionIndex],
        "ratingsValue": 3.5 +
            (i * 0.25) +
            (DateTime.now().millisecond % 15) * 0.04, // More varied ratings
        "reviews": [
          {
            "reviewer": "Community Member ${(nameIndex + i + 1) % 20 + 1}",
            "rating": 3.8 + (i * 0.2) + (DateTime.now().millisecond % 6) * 0.1,
            "title": "Potential Skill Exchange",
            "date":
                "${DateTime.now().subtract(Duration(days: i + 1)).day} ${_getMonthName(DateTime.now().month)} 2024",
            "comment": demoComments[(nameIndex + i) % demoComments.length]
          },
          {
            "reviewer": "SkillSocket User ${(educationIndex + i) % 15 + 1}",
            "rating": 4.0 + (i * 0.15) + (DateTime.now().microsecond % 4) * 0.1,
            "title": "Great Learning Partner",
            "date":
                "${DateTime.now().subtract(Duration(days: (i + 1) * 2)).day} ${_getMonthName(DateTime.now().month)} 2024",
            "comment": "Perfect complementary skills for knowledge exchange!"
          },
          {
            "reviewer": "Peer Reviewer",
            "rating": 4.3 + (i * 0.1),
            "title": "Excellent Mentor",
            "date":
                "${DateTime.now().subtract(Duration(days: (i + 1) * 3)).day} ${_getMonthName(DateTime.now().month)} 2024",
            "comment":
                demoComments[(professionIndex + i + 5) % demoComments.length]
          }
        ],
      });
    }

    return randomProfiles;
  }

  // Helper method to get month name
  String _getMonthName(int month) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return months[month - 1];
  }

  // Check if a profile is a demo user
  bool _isDemoUser(Map<String, dynamic> profile) {
    final id = profile["id"]?.toString() ?? "";
    return id.startsWith("random_demo_") || id.startsWith("demo_");
  }

  // Store demo connection request locally (for potential future use in notifications)
  Future<void> _storeDemoConnectionRequest(Map<String, dynamic> profile) async {
    try {
      // This could be expanded to store in SharedPreferences or local database
      // For now, just log the demo connection request
      print(
          'Demo connection request sent to: ${profile["name"]} (${profile["id"]})');
      print('Skills offered by demo user: ${profile["skillsOffered"]}');
      print('Skills required by demo user: ${profile["skillsRequired"]}');

      // Future enhancement: Store in local storage for demo notifications
      // final prefs = await SharedPreferences.getInstance();
      // List<String> demoRequests = prefs.getStringList('demo_connection_requests') ?? [];
      // demoRequests.add(jsonEncode({
      //   'id': profile['id'],
      //   'name': profile['name'],
      //   'timestamp': DateTime.now().toIso8601String(),
      //   'message': 'Demo connection request sent'
      // }));
      // await prefs.setStringList('demo_connection_requests', demoRequests);
    } catch (e) {
      print('Error storing demo connection request: $e');
    }
  }

  // Preload already sent requests from server to prevent duplicates across sessions
  Future<void> _loadAlreadySentRequests() async {
    try {
      final sent = await ConnectionService.getSentRequests();
      if (sent != null) {
        setState(() {
          for (final r in sent) {
            final to = (r['to'] is Map)
                ? (r['to']['_id'] ?? r['to']['id'])
                : (r['toUserId'] ?? r['to']);
            final status = r['status'] ?? 'pending';

            // Only track pending requests (Instagram-like behavior)
            // If rejected, allow sending new request
            if (to != null && status == 'pending') {
              _sentRequests.add(to.toString());
            }
          }
        });
      }
    } catch (e) {
      print('Error preloading sent requests: $e');
    }
  }

  // Send connection request
  Future<void> _sendConnectionRequest(Map<String, dynamic> profile) async {
    final String toId = (profile["id"] ?? "").toString();
    if (toId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text("Invalid user"), backgroundColor: Colors.red),
      );
      return;
    }

    // Handle demo users with simulated success (no backend call)
    if (_isDemoUser(profile)) {
      // Simulate successful connection request for demo users
      _sentRequests.add(toId);

      // Store demo connection request locally (could be used for local notifications)
      _storeDemoConnectionRequest(profile);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Connection request sent to ${profile["name"]}!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
      }
      return;
    }

    // Prevent sending requests to self (safety check)
    if (_currentUserId != null && toId == _currentUserId) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You cannot send a connection request to yourself"),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 2),
        ),
      );
      return;
    }

    if (_isSending) {
      return; // prevent overlapping requests
    }

    if (_sentRequests.contains(toId)) {
      // Already requested in this session
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              "Connection request already sent to ${profile["name"]}. Please wait for their response."),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 3),
        ),
      );
      return;
    }

    setState(() {
      _isSending = true;
    });
    try {
      final result = await ConnectionService.sendConnectionRequest(
        toUserId: toId,
        message:
            "Hi ${profile["name"]}, I'd like to connect and exchange skills: ${widget.requiredSkill} for ${widget.offeredSkill}!",
      );

      if (result != null && result['success'] == true) {
        // Success case
        _sentRequests.add(toId);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Connection request sent to ${profile["name"]}!"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      } else if (result != null && result['success'] == false) {
        // Handle specific error cases from backend
        final errorMessage = result['message'] ?? 'Failed to send request';

        if (errorMessage.toLowerCase().contains('already sent')) {
          // Connection request already sent
          _sentRequests.add(toId);
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                    "Connection request already sent to ${profile["name"]}. Please wait for their response."),
                backgroundColor: Colors.orange,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else if (errorMessage.toLowerCase().contains('already connected')) {
          // Already connected with this user
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text("You are already connected with ${profile["name"]}"),
                backgroundColor: Colors.blue,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        } else {
          // Other errors (network, validation, etc.)
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(errorMessage),
                backgroundColor: Colors.red,
                duration: const Duration(seconds: 3),
              ),
            );
          }
        }
      } else {
        // Null result - unexpected error
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Unexpected error sending request to ${profile["name"]}"),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('Error sending connection request: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content:
                Text("Network error sending request to ${profile["name"]}"),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSending = false;
        });
      }
    }
  }

  Widget _buildProfileCard(Map<String, dynamic> profile, int index) {
    return SizedBox.expand(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                radius: 60,
                backgroundColor: const Color(0xFFB6E1F0),
                backgroundImage: profile["profileImage"] != null &&
                        profile["profileImage"].toString().isNotEmpty
                    ? NetworkImage(profile["profileImage"])
                    : null,
                child: profile["profileImage"] == null ||
                        profile["profileImage"].toString().isEmpty
                    ? const Icon(Icons.person, size: 60, color: Colors.white)
                    : null,
              ),
              const SizedBox(height: 16),

              // Demo badge for sample profiles
              if (_isDemoUser(profile))
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    "SAMPLE PROFILE",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

              Text(
                profile["name"] ?? "Unknown",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                profile["profession"] ?? "",
                style: const TextStyle(fontSize: 18, color: Colors.black54),
              ),
              const SizedBox(height: 16),

              // Skills Required
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Skills Required",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123b53),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _getSkillsList(profile["skillsRequired"])
                    .map((skill) => Chip(label: Text(skill.trim())))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // Skills Offered
              const Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Skills Offered",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF123b53),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 10,
                children: _getSkillsList(profile["skillsOffered"])
                    .map((skill) => Chip(label: Text(skill.trim())))
                    .toList(),
              ),
              const SizedBox(height: 24),

              // 🌍 Location
              Row(
                children: [
                  const Icon(Icons.location_on, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(profile["location"] ?? ""),
                ],
              ),
              const SizedBox(height: 12),

              // 🎓 Education
              Row(
                children: [
                  const Icon(Icons.language, color: Colors.grey),
                  const SizedBox(width: 6),
                  Text(profile["education"] ?? ""),
                ],
              ),
              const SizedBox(height: 20),

              // 🔽 Reviews header row
              Row(
                children: [
                  const Text(
                    "Reviews",
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF123b53),
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Rating number
                  Text(
                    (profile["ratingsValue"] ?? 0).toString(),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 6),

                  // Stars (with half star logic)
                  Row(
                    children: List.generate(5, (starIndex) {
                      double rating = (profile["ratingsValue"] ?? 0).toDouble();
                      if (starIndex < rating.floor()) {
                        return const Icon(Icons.star,
                            color: Colors.amber, size: 20);
                      } else if (starIndex < rating && rating % 1 != 0) {
                        return const Icon(Icons.star_half,
                            color: Colors.amber, size: 20);
                      } else {
                        return const Icon(Icons.star_border,
                            color: Colors.amber, size: 20);
                      }
                    }),
                  ),

                  const Spacer(),

                  // Expand/Collapse button
                  IconButton(
                    icon: Icon(
                      expandedProfiles[index] == true
                          ? Icons.keyboard_arrow_up
                          : Icons.keyboard_arrow_down,
                      color: Colors.black54,
                      size: 28,
                    ),
                    onPressed: () {
                      setState(() {
                        expandedProfiles[index] =
                            !(expandedProfiles[index] ?? false);
                      });
                    },
                  ),
                ],
              ),

              // ✅ Show reviews if expanded
              if (expandedProfiles[index] == true) ...[
                const SizedBox(height: 12),
                Column(
                  children: (profile["reviews"] as List<dynamic>).map((review) {
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Reviewer name + rating
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                review["reviewer"],
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                              Row(
                                children: List.generate(5, (starIndex) {
                                  double rating =
                                      (review["rating"] ?? 0).toDouble();
                                  if (starIndex < rating.floor()) {
                                    return const Icon(Icons.star,
                                        color: Colors.amber, size: 18);
                                  } else if (starIndex < rating &&
                                      rating % 1 != 0) {
                                    return const Icon(Icons.star_half,
                                        color: Colors.amber, size: 18);
                                  } else {
                                    return const Icon(Icons.star_border,
                                        color: Colors.amber, size: 18);
                                  }
                                }),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review["title"],
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            review["date"],
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            review["comment"],
                            style: const TextStyle(fontSize: 14),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const buttonSpacing = 70;
    final screenWidth = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: const Color(0xFFEFEAEA),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Container(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFFB6E1F0),
                    Color(0xFF66B7D2),
                    Color(0xFF123b53)
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              child: SafeArea(
                child: Stack(
                  children: [
                    Center(
                      child: SizedBox(
                        height: MediaQuery.of(context).size.height * 0.8,
                        width: MediaQuery.of(context).size.width * 0.95,
                        child: SwipableStack(
                          controller: _controller,
                          detectableSwipeDirections: const {
                            SwipeDirection.left,
                            SwipeDirection.right
                          },
                          builder: (context, properties) {
                            if (profiles.isEmpty) {
                              return const Center(
                                  child: Text('No profiles found'));
                            }
                            final profile =
                                profiles[properties.index % profiles.length];
                            return _buildProfileCard(profile, properties.index);
                          },
                          onSwipeCompleted: (index, direction) {
                            // Swiping is purely for navigation/browsing
                            // No messages or actions - just silent navigation
                            // Users must explicitly click buttons to send requests
                          },
                        ),
                      ),
                    ),

                    // Reject button - just move to next profile silently
                    Positioned(
                      bottom: 5,
                      left: (screenWidth / 2) - buttonSpacing - 28,
                      child: FloatingActionButton(
                        heroTag: 'reject',
                        backgroundColor: Colors.redAccent,
                        onPressed: () => _controller.next(
                            swipeDirection: SwipeDirection.left),
                        child: const Icon(Icons.close,
                            size: 30, color: Colors.white),
                      ),
                    ),

                    // Accept button
                    Positioned(
                      bottom: 5,
                      left: (screenWidth / 2) + buttonSpacing - 28,
                      child: FloatingActionButton(
                        heroTag: 'accept',
                        backgroundColor: Colors.green,
                        onPressed: _isSending
                            ? null
                            : () {
                                if (profiles.isNotEmpty) {
                                  final currentIndex =
                                      _controller.currentIndex %
                                          profiles.length;
                                  final profile = profiles[currentIndex];
                                  final toId = (profile["id"] ?? "").toString();
                                  if (toId.isEmpty) return;

                                  // Prevent sending requests to self
                                  if (_currentUserId != null &&
                                      toId == _currentUserId) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text(
                                            "You cannot send a connection request to yourself"),
                                        backgroundColor: Colors.orange,
                                        duration: Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }

                                  if (_sentRequests.contains(toId)) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text(
                                            "You already sent a request to ${profile["name"]}"),
                                        backgroundColor: Colors.orange,
                                        duration: const Duration(seconds: 2),
                                      ),
                                    );
                                    return;
                                  }
                                  // Send connection request without swiping
                                  _sendConnectionRequest(profile);
                                }
                              },
                        child: const Icon(Icons.check,
                            size: 28, color: Colors.white),
                      ),
                    ),

                    // Back button
                    Positioned(
                      top: 10,
                      left: 10,
                      child: IconButton(
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
