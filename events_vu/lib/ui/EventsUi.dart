import 'package:events_vu/logic/Events.dart';
import 'package:events_vu/ui/MapPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_view.dart';
import 'package:intl/intl.dart';

class EventContainer extends StatelessWidget {
  final EventBloc eventBloc;

  EventContainer({
    Key key,
    this.eventBloc,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.circular(4.0);
    return StreamBuilder(
      stream: eventBloc.stream,
      builder: (context, snapshot) {
        if (!snapshot.hasData)
          return SizedBox(
            width: 100.0,
            height: 100.0,
            child: Container(color: Colors.red),
          );
        Event event = snapshot.data;
        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
          shape: RoundedRectangleBorder(
            borderRadius: borderRadius,
          ),
          child: GestureDetector(
            onTap: () => event.name == null
                ? null
                : Navigator.of(context).push(MaterialPageRoute(
                    builder: (context) => EventPage(event: event))),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: borderRadius.topLeft,
                    topRight: borderRadius.topRight,
                  ),
                  child: _EventPicture(
                    imagePath: event.imagePath,
                    timeAfterEnded: event.timeAfterEnded,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      _EventTitle(title: event.name),
                      _EventDate(
                        startTime: event.startsOn,
                      ),
                      _EventLocation(
                        event: event,
                        location: event.location,
                        latitude: event.latitude,
                        longitude: event.longitude,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Container(
                    color: Colors.grey[100],
                    child: _EventOrg(
                      padding: const EdgeInsets.all(8.0),
                      orgName: event.organizationName,
                      orgNames: event.organizationNames,
                      orgPicturePath: event.organizationProfilePicture,
                      orgPicturePaths: event.organizationProfilePictures,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// EventPage represents a full page for a single event
/// Includes information like the picture, name, theme, org(s), etc.
class EventPage extends StatelessWidget {
  final Event event;

  EventPage({
    Key key,
    this.event,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(event.theme.splitMapJoin(RegExp(r'([A-Z])'),
            onMatch: (m) => m.start == 0 ? '${m.group(1)}' : ' ${m.group(1)}',
            onNonMatch: (n) => '$n')),
// Text(event.name),
      ),
      body: ListView(
        primary: false, // No scroll if unnecessary
        children: <Widget>[
          _EventPicture(
            imagePath: event.imagePath,
            timeAfterEnded: event.timeAfterEnded,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _EventTitle(
                  title: event.name,
                ),
                _EventDate(
                  startTime: event.startsOn,
                  endTime: event.endsOn,
                ),
                _EventLocation(
                  event: event,
                  location: event.location,
                  latitude: event.latitude,
                  longitude: event.longitude,
                ),
                SizedBox(
                  height: 16.0,
                  child: Center(
                    child: Container(
                      height: 0.0,
                      decoration: BoxDecoration(
                          border: Border(
                              bottom:
                                  BorderSide(width: 1.5, color: Colors.grey))),
                    ),
                  ),
                ),
                Text(
                  'Description',
                  style: Theme.of(context).textTheme.title,
                ),
                HtmlView(
                  data: event.description ?? '',
                ),
                event.categoryNames.isEmpty
                    ? Container()
                    : Text(
                        'Categories',
                        style: Theme.of(context).textTheme.title,
                      ),
                event.categoryNames.isEmpty
                    ? Container()
                    : Wrap(
                        children: event.categoryNames
                            .map((cat) => Chip(
                                  label: Text(cat),
                                ))
                            .toList(),
                        spacing: 4.0,
                      ),
                event.benefitNames.isEmpty
                    ? Container()
                    : Text(
                        'Benefits',
                        style: Theme.of(context).textTheme.title,
                      ),
                event.benefitNames.isEmpty
                    ? Container()
                    : Wrap(
                        children: event.benefitNames
                            .map((ben) => Chip(
                                  label: Text(ben),
                                ))
                            .toList(),
                        spacing: 4.0,
                      ),
                _EventOrg(
                  orgName: event.organizationName,
                  orgNames: event.organizationNames,
                  orgPicturePath: event.organizationProfilePicture,
                  orgPicturePaths: event.organizationProfilePictures,
                  condensed: false,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for the event picture
/// Also shows whether the event has ended and how long it has ended on top
/// of the picture
class _EventPicture extends StatelessWidget {
  final String imagePath;
  final bool hasEnded;
  final String timeSinceEndText;

  _EventPicture({Key key, this.imagePath, timeAfterEnded})
      : hasEnded = timeAfterEnded != null,
        timeSinceEndText = timeAfterEnded == null
            ? ''
            : (timeAfterEnded.inMinutes < 60
                ? (timeAfterEnded.inMinutes < 2
                    ? 'Ended a minute ago'
                    : 'Ended ${timeAfterEnded.inMinutes.toString()} minutes ago')
                : (timeAfterEnded.inHours < 24
                    ? (timeAfterEnded.inHours < 2
                        ? 'Ended an hour ago'
                        : 'Ended ${timeAfterEnded.inHours.toString()} hours ago')
                    : (timeAfterEnded.inDays < 2
                        ? 'Ended a day ago'
                        : 'Ended ${timeAfterEnded.inDays.toString()} days ago'))),
        super(key: key);

  Widget _picture(BuildContext context) {
    return Stack(
      children: <Widget>[
        FadeInImage.assetNetwork(
            placeholder: "assets/blank_image.png", image: imagePath),
        Opacity(
          opacity: hasEnded ? 1.0 : 0.0,
          child: Container(
            margin: const EdgeInsets.all(12.0),
            padding: const EdgeInsets.all(8.0),
            color: Colors.yellow[100],
            child: Row(
              children: <Widget>[
                Icon(Icons.access_time),
                Expanded(
                  flex: 1,
                  child: Padding(
                    padding: const EdgeInsets.only(left: 4.0),
                    child: Text(
                      timeSinceEndText,
                      style: Theme.of(context).textTheme.subhead,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _placeholder(BuildContext context) {
    return SizedBox(
      width: 1200.0,
      height: 200.0,
      child: Container(
        color: Colors.black12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (imagePath == null)
      return _placeholder(context);
    else
      return _picture(context);
  }
}

class _EventTitle extends StatelessWidget {
  final String title;
  final EdgeInsets padding;

  const _EventTitle({
    Key key,
    this.title,
    this.padding = const EdgeInsets.only(bottom: 8.0),
  }) : super(key: key);

  Widget _title(BuildContext context) {
    return Text(
      title ?? 'No title provided',
      style: Theme.of(context).textTheme.headline,
      textAlign: TextAlign.left,
    );
  }

  Widget _placeholder(BuildContext context) {
    return SizedBox(
      width: 100.0,
      height: 20.0,
      child: Container(
        color: Colors.black12,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: title == null ? _placeholder(context) : _title(context),
    );
  }
}

class _EventDate extends StatelessWidget {
//  final EdgeInsets padding;
  final DateTime startTime;
  final DateTime endTime;
  final bool showIcon;
  final EdgeInsets padding;

  const _EventDate({
    Key key,
    //this.padding,
    this.startTime,
    this.endTime,
    this.showIcon = true,
    this.padding = const EdgeInsets.only(bottom: 4.0),
  }) : super(key: key);

  String _getStartDateString() {
    DateTime d = startTime.toLocal();
    String formatStr = "EEEE, MMMM d, yyyy 'at' h:mma";
    // if it is the year we are currently in, then don't show the year, otherwise show it
    if (d.year == DateTime.now().year)
      formatStr = formatStr.replaceAll(RegExp(', yyyy'), '');
    return DateFormat(formatStr, 'en_US').format(d) + ' ' + d.timeZoneName;
  }

  String _getFullDateString() {
    DateTime d = startTime.toLocal();
    DateTime d2 = endTime.toLocal();
    String formatStr = "EEEE, MMMM d, yyyy 'at' h:mma";
    String formatStr2 = " 'to' EEEE, MMMM d, yyyy 'at' h:mma";
    // if it is the year we are currently in, then don't show the year, otherwise show it
    RegExp year = RegExp(', yyyy');
    RegExp monthDay = RegExp(', MMMM d');
    RegExp weekday = RegExp('EEEE');
    RegExp at = RegExp(" 'at' ");

    if (d.year == DateTime.now().year)
      formatStr = formatStr.replaceAll(year, '');
    if (d2.year == d.year) {
      formatStr2 = formatStr2.replaceAll(year, '');
      if (d2.day == d.day) {
        formatStr2 = formatStr2
            .replaceAll(monthDay, '')
            .replaceAll(weekday, '')
            .replaceAll(at, '');
        formatStr = formatStr.replaceAll(at, " 'from' ");
      }
    }
    return DateFormat(formatStr, 'en_US').format(d) +
        DateFormat(formatStr2, 'en_US').format(d2) +
        ' ' +
        d.timeZoneName;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          showIcon
              ? Icon(
                  Icons.event,
                  semanticLabel: 'Date',
                )
              : Container(),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: endTime != null && startTime != null
                  ? Text(
                      _getFullDateString(),
                      style: Theme.of(context).textTheme.subhead,
                    )
                  : (startTime != null
                      ? Text(
                          _getStartDateString(),
                          style: Theme.of(context).textTheme.subhead,
                        )
                      : SizedBox(
                          height: 20.0,
                          child: Container(
                            color: Colors.black12,
                          ),
                        )),
            ),
          ),
        ],
      ),
    );
  }
}

class _EventLocation extends StatelessWidget {
  final String location;
  final double latitude;
  final double longitude;
  final bool showIcon;
  final EdgeInsets padding;
  final Event event;

  _EventLocation({
    Key key,
    this.location,
    this.latitude,
    this.longitude,
    this.showIcon = true,
    this.padding = const EdgeInsets.all(0.0),
    @required this.event,
  }) : super(key: key);

  Widget _icon(context) {
    return Icon(
      Icons.location_on,
      semanticLabel: 'Location',
    );
  }

  Future _askToAddLocation(context) {
    // TODO
    print('No current location');
//    return Future<void>.value();
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
            title: Text('Add location to map?'),
            content: Text(
                'This location is not on the map yet. Would you like to place it?'),
            actions: <Widget>[
              FlatButton(
                child: Text('No'),
                onPressed: () {
                  print('Not adding location'); // TODO
                  Navigator.of(context).pop();
                },
              ),
              FlatButton(
                child: Text('Yes'),
                onPressed: () {
                  print('Adding location'); // TODO
                  Navigator.of(context).pop();
                },
              ),
            ],
          ),
    );
  }

  Widget _location(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(4.0),
      onTap: () => Navigator.of(context).push(MaterialPageRoute(
          builder: (context) => MapPage(
                event: null,
                latitude: latitude,
                longitude: longitude,
                location: location,
              ))),
//        (latitude != null && longitude != null)
//            ? print('[${latitude.toString()}, ${longitude.toString()}]')
//            : _askToAddLocation(context),
      child: Row(
        children: <Widget>[
          showIcon ? _icon(context) : Container(),
          Expanded(
            flex: 1,
            child: Padding(
              padding: const EdgeInsets.only(left: 4.0),
              child: Text(
                location ?? '',
                style: Theme.of(context).textTheme.subhead,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Row(
      children: <Widget>[
        showIcon ? _icon(context) : Container(),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(left: 4.0),
            child: SizedBox(
              width: 100.0,
              height: 20.0,
              child: Container(
                color: Colors.black12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: location == null ? _placeholder(context) : _location(context),
    );
  }
}

/// Creates a condensed version of the organizations i.e. "Hosted by 2 or more
/// organizations" or creates a list of organizations with their respective
/// profile pictures
/// If no profile picture is provided, uses the first letter of the name in
/// a circularly clipped container as the profile picture
class _EventOrg extends StatelessWidget {
  final String orgPicturePath;
  final String orgName;
  final List<String> orgNames;
  final List<String> orgPicturePaths;
  final bool condensed;
  final double pictureScale;
  final EdgeInsets padding;

  const _EventOrg({
    Key key,
    this.orgPicturePath,
    this.orgName,
    this.orgNames,
    this.orgPicturePaths,
    this.pictureScale = 2.0,
    this.condensed = true,
    this.padding = const EdgeInsets.all(0.0),
  }) : super(key: key);

  Widget _createCircleAvatar(String oName, String oPic, bool onlyOne) {
    return ClipOval(
        child: onlyOne
            ? (oPic != null
                ? Image.network(
                    oPic,
                    scale: pictureScale,
                  )
                : Container(
                    color: Colors.blueGrey,
                    constraints: BoxConstraints.expand(
                      width: 75.0 / pictureScale,
                      height: 75.0 / pictureScale,
                    ),
                    child: Center(
                      child: Text(
                        oName[0],
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 40 / pictureScale,
                          fontWeight: FontWeight.w300,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ))
            : Container(
                color: Colors.blueGrey,
                constraints: BoxConstraints.expand(
                  width: 75.0 / pictureScale,
                  height: 75.0 / pictureScale,
                ),
                child: Center(
                    child: Icon(
                  Icons.group,
                  color: Colors.white,
                )),
              ));
  }

  Widget _createSingleElement(context, onlyOne, oName, oPic) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _createCircleAvatar(oName, oPic, onlyOne),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: Text(
              onlyOne
                  ? (oName ?? 'Unknown Organization')
                  : 'Hosted by ${orgNames.length.toString()} organizations',
              style: Theme.of(context).textTheme.subhead,
            ),
          ),
        ),
      ],
    );
  }

  Widget _createMultipleElement(context) {
    return Column(
      children: Map.fromIterables(orgNames, orgPicturePaths)
          .map((name, pic) =>
              MapEntry(name, _createSingleElement(context, true, name, pic)))
          .values
          .toList(),
    );
  }

  Widget _placeholder(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        _createCircleAvatar(null, null, false),
        Expanded(
          flex: 1,
          child: Padding(
            padding: const EdgeInsets.only(left: 8.0),
            child: SizedBox(
              width: 100.0,
              height: 20.0,
              child: Container(
                color: Colors.black12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: orgName == null && orgNames == null
          ? _placeholder(context)
          : ((condensed || orgNames.length < 2)
              ? _createSingleElement(
                  context, orgNames.length < 2, orgName, orgPicturePath)
              : _createMultipleElement(context)),
    );
  }
}
