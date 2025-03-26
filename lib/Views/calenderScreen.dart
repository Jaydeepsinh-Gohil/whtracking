import 'package:calltrackinh/Views/loginscreen.dart';
import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarScreen extends StatefulWidget {
  @override
  _CalendarScreenState createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  int tapCount = 0;
  DateTime? lastTapTime;

  Future<void> _handleTap() async {

    DateTime now = DateTime.now();

    if (lastTapTime == null ||
        now.difference(lastTapTime!).inSeconds > 2) {
      // Reset counter if more than 2 seconds have passed
      tapCount = 1;
    } else {
      tapCount++;
    }

    lastTapTime = now;

    if (tapCount == 3) {
      // Navigate to another screen after 3 consecutive taps
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => LoginScreen()),
      );
      tapCount = 0; // Reset counter
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Calendar')),
      body: GestureDetector(
        onTap: _handleTap,
        child: AbsorbPointer(
          absorbing: true,
          child: TableCalendar(
            focusedDay: DateTime.now(),
            firstDay: DateTime(2000),
            lastDay: DateTime(2100),
            // daysOfWeekVisible: false
            headerVisible: false,
          ),
        ),
      ),
    );
  }

}
