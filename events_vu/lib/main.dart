import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:events_vu/Events.dart';
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
  final FlutterWebviewPlugin flutterWebviewPlugin = FlutterWebviewPlugin();
  StreamSubscription<WebViewStateChanged> streamSubscription;
  Events events = Events();

  final String getEventsCode = '''
    if (document.getElementById("event-discovery-list") !== null)
     Array.from(document.getElementById("event-discovery-list").firstElementChild.children).map(d => {
      let x = d.firstElementChild.firstElementChild.firstElementChild;
      let arr = Array.from(x.children);
      let first = arr[0].firstElementChild.firstElementChild;
      let ret = {};
      ret.ended = first.firstElementChild !== null && first.firstElementChild.tagName === "DIV" ? first.firstElementChild.innerText : null;
      let match = first.lastElementChild.getAttribute('style').match(/url\(["']?(.*[^"'])["']?\)/);
      ret.eventPic = match !== null ?match[1] : null;
      ret.title = arr[1].getElementsByTagName('span')[0].innerText;
      let time_loc = Array.from(arr[2].firstElementChild.children).map(child => child.innerText);
      ret.time = time_loc[0];
      ret.location = time_loc[1];
      let imgL = arr[2].lastElementChild.getElementsByTagName('img');
      ret.orgPic = imgL.length > 0 ? imgL[0].getAttribute('src') : null;
      ret.org = arr[2].lastElementChild.getElementsByTagName('span')[0].innerText;
      return ret;
    })
    ''';
  final String getMoreCode = '''
        if(document.getElementById("event-discovery-list").nextSibling === null)
          'none'
        else
          document.getElementById("event-discovery-list").nextSibling.getElementsByTagName("button")[0].click();
      ''';
  final String reloadCode = 'location.reload(true)';

  @override
  void initState() {
    super.initState();

    flutterWebviewPlugin.close();
    flutterWebviewPlugin.launch('https://anchorlink.vanderbilt.edu/events',
        hidden: true);

    streamSubscription = flutterWebviewPlugin.onStateChanged.listen((event) {
      if (event.type == WebViewState.finishLoad) {
        streamSubscription.cancel();
        Future.doWhile(
            () => flutterWebviewPlugin.evalJavascript(getEventsCode).then((s) {
                  if (s == "null") return true;

                  setState(() => events = Events.fromList(json.decode(s)));
                  return false;
                }));
      }
    });
  }

  Widget _buildEventsList(BuildContext context, int index) {
    return EventContainer(event: events.list[index]);
  }

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
