import 'package:events_vu/secrets.dart';
import 'package:flutter/material.dart';
import 'package:events_vu/logic/Events.dart';
import 'package:events_vu/ui/EventsUi.dart';
import 'package:http/http.dart' as http;
import 'package:map_view/map_view.dart';

/*
NOTE
I have created another file called secrets.dart and stored my API key there.
You can do the same and this will work.
 */
void main() {
  MapView.setApiKey(API_KEY);
  runApp(new MyApp());
}

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
  Events events;

  final int numEventsOnStart =
      20; // number of events to retrieve on start (and each reload)

  @override
  void initState() {
    super.initState();

    // initialize events
    events = Events(numEventsOnStart);
  }

  Future<void> refreshEvents() {
    final numEventsOnScreen = events.length;

    // This is to make the user see a reload
    setState(() {
      events = Events(numEventsOnStart);
    });

    return events.getEvents(numEventsOnScreen);
  }

  Widget _buildEventsList(BuildContext context, int index) {
    return EventContainer(
      eventBloc: events.list[index],
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
//      appBar: AppBar(
//        title: Text(widget.title),
//      ),
      body: SafeArea(
        child: NestedScrollView(
          headerSliverBuilder: (BuildContext context, bool innerBoxScrolled) =>
              <Widget>[
                SliverAppBar(
                  title: Text(widget.title),
                  floating: true,
                  snap: true,
                ),
              ],
          body: RefreshIndicator(
            child: ListView.builder(
              itemBuilder: _buildEventsList,
              itemCount: events.length,
            ),
            onRefresh: refreshEvents,
          ),
        ),
//        SmartRefresher(
//          enablePullDown: true,
//          enablePullUp: true,
//          controller: _refreshController,
//          headerBuilder: (context, mode) => ClassicIndicator(
//                mode: mode,
//                releaseText: 'Release to refresh',
//                refreshingText: '',
//                completeText: '',
//                noMoreIcon: const Icon(Icons.clear, color: Colors.grey),
//                failedText: 'Refresh failed',
//                idleText: 'Refresh',
//                iconPos: IconPosition.top,
//                spacing: 5.0,
//                refreshingIcon:
//                    const CircularProgressIndicator(strokeWidth: 2.0),
//                failedIcon: const Icon(Icons.clear, color: Colors.grey),
//                completeIcon: const Icon(Icons.done, color: Colors.grey),
//                idleIcon: const Icon(Icons.arrow_downward, color: Colors.grey),
//                releaseIcon: const Icon(Icons.arrow_upward, color: Colors.grey),
//              ),
//          footerBuilder: (context, mode) => ClassicIndicator(
//                mode: mode,
//                releaseText: 'Release to load',
//                refreshingText: '',
//                completeText: '',
//                noMoreIcon: const Icon(Icons.clear, color: Colors.grey),
//                failedText: 'Refresh failed',
//                idleText: 'Load More',
//                iconPos: IconPosition.bottom,
//                spacing: 5.0,
//                refreshingIcon:
//                    const CircularProgressIndicator(strokeWidth: 2.0),
//                failedIcon: const Icon(Icons.clear, color: Colors.grey),
//                completeIcon: const Icon(Icons.done, color: Colors.grey),
//                idleIcon: const Icon(Icons.arrow_upward, color: Colors.grey),
//                releaseIcon:
//                    const Icon(Icons.arrow_downward, color: Colors.grey),
//              ),
//          footerConfig: RefreshConfig(
//            triggerDistance: 125.0,
//            visibleRange: 100.0,
//          ),
//          headerConfig: RefreshConfig(
//            triggerDistance: 125.0,
//            visibleRange: 100.0,
//            completeDuration: 500,
//          ),
//          onRefresh: (bool up) {
//            if (up) {
//              setState(() {});
//              _refreshController.sendBack(up, RefreshStatus.completed);
//            } else {
//              http
//                  .get(
//                      baseUrl + eventsUrl + '&skip=${events.length.toString()}')
//                  .then((response) {
//                setState(() => events.add(response.body));
//                _refreshController.sendBack(up, RefreshStatus.completed);
//              }).catchError((error) =>
//                      _refreshController.sendBack(up, RefreshStatus.failed));
//            }
//          },
//          // TODO: find a way to load fake content first then replace it
//          // TODO: maybe use streams???
//          child: ListView.builder(
//            itemBuilder: _buildEventsList,
//            itemCount: events.length,
//          ),
//        ),
      ),
    );
  }
}

// IDEA: refresh + infinite scroll where items are fake loaded until you get there
// IDEA: back to top button
// IDEA: use chips for searching based on certain tags / orgs
