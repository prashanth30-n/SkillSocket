import 'package:barter_system/chatbot.dart';
import 'package:barter_system/history.dart';
import 'package:barter_system/login.dart';
import 'package:barter_system/profile.dart';
import 'package:barter_system/reviews.dart';
import 'package:barter_system/notification.dart';
import 'package:barter_system/services/todo_service.dart';
import 'package:barter_system/services/event_service.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class TodoList extends StatelessWidget {
  final DateTime selectedDate;
  final TextEditingController controller;
  final List<Map<String, dynamic>> todos;
  final VoidCallback onAdd;
  final Function(int index, bool? value) onToggle;
  final Function(int index) onDelete;

  const TodoList({
    super.key,
    required this.selectedDate,
    required this.controller,
    required this.todos,
    required this.onAdd,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: controller,
                  decoration: const InputDecoration(
                    labelText: 'Add a to-do',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.check),
                onPressed: onAdd,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        todos.isEmpty
            ? const Center(child: Text("No tasks for today."))
            : ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: todos.length,
                itemBuilder: (context, index) {
                  final todo = todos[index];
                  return ListTile(
                    leading: Checkbox(
                      value: todo['done'],
                      onChanged: (value) => onToggle(index, value),
                    ),
                    title: Text(
                      todo['task'],
                      style: TextStyle(
                        decoration: todo['done']
                            ? TextDecoration.lineThrough
                            : TextDecoration.none,
                      ),
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.delete, color: Color(0xFF56195B)),
                      onPressed: () => onDelete(index),
                    ),
                  );
                },
              ),
      ],
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;
  final TextEditingController _todoController = TextEditingController();
  final TextEditingController _eventController = TextEditingController();
  final Map<DateTime, List<Map<String, dynamic>>> _todos = {};
  final Map<DateTime, List<Map<String, dynamic>>> _events = {};

  @override
  void initState() {
    super.initState();
    _loadTodosForDate(_focusedDay);
    _loadEventsForDate(_focusedDay);
  }

  DateTime _getDateKey(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  // Load todos from backend for specific date
  Future<void> _loadTodosForDate(DateTime date) async {
    try {
      final todos = await TodoService.getTodos(date);
      if (todos != null) {
        final dateKey = _getDateKey(date);
        setState(() {
          _todos[dateKey] = todos;
        });
      }
    } catch (e) {
      print('Error loading todos: $e');
    }
  }

  // Load events from backend for specific date
  Future<void> _loadEventsForDate(DateTime date) async {
    try {
      final events = await EventService.getEvents(date);
      if (events != null) {
        final dateKey = _getDateKey(date);
        setState(() {
          _events[dateKey] = events;
        });
      }
    } catch (e) {
      print('Error loading events: $e');
    }
  }

  void _showAddEventDialog() {
    _eventController.clear();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Add Event"),
        content: TextField(
          controller: _eventController,
          decoration: const InputDecoration(labelText: "Event Title"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () async {
              if (_eventController.text.isEmpty) return;

              final title = _eventController.text;
              final dateKey = _getDateKey(_selectedDay ?? _focusedDay);
              Navigator.pop(context);

              try {
                final newEvent = await EventService.createEvent(dateKey, title);
                if (newEvent != null) {
                  setState(() {
                    _events[dateKey] = [...(_events[dateKey] ?? []), newEvent];
                  });
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Failed to add event. Please try again.'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                }
              } catch (e) {
                print('Error adding event: $e');
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content:
                          Text('Network error. Please check your connection.'),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text("Add"),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dateKey = _getDateKey(_selectedDay ?? _focusedDay);
    final todaysTodos = _todos[dateKey] ?? [];
    final todaysEvents = _events[dateKey] ?? [];

    return Scaffold(
      drawer: Drawer(
        backgroundColor: const Color(0xFF123b53),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
                child: Row(
              children: [
                /*IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                  color: Color.fromARGB(255, 255, 255, 255),
                ),*/
                Expanded(
                  child: Align(
                    alignment: Alignment.center,
                    child: Text(
                      'SkillSocket',
                      style: TextStyle(
                          color: Color.fromARGB(255, 255, 255, 255),
                          fontSize: 39),
                    ),
                  ),
                ),
              ],
            )),
            ListTile(
              leading: Icon(
                Icons.history,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'History',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => History()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
              leading: Icon(
                Icons.reviews,
                color: Color.fromARGB(255, 255, 255, 255),
              ),
              title: Text(
                'Reviews',
                style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
              ),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Reviews()));
              },
            ),
            Divider(color: Colors.white, thickness: 1),
            ListTile(
                leading: Icon(
                  Icons.logout,
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
                title: Text(
                  'Sign Out',
                  style: TextStyle(color: Color.fromARGB(255, 255, 255, 255)),
                ),
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(context,
                      MaterialPageRoute(builder: (context) => LoginScreen()));
                }),
            Divider(color: Colors.white, thickness: 1),
          ],
        ),
      ),
      appBar: AppBar(
        centerTitle: true,
        title: Text(
          'SkillSocket',
          style: TextStyle(
              fontSize: 20,
              // fontStyle: FontStyle.italic,
              color: Color.fromARGB(255, 255, 255, 255)),
        ),
        backgroundColor: Color(0xFF123b53),
        iconTheme:
            IconThemeData(color: const Color.fromARGB(255, 255, 255, 255)),
        actions: [
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Notifications()));
              },
              icon: Icon(Icons.notifications)),
          IconButton(
              onPressed: () {
                Navigator.push(context,
                    MaterialPageRoute(builder: (context) => Profile()));
              },
              icon: Icon(Icons.person_rounded)),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TableCalendar(
                    focusedDay: _focusedDay,
                    firstDay: DateTime.utc(1970, 1, 1),
                    lastDay: DateTime.utc(2100, 12, 31),
                    selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
                    onDaySelected: (selectedDay, focusedDay) {
                      setState(() {
                        _selectedDay = selectedDay;
                        _focusedDay = focusedDay;
                      });
                      // Load todos and events for selected date
                      _loadTodosForDate(selectedDay);
                      _loadEventsForDate(selectedDay);
                    },
                    eventLoader: (day) {
                      final events = _events[_getDateKey(day)] ?? [];
                      return events
                          .map((event) => event['title'] ?? '')
                          .toList();
                    },
                    calendarFormat: _calendarFormat,
                    onFormatChanged: (format) {
                      setState(() {
                        _calendarFormat = format;
                      });
                    },
                    availableCalendarFormats: const {
                      CalendarFormat.month: 'Month',
                      CalendarFormat.week: 'Week',
                    },
                    calendarStyle: const CalendarStyle(
                      selectedDecoration: BoxDecoration(
                        color: Color.fromARGB(255, 178, 211, 240),
                        shape: BoxShape.circle,
                      ),
                      todayDecoration: BoxDecoration(
                        color: Color(0xFF123b53),
                        shape: BoxShape.circle,
                      ),
                      markerDecoration: BoxDecoration(
                        color: Colors.deepPurple,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Events on ${dateKey.toLocal().toString().split(' ')[0]}",
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: const Icon(Icons.add_circle,
                            color: Colors.deepPurple),
                        onPressed: _showAddEventDialog,
                      ),
                    ],
                  ),
                ),
                if (todaysEvents.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Column(
                      children: todaysEvents.asMap().entries.map((entry) {
                        final index = entry.key;
                        final event = entry.value;
                        return ListTile(
                          leading: const Icon(Icons.event),
                          title: Text(event['title'] ?? 'No title'),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit,
                                    color: Colors.deepPurple),
                                onPressed: () {
                                  TextEditingController editController =
                                      TextEditingController(
                                          text: event['title'] ?? '');
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text("Edit Event"),
                                      content:
                                          TextField(controller: editController),
                                      actions: [
                                        TextButton(
                                            onPressed: () =>
                                                Navigator.pop(context),
                                            child: const Text("Cancel")),
                                        TextButton(
                                          onPressed: () async {
                                            if (editController.text.isEmpty)
                                              return;

                                            final eventId = event['_id'];
                                            if (eventId == null) {
                                              Navigator.pop(context);
                                              return;
                                            }

                                            Navigator.pop(context);

                                            try {
                                              final updatedEvent =
                                                  await EventService
                                                      .updateEvent(eventId,
                                                          editController.text);
                                              if (updatedEvent != null) {
                                                setState(() {
                                                  final updatedEvents = [
                                                    ...todaysEvents
                                                  ];
                                                  updatedEvents[index] =
                                                      updatedEvent;
                                                  _events[dateKey] =
                                                      updatedEvents;
                                                });
                                              } else {
                                                if (mounted) {
                                                  ScaffoldMessenger.of(context)
                                                      .showSnackBar(
                                                    const SnackBar(
                                                      content: Text(
                                                          'Failed to update event. Please try again.'),
                                                      backgroundColor:
                                                          Colors.red,
                                                    ),
                                                  );
                                                }
                                              }
                                            } catch (e) {
                                              print('Error updating event: $e');
                                              if (mounted) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Network error. Please check your connection.'),
                                                    backgroundColor: Colors.red,
                                                  ),
                                                );
                                              }
                                            }
                                          },
                                          child: const Text("Save"),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final eventId = event['_id'];
                                  if (eventId == null) {
                                    print('Event ID is null, cannot delete');
                                    return;
                                  }

                                  try {
                                    final success =
                                        await EventService.deleteEvent(eventId);
                                    if (success) {
                                      setState(() {
                                        final updatedEvents =
                                            List<Map<String, dynamic>>.from(
                                                todaysEvents);
                                        updatedEvents.removeAt(index);
                                        _events[dateKey] = updatedEvents;
                                      });
                                    } else {
                                      if (mounted) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text(
                                                'Failed to delete event. Please try again.'),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      }
                                    }
                                  } catch (e) {
                                    print('Error deleting event: $e');
                                    if (mounted) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        const SnackBar(
                                          content: Text(
                                              'Network error. Please check your connection.'),
                                          backgroundColor: Colors.red,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  )
                else
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text("No events for today."),
                  ),
                TodoList(
                  selectedDate: dateKey,
                  controller: _todoController,
                  todos: todaysTodos,
                  onAdd: () async {
                    if (_todoController.text.isNotEmpty) {
                      final task = _todoController.text;
                      _todoController.clear();

                      try {
                        final newTodo =
                            await TodoService.createTodo(dateKey, task);
                        if (newTodo != null) {
                          setState(() {
                            _todos[dateKey] = [...todaysTodos, newTodo];
                          });
                        } else {
                          // Show error message
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text(
                                    'Failed to add todo. Please try again.'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        }
                      } catch (e) {
                        print('Error adding todo: $e');
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Network error. Please check your connection.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                  onToggle: (index, value) async {
                    final todo = todaysTodos[index];
                    final todoId = todo['_id'];

                    if (todoId == null) {
                      print('Todo ID is null, cannot update');
                      return;
                    }

                    try {
                      final updatedTodo =
                          await TodoService.updateTodo(todoId, done: value);
                      if (updatedTodo != null) {
                        setState(() {
                          final updatedTodos = [...todaysTodos];
                          updatedTodos[index] = updatedTodo;
                          _todos[dateKey] = updatedTodos;
                        });
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Failed to update todo. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error updating todo: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Network error. Please check your connection.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  onDelete: (index) async {
                    final todo = todaysTodos[index];
                    final todoId = todo['_id'];

                    if (todoId == null) {
                      print('Todo ID is null, cannot delete');
                      return;
                    }

                    try {
                      final success = await TodoService.deleteTodo(todoId);
                      if (success) {
                        setState(() {
                          final updatedTodos =
                              List<Map<String, dynamic>>.from(todaysTodos);
                          updatedTodos.removeAt(index);
                          _todos[dateKey] = updatedTodos;
                        });
                      } else {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Failed to delete todo. Please try again.'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      print('Error deleting todo: $e');
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text(
                                'Network error. Please check your connection.'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                ),
                Padding(
                  padding: EdgeInsets.all(25.0),
                ),
              ],
            )),
      ),
       floatingActionButton: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          image: DecorationImage(
            image: AssetImage('assets/new-chatbot-skyblue.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(30),
          child: InkWell(
            borderRadius: BorderRadius.circular(30),
            onTap: () {
              Navigator.push(context,
                  MaterialPageRoute(builder: (context) => ChatbotScreen()));
            },
          ),
        ),
      ),
    );
  }
}


