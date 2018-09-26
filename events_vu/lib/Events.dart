import 'package:flutter/material.dart';

class Events {
  Set<Event> _eventsSet;

  Events() : _eventsSet = Set<Event>();

  Events.fromList(List<dynamic> l)
      : _eventsSet = l.map((item) => Event.fromMap(item)).toSet();

  List<Event> get list => _eventsSet.toList();

  int get length => _eventsSet.length;

  void add(List<dynamic> l) =>
      _eventsSet.addAll(l.map<Event>((item) => Event.fromMap(item)).toSet());
}

class Event {
  final ended;
  final eventPic;
  final org;
  final location;
  final orgPic;
  final time;
  final title;

  Event()
      : ended = null,
        eventPic = null,
        org = null,
        location = null,
        orgPic = null,
        time = null,
        title = null;

  Event.fromMap(Map<String, dynamic> m)
      : ended = m['ended'],
        eventPic = m['eventPic']?.replaceAll(RegExp(r'\("|"\);'), ''),
        org = m['org'],
        location = m['location'],
        orgPic = m['orgPic']?.replaceAll(RegExp(r'\("|"\);'), ''),
        time = m['time'],
        title = m['title'];

  @override
  bool operator ==(other) =>
      location == other.location &&
      org == other.org &&
      time == other.time &&
      title == other.title;

  @override
  int get hashCode => hashValues(location, org, time, title);
}

class EventContainer extends StatelessWidget {
  final Event event;

  EventContainer({
    Key key,
    this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        Image.network(event.eventPic),
        Text(event.title),
        Text(event.location),
        Text(event.time),
        Text(event.org),
      ],
    );
  }
}
