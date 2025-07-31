import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

class CalendarEvent {
  final String title;
  final DateTime date;

  CalendarEvent({required this.title, required this.date});
}

class CalendarPage extends StatefulWidget {
  final List<CalendarEvent> events;

  const CalendarPage({super.key, required this.events});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage>
    with TickerProviderStateMixin {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  CalendarFormat _calendarFormat = CalendarFormat.month;

  late final Map<DateTime, List<CalendarEvent>> _eventsMap;

  @override
  void initState() {
    super.initState();
    _selectedDay = _focusedDay;
    _eventsMap = _groupEvents(widget.events);
  }

  Map<DateTime, List<CalendarEvent>> _groupEvents(List<CalendarEvent> events) {
    Map<DateTime, List<CalendarEvent>> map = {};
    for (var event in events) {
      final key = DateTime(event.date.year, event.date.month, event.date.day);
      map.putIfAbsent(key, () => []).add(event);
    }
    return map;
  }

  List<CalendarEvent> _getEventsForDay(DateTime day) {
    return _eventsMap[DateTime(day.year, day.month, day.day)] ?? [];
  }

  void _onViewChanged(String view) {
    setState(() {
      if (view == 'Month') {
        _calendarFormat = CalendarFormat.month;
      } else if (view == 'Week') {
        _calendarFormat = CalendarFormat.week;
      } else {
        // Day view simulated by selecting the day directly
        _calendarFormat = CalendarFormat.twoWeeks;
      }
    });
  }

  void _showEventsDialog(DateTime date) {
    final events = _getEventsForDay(date);
    showDialog(
      context: context,
      builder:
          (ctx) => AlertDialog(
            title: Text('Events on ${date.toLocal().toString().split(' ')[0]}'),
            content:
                events.isEmpty
                    ? const Text('No events.')
                    : Column(
                      mainAxisSize: MainAxisSize.min,
                      children:
                          events
                              .map((e) => ListTile(title: Text(e.title)))
                              .toList(),
                    ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Close'),
              ),
            ],
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calendar'),
        bottom: TabBar(
          controller: TabController(length: 3, vsync: this),
          onTap: (index) => _onViewChanged(['Month', 'Week', 'Day'][index]),
          tabs: const [Tab(text: 'Month'), Tab(text: 'Week'), Tab(text: 'Day')],
        ),
      ),
      body: Column(
        children: [
          TableCalendar<CalendarEvent>(
            firstDay: DateTime.utc(2020, 1, 1),
            lastDay: DateTime.utc(2030, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (day) => isSameDay(_selectedDay, day),
            calendarFormat: _calendarFormat,
            eventLoader: _getEventsForDay,
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
              _showEventsDialog(selected);
            },
            calendarStyle: const CalendarStyle(
              markerDecoration: BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
