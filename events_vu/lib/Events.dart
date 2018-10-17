import 'dart:async';
import 'dart:convert';
import 'package:events_vu/MapPage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html_view/flutter_html_view.dart';
import 'package:intl/intl.dart';
import 'package:http/http.dart' as http;

// =============================================================================
// Implementation
// =============================================================================
class Events {
  List<Event> _eventsList; // list of Event objects

  Events() : _eventsList = <Event>[]; // set to empty list

  // creates Events object from a list (decoded json)
  Events.fromList(List<dynamic> l)
      : _eventsList = l.map((item) => Event.fromMap(item)).toList();

  List<Event> get list => _eventsList; // returns the

  int get length => _eventsList.length; // returns length of list

  // adds events to list
  void add(List<dynamic> l) =>
      _eventsList.addAll(l.map<Event>((item) => Event.fromMap(item)).toList());

  // TODO: implement find methods for finding a certain event
  Event find([String time, String location, String org]) {
    return null;
  }
}

// TODO
/*
The following link gets you:
1. Event website url via: items[0]['freeText'] if first word of items[0]['questionText'] is "Event"
2. Facebook event url via: items[1]['freeText'] if items[1]['questionText'] has 'Facebook' as first word
3. Additional documents if items[2]['questionText'] first words are "Additional Document"
  i. documentId via items[2]['documentId']
  ii. filename via items[2]['filename']
  iii. respondentId via items[2]['respondentId']
  iv. The file url via 'https://anchorlink.vanderbilt.edu/legacy/fileuploadquestion/
                        getdocument?documentId=${documentId}&respondentId=${respondentId}'
URL =  'https://anchorlink.vanderbilt.edu/api/discovery/event/${event._id}/additionalfields?'
*/

/// Encapsulates an event that is gotten from the anchorlink api
class Event {
  final int _id; // String
  final int _organizationId; // int
  final List<int> _organizationIds; // List<dynamic>
  final String _organizationName;
  final List<String> _organizationNames; // List<dynamic>
  final String _organizationProfilePicture;
  List<String> _organizationProfilePictures;
  final String _name;
  final String _description;
  final String _location;
  final DateTime _startsOn; // String
  final DateTime _endsOn; // String
  // Default images associated with themes in same order:
  // 'https://static.campuslabsengage.com/discovery/images/events/' followed by
  // 'artsandmusic.jpg', 'athletics.jpg', 'service.jpg', 'cultural.jpg', 'fundraising.jpg',
  // 'groupbusiness.jpg', 'social.jpg', 'spirituality.jpg', 'learning.jpg'
  String _imagePath;

  // possible themes:
  // 'Arts', 'Athletics', 'CommunityService', 'Cultural', 'Fundraising', 'GroupBusiness'
  // 'Social', 'Spirituality', 'ThoughtfulLearning'
  final String _theme;
  final List<int> _categoryIds; //? don't need
  final List<String> _categoryNames; // List<dynamic>
  final List<String> _benefitNames; // List<dynamic>
  final double _latitude; // String
  final double _longitude; // String

  // amount of time passed since event ended
  Duration _timeAfterEnded;

  Event.fromMap(Map<String, dynamic> m)
      :
        // id in integer form
        _id = int.parse(m['Id']),
        // organization in integer form
        _organizationId = m['OrganizationId'],
        // multiple orgs
        _organizationIds =
            m['OrganizationIds'].map<int>((item) => int.parse(item)).toList(),
        // org name
        _organizationName = m['OrganizationName'],
        _organizationNames = m['OrganizationNames']
            .map<String>((item) => item as String)
            .toList(),
        // sets profile pic to null if one is not available
        _organizationProfilePicture = m['OrganizationProfilePicture'] != null
            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/${m['OrganizationProfilePicture']}?preset=small-sq'
            : null,
        // name of event
        _name = m['Name'],
        // event description in HTML
        _description = m['Description'],
        // event location (name)
        _location = m['Location'],
        // start time in DateTime format
        _startsOn = DateTime.parse(m['StartsOn']),
        // end time in DateTime format
        _endsOn = DateTime.parse(m['EndsOn']),
        // null if no image
        _imagePath = m['ImagePath'] != null
            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/' +
                m['ImagePath'] +
                '?preset=med-w'
            : null,
        // theme
        _theme = m['Theme'],
        _categoryIds =
            m['CategoryIds'].map<int>((item) => int.parse(item)).toList(),
        _categoryNames =
            m['CategoryNames'].map<String>((item) => item as String).toList(),
        _benefitNames =
            m['BenefitNames'].map<String>((item) => item as String).toList(),
        // double lat
        _latitude = m['Latitude'] != null ? double.parse(m['Latitude']) : null,
        // double long
        _longitude =
            m['Longitude'] != null ? double.parse(m['Longitude']) : null {
    // sets _imagePath correctly if it is null i.e. need a default image
    if (_imagePath == null) {
      String defaultImg =
          'learning.jpg'; // if _theme is null then this is the image
      if (_theme != null) {
        // uses theme to get an image
        switch (_theme) {
          case 'Arts':
            defaultImg = _theme.toLowerCase() + 'andmusic.jpg';
            break;
          case 'ThoughtfulLearning':
          case 'CommunityService':
            defaultImg = _theme
                    .toLowerCase()
                    .replaceAll(RegExp(r'thoughtful|community'), '') +
                '.jpg';
            break;
          default:
            defaultImg = _theme.toLowerCase() + '.jpg';
            break;
        }
      }
      _imagePath =
          'https://static.campuslabsengage.com/discovery/images/events/' +
              defaultImg;
    }

    if (_organizationNames.length > 1) {
      _getOrganizationPictures();
    }
  }

  void _getOrganizationPictures() {
    http
        .get(
            'https://anchorlink.vanderbilt.edu/api/discovery/event/${_id.toString()}/organizations?')
        .then((response) {
      List<dynamic> orgs = json.decode(response.body);
      _organizationProfilePictures = _organizationIds.map((id) {
        String pic =
            orgs.singleWhere((org) => org['id'] == id)['profilePicture'];
        return pic != null
            ? 'https://se-infra-imageserver2.azureedge.net/clink/images/$pic?preset=small-sq'
            : null;
      }).toList();
    });
  }

  // returns true if updated and false if not
  void updateTime(DateTime now) {
    if (now.isAfter(_endsOn)) {
      _timeAfterEnded = now.difference(_endsOn);
    }
  }
}

// =============================================================================
// Widget / Abstraction
// =============================================================================

class EventContainer extends StatelessWidget {
  final Event event;

  EventContainer({
    Key key,
    this.event,
  }) : super(key: key) {
    event.updateTime(DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    BorderRadius borderRadius = BorderRadius.circular(4.0);

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      shape: RoundedRectangleBorder(
        borderRadius: borderRadius,
      ),
      child: GestureDetector(
        onTap: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (context) => EventPage(event: event))),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft: borderRadius.topLeft,
                topRight: borderRadius.topRight,
              ),
              child: _EventPicture(
                imagePath: event._imagePath,
                timeAfterEnded: event._timeAfterEnded,
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _EventTitle(title: event._name),
                  _EventDate(
                    startTime: event._startsOn,
                  ),
                  _EventLocation(
                    location: event._location,
                    latitude: event._latitude,
                    longitude: event._longitude,
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
                  orgName: event._organizationName,
                  orgNames: event._organizationNames,
                  orgPicturePath: event._organizationProfilePicture,
                  orgPicturePaths: event._organizationProfilePictures,
                ),
              ),
            ),
          ],
        ),
      ),
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
        title: Text(event._theme.splitMapJoin(RegExp(r'([A-Z])'),
            onMatch: (m) => m.start == 0 ? '${m.group(1)}' : ' ${m.group(1)}',
            onNonMatch: (n) => '$n')),
// Text(event._name),
      ),
      body: ListView(
        primary: false, // No scroll if unnecessary
        children: <Widget>[
          _EventPicture(
            imagePath: event._imagePath,
            timeAfterEnded: event._timeAfterEnded,
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                _EventTitle(
                  title: event._name,
                ),
                _EventDate(
                  startTime: event._startsOn,
                  endTime: event._endsOn,
                ),
                _EventLocation(
                  location: event._location,
                  latitude: event._latitude,
                  longitude: event._longitude,
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
                  data: event._description ?? '',
                ),
                event._categoryNames.isEmpty
                    ? Container()
                    : Text(
                        'Categories',
                        style: Theme.of(context).textTheme.title,
                      ),
                event._categoryNames.isEmpty
                    ? Container()
                    : Wrap(
                        children: event._categoryNames
                            .map((cat) => Chip(
                                  label: Text(cat),
                                ))
                            .toList(),
                        spacing: 4.0,
                        runSpacing: 4.0,
                      ),
                event._benefitNames.isEmpty
                    ? Container()
                    : Text(
                        'Benefits',
                        style: Theme.of(context).textTheme.title,
                      ),
                event._benefitNames.isEmpty
                    ? Container()
                    : Wrap(
                        children: event._benefitNames
                            .map((ben) => Chip(
                                  label: Text(ben),
                                ))
                            .toList(),
                        spacing: 4.0,
                        runSpacing: 4.0,
                      ),
                _EventOrg(
                  orgName: event._organizationName,
                  orgNames: event._organizationNames,
                  orgPicturePath: event._organizationProfilePicture,
                  orgPicturePaths: event._organizationProfilePictures,
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

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        Image.network(
          imagePath,
        ),
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
}

class _EventTitle extends StatelessWidget {
  final String title;
  final EdgeInsets padding;

  const _EventTitle({
    Key key,
    this.title,
    this.padding = const EdgeInsets.only(bottom: 8.0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Text(
        title ?? 'No title provided',
        style: Theme.of(context).textTheme.headline,
        textAlign: TextAlign.left,
      ),
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
    DateTime d = startTime;
    d = d.toLocal();
    String formatStr = "EEEE, MMMM d, yyyy 'at' h:mma";
    // if it is the year we are currently in, then don't show the year, otherwise show it
    if (d.year == DateTime.now().year)
      formatStr = formatStr.replaceAll(RegExp(', yyyy'), '');
    return DateFormat(formatStr, 'en_US').format(d) + ' ' + d.timeZoneName;
  }

  String _getFullDateString() {
    DateTime d = startTime;
    DateTime d2 = endTime;
    d = d.toLocal();
    d2 = d2.toLocal();
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
              child: Text(
                endTime != null && startTime != null
                    ? _getFullDateString()
                    : (startTime != null
                        ? _getStartDateString()
                        : 'No start date provided'),
                style: Theme.of(context).textTheme.subhead,
              ),
            ),
          ),
        ],
      ),
    ); // EVENT START TIME;
  }
}

class _EventLocation extends StatelessWidget {
  final String location;
  final double latitude;
  final double longitude;
  final bool showIcon;
  final EdgeInsets padding;

  const _EventLocation({
    Key key,
    this.location,
    this.latitude,
    this.longitude,
    this.showIcon = true,
    this.padding = const EdgeInsets.all(0.0),
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
    return Future<void>.value();
//    return showDialog(
//      context: context,
//      barrierDismissible: false,
//      builder: (context) => AlertDialog(
//        title: Text('Add location to map?'),
//        content: Text(
//            'This location is not on the map yet. Would you like to place it?'),
//        actions: <Widget>[
//          FlatButton(
//            child: Text('No'),
//            onPressed: () {
//              print('Not adding location'); // TODO
//              Navigator.of(context).pop();
//            },
//          ),
//          FlatButton(
//            child: Text('Yes'),
//            onPressed: () {
//              print('Adding location'); // TODO
//              Navigator.of(context).pop();
//            },
//          ),
//        ],
//      ),
//    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: InkWell(
        borderRadius: BorderRadius.circular(4.0),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(
            builder: (BuildContext context) => MapPage(
                  location: location,
                  latitude: latitude,
                  longitude: longitude,
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
      ),
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

  Widget _createCircleAvatar(oName, oPic, onlyOne) {
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

  Widget _createMultipleElement(context) {
    return Column(
      children: Map.fromIterables(orgNames, orgPicturePaths)
          .map((name, pic) =>
              MapEntry(name, _createSingleElement(context, true, name, pic)))
          .values
          .toList(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: (condensed || orgNames.length < 2)
          ? _createSingleElement(
              context, orgNames.length < 2, orgName, orgPicturePath)
          : _createMultipleElement(context),
    );
  }
}
