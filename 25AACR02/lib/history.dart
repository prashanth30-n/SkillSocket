import 'package:flutter/material.dart';
import 'history_detail.dart'; 

class History extends StatelessWidget {
  const History({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Map<String, dynamic>> historyData = [
  {
    "type": "Class",
    "title": "Flutter Basics",
    "date": "10 June 2025",
    "time": "4:00 PM",
    "status": "Completed",
    "description": "A beginner's guide to Flutter development.",
    "completed": 5,
    "total": 8,
  },
  {
    "type": "Match",
    "title": "Skill match with Aanya",
    "date": "08 June 2025",
    "time": "2:00 PM",
    "status": "Completed",
    "description": "Skill-sharing session for UI/UX design tips.",
    "completed": 1,
    "total": 1,
  },
];


    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'History',
          style: TextStyle(
            fontSize: 30,
            //fontStyle: FontStyle.italic,
            color: Colors.white,
          ),
        ),
        backgroundColor: Color(0xFF123b53),
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: ListView.builder(
        itemCount: historyData.length,
        itemBuilder: (context, index) {
          final item = historyData[index];
          return Card(
            margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: ListTile(
              leading: Icon(
                item['type'] == 'Class' ? Icons.school : Icons.handshake,
                color: item['type'] == 'Class' ? Colors.deepPurple : Colors.green,
              ),
              title: Text(item['title'] ?? '', style: TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${item['date']} at ${item['time']}\nStatus: ${item['status']}'),
              isThreeLine: true,
              trailing: Icon(Icons.chevron_right),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => HistoryDetailPage(data: item),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
