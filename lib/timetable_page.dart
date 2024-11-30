import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(); // Initialize Firebase
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Time Table',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
      home: TimeTablePage(),
    );
  }
}

class TimeTablePage extends StatefulWidget {
  @override
  _TimeTablePageState createState() => _TimeTablePageState();
}

class _TimeTablePageState extends State<TimeTablePage> {
  late FlutterLocalNotificationsPlugin notificationsPlugin;
  TextEditingController eventNameController = TextEditingController();
  DateTime? selectedDateTime;
  String? selectedEventId;
  bool isReminderEnabled = false;

  List<Map<String, dynamic>> events = [];

  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones(); // Initialize timezone
    notificationsPlugin = FlutterLocalNotificationsPlugin();

    final settings = InitializationSettings(
      android: AndroidInitializationSettings('@mipmap/ic_launcher'),
    );

    notificationsPlugin.initialize(settings);
    _fetchEvents();
  }

  Future<void> _fetchEvents() async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;
    QuerySnapshot snapshot = await firestore.collection('timetable').get();

    setState(() {
      events = snapshot.docs.map((doc) {
        return {
          'id': doc.id,
          'event_name': doc['event_name'],
          'event_datetime': (doc['event_datetime'] as Timestamp).toDate(),
        };
      }).toList();
    });
  }

  Future<void> _saveEvent() async {
    if (eventNameController.text.isEmpty || selectedDateTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please complete all fields')),
      );
      return;
    }

    FirebaseFirestore firestore = FirebaseFirestore.instance;

    final event = {
      'event_name': eventNameController.text,
      'event_datetime': selectedDateTime,
    };

    if (selectedEventId == null) {
      // Add new event
      DocumentReference doc = await firestore.collection('timetable').add(event);
      if (isReminderEnabled) {
        _scheduleNotification(eventNameController.text, selectedDateTime!, doc.id);
      }
    } else {
      // Update existing event
      await firestore.collection('timetable').doc(selectedEventId).update(event);
      if (isReminderEnabled) {
        _scheduleNotification(eventNameController.text, selectedDateTime!, selectedEventId!);
      }
    }

    _resetForm();
    _fetchEvents();
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Event saved successfully')));
  }

  Future<void> _scheduleNotification(String eventName, DateTime dateTime, String eventId) async {
    final tzDateTime = tz.TZDateTime.from(dateTime, tz.local);  // Ensure correct timezone

    const androidDetails = AndroidNotificationDetails(
      'timetable_channel',
      'Timetable Notifications',
      channelDescription: 'Reminder notifications for events',
      importance: Importance.high,
      priority: Priority.high,
    );

    const platformDetails = NotificationDetails(android: androidDetails);

    await notificationsPlugin.zonedSchedule(
      eventId.hashCode,
      eventName,
      'Don\'t forget your event!',
      tzDateTime,  // Correct time zone handling
      platformDetails,
      androidAllowWhileIdle: true,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }

  Future<void> _deleteEvent(String eventId) async {
    FirebaseFirestore firestore = FirebaseFirestore.instance;

    try {
      await firestore.collection('timetable').doc(eventId).delete();
      await notificationsPlugin.cancel(eventId.hashCode);
      _fetchEvents();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Event deleted successfully')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to delete event: ${e.toString()}')),
      );
    }
  }

  Future<void> _pickDateTime() async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),  // Prevent selecting past dates
      lastDate: DateTime(2101),
    );

    if (pickedDate != null) {
      TimeOfDay? pickedTime = await showTimePicker(
        context: context,
        initialTime: TimeOfDay.now(),
      );

      if (pickedTime != null) {
        DateTime selectedDateTimeWithPickedTime = DateTime(
          pickedDate.year,
          pickedDate.month,
          pickedDate.day,
          pickedTime.hour,
          pickedTime.minute,
        );

        // Check if selected time is in the past for the chosen date
        if (selectedDateTimeWithPickedTime.isBefore(DateTime.now())) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('You cannot select a past time')),
          );
        } else {
          // If the selected date is today, ensure the selected time is not in the past
          if (pickedDate.isAtSameMomentAs(DateTime.now().toLocal()) &&
              selectedDateTimeWithPickedTime.isBefore(DateTime.now())) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('You cannot select a past time today')),
            );
          } else {
            setState(() {
              selectedDateTime = selectedDateTimeWithPickedTime;
            });
          }
        }
      }
    }
  }

  void _resetForm() {
    eventNameController.clear();
    selectedDateTime = null;
    selectedEventId = null;
    isReminderEnabled = false;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Time Table'),
        backgroundColor: Colors.deepPurple,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: eventNameController,
              decoration: InputDecoration(
                labelText: 'Event Name',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.event),
              ),
            ),
            SizedBox(height: 16),
            ElevatedButton(
              onPressed: _pickDateTime,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                'Pick Date and Time',
                style: TextStyle(color: Colors.white),
              ),
            ),
            if (selectedDateTime != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  'Selected Date & Time: ${selectedDateTime!.toLocal()}',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            Row(
              children: [
                Checkbox(
                  value: isReminderEnabled,
                  onChanged: (value) {
                    setState(() {
                      isReminderEnabled = value ?? false;
                    });
                  },
                ),
                Text('Set Reminder'),
              ],
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _saveEvent,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                padding: EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(30),
                ),
              ),
              child: Text(
                selectedEventId == null ? 'Save Event' : 'Update Event',
                style: TextStyle(color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return Card(
                    elevation: 4,
                    margin: EdgeInsets.symmetric(vertical: 8),
                    child: ListTile(
                      contentPadding: EdgeInsets.all(16),
                      title: Text(
                        event['event_name'],
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text('Date: ${event['event_datetime'].toLocal()}'),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.edit),
                            onPressed: () {
                              setState(() {
                                eventNameController.text = event['event_name'];
                                selectedDateTime = event['event_datetime'];
                                selectedEventId = event['id'];
                                isReminderEnabled = true;
                              });
                            },
                          ),
                          IconButton(
                            icon: Icon(Icons.delete),
                            onPressed: () {
                              _deleteEvent(event['id']);
                            },
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
