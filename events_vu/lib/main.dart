import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:events_vu/Events.dart';
import 'package:http/http.dart' as http;
import 'package:pull_to_refresh/pull_to_refresh.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  final String title = 'Events VU';

  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: title,
      theme: new ThemeData(
        primarySwatch: Colors.blueGrey,
      ),
      home: new MyHomePage(title: title),
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

  final int numEventsOnStart =
      20; // number of events to retrieve on start (and each reload)

  final String baseUrl =
      'https://anchorlink.vanderbilt.edu/api/discovery/'; // base api url
  String eventsUrl = ''; // additional url to get events

  final RefreshController _refreshController = RefreshController();
  final eventContainerList = <EventContainer>[];

  @override
  void initState() {
    super.initState();

    final DateTime now = DateTime.now();
    final nowUrlStr = now
        .toIso8601String()
        .replaceAll(RegExp(r':'), '%3A')
        .replaceAll(RegExp(r'\.[0-9]*'), '');

    // url for http get request
    eventsUrl = 'search/events?filter=EndsOn%20ge%20$nowUrlStr-05%3A00&top='
        '${numEventsOnStart.toString()}&orderBy%5B0%5D=EndsOn%20asc&query='
        '&context=%7B%22branchIds%22%3A%5B%5D%7D';

    // get request
    http
        .get(baseUrl + eventsUrl)
        .then((http.Response response) => setState(() =>
            events = Events.fromList(json.decode(response.body)['value'])))
        .catchError(
            (error) => print('Failed to fetch data: ' + error.toString()));
  }

  Widget _buildEventsList(BuildContext context, int index) =>
      EventContainer(event: events.list[index]);

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      appBar: new AppBar(
        title: new Text(widget.title),
      ),
      body: SmartRefresher(
        enablePullDown: true,
        enablePullUp: true,
        controller: _refreshController,
        headerBuilder: (context, mode) => ClassicIndicator(
              mode: mode,
              releaseText: 'Release to refresh',
              refreshingText: '',
              completeText: '',
              noMoreIcon: const Icon(Icons.clear, color: Colors.grey),
              failedText: 'Refresh failed',
              idleText: 'Refresh',
              iconPos: IconPosition.top,
              spacing: 5.0,
              refreshingIcon: const CircularProgressIndicator(strokeWidth: 2.0),
              failedIcon: const Icon(Icons.clear, color: Colors.grey),
              completeIcon: const Icon(Icons.done, color: Colors.grey),
              idleIcon: const Icon(Icons.arrow_downward, color: Colors.grey),
              releaseIcon: const Icon(Icons.arrow_upward, color: Colors.grey),
            ),
        footerBuilder: (context, mode) => ClassicIndicator(
              mode: mode,
              releaseText: 'Release to load',
              refreshingText: '',
              completeText: '',
              noMoreIcon: const Icon(Icons.clear, color: Colors.grey),
              failedText: 'Refresh failed',
              idleText: 'Load More',
              iconPos: IconPosition.bottom,
              spacing: 5.0,
              refreshingIcon: const CircularProgressIndicator(strokeWidth: 2.0),
              failedIcon: const Icon(Icons.clear, color: Colors.grey),
              completeIcon: const Icon(Icons.done, color: Colors.grey),
              idleIcon: const Icon(Icons.arrow_upward, color: Colors.grey),
              releaseIcon: const Icon(Icons.arrow_downward, color: Colors.grey),
            ),
        footerConfig: RefreshConfig(
          triggerDistance: 125.0,
          visibleRange: 100.0,
        ),
        headerConfig: RefreshConfig(
          triggerDistance: 125.0,
          visibleRange: 100.0,
          completeDuration: 500,
        ),
        onRefresh: (bool up) {
          if (up) {
            setState(() {});
            _refreshController.sendBack(up, RefreshStatus.completed);
          } else {
            http
                .get(baseUrl + eventsUrl + '&skip=${events.length.toString()}')
                .then((response) {
              setState(() => events.add(json.decode(response.body)['value']));
              _refreshController.sendBack(up, RefreshStatus.completed);
            }).catchError((error) =>
                    _refreshController.sendBack(up, RefreshStatus.failed));
          }
        },
        child: ListView.builder(
          itemBuilder: _buildEventsList,
          itemCount: events.length,
        ),
      ),
    );
  }
}
