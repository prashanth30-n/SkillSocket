import 'package:flutter/material.dart';
import 'package:barter_system/services/connection_service.dart';
import 'package:barter_system/services/notification_service.dart';
import 'package:barter_system/chat.dart';

class Notifications extends StatefulWidget {
  const Notifications({super.key});

  @override
  State<Notifications> createState() => _NotificationsState();
}

class _NotificationsState extends State<Notifications> {
  Map<String, List<Map<String, dynamic>>> notifications = {};
  bool isLoading = true;
  List<Map<String, dynamic>> connectionRequests = [];
  List<Map<String, dynamic>> allNotifications = [];
  int unreadCount = 0;
  Set<String> _processingRequests =
      {}; // Track requests being processed to prevent duplicates

  @override
  void initState() {
    super.initState();
    _loadNotifications();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Refresh notifications when returning to this screen
    // This ensures we have the latest pending connection requests
    _loadNotifications();
  }

  // Method to refresh notifications (can be called manually)
  Future<void> refreshNotifications() async {
    await _loadNotifications();
  }

  // Method to clean up processed requests from UI
  void _cleanupProcessedRequests() {
    setState(() {
      // Remove any notifications that are no longer pending
      notifications.forEach((section, notificationList) {
        notificationList.removeWhere((notification) {
          if (notification["type"] == "connection_request") {
            final status = notification["status"] ?? "pending";
            return status != "pending";
          }
          return false;
        });
      });

      // Remove empty sections
      notifications
          .removeWhere((section, notificationList) => notificationList.isEmpty);
    });
  }

  // Get current user ID for validation
  String? _getCurrentUserId() {
    // This should be implemented to get the current user's ID
    // For now, return null to skip self-request validation
    // TODO: Implement proper current user ID retrieval
    return null;
  }

  Future<void> _loadNotifications() async {
    setState(() {
      isLoading = true;
    });

    try {
      // Load both connection requests and general notifications
      final requests = await ConnectionService.getReceivedRequests();
      final notificationsData = await NotificationService.getNotifications();

      if (requests != null) {
        // Comprehensive filtering to ensure only valid pending requests
        connectionRequests = requests.where((request) {
          try {
            // Basic null check (request can't be null in where clause, but keeping for safety)

            // Check status
            final status = request["status"] ?? "pending";
            if (status != "pending") return false;

            // Check required fields
            if (request["_id"] == null || request["_id"].toString().isEmpty)
              return false;
            if (request["from"] == null) return false;

            final from = request["from"];
            if (from is! Map<String, dynamic>) return false;
            if (from["name"] == null || from["name"].toString().isEmpty)
              return false;
            if (from["_id"] == null || from["_id"].toString().isEmpty)
              return false;

            // Basic ID format validation
            if (request["_id"].toString().length < 10) return false;
            if (from["_id"].toString().length < 10) return false;

            return true;
          } catch (e) {
            print('Error validating request in filter: $e, request: $request');
            return false;
          }
        }).toList();

        print(
            'Loaded ${connectionRequests.length} valid pending connection requests');
      } else {
        connectionRequests = []; // Ensure it's not null
        print('No connection requests received from backend');
      }

      if (notificationsData != null) {
        allNotifications =
            List<Map<String, dynamic>>.from(notificationsData['data'] ?? []);
        unreadCount = notificationsData['unreadCount'] ?? 0;
      } else {
        allNotifications = []; // Ensure it's not null
        unreadCount = 0;
      }

      _buildNotificationsMap();

      // Clean up any processed requests from UI
      _cleanupProcessedRequests();
    } catch (e) {
      print('Error loading notifications: $e');
      // Set empty arrays on error to prevent null issues
      connectionRequests = [];
      allNotifications = [];
      unreadCount = 0;
      _buildNotificationsMap();
    }

    setState(() {
      isLoading = false;
    });
  }

  void _buildNotificationsMap() {
    Map<String, List<Map<String, dynamic>>> tempNotifications = {
      "Today": [],
    };

    // Add general notifications (excluding message notifications)
    for (var notification in allNotifications) {
      // Skip message notifications - they don't belong in notifications tab
      if ((notification['type'] ?? '') == 'message') continue;

      final String title = (notification['title'] ?? '').toString();
      final String body = (notification['body'] ?? '').toString();
      final sender = notification['sender'];
      final String? profileImage = sender is Map<String, dynamic>
          ? (sender['profileImage'] as String?)
          : null;

      tempNotifications["Today"]!.add({
        "id": notification['_id'] ?? '',
        "type": notification['type'] ?? 'normal',
        // Normalize for UI: map to user/action so Text.rich never gets nulls
        "user": title.isNotEmpty ? title : 'Notification',
        "action": body,
        "title": title,
        "body": body,
        "time": NotificationService.formatNotificationTime(
            (notification['createdAt'] ?? '').toString()),
        "icon": Icons.notifications,
        "profileImage": profileImage,
        "read": notification['read'] ?? false,
        "data": notification['data'] ?? {},
      });
    }

    // Add connection requests (only valid pending ones)
    for (var request in connectionRequests) {
      try {
        // Comprehensive validation before adding
        // (request can't be null in for loop, but keeping for safety)

        // Validate request ID
        if (request["_id"] == null || request["_id"].toString().isEmpty) {
          print('Skipping request with invalid ID: $request');
          continue;
        }

        // Validate from user data
        if (request["from"] == null) {
          print('Skipping request with null from data: $request');
          continue;
        }

        final from = request["from"];
        if (from is! Map<String, dynamic>) {
          print('Skipping request with invalid from data type: $from');
          continue;
        }

        // Validate from user required fields
        if (from["name"] == null || from["name"].toString().isEmpty) {
          print('Skipping request with invalid from name: $from');
          continue;
        }

        if (from["_id"] == null || from["_id"].toString().isEmpty) {
          print('Skipping request with invalid from ID: $from');
          continue;
        }

        // Ensure only pending requests are shown
        final status = request["status"] ?? "pending";
        if (status != "pending") {
          print(
              'Skipping non-pending request: ${request["_id"]} with status: $status');
          continue;
        }

        // Validate request ID format (should be valid ObjectId)
        final requestId = request["_id"].toString();
        if (requestId.length < 10) {
          // Basic ObjectId validation
          print('Skipping request with invalid ID format: $requestId');
          continue;
        }

        // Validate from user ID format
        final fromUserId = from["_id"].toString();
        if (fromUserId.length < 10) {
          // Basic ObjectId validation
          print(
              'Skipping request with invalid from user ID format: $fromUserId');
          continue;
        }

        // Additional safety check - ensure request is not from self
        // This should be handled by backend, but adding extra safety
        if (fromUserId == _getCurrentUserId()) {
          print('Skipping self-request: $fromUserId');
          continue;
        }

        // All validations passed - add to notifications
        tempNotifications["Today"]!.add({
          "type": "connection_request",
          "requestId": requestId,
          "user": from["name"].toString(),
          "userId": fromUserId,
          "profileImage": from["profileImage"] ?? from["logo"],
          "userEmail": from["email"],
          "action": "sent you a connection request",
          "message": request["message"] ?? "",
          "time": _formatTime(request["createdAt"]),
          "icon": Icons.person_add,
          "accepted": false,
          "status": status,
        });

        print('Added valid connection request: ${from["name"]} (${requestId})');
      } catch (e) {
        print('Error processing connection request: $e, request: $request');
        continue; // Skip this request and continue with others
      }
    }

    // Removed sample profile messages as requested

    setState(() {
      notifications = tempNotifications;
    });
  }

  String _formatTime(String timestamp) {
    try {
      final dateTime = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(dateTime);

      if (difference.inMinutes < 1) {
        return 'Just now';
      } else if (difference.inHours < 1) {
        return '${difference.inMinutes}m ago';
      } else if (difference.inDays < 1) {
        return '${difference.inHours}h ago';
      } else {
        return '${difference.inDays}d ago';
      }
    } catch (e) {
      return 'Recently';
    }
  }

  void _showOverlayMessage(String message) {
    OverlayEntry overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: 100,
        left: MediaQuery.of(context).size.width * 0.2,
        width: MediaQuery.of(context).size.width * 0.6,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(30),
            ),
            child: Center(
              child: Text(
                message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 14),
              ),
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(overlayEntry);
    Future.delayed(const Duration(seconds: 2), () {
      overlayEntry.remove();
    });
  }

  Future<void> _acceptConnectionRequest(String section, int index) async {
    final notification = notifications[section]?[index];
    if (notification == null) return;

    final requestId = notification["requestId"];
    final userName = notification["user"] ?? "User";
    final userId = notification["userId"];

    // Validate required fields
    if (requestId == null || requestId.toString().isEmpty) {
      _showOverlayMessage("Invalid request");
      return;
    }

    if (userId == null || userId.toString().isEmpty) {
      _showOverlayMessage("Invalid user");
      return;
    }

    // Prevent multiple requests for the same request
    final requestIdStr = requestId.toString();
    if (_processingRequests.contains(requestIdStr)) {
      _showOverlayMessage("Request is already being processed");
      return;
    }

    // Mark as processing
    setState(() {
      _processingRequests.add(requestIdStr);
    });

    try {
      final success =
          await ConnectionService.acceptConnectionRequest(requestId.toString());

      if (success) {
        setState(() {
          // Remove the notification after successful acceptance
          if (notifications[section] != null) {
            notifications[section]!.removeAt(index);
            if (notifications[section]!.isEmpty) {
              notifications.remove(section);
            }
          }
          // Remove from processing set
          _processingRequests.remove(requestIdStr);
        });

        _showOverlayMessage("Connection request accepted!");

        // Navigate to chat after a short delay
        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => Chat(
                  chatId: '${userId}_connection',
                  recipientId: userId,
                  name: userName,
                ),
              ),
            );
          }
        });
      } else {
        // Treat as already handled (idempotent UX)
        setState(() {
          if (notifications[section] != null) {
            notifications[section]!.removeAt(index);
            if (notifications[section]!.isEmpty) {
              notifications.remove(section);
            }
          }
          // Remove from processing set
          _processingRequests.remove(requestIdStr);
        });
        _showOverlayMessage("Request already handled");
      }
    } catch (e) {
      print('Error accepting connection request: $e');
      // Fail-soft: assume handled to keep UX clean
      setState(() {
        if (notifications[section] != null) {
          notifications[section]!.removeAt(index);
          if (notifications[section]!.isEmpty) {
            notifications.remove(section);
          }
        }
        // Remove from processing set
        _processingRequests.remove(requestIdStr);
      });
      _showOverlayMessage("Request already handled");
    }
  }

  Future<void> _rejectConnectionRequest(String section, int index) async {
    final notification = notifications[section]?[index];
    if (notification == null) return;

    final requestId = notification["requestId"];

    // Validate required fields
    if (requestId == null || requestId.toString().isEmpty) {
      _showOverlayMessage("Invalid request");
      return;
    }

    // Prevent multiple requests for the same request
    final requestIdStr = requestId.toString();
    if (_processingRequests.contains(requestIdStr)) {
      _showOverlayMessage("Request is already being processed");
      return;
    }

    // Mark as processing
    setState(() {
      _processingRequests.add(requestIdStr);
    });

    try {
      final success =
          await ConnectionService.rejectConnectionRequest(requestId.toString());

      if (success) {
        setState(() {
          notifications[section]?.removeAt(index);
          if (notifications[section]?.isEmpty ?? false) {
            notifications.remove(section);
          }
          // Remove from processing set
          _processingRequests.remove(requestIdStr);
        });

        _showOverlayMessage("Connection request rejected");
      } else {
        // Treat as already handled (idempotent UX)
        setState(() {
          notifications[section]?.removeAt(index);
          if (notifications[section]?.isEmpty ?? false) {
            notifications.remove(section);
          }
          // Remove from processing set
          _processingRequests.remove(requestIdStr);
        });
        _showOverlayMessage("Request already handled");
      }
    } catch (e) {
      print('Error rejecting connection request: $e');
      // Fail-soft: assume handled to keep UX clean
      setState(() {
        notifications[section]?.removeAt(index);
        if (notifications[section]?.isEmpty ?? false) {
          notifications.remove(section);
        }
        // Remove from processing set
        _processingRequests.remove(requestIdStr);
      });
      _showOverlayMessage("Request already handled");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Notifications',
          style: TextStyle(
            fontSize: 32,
            fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        backgroundColor: const Color(0xFF123b53),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadNotifications,
          ),
        ],
      ),
      body: isLoading
          ? const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF123b53),
              ),
            )
          : notifications.isEmpty
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.notifications_none,
                        size: 64,
                        color: Colors.grey,
                      ),
                      SizedBox(height: 16),
                      Text(
                        'No notifications yet',
                        style: TextStyle(
                          fontSize: 18,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                )
              : ListView(
                  children: notifications.entries.map((entry) {
                    String section = entry.key;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Text(
                            section,
                            style: const TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        ...entry.value.asMap().entries.map((notifEntry) {
                          int index = notifEntry.key;
                          Map<String, dynamic> notif = notifEntry.value;

                          if (notif["type"] == "connection_request") {
                            bool isAccepted = notif["accepted"] ?? false;

                            return Card(
                              margin: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 8),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12)),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Row(
                                  children: [
                                    CircleAvatar(
                                      radius: 28,
                                      backgroundColor: const Color(0xFF123b53),
                                      backgroundImage: (notif["profileImage"] !=
                                                  null &&
                                              (notif["profileImage"] as String)
                                                  .isNotEmpty)
                                          ? NetworkImage(notif["profileImage"])
                                          : null,
                                      child: (notif["profileImage"] == null ||
                                              (notif["profileImage"] as String)
                                                  .isEmpty)
                                          ? Icon(notif["icon"],
                                              color: Colors.white)
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "${notif["user"]} ${notif["action"]}",
                                            style: const TextStyle(
                                                fontSize: 16,
                                                fontWeight: FontWeight.bold),
                                          ),
                                          const SizedBox(height: 4),
                                          if (notif["message"] != null &&
                                              notif["message"].isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                  bottom: 4),
                                              child: Text(
                                                notif["message"],
                                                style: const TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.black87),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                          Text(
                                            notif["time"],
                                            style: const TextStyle(
                                                color: Colors.grey,
                                                fontSize: 12),
                                          ),
                                          const SizedBox(height: 8),
                                          isAccepted
                                              ? Row(
                                                  children: const [
                                                    Icon(Icons.check_circle,
                                                        color: Colors.green),
                                                    SizedBox(width: 6),
                                                    Text(
                                                      "Accepted",
                                                      style: TextStyle(
                                                        color: Colors.green,
                                                        fontWeight:
                                                            FontWeight.bold,
                                                      ),
                                                    ),
                                                  ],
                                                )
                                              : Row(
                                                  children: [
                                                    ElevatedButton.icon(
                                                      onPressed: () {
                                                        _acceptConnectionRequest(
                                                            section, index);
                                                      },
                                                      icon: const Icon(
                                                          Icons.check),
                                                      label:
                                                          const Text("Accept"),
                                                      style: ElevatedButton
                                                          .styleFrom(
                                                        backgroundColor:
                                                            Colors.green,
                                                        foregroundColor:
                                                            Colors.white,
                                                      ),
                                                    ),
                                                    const SizedBox(width: 10),
                                                    OutlinedButton.icon(
                                                      onPressed: () {
                                                        _rejectConnectionRequest(
                                                            section, index);
                                                      },
                                                      icon: const Icon(
                                                          Icons.close),
                                                      label:
                                                          const Text("Decline"),
                                                      style: OutlinedButton
                                                          .styleFrom(
                                                        foregroundColor:
                                                            Colors.red,
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          } else {
                            return Padding(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0, vertical: 8),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    radius: 24,
                                    backgroundColor: const Color(0xFF123b53),
                                    child: Icon(notif["icon"],
                                        color: Colors.white),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text.rich(
                                          TextSpan(
                                            children: [
                                              TextSpan(
                                                text: (notif["user"] ??
                                                        notif["title"] ??
                                                        'Notification')
                                                    .toString(),
                                                style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    color: Colors.black),
                                              ),
                                              TextSpan(
                                                text: ' ' +
                                                    (notif["action"] ??
                                                            notif["body"] ??
                                                            '')
                                                        .toString(),
                                                style: const TextStyle(
                                                    color: Colors.black),
                                              ),
                                            ],
                                          ),
                                          softWrap: true,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          notif["time"] ?? '',
                                          style: const TextStyle(
                                              fontSize: 12, color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                  if (notif["showThumbnail"] == true)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 8.0),
                                      child: Container(
                                        width: 50,
                                        height: 50,
                                        decoration: BoxDecoration(
                                          color: Colors.grey[300],
                                          borderRadius:
                                              BorderRadius.circular(8),
                                        ),
                                        child: const Icon(Icons.image,
                                            color: Colors.black54),
                                      ),
                                    ),
                                ],
                              ),
                            );
                          }
                        }).toList(),
                      ],
                    );
                  }).toList(),
                ),
    );
  }
}
