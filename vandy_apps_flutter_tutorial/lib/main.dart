import 'dart:async';

import 'package:flutter/material.dart';

void main() => runApp(new MyApp());

class MyApp extends StatelessWidget {
  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return new MaterialApp(
      title: 'Flutter Demo',
      theme: new ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or press Run > Flutter Hot Reload in IntelliJ). Notice that the
        // counter didn't reset back to zero; the application is not restarted.
        primarySwatch: Colors.blue,
      ),
      home: new MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  MyHomePage({Key key, this.title}) : super(key: key);

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  _MyHomePageState createState() => new _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _counter = 0;

  void _incrementCounter() {
    setState(() {
      // This call to setState tells the Flutter framework that something has
      // changed in this State, which causes it to rerun the build method below
      // so that the display can reflect the updated values. If we changed
      // _counter without calling setState(), then the build method would not be
      // called again, and so nothing would appear to happen.
      _counter++;
    });
  }

  @override
  Widget build(BuildContext context) {
    // This method is rerun every time setState is called, for instance as done
    // by the _incrementCounter method above.
    //
    // The Flutter framework has been optimized to make rerunning build methods
    // fast, so that you can just rebuild anything that needs updating rather
    // than having to individually change instances of widgets.
    return new Scaffold(
      appBar: new AppBar(
        // Here we take the value from the MyHomePage object that was created by
        // the App.build method, and use it to set our appbar title.
        title: new Text(widget.title),
      ),
      body: new Center(
        // Center is a layout widget. It takes a single child and positions it
        // in the middle of the parent.
        child: new Column(
          // Column is also layout widget. It takes a list of children and
          // arranges them vertically. By default, it sizes itself to fit its
          // children horizontally, and tries to be as tall as its parent.
          //
          // Invoke "debug paint" (press "p" in the console where you ran
          // "flutter run", or select "Toggle Debug Paint" from the Flutter tool
          // window in IntelliJ) to see the wireframe for each widget.
          //
          // Column has various properties to control how it sizes itself and
          // how it positions its children. Here we use mainAxisAlignment to
          // center the children vertically; the main axis here is the vertical
          // axis because Columns are vertical (the cross axis would be
          // horizontal).
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ColorChangerTimer(),
            new Text(
              'You have pushed the button this many times:',
            ),
            ColorChanger(
              num: _counter,
              child: new Text(
                '$_counter',
                style: Theme.of(context).textTheme.display1.apply(
                      color: _counter % 2 == 0 ? Colors.white : Colors.black,
                    ),
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: new FloatingActionButton(
        onPressed: _incrementCounter,
        tooltip: 'Increment',
        child: new Icon(Icons.add),
      ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }
}

class ColorChanger extends StatelessWidget {
  ColorChanger({
    Key key,
    @required this.num,
    @required this.child,
  }) : super(key: key);

  final int num;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: num % 2 == 0 ? Colors.black : Colors.amberAccent,
      child: child,
    );
  }
}

class ColorChangerTimer extends StatefulWidget {
  @override
  _ColorChangerTimerState createState() => _ColorChangerTimerState();
}

class _ColorChangerTimerState extends State<ColorChangerTimer>
    with SingleTickerProviderStateMixin {
  Timer _timer;
  Color _color;
  AnimationController _animationController;
  Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController =
        AnimationController(duration: Duration(seconds: 4), vsync: this)
          ..addListener(() => setState(() {}));
    _animation =
        CurvedAnimation(parent: _animationController, curve: Curves.easeInOut);

    _color = Colors.purple;

    _timer = Timer.periodic(
        Duration(seconds: 2),
        (timer) => setState(() {
              _color = _color == Colors.purple ? Colors.black : Colors.purple;
            }));
    _animationController.forward();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300.0 * _animation.value,
      height: 300.0 * _animation.value,
      child: AnimatedContainer(
        duration: Duration(milliseconds: 500),
        color: _color,
      ),
    );
  }
}
