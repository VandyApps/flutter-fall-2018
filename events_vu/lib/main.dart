import 'package:events_vu/secrets.dart';
import 'package:flutter/material.dart';
import 'package:events_vu/logic/Events.dart';
import 'package:events_vu/ui/EventsUi.dart';
import 'package:map_view/map_view.dart';
import 'package:rxdart/rxdart.dart';

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
  final GlobalKey<ScaffoldState> scaffoldKey = GlobalKey<ScaffoldState>();
  BehaviorSubject _scrollPosition = BehaviorSubject<int>();

  final int numEventsOnStart =
      20; // number of events to retrieve on start (and each reload)

  final double margin = 8.0;

  @override
  void initState() {
    super.initState();

    // initialize events
    events = Events(numEventsOnStart);

    // use this to avoid calling `setState()` in a build method
    _scrollPosition.listen((index) {
      if (index >= events.length - 2) {
        print('adding more');
        setState(() {
          events.getEvents();
        });
      }
    });
  }

  Future<void> refreshEvents() {
    final numEventsOnScreen = events.length;

    // This is to make the user see a reload
    setState(() {
      events = Events(numEventsOnScreen);
    });

    return Future.value();
  }

  Widget _buildEventsList(BuildContext context, int index) {
    _scrollPosition.add(index);

    return EventContainer(
      eventBloc: events.list[index],
      margin: margin,
      key: Key(index.toString()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return new Scaffold(
      key: scaffoldKey,
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
              // must have itemExtent so that the scroll view can guess how much
              // that it needs jump on fast scrolls
              // TODO: look at ListView.custom & specify algorithm for finding extent
              // height of picture should be (width - 16) * 360 / 600 rounded to nearest tenth, the rest should always be 104.0 + 57.5
              itemExtent: 360 / 600 * MediaQuery.of(context).size.width +
                  104 +
                  57.5 +
                  margin * 2 * (1 - 360 / 600),
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
