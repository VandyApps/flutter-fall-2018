import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:events_vu/Events.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Events VU',
      theme: new ThemeData(
        primarySwatch: Colors.amber,
      ),
      home: new MyHomePage(title: 'Events VU'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  Events events = Events(); // empty events

  final int numEventsOnStart = 20; // number of events to retrieve on start (and each reload)

  final String baseUrl = 'https://anchorlink.vanderbilt.edu/api/discovery/'; // base api url
  String eventsUrl = ''; // additional url to get events

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();
    final nowUrlStr =
        now.toIso8601String().replaceAll(RegExp(r':'), '%3A').replaceAll(RegExp(r'\.[0-9]*'), '');

    // url for http get request
    eventsUrl = 'search/events?filter=EndsOn%20ge%20$nowUrlStr-05%3A00&top='
        '${numEventsOnStart.toString()}&orderBy%5B0%5D=EndsOn%20asc&query='
        '&context=%7B%22branchIds%22%3A%5B%5D%7D';

    // get request
    http
        .get(baseUrl + eventsUrl)
        .then((http.Response response) =>
            setState(() => events = Events.fromList(json.decode(response.body)['value'])))
        .catchError((error) => print('Failed to fetch data: ' + error.toString()));
  }

  Widget _buildEventsList(BuildContext context, int index) =>
      EventContainer(event: events.list[index]);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: ListView.builder(
        itemBuilder: _buildEventsList,
        itemCount: events.length,
      ),
    );
  }
}
